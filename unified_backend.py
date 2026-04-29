import os
import sys

# Priority 1: Force local CodeFormer paths before anything else starts
cf_path = os.path.abspath(os.path.join(os.getcwd(), 'ai-service', 'CodeFormer'))
if os.path.exists(cf_path):
    sys.path.insert(0, cf_path)
    # Add internal basicsr path just in case
    sys.path.insert(0, os.path.join(cf_path, 'basicsr'))

import time
import uuid
import json
import base64
import cv2
import numpy as np
from fastapi import FastAPI, UploadFile, File, Form, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.responses import Response, JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from typing import List

# Compatibility patch for basicsr/torchvision
import sys
try:
    import torchvision.transforms.functional as F
    sys.modules['torchvision.transforms.functional_tensor'] = F
except ImportError:
    pass

# Import our enhancer and feature synthesizer
import sys
sys.path.append(os.path.join(os.getcwd(), 'ai-service'))
from enhancer import FaceEnhancer
from feature_synthesizer import analyze_image, synthesize_images

app = FastAPI(title="Synthora AI Unified Backend")

# CORS setup
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Directories
BASE_DIR = os.getcwd()
UPLOAD_DIR = os.path.join(BASE_DIR, "demo", "uploads")
RESULTS_DIR = os.path.join(BASE_DIR, "demo", "results")
HISTORY_FILE = os.path.join(BASE_DIR, "demo", "history.json")

for d in [UPLOAD_DIR, RESULTS_DIR]:
    if not os.path.exists(d):
        os.makedirs(d, exist_ok=True)

# Initialize Enhancer
print("Loading AI Model (Enhancer)...")
enhancer = FaceEnhancer()
print("AI Model loaded.")

# --- MOCK AUTH ---

@app.post("/auth/login")
async def login(creds: dict):
    return {
        "success": True, 
        "user": {"id": "demo-user", "email": creds.get("email", "guest@example.com")},
        "session": {"access_token": "demo-token"}
    }

@app.post("/auth/signup")
async def signup(creds: dict):
    return {"success": True, "user": {"id": "demo-user", "email": creds.get("email")}}

# --- DATA STORAGE (JSON MOCK) ---

def load_history():
    if os.path.exists(HISTORY_FILE):
        with open(HISTORY_FILE, 'r') as f:
            return json.load(f)
    return []

def save_history(entry):
    history = load_history()
    history.insert(0, entry)
    with open(HISTORY_FILE, 'w') as f:
        json.dump(history[:50], f)

@app.get("/user-history")
async def get_history():
    return {"success": True, "history": load_history()}

@app.get("/user-credits")
async def get_credits():
    return {"success": True, "credits": 1250}

# --- ENHANCEMENT ---

@app.post("/upload-images")
async def enhance_images(
    images: List[UploadFile] = File(...),
    fidelity_weight: float = Form(0.5)
):
    results = []
    
    for file in images:
        try:
            contents = await file.read()
            nparr = np.frombuffer(contents, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            if img is None:
                results.append({"original": file.filename, "error": "Invalid image"})
                continue
                
            # Run AI Enhancement
            enhanced_img = enhancer.enhance(img, fidelity_weight=fidelity_weight)
            
            # Save Result
            filename = f"enhanced_{int(time.time())}_{uuid.uuid4().hex[:6]}.jpg"
            save_path = os.path.join(RESULTS_DIR, filename)
            cv2.imwrite(save_path, enhanced_img, [int(cv2.IMWRITE_JPEG_QUALITY), 95])
            
            enhanced_url = f"/results/{filename}"
            
            # Record History
            entry = {
                "id": str(uuid.uuid4()),
                "original_name": file.filename,
                "enhanced_url": enhanced_url,
                "created_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
            }
            save_history(entry)
            
            results.append({
                "original": file.filename,
                "enhanced_url": enhanced_url,
                "success": True
            })
            
        except Exception as e:
            print(f"Error processing {file.filename}: {e}")
            results.append({"original": file.filename, "error": str(e)})

    return {
        "success": True, 
        "results": results,
        "enhanced_url": results[0]["enhanced_url"] if results else None
    }

# --- FEATURE SYNTHESIS (Multi-Image → One Composite) ---

@app.post("/synthesize-features")
async def synthesize_features(
    images: List[UploadFile] = File(...),
    fidelity_weight: float = Form(0.5)
):
    """
    Accept multiple images, analyze each for quality features,
    extract the best features from each, and composite them
    into a single high-quality output image.
    """
    if len(images) < 2:
        raise HTTPException(status_code=400, detail="Please upload at least 2 images for synthesis")

    decoded_images = []
    filenames = []

    for file in images:
        try:
            contents = await file.read()
            nparr = np.frombuffer(contents, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            if img is not None:
                decoded_images.append(img)
                filenames.append(file.filename)
        except Exception as e:
            print(f"Error reading {file.filename}: {e}")

    if len(decoded_images) < 2:
        raise HTTPException(status_code=400, detail="Could not decode enough valid images")

    try:
        result = synthesize_images(decoded_images, filenames, RESULTS_DIR, fidelity_weight=fidelity_weight)

        if result is None:
            raise HTTPException(status_code=500, detail="Synthesis failed")

        filename, extracted_features, overall_score = result
        synthesized_url = f"/results/{filename}"

        # Build per-image analysis for diagnostics
        per_image_analysis = []
        for img, fn in zip(decoded_images, filenames):
            analysis = analyze_image(img, fn)
            per_image_analysis.append({
                "filename": fn,
                "scores": analysis["scores"],
                "overall": analysis["overall"],
            })

        # Record in history
        entry = {
            "id": str(uuid.uuid4()),
            "original_name": f"Fusion of {len(filenames)} photos",
            "enhanced_url": synthesized_url,
            "created_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "type": "fusion",
        }
        save_history(entry)

        return {
            "success": True,
            "enhanced_url": synthesized_url,
            "extracted_features": extracted_features,
            "per_image_analysis": per_image_analysis,
            "overall_score": overall_score,
            "source_count": len(decoded_images),
        }

    except HTTPException:
        raise
    except Exception as e:
        print(f"Synthesis error: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

# --- WEBSOCKET FOR LIVE STREAM ---

@app.websocket("/ws/enhance")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_text()
            # Decode base64 frame
            if ',' in data:
                encoded_data = data.split(',')[1]
            else:
                encoded_data = data
                
            nparr = np.frombuffer(base64.b64decode(encoded_data), np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            if img is not None:
                # Enhance (skip heavy beautify for speed)
                enhanced = enhancer.enhance(img, fidelity_weight=0.5, skip_beautify=True)
                
                _, buffer = cv2.imencode('.jpg', enhanced, [int(cv2.IMWRITE_JPEG_QUALITY), 90])
                b64_str = base64.b64encode(buffer).decode('utf-8')
                
                await websocket.send_text(f"data:image/jpeg;base64,{b64_str}")
    except WebSocketDisconnect:
        pass
    except Exception as e:
        print(f"WS Error: {e}")

# --- STATIC FILES ---

app.mount("/results", StaticFiles(directory=RESULTS_DIR), name="results")

@app.get("/")
async def root():
    return {"message": "Synthora AI Unified Backend is running"}

if __name__ == "__main__":
    import uvicorn
    # Try port 8000
    uvicorn.run(app, host="127.0.0.1", port=5001)
