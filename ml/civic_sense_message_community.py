# Import Required Libraries
import re
import requests
from bs4 import BeautifulSoup
import numpy as np
from PIL import Image as PILImage
import io
import spacy
import torch
from torchvision import transforms

# URL Extraction & Filtering
def extract_urls(text):
    # Regex to extract URLs
    url_pattern = r'https?://\S+'
    return re.findall(url_pattern, text)

def is_news_url(url):
    # Expanded list of keywords and domain fragments from various regions
    news_keywords = [
        "news", "bbc", "cnn", "nytimes", "theguardian", "reuters", "foxnews", "nbc", "abcnews", "usatoday",
        "washingtonpost", "latimes", "npr", "aljazeera", "economist", "bloomberg", "cnbc", "dailymail",
        "hindustantimes", "indiatimes", "timesofindia", "indianexpress", "thehindu", "dnaindia", "firstpost",
        "news18", "zeenews", "oneindia", "timesnow", "ibtimes", "expressindia", "thequint", "newsx", "aajtak",
        "tribune", "thetimes", "post", "herald", "channelnewsasia", "scmp", "telegraph", "thedaily", "guardian",
        "abc", "cbs", "msnbc", "usat", "global", "daily", "breaking", "bulletin", "chronicle"
    ]
    url_lower = url.lower()
    return any(keyword in url_lower for keyword in news_keywords)

# Scrape Website Text & Image URLs
def scrape_website(url):
    try:
        response = requests.get(url)
        if response.status_code != 200:
            return None, None
        soup = BeautifulSoup(response.text, 'html.parser')
        paragraphs = soup.find_all('p')
        text_content = ' '.join(p.get_text() for p in paragraphs)
        images = [img['src'] for img in soup.find_all('img')
                  if 'src' in img.attrs and not img['src'].startswith('data:')]
        return text_content, images
    except Exception as e:
        return None, None

# Fact Check Text Using Google API
def check_text_fact(text, api_key):
    endpoint = "https://factchecktools.googleapis.com/v1alpha1/claims:search"
    params = {"query": text, "key": api_key}
    try:
        response = requests.get(endpoint, params=params)
        if response.status_code != 200:
            return "Fact Check API inaccessible", None
        data = response.json()
        if 'claims' in data and data['claims']:
            claim = data['claims'][0]
            review = claim.get('claimReview', [{}])[0]
            rating = review.get('textualRating', 'Unknown')
            detail = review.get('title', 'No additional details')
            return rating, detail
        return "No fact-check found (URL not in Fact-Check domain)", None
    except Exception as e:
        return "Error: " + str(e), None

# PyTorch Deepfake Model Setup
transform_pipeline = transforms.Compose([
    transforms.Resize((128, 128)),
    transforms.ToTensor(),
])

def load_deepfake_model(model_path="deepfake_model.pt"):
    try:
        # Load model with weights_only=False (if you trust the checkpoint)
        model = torch.load(model_path, map_location=torch.device("cpu"), weights_only=False)
        model.eval()
        return model
    except Exception as e:
        print("Failed to load deepfake model:", e)
        return None

# Check Deepfake on a Single Image
def check_image_deepfake(image_source, model):
    """
    image_source: either a URL (if it starts with 'http') or a local file path.
    """
    try:
        if image_source.startswith("http"):
            response = requests.get(image_source, stream=True)
            if response.status_code != 200:
                return "Image not accessible"
            img = PILImage.open(io.BytesIO(response.content)).convert('RGB')
        else:
            img = PILImage.open(image_source).convert('RGB')
        img = transform_pipeline(img)
        img = img.unsqueeze(0)  # Add batch dimension
        with torch.no_grad():
            output = model(img)
        prediction = output[0].item()  # Adjust threshold based on your model's output
        return "Deepfake" if prediction > 0.5 else "Real"
    except Exception as e:
        return "Invalid Image (" + str(e) + ")"

# Analyze Images for Deepfake
def check_images_for_deepfake(image_list, model):
    results = {}
    for img_source in image_list:
        results[img_source] = check_image_deepfake(img_source, model)
    return results

# Analyze News URL and Return Decision
def analyze_news_url(url, api_key, model):
    text, images = scrape_website(url)
    if not text:
        return "Rejected", "No text found on page"
    
    try:
        nlp = spacy.load('en_core_web_sm')
        doc = nlp(text)
        key_claims = [ent.text for ent in doc.ents if ent.label_ in ['ORG', 'PERSON', 'EVENT']]
        query_text = key_claims[0] if key_claims else ' '.join(text.split('.')[:3])
    except Exception:
        query_text = ' '.join(text.split('.')[:3])
    
    text_result, _ = check_text_fact(query_text, api_key)
    deepfake_results = check_images_for_deepfake(images, model)
    fake_score = sum(1 for v in deepfake_results.values() if "Deepfake" in v) / max(len(deepfake_results), 1)
    
    # Compute a simple confidence measure based on text and image analysis
    if text_result and "fake" in text_result.lower():
        confidence = max(fake_score, 0.7)
    else:
        confidence = fake_score * 0.5
    
    if confidence > 0.5:
        return "Rejected", "Fake indicators detected (Confidence: {:.2f}%)".format(confidence * 100)
    else:
        return "Allowed", "Likely genuine (Confidence: {:.2f}%)".format((1 - confidence) * 100)

# Analyze Local Images and Return Decision
def analyze_local_images(image_paths, model):
    results = check_images_for_deepfake(image_paths, model)
    if any("Deepfake" in result for result in results.values()):
        return "Rejected", "Deepfake detected in one or more local images."
    else:
        return "Allowed", "Local images appear genuine."

# Main Analysis for Social Media Post
def analyze_social_media_post(input_text, api_key, model):
    decisions = {}
    urls = extract_urls(input_text)
    news_urls = [url for url in urls if is_news_url(url)]
    for news_url in news_urls:
        verdict, reason = analyze_news_url(news_url, api_key, model)
        decisions[news_url] = (verdict, reason)
    
    # Check for local images if provided
    local_images_input = input("Enter local image file paths (comma-separated) for analysis (or leave blank): ").strip()
    if local_images_input:
        image_paths = [p.strip() for p in local_images_input.split(",") if p.strip()]
        if image_paths:
            verdict, reason = analyze_local_images(image_paths, model)
            decisions["local_images"] = (verdict, reason)
    return decisions

# Entry Point
if __name__ == "__main__":
    # Set your Google Fact Check API key here
    api_key = "#####"
    model = load_deepfake_model("deepfake_model.pt")
    if model is None:
        print("Deepfake model could not be loaded. Exiting.")
    else:
        post_text = input("Enter the social media post text (can include URLs): ").strip()
        results = analyze_social_media_post(post_text, api_key, model)
        # Print a simple decision for each analyzed item
        for key, (verdict, reason) in results.items():
            if key == "local_images":
                print("\nLocal Images Decision: {} - {}".format(verdict, reason))
            else:
                print("\nNews URL: {}".format(key))
                print("Decision: {} - {}".format(verdict, reason))
