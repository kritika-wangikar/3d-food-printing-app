import requests
import time
import logging
import json
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

MESHY_API_KEY = os.getenv("MESHY_API_KEY")
if not MESHY_API_KEY:
    raise ValueError("MESHY_API_KEY not found in environment variables. Please create a .env file with your API key.")

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

def generate_3d_model(prompt, format="glb", art_style="realistic", should_remesh=True):
    """Generate 3D model using Meshy API"""
    payload = {
        "mode": "preview",
        "prompt": prompt,  # Use direct prompt
        "output_format": format,
        "art_style": art_style,
        "should_remesh": should_remesh,
    }

    headers = {
        "Authorization": f"Bearer {MESHY_API_KEY}",
        "Content-Type": "application/json"
    }

    try:
        # Step 1: Create generation task - CORRECTED ENDPOINT
        logger.debug(f"Sending to Meshy API: {json.dumps(payload, indent=2)}")
        response = requests.post(
            "https://api.meshy.ai/openapi/v2/text-to-3d",  # Fixed endpoint
            headers=headers,
            json=payload,
            timeout=30
        )
        
        # Handle HTTP errors
        try:
            response.raise_for_status()
        except requests.exceptions.HTTPError as http_err:
            logger.error(f"Meshy API HTTP error: {http_err}")
            logger.error(f"Response content: {response.text}")
            raise

        response_data = response.json()
        logger.debug(f"Initial Meshy response: {json.dumps(response_data, indent=2)}")
        
        # CORRECTED TASK ID EXTRACTION
        task_id = response_data.get("result")
        if not task_id:
            raise Exception(f"No task ID received. Full response: {response_data}")

        # Step 2: Poll for completion
        status_url = f"https://api.meshy.ai/openapi/v2/text-to-3d/{task_id}"  # Fixed endpoint
        start_time = time.time()
        max_wait = 600  # 10 minutes timeout
        poll_interval = 5  # Seconds
        
        while time.time() - start_time < max_wait:
            logger.info(f"Checking status (task_id={task_id})...")
            status_resp = requests.get(status_url, headers=headers)
            status_resp.raise_for_status()
            status_data = status_resp.json()
            logger.debug(f"Polling response: {json.dumps(status_data, indent=2)}")

            status = status_data.get("status", "").upper()
            
            if status == "SUCCEEDED":
                # CORRECTED MODEL URL EXTRACTION
                model_url = status_data.get("model_url")
                if not model_url:
                    # Check alternative location
                    model_url = status_data.get("model_urls", {}).get("glb")
                
                if model_url:
                    logger.info(f"Model generation succeeded! URL: {model_url}")
                    return model_url
                else:
                    raise Exception("GLB URL not found in successful response")
                    
            elif status == "FAILED":
                error_msg = status_data.get("error", "Unknown error")
                raise Exception(f"Meshy generation failed: {error_msg}")
            
            logger.info(f"Current status: {status} - waiting {poll_interval}s")
            time.sleep(poll_interval)
        
        raise Exception("Generation timeout exceeded")
        
    except Exception as e:
        logger.error(f"Meshy API error: {str(e)}", exc_info=True)
        raise
