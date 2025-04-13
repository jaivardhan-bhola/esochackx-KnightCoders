from flask import Flask, request, jsonify
import os
from dotenv import load_dotenv
import json
from flask_cors import CORS 
from civic_sense_complain import process_complaint
from civic_sense_message_community import (
    analyze_social_media_post,
    load_deepfake_model,
    analyze_local_images,
    extract_urls,
    is_news_url,
    analyze_news_url
)

# Load environment variables
load_dotenv(".env")
serper_api_key = os.getenv("SERPER_API_KEY")

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Load deepfake model once when the server starts
deepfake_model = load_deepfake_model("deepfake_model.pt")

@app.route('/health', methods=['GET'])
def health_check():
    """Simple health check endpoint"""
    return jsonify({
        "status": "ok",
        "model_loaded": deepfake_model is not None,
    })

@app.route('/process_complaint', methods=['POST'])
def process_complaint_api():
    """Process a civic complaint"""
    data = request.json
    if not data:
        return jsonify({"error": "No data provided"}), 400
    
    complaint = data.get('complaint')
    location = data.get('location')
    image_path = data.get('image_path')
    
    if not complaint or not location:
        return jsonify({"error": "Complaint and location are required"}), 400
    
    complainer_view, officer_view = process_complaint(complaint, location, image_path)
    
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

if __name__ == '__main__':
    # Check if model is loaded
    if deepfake_model is None:
        print("WARNING: Deepfake model could not be loaded.")
        print("Image analysis features will be unavailable.")
    else:
        print("Deepfake model loaded successfully.")
    
    # Run Flask server
    app.run(host='0.0.0.0', port=7122, debug=True)