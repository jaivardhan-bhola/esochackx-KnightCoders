import os
import json
import datetime
from dotenv import load_dotenv
from PIL import Image
import base64
from io import BytesIO
import torch
import torchvision.transforms as transforms
from langchain_groq import ChatGroq
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.chains import load_summarize_chain
from langchain_core.documents import Document

# Load environment variables
load_dotenv(".env")
groq_api_key = os.getenv("GROQ_API_KEY")


# Initialize LLM and tools
llm = ChatGroq(model="llama3-8b-8192", api_key=groq_api_key)
text_splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
summarize_chain = load_summarize_chain(llm, chain_type="map_reduce")

# Departments and contacts
DEPARTMENT_CONTACTS = {
    "Electricity Board": {"phone": "1800-112-233", "email": "power@civic.gov.in"},
    "Department of Water Resources": {"phone": "1800-221-445", "email": "water@civic.gov.in"},
    "Road Development": {"phone": "1800-443-556", "email": "roads@civic.gov.in"},
    "Health Ministry": {"phone": "1800-777-999", "email": "health@civic.gov.in"},
    "Sanitation": {"phone": "1800-333-122", "email": "cleanliness@civic.gov.in"}
}
DEPARTMENTS = list(DEPARTMENT_CONTACTS.keys())

# Analyze image for relevance to complaint

def validate_image_with_llama(image_path, complaint_text):
    img = Image.open(image_path).convert("RGB")
    buffered = BytesIO()
    img.save(buffered, format="PNG")
    img_base64 = base64.b64encode(buffered.getvalue()).decode("utf-8")

    prompt = f"A citizen has filed the following complaint: \"{complaint_text}\". Attached below is a base64-encoded image as proof. Does this image look relevant as evidence to support the complaint? Justify your answer briefly and short.also don't play too hard if it simply suggest or supports the case aprove it, however if it lacks something tell it but don't accept too perfect evidence Base64 Image (PNG): {img_base64[:1000]}..."

    response = llm.invoke(prompt).content.strip()
    return response
# Classify departments using LLaMA

def classify_departments(text):
    prompt = f"""Given this complaint:
{text}
Classify it into one or more of the following departments:
{', '.join(DEPARTMENTS)}.
Return only department names as a comma-separated list."""
    response = llm.invoke(prompt)
    return [d.strip() for d in response.content.split(",") if d.strip() in DEPARTMENTS]

# Assess severity using LLaMA

def get_severity_score(text):
    prompt = f"""Assess the severity of this civic complaint on a scale of 1 (least) to 5 (most severe).
Complaint:
{text}
Severity (number only):"""
    try:
        response = llm.invoke(prompt).content
        score = int("".join(filter(str.isdigit, response)))
        return min(max(score, 1), 5)
    except Exception:
        return 3

# Summarize using LLaMA

def summarize_text(text):
    docs = [Document(page_content=t) for t in text_splitter.split_text(text)]
    return summarize_chain.run(docs)

# Get contact info

def get_contact_info(departments):
    return {d: DEPARTMENT_CONTACTS[d] for d in departments if d in DEPARTMENT_CONTACTS}

# Fetch suggestions using LLaMA

def fetch_interim_suggestions(complaint_text, department):
    query = f"answer in few (3-4) short points , and don't involve dear sir / madam or any salutation and also don't write  here is your answer/summary /suggestions or anything, just list out suggestions the complainer could do while waiting for depatment to deal with it- you are a government representative who received a complaint-{complaint_text} answer from perspective of {department}"
    result = llm.invoke(query).content
    return [line.strip("-• ") for line in result.split("\n") if line.strip()]

# Generate officer brief

def generate_officer_brief(summary, severity, departments):
    dept_str = ", ".join(departments) if departments else "relevant authority"
    return f"A complaint has been received regarding {summary}. The issue is rated {severity}/5 in severity and is forwarded to the {dept_str}."

# Process complaint

def process_complaint(text, location, image_path=None):
    timestamp = datetime.datetime.utcnow().isoformat()
    departments = classify_departments(text)
    severity = get_severity_score(text)
    summary = summarize_text(text)
    contact_info = get_contact_info(departments)
    suggestions = []
    for dept in departments:
        suggestions.extend(fetch_interim_suggestions(text, dept))
    officer_brief = generate_officer_brief(summary, severity, departments)

    image_analysis = None
    if image_path and os.path.exists(image_path):
        image_analysis = validate_image_with_llama(image_path, text)

    complainer_txt = f"--- COMPLAINER COPY ---\n"
    complainer_txt += f"Original Complaint: {text}\nLocation: {location}\nDepartments Forwarded: {', '.join(departments)}\n"
    complainer_txt += "Contact Details:\n"
    for dept, info in contact_info.items():
        complainer_txt += f"  {dept}: Phone - {info['phone']}, Email - {info['email']}\n"
    complainer_txt += "Suggestions:\n"
    for s in suggestions:
        complainer_txt += f"  - {s}\n"
    if image_analysis:
        complainer_txt += f"Image Validation: {image_analysis}\n"
    complainer_txt += f"Timestamp: {timestamp}\nStatus: Pending\n\n"

    officer_txt = f"--- OFFICER COPY ---\n"
    officer_txt += f"Timestamp: {timestamp}\nSeverity: {severity}/5\nSummary: {summary}\nLocation: {location}\n"
    officer_txt += f"Original Complaint: {text}\nDepartments: {', '.join(departments)}\n"
    if image_analysis:
        officer_txt += f"Image Review: {image_analysis}\n"

    with open("complainer_output.txt", "a") as f1:
        f1.write(complainer_txt + "\n")

    with open("officer_output.txt", "a") as f2:
        f2.write(officer_txt + "\n")

    complainer_json = {
        "departments_forwarded": departments,
        "contact_details": contact_info,
        "suggestions": suggestions,
        "timestamp": timestamp,
        "image_analysis": image_analysis
    }

    officer_json = {
        "timestamp": timestamp,
        "severity": severity,
        "summary": summary,
        "original_text": text,
        "location": location,
        "departments": departments,
        "image_analysis": image_analysis
    }

    with open("complainer_output.json", "a") as f3:
        json.dump(complainer_json, f3, indent=4)
        f3.write(",\n")

    with open("officer_output.json", "a") as f4:
        json.dump(officer_json, f4, indent=4)
        f4.write(",\n")

    return complainer_txt, officer_txt

# CLI entry point
if __name__ == "__main__":
    location = input("Enter the location where the issue occurred: ").strip()
    complaint = input("Enter your civic complaint: ").strip()
    image_path = input("Attach image path (optional): ").strip()
    image_path = image_path if image_path else None

    if complaint and location:
        complainer_view, officer_view = process_complaint(complaint, location, image_path)
        print("\n✅ Complaint Processed!\n")
        print(complainer_view)
        print(officer_view)
    else:
        print("Complaint and location fields cannot be empty.")
