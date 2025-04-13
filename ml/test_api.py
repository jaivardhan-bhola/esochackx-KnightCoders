import requests
import json
import sys

# Base URL for the Flask API
BASE_URL = "http://192.168.77.84:7122"

def test_health_endpoint():
    """Test the health check endpoint"""
    try:
        response = requests.get(f"{BASE_URL}/health")
        print("Health Check Response:", response.status_code)
        print(json.dumps(response.json(), indent=2))
    except Exception as e:
        print(f"Error testing health endpoint: {e}")
    print("-" * 50)

def test_process_complaint():
    """Test the process_complaint endpoint"""
    payload = {
        "complaint": "I waS OUT OF SAATTION AND WHEN I CAME BACK TO MY NHOUSEHOLD MY WHOLE FAMILY DDIES DUE TO DEHYDRATION, all beacause of the water shortage in my area.",
        "location": "Downtown"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/process_complaint", json=payload)
        print("Process Complaint Response:", response.status_code)
        print(json.dumps(response.json(), indent=2))
    except Exception as e:
        print(f"Error testing process_complaint endpoint: {e}")
    print("-" * 50)

def test_analyze_post():
    """Test the analyze_post endpoint"""
    payload = {
        "post_text": "This article claims vaccines cause autism: https://fake-news-site.com/vaccines-autism",
        "image_paths": []  # You can add paths to test images if available
    }
    
    try:
        response = requests.post(f"{BASE_URL}/analyze_post", json=payload)
        print("Analyze Post Response:", response.status_code)
        print(json.dumps(response.json(), indent=2))
    except Exception as e:
        print(f"Error testing analyze_post endpoint: {e}")
    print("-" * 50)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        # Run a specific test based on argument
        test_name = sys.argv[1].lower()
        print(f"Testing {test_name} endpoint...")
        if test_name == "health":
            test_health_endpoint()
        elif test_name == "complaint":
            test_process_complaint()
        elif test_name == "post":
            test_analyze_post()
        else:
            print(f"Unknown test: {test_name}")
    else:
        # Run all tests
        print("Testing Flask API Endpoints...")
        test_health_endpoint()
        test_process_complaint()
        test_analyze_post()
    
    print("Testing complete!")