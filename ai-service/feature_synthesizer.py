"""
Feature Synthesizer: Analyzes multiple images, extracts the best features
from each, and composites them into a single high-quality output image.

Features analyzed per image:
  - Sharpness (Laplacian variance)
  - Color richness (saturation histogram)
  - Brightness balance (luminance analysis)
  - Face quality (detection + alignment)
  - Skin tone (HSV skin-range analysis)

The synthesizer aligns faces across all input images, picks the best regions 
from each source image based on quality scores, and blends them together.
"""

import cv2
import numpy as np
import os
import time
import uuid
import sys

# Add local path for FaceRestoreHelper if needed
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), 'CodeFormer')))

try:
    from facexlib.utils.face_restoration_helper import FaceRestoreHelper
    FACEXLIB_AVAILABLE = True
except ImportError:
    FACEXLIB_AVAILABLE = False


def _compute_sharpness(img_gray):
    """Laplacian variance — higher = sharper."""
    return cv2.Laplacian(img_gray, cv2.CV_64F).var()


def _compute_color_richness(img_bgr):
    """Mean saturation in HSV space — higher = more vivid."""
    hsv = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2HSV)
    return float(np.mean(hsv[:, :, 1]))


def _compute_brightness_score(img_bgr):
    """How close average luminance is to ideal mid-range (120-140)."""
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    mean_val = float(np.mean(gray))
    # Score peaks at 130, drops away from it
    return max(0, 100 - abs(mean_val - 130))


def _compute_skin_quality(img_bgr):
    """Detect skin-tone pixels and score their smoothness."""
    hsv = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2HSV)
    # Skin tone range in HSV
    lower = np.array([0, 20, 70], dtype=np.uint8)
    upper = np.array([20, 255, 255], dtype=np.uint8)
    mask = cv2.inRange(hsv, lower, upper)
    skin_ratio = np.count_nonzero(mask) / mask.size
    if skin_ratio < 0.01:
        return 0.0
    # Smoothness of skin region (lower Laplacian = smoother)
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    skin_region = cv2.bitwise_and(gray, gray, mask=mask)
    lap = cv2.Laplacian(skin_region, cv2.CV_64F)
    smoothness = max(0, 100 - lap.var() * 0.1)
    return float(smoothness * skin_ratio * 10)


def _compute_contrast(img_bgr):
    """Standard deviation of luminance — higher = more contrast."""
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    return float(np.std(gray))


def _detect_face_region(img_bgr):
    """Detect the largest face bounding box."""
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    cascade_paths = [
        cv2.data.haarcascades + 'haarcascade_frontalface_default.xml',
        cv2.data.haarcascades + 'haarcascade_frontalface_alt2.xml',
    ]
    for path in cascade_paths:
        if os.path.exists(path):
            cascade = cv2.CascadeClassifier(path)
            faces = cascade.detectMultiScale(gray, 1.1, 5, minSize=(60, 60))
            if len(faces) > 0:
                faces = sorted(faces, key=lambda f: f[2] * f[3], reverse=True)
                return faces[0]  # (x, y, w, h)
    return None


FEATURE_LIST = [
    "Sharpness & Detail",
    "Color Richness",
    "Brightness Balance",
    "Skin Quality",
    "Contrast & Depth",
    "Face Structure",
]


def analyze_image(img_bgr, filename="unknown"):
    """Analyze a single image and return feature scores."""
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    face_rect = _detect_face_region(img_bgr)

    scores = {
        "Sharpness & Detail": round(_compute_sharpness(gray), 2),
        "Color Richness": round(_compute_color_richness(img_bgr), 2),
        "Brightness Balance": round(_compute_brightness_score(img_bgr), 2),
        "Skin Quality": round(_compute_skin_quality(img_bgr), 2),
        "Contrast & Depth": round(_compute_contrast(img_bgr), 2),
        "Face Structure": 80.0 if face_rect is not None else 10.0,
    }

    return {
        "filename": filename,
        "scores": scores,
        "face_rect": face_rect,
        "overall": round(sum(scores.values()) / len(scores), 2),
    }


def _align_faces(images):
    """
    Align faces across all images.
    1. Try FaceRestoreHelper (A+)
    2. Fallback to Feature Matching (B)
    """
    if len(images) < 2:
        return images

    aligned_images = [images[0]]  # First image is the reference
    
    # --- Option A: facexlib (Best for Faces) ---
    if FACEXLIB_AVAILABLE:
        try:
            helper = FaceRestoreHelper(1, face_size=512, crop_ratio=(1, 1), det_model='retinaface_resnet50', device='cpu')
            for i in range(1, len(images)):
                helper.clean_all()
                helper.read_image(images[i])
                num_faces = helper.get_face_landmarks_5(only_center_face=True)
                if num_faces > 0:
                    helper.align_warp_face()
                    if len(helper.cropped_faces) > 0:
                        aligned_images.append(helper.cropped_faces[0])
                        continue
                aligned_images.append(images[i])
            return aligned_images
        except Exception as e:
            print(f"facexlib alignment failed: {e}")

    # --- Option B: Feature Matching Fallback (Prevents 'Mixed' Ghosting) ---
    print("Using Fallback Feature Alignment...")
    orb = cv2.ORB_create(1000)
    kp1, des1 = orb.detectAndCompute(images[0], None)
    
    for i in range(1, len(images)):
        try:
            kp2, des2 = orb.detectAndCompute(images[i], None)
            bf = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)
            matches = bf.match(des1, des2)
            matches = sorted(matches, key=lambda x: x.distance)
            
            if len(matches) > 10:
                src_pts = np.float32([kp1[m.queryIdx].pt for m in matches]).reshape(-1, 1, 2)
                dst_pts = np.float32([kp2[m.trainIdx].pt for m in matches]).reshape(-1, 1, 2)
                M, mask = cv2.findHomography(dst_pts, src_pts, cv2.RANSAC, 5.0)
                
                h, w = images[0].shape[:2]
                aligned = cv2.warpPerspective(images[i], M, (w, h))
                aligned_images.append(aligned)
            else:
                aligned_images.append(images[i])
        except Exception as e:
            print(f"Fallback alignment error for image {i}: {e}")
            aligned_images.append(images[i])
            
    return aligned_images


def _create_feature_mask(img_bgr, feature_name):
    """Create a soft mask for a specific feature region."""
    h, w = img_bgr.shape[:2]
    mask = np.zeros((h, w), dtype=np.float32)

    if feature_name == "Face Structure":
        face_rect = _detect_face_region(img_bgr)
        if face_rect is not None:
            x, y, fw, fh = face_rect
            pad_x, pad_y = int(fw * 0.25), int(fh * 0.25)
            x1, y1 = max(0, x - pad_x), max(0, y - pad_y)
            x2, y2 = min(w, x + fw + pad_x), min(h, y + fh + pad_y)
            mask[y1:y2, x1:x2] = 1.0
            # Higher blur for smoother blending
            mask = cv2.GaussianBlur(mask, (0, 0), sigmaX=fw * 0.25)
        return mask

    if feature_name == "Skin Quality":
        hsv = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2HSV)
        lower = np.array([0, 20, 70], dtype=np.uint8)
        upper = np.array([20, 255, 255], dtype=np.uint8)
        skin_mask = cv2.inRange(hsv, lower, upper).astype(np.float32) / 255.0
        # Very high blur for skin transitions
        skin_mask = cv2.GaussianBlur(skin_mask, (45, 45), 0)
        return skin_mask

    if feature_name in ("Sharpness & Detail", "Contrast & Depth"):
        gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
        lap = np.abs(cv2.Laplacian(gray, cv2.CV_64F))
        lap = (lap / (lap.max() + 1e-6)).astype(np.float32)
        lap = cv2.GaussianBlur(lap, (31, 31), 0)
        return lap

    mask[:] = 1.0
    return mask


def analyze_image(img_bgr, filename):
    """Analyze image quality for different features."""
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    
    # 1. Sharpness (Laplacian variance)
    sharpness = cv2.Laplacian(gray, cv2.CV_64F).var()
    
    # 2. Color (Saturation variance)
    hsv = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2HSV)
    color_richness = hsv[:, :, 1].mean()
    
    # 3. Brightness
    brightness = hsv[:, :, 2].mean()
    
    # 4. Facial Quality (Focus on eyes and skin)
    face_rect = _detect_face_region(img_bgr)
    face_score = 0
    eye_score = 0
    if face_rect is not None:
        x, y, w, h = face_rect
        face_roi = gray[y:y+h, x:x+w]
        face_score = cv2.Laplacian(face_roi, cv2.CV_64F).var()
        
        # Eye-openness heuristic: look for high-contrast 'pupil' regions in the upper half of the face
        eye_roi = face_roi[int(h*0.2):int(h*0.5), :]
        eye_score = cv2.Laplacian(eye_roi, cv2.CV_64F).var()
        
    return {
        "overall": (sharpness * 0.5) + (face_score * 0.5),
        "scores": {
            "Sharpness & Detail": sharpness,
            "Face Structure": face_score,
            "Skin Quality": 100 - (cv2.meanStdDev(gray)[1][0][0] * 0.5), # Lower variance in skin can mean smoother
            "Color Richness": color_richness,
            "Brightness Balance": brightness,
            "Eye Clarity": eye_score
        }
    }


def synthesize_images(images, filenames, results_dir, fidelity_weight=0.5):
    """
    Main synthesis pipeline:
    1. Align faces across all images
    2. Analyze images for quality (including eye openness)
    3. Select best sources for each feature
    4. Composite without ghosting or closed eyes
    5. Final AI Enhancement
    """
    if len(images) == 0:
        return None, []

    # 1. Align and Normalize
    if len(images) >= 2:
        proc_images = _align_faces(images)
    else:
        proc_images = images

    max_h = max(img.shape[0] for img in proc_images)
    max_w = max(img.shape[1] for img in proc_images)
    norm_images = [cv2.resize(img, (max_w, max_h), interpolation=cv2.INTER_LANCZOS4) for img in proc_images]
    h, w = norm_images[0].shape[:2]

    # 2. Analyze each image
    analyses = [analyze_image(img, fn) for img, fn in zip(norm_images, filenames)]

    # 3. Feature Selection
    extracted_features = []
    for feature_name in FEATURE_LIST:
        # Special logic for eyes: use 'Eye Clarity' to pick source
        target_score = "Eye Clarity" if feature_name == "Face Structure" else feature_name
        
        best_idx = 0
        best_score = -1
        for i, a in enumerate(analyses):
            score = a["scores"].get(target_score, a["scores"].get(feature_name, 0))
            if score > best_score:
                best_score = score
                best_idx = i

        extracted_features.append({
            "feature": feature_name,
            "original_name": filenames[best_idx],
            "clip_score": min(1.0, best_score / 100.0),
            "source_index": best_idx,
        })

    # 4. Composite: Region Replacement Strategy (Anti-Ghosting)
    # 1. Pick the best eye/face anchor
    eye_scores = [a["scores"]["Eye Clarity"] for a in analyses]
    base_idx = int(np.argmax(eye_scores))
    
    # Start with the best frame as the foundation
    composite = norm_images[base_idx].astype(np.float64)
    h, w = composite.shape[:2]

    # 2. Surgical Replacement (No mixing = No ghosting)
    # We replace specific regions from better sources if they exist.
    for ef in extracted_features:
        src_idx = ef["source_index"]
        if src_idx == base_idx: continue
        
        # Only replace if the source is significantly better
        if ef["clip_score"] < 0.2: continue

        src_img = norm_images[src_idx].astype(np.float64)
        mask = _create_feature_mask(norm_images[src_idx], ef["feature"])
        
        # For structural features (Face/Sharpness), we use surgery (Replacement)
        # For non-structural (Color), we use subtle blending
        if ef["feature"] in ("Face Structure", "Sharpness & Detail", "Eye Clarity"):
            # Surgically replace the region
            mask_3ch = np.stack([mask] * 3, axis=-1)
            # Use a harder replacement to ensure no ghosting (mixture)
            composite = composite * (1 - mask_3ch) + src_img * mask_3ch
        else:
            # Subtle color/lighting blend
            mask_3ch = np.stack([mask] * 3, axis=-1)
            blend_strength = ef["clip_score"] * 0.25
            weighted_mask = mask_3ch * blend_strength
            composite = composite * (1 - weighted_mask) + src_img * weighted_mask

    composite = np.clip(composite, 0, 255).astype(np.uint8)

    # 5. Final AI pass: Reconstruct the details and heal surgery sites
    from enhancer import FaceEnhancer
    enhancer = FaceEnhancer()
    # Ensure identity preservation by using a higher fidelity anchor
    effective_fidelity = max(0.5, fidelity_weight) 
    final_img = enhancer.enhance(composite, fidelity_weight=effective_fidelity)

    # 6. Save and return
    fname = f"fusion_{int(time.time())}_{uuid.uuid4().hex[:6]}.jpg"
    path = os.path.join(results_dir, fname)
    cv2.imwrite(path, final_img, [int(cv2.IMWRITE_JPEG_QUALITY), 95])

    final_analysis = analyze_image(final_img, "fusion")
    return fname, extracted_features, final_analysis["overall"]
