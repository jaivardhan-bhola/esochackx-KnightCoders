from flask import Flask, request, jsonify
import os
import sys
from dotenv import load_dotenv
import json
from flask_cors import CORS 
import tempfile
from werkzeug.utils import secure_filename
from civic_sense_complain import process_complaint
from civic_sense_message_community import (
    analyze_social_media_post,
    load_deepfake_model,
    analyze_local_images,
    extract_urls,
    is_news_url,
    analyze_news_url
)
import torch
import torch.nn as nn
import torch.nn.functional as F
import torchvision.models as models
import torchvision.transforms as T
from PIL import Image
# Import LangChain components for search_and_summarize
from langchain_groq import ChatGroq
from langchain.chains import load_summarize_chain
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.utilities import GoogleSerperAPIWrapper
from langchain_core.documents import Document

# Load environment variables
load_dotenv(".env")
serper_api_key = os.getenv("SERPER_API_KEY")
groq_api_key = os.getenv("GROQ_API_KEY")

# Initialize LangChain components
llm = ChatGroq(model="llama3-8b-8192", api_key=groq_api_key)
text_splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
summarize_chain = load_summarize_chain(llm, chain_type="map_reduce")
search = GoogleSerperAPIWrapper(serper_api_key=serper_api_key)

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Configure upload settings
UPLOAD_FOLDER = tempfile.gettempdir()  # Use system temp directory
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}  # Added webp format
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max upload

# Load deepfake model once when the server starts
deepfake_model = load_deepfake_model("deepfake_model.pt")

# === Skin Disease Model Setup ===

# Class mapping for skin disease
skin_class_map = {
    'nv': 'Melanocytic nevi',
    'mel': 'Melanoma',
    'bkl': 'Benign keratosis-like lesions',
    'bcc': 'Basal cell carcinoma',
    'akiec': 'Actinic keratoses',
    'vasc': 'Vascular lesions',
    'df': 'Dermatofibroma'
}
skin_class_labels = list(skin_class_map.values())

def load_skin_model(path='health0check-feature/skin-disease-model2.pth'):
    try:
        model = models.densenet121(pretrained=False)
        model.classifier = nn.Linear(model.classifier.in_features, 7)
        state_dict = torch.load(path, map_location='cpu')
        model.load_state_dict(state_dict, strict=False)
        model.eval()
        return model
    except Exception as e:
        print(f"Error loading skin model: {e}")
        return None

def preprocess_skin_image(image_path):
    transform = T.Compose([
        T.Resize((224, 224)),
        T.ToTensor(),
        T.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])
    image = Image.open(image_path).convert("RGB")
    image_tensor = transform(image).unsqueeze(0)
    return image_tensor

def predict_skin(model, image_tensor):
    with torch.no_grad():
        output = model(image_tensor)
        probs = F.softmax(output, dim=1)
        pred_idx = torch.argmax(probs, dim=1).item()
        confidence = probs[0][pred_idx].item()
        
        print(f"output")
    return skin_class_labels[pred_idx], confidence

skin_model = load_skin_model()
print(f"Skin disease model loaded: {'Successfully' if skin_model is not None else 'Failed'}")
if skin_model is None:
    print("WARNING: Skin disease model could not be loaded.")
    print("Please ensure the file exists at 'health0check-feature/skin-disease-model2.pth'")
    print("Current working directory: " + os.getcwd())

def allowed_file(filename):
    """Check if the file has an allowed extension"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/health', methods=['GET'])
def health_check():
    """Simple health check endpoint"""
    return jsonify({
        "status": "ok",
        "deepfake_model_loaded": deepfake_model is not None,
        "skin_model_loaded": skin_model is not None,
    })

@app.route('/process_complaint', methods=['POST'])
def process_complaint_api():
    """Process a civic complaint"""
    # Initialize variables to avoid UnboundLocalError
    complaint = None
    location = None
    image_path = None
    
    print(f"Request received: {request.method}, Content-Type: {request.content_type}")
    print(f"Request form: {request.form}")
    print(f"Request files: {list(request.files.keys())}")
    
    # Check if the request is multipart (contains a file)
    if request.content_type and 'multipart/form-data' in request.content_type:
        # Handle file upload
        if request.files and 'image' in request.files:
            file = request.files['image']
            if file and file.filename and allowed_file(file.filename):
                filename = secure_filename(file.filename)
                file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
                file.save(file_path)
                image_path = file_path
                print(f"Image saved to temp location: {file_path}")
                print(f"Image exists: {os.path.exists(file_path)}, Size: {os.path.getsize(file_path)} bytes")
        
        # Get form data when uploading files
        complaint = request.form.get('complaint')
        location = request.form.get('location')
        
        print(f"From form data - Complaint: {complaint is not None}, Location: {location is not None}")
    else:
        # Handle regular JSON data
        data = request.get_json(silent=True)
        if data:
            complaint = data.get('complaint')
            location = data.get('location')
            print(f"From JSON data - Complaint: {complaint is not None}, Location: {location is not None}")
    
    # Validate required fields
    if not complaint or not location:
        print("Error: Missing complaint or location")
        return jsonify({
            "error": "Complaint and location are required", 
            "received": {
                "complaint": complaint is not None,
                "location": location is not None,
                "content_type": request.content_type
            }
        }), 400
    
    # Check if image exists before processing
    if image_path and os.path.exists(image_path):
        print(f"Processing complaint with image: {image_path}")
    else:
        print(f"Image path invalid or not provided, processing without image")
        image_path = None  # Reset to None if path doesn't exist
    
    # Process the complaint
    complainer_view, officer_view = process_complaint(complaint, location, image_path)
    
    # Clean up temp file if one was created
    if image_path and os.path.exists(image_path):
        try:
            os.remove(image_path)
            print(f"Temporary image file removed: {image_path}")
        except Exception as e:
            # Log the error but don't fail the request
            print(f"Warning: Failed to remove temp file: {e}")
    
    return jsonify({
        "complainer_view": complainer_view,
        "officer_view": officer_view
    })

@app.route('/analyze_post', methods=['POST'])
def analyze_post_api():
    """Analyze a social media post for fake news/deepfakes"""
    data = request.json
    if not data:
        return jsonify({"error": "No data provided"}), 400
    
    post_text = data.get('post_text')
    image_paths = data.get('image_paths', [])
    
    if not post_text:
        return jsonify({"error": "Post text is required"}), 400
    
    if deepfake_model is None:
        return jsonify({"error": "Deepfake model is not loaded"}), 500
    
    # Extract and analyze URLs from the post
    urls = extract_urls(post_text)
    news_urls = [url for url in urls if is_news_url(url)]
    
    results = {}
    for news_url in news_urls:
        verdict, reason = analyze_news_url(news_url, serper_api_key, deepfake_model)
        results[news_url] = {"verdict": verdict, "reason": reason}
    
    # Analyze local images if provided
    if image_paths:
        verdict, reason = analyze_local_images(image_paths, deepfake_model)
        results["local_images"] = {"verdict": verdict, "reason": reason}
    
    return jsonify({
        "results": results,
        "urls_found": urls,
        "news_urls_found": news_urls
    })

@app.route('/predict_skin_disease', methods=['POST'])
def predict_skin_disease_api():
    """Predict skin disease from an uploaded image"""
    print("Skin disease prediction request received")
    
    if skin_model is None:
        print("ERROR: Skin disease model not loaded")
        return jsonify({"error": "Skin disease model not loaded"}), 500
    
    if 'image' not in request.files:
        print("ERROR: No image file in request")
        return jsonify({"error": "No image uploaded"}), 400
    
    file = request.files['image']
    print(f"Received file: {file.filename if file and file.filename else 'No filename'}")
    
    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(file_path)
        print(f"Image saved to: {file_path}")
        print(f"Image exists: {os.path.exists(file_path)}, Size: {os.path.getsize(file_path)} bytes")
        
        try:
            print("Preprocessing image...")
            image_tensor = preprocess_skin_image(file_path)
            print("Running prediction...")
            prediction, confidence = predict_skin(skin_model, image_tensor)
            print(f"Prediction successful: {prediction}, confidence: {confidence}")
            
            # Get additional information about the disease
            print(f"Retrieving additional information about {prediction}...")
            disease_info = search_and_summarize(prediction)
            
            # Clean up
            os.remove(file_path)
            print(f"Temporary file removed: {file_path}")
            
            return jsonify({
                "prediction": prediction,
                "confidence": confidence,
                "symptoms": disease_info.get("Symptoms", "No information available"),
                "treatment": disease_info.get("Treatment", "No information available"),
                "prevention": disease_info.get("Prevention", "No information available")
            })
        except Exception as e:
            print(f"ERROR during prediction: {str(e)}")
            if os.path.exists(file_path):
                os.remove(file_path)
                print(f"Cleaned up temporary file after error: {file_path}")
            return jsonify({"error": str(e)}), 500
    else:
        print(f"Invalid file type: {file.filename if file and file.filename else 'No file'}")
        return jsonify({"error": "Invalid file type"}), 400

def search_and_summarize(disease_name):
    """
    Search for information about a disease and summarize the results.
    Returns information about symptoms, treatment, and prevention.
    """
    queries = {
        "Symptoms": f"What are the symptoms of {disease_name}?",
        "Treatment": f"What are the treatments for {disease_name}?",
        "Prevention": f"How to prevent {disease_name}?"
    }
    result = {}
    for key, query in queries.items():
        print(f"🔍 Fetching {key} info for {disease_name}...")
        try:
            raw = search.run(query)
            docs = [Document(page_content=t) for t in text_splitter.split_text(raw)]
            result[key] = summarize_chain.run(docs)
            print(f"✅ Successfully retrieved {key} information")
        except Exception as e:
            print(f"❌ Error retrieving {key} information: {str(e)}")
            result[key] = f"Could not retrieve information: {str(e)}"
    return result

if __name__ == '__main__':
    # Print Python and system information for debugging
    print(f"Python version: {sys.version}")
    print(f"Running on platform: {sys.platform}")
    print(f"Upload folder: {UPLOAD_FOLDER}")
    
    # Check if model is loaded
    if deepfake_model is None:
        print("WARNING: Deepfake model could not be loaded.")
        print("Image analysis features will be unavailable.")
    else:
        print("Deepfake model loaded successfully.")
    
    # Run Flask server
    app.run(host='0.0.0.0', port=7122, debug=True)