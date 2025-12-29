import requests
import time
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# 1. Configure
API_KEY = os.getenv("MESHY_API_KEY")
if not API_KEY:
    print("Error: MESHY_API_KEY not found in environment variables")
    print("Please create a .env file with your API key")
    exit(1)

PROMPT = "a simple cube"       # Simple object for quick testing

# 2. Start generation
print("🚀 Sending request to Meshy...")
response = requests.post(
    "https://api.meshy.ai/openapi/v2/text-to-3d",
    headers={"Authorization": f"Bearer {API_KEY}"},
    json={
        "mode": "preview",
        "prompt": PROMPT,
        "output_format": "stl",
        "art_style": "realistic"
    },
    timeout=10
)
response.raise_for_status()
task_id = response.json()["result"]
print(f"🎯 Task ID: {task_id}")

# 3. Check status (run every 15 seconds)
print("\n⏳ Checking status (Ctrl+C to stop)...")
while True:
    status = requests.get(
        f"https://api.meshy.ai/openapi/v2/text-to-3d/{task_id}",
        headers={"Authorization": f"Bearer {API_KEY}"}
    ).json()["result"]
    
    print(f"Status: {status['status']} - {status.get('progress', 0)}%")
    if status["status"] == "succeeded":
        print(f"\n✅ Success! Download URL:\n{status['assets']['stl']}")
        break
    time.sleep(15)
