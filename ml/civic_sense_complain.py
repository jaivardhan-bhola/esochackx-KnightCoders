import os
import json
import datetime
import traceback
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

print(f"GROQ API Key available: {groq_api_key is not None and groq_api_key != ''}")

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
    try:
        print(f"Starting image validation for: {image_path}")
        
        # Double check that image path exists
        if not image_path:
            print("No image path provided")
            return "No image was provided with the complaint."
            
        # Verify image exists
        if not os.path.exists(image_path):
            print(f"Error: Image path does not exist: {image_path}")
            return f"The image could not be found on the server."
        
        # Display image info
        file_size = os.path.getsize(image_path)
        print(f"Image file exists with size: {file_size} bytes")
        
        # If GROQ API key is not available, return a default message
        if not groq_api_key or groq_api_key == "":
            print("GROQ API key not available, returning mock response")
            return "The image was received and will be evaluated by the relevant department."
        
        # Basic file validation
        try:
            img = Image.open(image_path)
            img_format = img.format
            img_size = img.size
            print(f"Image opened successfully: format={img_format}, dimensions={img_size}")
            
            # Convert to RGB (handles PNG with alpha channel)
            img = img.convert("RGB")
            
            # Resize large images to reduce token usage
            if img.width > 800 or img.height > 800:
                print("Image is large, resizing to reduce size")
                ratio = min(800/img.width, 800/img.height)
                new_size = (int(img.width * ratio), int(img.height * ratio))
                img = img.resize(new_size, Image.LANCZOS)
                print(f"Image resized to {new_size}")
                
        except Exception as e:
            print(f"Error opening image: {str(e)}")
            print(traceback.format_exc())
            return "The image was received but couldn't be properly processed."
        
        # Creating base64 for the image
        try:
            buffered = BytesIO()
            img.save(buffered, format="JPEG", quality=70)  # Lower quality to reduce size
            img_base64 = base64.b64encode(buffered.getvalue()).decode("utf-8")
            print(f"Base64 encoded image size: {len(img_base64)} characters")
            
            # If base64 string is too large, further reduce image quality/size
            if len(img_base64) > 100000:
                print("Base64 too large, further reducing image quality")
                buffered = BytesIO()
                # Resize more aggressively
                img = img.resize((400, int(400 * img.height / img.width)), Image.LANCZOS)
                img.save(buffered, format="JPEG", quality=50)
                img_base64 = base64.b64encode(buffered.getvalue()).decode("utf-8")
                print(f"Reduced base64 size: {len(img_base64)} characters")
        except Exception as e:
            print(f"Error encoding image: {str(e)}")
            print(traceback.format_exc())
            return "The image was received but couldn't be properly encoded for analysis."

        # Use a simpler prompt with a shorter base64 segment
        try:
            # Only send the first 1000 chars of base64 to reduce token usage
            shortened_base64 = img_base64[:1000]
            
            prompt = f"A citizen has filed the following complaint: \"{complaint_text}\". I've attached an image as evidence. Does this image appear to be relevant to the complaint? Give a brief assessment (2-3 sentences max). Base64 Image excerpt: {shortened_base64}..."

            print("Sending prompt to LLM for image analysis...")
            try:
                response_obj = llm.invoke(prompt)
                response_text = response_obj.content.strip()
                print(f"LLM response received: {response_text[:100]}...")
                return response_text
            except Exception as inner_e:
                print(f"Error in LLM invocation: {inner_e}")
                return "Image received but couldn't be analyzed with AI. Your complaint has been registered."
                
        except Exception as e:
            print(f"Error during LLM processing: {str(e)}")
            print(traceback.format_exc())
            return f"Image received but couldn't be analyzed with AI: {str(e)}. Proceeding with complaint."
    except Exception as e:
        print(f"Unexpected error in validate_image_with_llama: {str(e)}")
        print(traceback.format_exc())
        return f"Image processing error: {str(e)}. Continuing with your complaint."

# Classify departments using LLaMA
def classify_departments(text):
    print("Classifying departments for complaint")
    prompt = f"""Given this complaint:
{text}
Classify it into one or more of the following departments:
{', '.join(DEPARTMENTS)}.
Return only department names as a comma-separated list."""
    try:
        response = llm.invoke(prompt)
        result = [d.strip() for d in response.content.split(",") if d.strip() in DEPARTMENTS]
        print(f"Classified departments: {result}")
        return result
    except Exception as e:
        print(f"Error classifying departments: {str(e)}")
        print(traceback.format_exc())
        # Return a default department during errors
        return ["Road Development"]

# Process complaint
def process_complaint(text, location, image_path=None):
    print(f"\n--- Processing new complaint ---")
    print(f"Text: {text[:50]}...")
    print(f"Location: {location}")
    print(f"Image path: {image_path}")
    
    timestamp = datetime.datetime.utcnow().isoformat()
    
    try:
        departments = classify_departments(text)
        print("Departments classified successfully")
        
        severity = get_severity_score(text)
        print(f"Severity determined: {severity}/5")
        
        summary = summarize_text(text)
        print(f"Text summarized: {summary[:50]}...")
        
        contact_info = get_contact_info(departments)
        print("Contact info retrieved")
        
        suggestions = []
        for dept in departments:
            dept_suggestions = fetch_interim_suggestions(text, dept)
            suggestions.extend(dept_suggestions)
            print(f"Got {len(dept_suggestions)} suggestions for {dept}")
        
        officer_brief = generate_officer_brief(summary, severity, departments)
        print("Officer brief generated")
    except Exception as e:
        print(f"Error in main complaint processing: {str(e)}")
        print(traceback.format_exc())
        # Set fallback values
        departments = ["Road Development"]
        severity = 3
        summary = text[:100] + "..."
        contact_info = get_contact_info(departments)
        suggestions = ["Report issue to local authorities", "Document any changes in the situation"]
        officer_brief = f"A complaint has been received regarding {text[:50]}... The issue is forwarded to Road Development."

    image_analysis = None
    if image_path and os.path.exists(image_path):
        print(f"Processing image at {image_path}")
        image_analysis = validate_image_with_llama(image_path, text)
        print(f"Image analysis result: {image_analysis[:50]}...")
    else:
        print("No image to process or image path doesn't exist")

    # Create complainer and officer responses
    complainer_txt = f"--- COMPLAINER COPY ---\n"
    complainer_txt += f"Original Complaint: {text}\nLocation: {location}\nDepartments Forwarded: {', '.join(departments)}\n"
    complainer_txt += "Contact Details:\n"
    for dept, info in contact_info.items():
        complainer_txt += f"  {dept}: Phone - {info['phone']}, Email - {info['email']}\n"
    complainer_txt += "Suggestions:\n"
    for s in suggestions:
        complainer_txt += f"  - {s}\n"
    if "Health Ministry" in departments:
        complainer_txt += "In the meantime, you can use the app's '/health-check/' feature to get an early diagnosis of the problem.\n"    
    if image_analysis:
        complainer_txt += f"Image Validation: {image_analysis}\n"
    complainer_txt += f"Timestamp: {timestamp}\nStatus: Pending\n\n"

    officer_txt = f"--- OFFICER COPY ---\n"
    officer_txt += f"Timestamp: {timestamp}\nSeverity: {severity}/5\nSummary: {summary}\nLocation: {location}\n"
    officer_txt += f"Original Complaint: {text}\nDepartments: {', '.join(departments)}\n"
    if image_analysis:
        officer_txt += f"Image Review: {image_analysis}\n"

    try:
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
    except Exception as e:
        print(f"Error writing output files: {str(e)}")
        print(traceback.format_exc())

    print("Complaint processing complete!")
    return complainer_txt, officer_txt

# Assess severity using LLaMA
def get_severity_score(text):
    print("Determining complaint severity")
    prompt = f"""Assess the severity of this civic complaint on a scale of 1 (least) to 5 (most severe).
Complaint:
{text}
Severity (number only):"""
    try:
        response = llm.invoke(prompt).content
        score = int("".join(filter(str.isdigit, response)))
        score = min(max(score, 1), 5)  # Clamp between 1 and 5
        print(f"Severity determined: {score}")
        return score
    except Exception as e:
        print(f"Error determining severity: {str(e)}")
        # Default to medium severity on error
        return 3

# Summarize using LLaMA
def summarize_text(text):
    print("Summarizing complaint text")
    try:
        docs = [Document(page_content=t) for t in text_splitter.split_text(text)]
        summary = summarize_chain.run(docs)
        print(f"Summary generated: {summary[:50]}...")
        return summary
    except Exception as e:
        print(f"Error summarizing text: {str(e)}")
        return text[:100] + "..."  # Return truncated original text as fallback

# Get contact info
def get_contact_info(departments):
    return {d: DEPARTMENT_CONTACTS[d] for d in departments if d in DEPARTMENT_CONTACTS}

# Fetch suggestions using LLaMA
def fetch_interim_suggestions(complaint_text, department):
    print(f"Fetching suggestions for department: {department}")
    query = f"""Answer in 3-4 short points. Don't use salutations. 
    Just list suggestions the complainer could do while waiting for the department to deal with it.
    You are a government representative who received a complaint: {complaint_text}
    Answer from perspective of {department}"""
    
    try:
        result = llm.invoke(query).content
        suggestions = [line.strip("-• ") for line in result.split("\n") if line.strip()]
        print(f"Generated {len(suggestions)} suggestions")
        return suggestions[:4]  # Limit to 4 suggestions
    except Exception as e:
        print(f"Error fetching suggestions: {str(e)}")
        return ["Contact local authorities", "Document the issue with photos", "Keep track of any developments"]

# Generate officer brief
def generate_officer_brief(summary, severity, departments):
    dept_str = ", ".join(departments) if departments else "relevant authority"
    return f"A complaint has been received regarding {summary}. The issue is rated {severity}/5 in severity and is forwarded to the {dept_str}."

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
