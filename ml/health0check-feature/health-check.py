# === Import Libraries ===
import os
import pickle
import torch
import torch.nn as nn
import torch.nn.functional as F
import numpy as np
from PIL import Image
import torchvision.models as models
import torchvision.transforms as T
from langchain_groq import ChatGroq
from langchain.chains import load_summarize_chain
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.utilities import GoogleSerperAPIWrapper
from langchain_core.documents import Document
from dotenv import load_dotenv  # Import dotenv to load environment variables

# === Load Environment Variables ===
load_dotenv()  # Load variables from .env file
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
SERPER_API_KEY = os.getenv("SERPER_API_KEY")

# === LangChain Setup ===
llm = ChatGroq(model="llama3-8b-8192", api_key=GROQ_API_KEY)
text_splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
summarize_chain = load_summarize_chain(llm, chain_type="map_reduce")
search = GoogleSerperAPIWrapper(serper_api_key=SERPER_API_KEY)

# === Class Mapping ===
class_map = {
    'nv': 'Melanocytic nevi',
    'mel': 'Melanoma',
    'bkl': 'Benign keratosis-like lesions',
    'bcc': 'Basal cell carcinoma',
    'akiec': 'Actinic keratoses',
    'vasc': 'Vascular lesions',
    'df': 'Dermatofibroma'
}
class_labels = list(class_map.values())

# === Define DenseNet-121 Model ===
def load_skin_model(path=r'skin-disease-model2.pth'):
    try:
        model = models.densenet121(pretrained=False)  # Use DenseNet-121
        model.classifier = nn.Linear(model.classifier.in_features, 7)  # Adjust for 7 output classes
        state_dict = torch.load(path, map_location='cpu')
        model.load_state_dict(state_dict, strict=False)  # Allow flexibility for missing keys
        model.eval()
        return model
    except Exception as e:
        print(f"❌ Error loading model: {e}")
        return None

# === Image Preprocessing ===
def preprocess_skin_image(image_path):
    transform = T.Compose([
        T.Resize((224, 224)),
        T.ToTensor(),
        T.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),  # ImageNet stats
    ])
    image = Image.open(image_path).convert("RGB")
    image_tensor = transform(image).unsqueeze(0)
    return image_tensor

# === Predict Skin Disease ===
def predict_skin(model, image_tensor):
    with torch.no_grad():
        output = model(image_tensor)
        probs = F.softmax(output, dim=1)
        pred_idx = torch.argmax(probs, dim=1).item()
        confidence = probs[0][pred_idx].item()
    return class_labels[pred_idx], confidence

# === Diabetes Model (.sav) ===
def load_diabetes_model(path='A:\hackathon\elevate\health-check\diabetes_model.sav'):
    return pickle.load(open(path, 'rb'))

def predict_diabetes(model, input_data):
    prediction = model.predict([input_data])
    return "Diabetes Detected" if prediction[0] == 1 else "No Diabetes Detected"

# === Serper + LLaMA Summary ===
def search_and_summarize(disease_name):
    queries = {
        "Symptoms": f"What are the symptoms of {disease_name}?",
        "Treatment": f"What are the treatments for {disease_name}?",
        "Prevention": f"How to prevent {disease_name}?"
    }
    result = {}
    for key, query in queries.items():
        print(f"🔍 Fetching {key} info...")
        raw = search.run(query)
        docs = [Document(page_content=t) for t in text_splitter.split_text(raw)]
        result[key] = summarize_chain.run(docs)
    return result

# === Main App ===
def main():
    print("\n📋 Welcome to the Health Check CLI App")
    print("1. Diabetes Prediction")
    print("2. Skin Disease Prediction")
    choice = input("Select an option (1 or 2): ").strip()
    disease_info = {}

    if choice == '1':
        print("\n🧪 Enter values for Diabetes Prediction:")
        fields = [
            "Pregnancies", "Glucose", "Blood Pressure", "Skin Thickness",
            "Insulin", "BMI", "Diabetes Pedigree Function", "Age"
        ]
        user_input = [float(input(f"{field}: ")) for field in fields]
        model = load_diabetes_model()
        result = predict_diabetes(model, user_input)
        print(f"\n🩺 Prediction: {result}")
        print("\n💡 Gathering more info...")
        disease_info = search_and_summarize("diabetes")

    elif choice == '2':
        print("\n📤 Enter the path to an image for skin disease prediction:")
        image_path = input("Image Path: ").strip()
        if os.path.exists(image_path):
            try:
                image_tensor = preprocess_skin_image(image_path)
                model = load_skin_model()
                if model:
                    prediction, confidence = predict_skin(model, image_tensor)
                    print(f"\n🩺 Prediction: {prediction} ({confidence*100:.2f}% confidence)")
                    print("\n💡 Gathering more info...")
                    disease_info = search_and_summarize(prediction)
                else:
                    print("❌ Model loading failed.")
            except Exception as e:
                print(f"❌ Error: {e}")
        else:
            print("❌ Invalid image path.")
    else:
        print("❌ Invalid option.")
        return

    print("\n📚 Additional Information:")
    for section, content in disease_info.items():
        print(f"\n🔹 {section}:\n{content}")

if __name__ == "__main__":
    main()