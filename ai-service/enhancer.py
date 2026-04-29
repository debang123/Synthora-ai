import sys
import os
import cv2
import torch
import numpy as np
import traceback

# --- Compatibility patch for basicsr/torchvision ---
import sys
try:
    import torchvision.transforms.functional as F
    sys.modules['torchvision.transforms.functional_tensor'] = F
except ImportError:
    pass

# Add local path for CodeFormer and its internal modules
cf_path = os.path.abspath(os.path.join(os.path.dirname(__file__), 'CodeFormer'))
# We append to end to prefer global basicsr IF it works, 
# but we will manually import the arch if needed.
if cf_path not in sys.path:
    sys.path.append(cf_path)

try:
    from torchvision.transforms.functional import normalize
    from basicsr.utils import img2tensor, tensor2img
    from facexlib.utils.face_restoration_helper import FaceRestoreHelper
    
    # Robust architecture import
    try:
        from basicsr.archs.codeformer_arch import CodeFormer
    except ImportError:
        from codeformer_arch import CodeFormer
    
    CODEFORMER_AVAILABLE = True
except ImportError as e:
    print(f"Warning: CodeFormer dependencies not fully installed. Error: {e}")
    CODEFORMER_AVAILABLE = False


def _beautify(img_bgr):
    """
    Post-processing pipeline for natural results:
    1. Bilateral filter   → subtle skin smoothing
    2. CLAHE              → balanced contrast
    3. Unsharp mask       → micro-detail sharpening
    4. Color balance      → natural vibrancy boost
    5. Gamma correction   → luminance lift
    """
    try:
        # ── 1. Subtle skin smoothing ──────────────────────────────────────────
        smooth = cv2.bilateralFilter(img_bgr, d=7, sigmaColor=25, sigmaSpace=25)

        # ── 2. CLAHE contrast enhancement ──────────────────────────────────────
        lab = cv2.cvtColor(smooth, cv2.COLOR_BGR2LAB)
        l, a, b = cv2.split(lab)
        clahe = cv2.createCLAHE(clipLimit=1.5, tileGridSize=(8, 8))
        l = clahe.apply(l)
        lab = cv2.merge([l, a, b])
        contrast_img = cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)

        # ── 3. Gentle sharpening ──────────────────────────────────────────────
        gaussian = cv2.GaussianBlur(contrast_img, (0, 0), sigmaX=1.5)
        sharp = cv2.addWeighted(contrast_img, 1.3, gaussian, -0.3, 0)

        # ── 4. Natural Color Boost ─────────────────────────────────────────────
        hsv = cv2.cvtColor(sharp, cv2.COLOR_BGR2HSV).astype(np.float32)
        hsv[:, :, 1] = np.clip(hsv[:, :, 1] * 1.12, 0, 255)   # +12% saturation
        vibrant = cv2.cvtColor(hsv.astype(np.uint8), cv2.COLOR_HSV2BGR)

        # ── 5. Subtle gamma lift ──────────────────────────────────────────────
        gamma = 0.96
        lut = np.array([((i / 255.0) ** gamma) * 255 for i in range(256)], dtype=np.uint8)
        final = cv2.LUT(vibrant, lut)

        return final
    except Exception as e:
        print(f"Beautify Error: {e}")
        return img_bgr


class FaceEnhancer:
    def __init__(self):
        if not CODEFORMER_AVAILABLE:
            self.mock_mode = True
            return

        self.mock_mode = False

        # Device selection: MPS (Apple Silicon) → CUDA → CPU
        if torch.backends.mps.is_available():
            self.device = torch.device('mps')
        elif torch.cuda.is_available():
            self.device = torch.device('cuda')
        else:
            self.device = torch.device('cpu')

        print(f"Using device: {self.device}")

        self.codeformer_net = None
        self.face_helper = None
        self._load_models()

    def _load_models(self):
        codeformer_model_path = os.path.abspath(os.path.join(os.path.dirname(__file__), 'CodeFormer', 'weights', 'codeformer.pth'))

        if not os.path.exists(codeformer_model_path):
            print(f"Model not found at {codeformer_model_path}. Operating in MOCK mode.")
            self.mock_mode = True
            return

        try:
            self.codeformer_net = CodeFormer(
                dim_embd=512, codebook_size=1024, n_head=8, n_layers=9,
                connect_list=['32', '32', '32']
            ).to(self.device)
            checkpoint = torch.load(codeformer_model_path, map_location=self.device)['params_ema']
            self.codeformer_net.load_state_dict(checkpoint, strict=False)
            self.codeformer_net.eval()

            self.face_helper = FaceRestoreHelper(
                1, face_size=512, crop_ratio=(1, 1),
                det_model='retinaface_resnet50',
                save_ext='png', use_parse=True,
                device=torch.device('cpu')
            )
        except Exception as e:
            print(f"Error loading models: {e}")
            self.mock_mode = True

    def enhance(self, img_np, fidelity_weight=0.5, skip_beautify=False):
        if self.mock_mode:
            # Fallback to just beautification
            return _beautify(img_np) if not skip_beautify else img_np

        try:
            self.face_helper.clean_all()
            self.face_helper.read_image(img_np)

            num_det_faces = self.face_helper.get_face_landmarks_5(
                only_center_face=False, resize=640, eye_dist_threshold=5
            )

            if num_det_faces == 0:
                return _beautify(img_np) if not skip_beautify else img_np

            self.face_helper.align_warp_face()

            for cropped_face in self.face_helper.cropped_faces:
                cropped_face_t = img2tensor(cropped_face / 255., bgr2rgb=True, float32=True)
                normalize(cropped_face_t, (0.5, 0.5, 0.5), (0.5, 0.5, 0.5), inplace=True)
                cropped_face_t = cropped_face_t.unsqueeze(0).to(self.device)

                with torch.no_grad():
                    output = self.codeformer_net(cropped_face_t, w=fidelity_weight, adain=True)[0]
                    restored_face = tensor2img(output, rgb2bgr=True, min_max=(-1, 1))
                
                self.face_helper.add_restored_face(restored_face)

            self.face_helper.get_inverse_affine(None)
            restored_img = self.face_helper.paste_faces_to_input_image()
            
            return _beautify(restored_img) if not skip_beautify else restored_img
        except Exception as e:
            print(f"Enhance logic error: {e}")
            return _beautify(img_np) if not skip_beautify else img_np
