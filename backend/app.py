from flask import Flask, request, jsonify
from flask_cors import CORS
from gemini_utils import chat_with_gemini
from meshy_utils import generate_3d_model
import os
import logging

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app, resources={
    r"/start-chat": {"origins": "*"},
    r"/generate-model": {"origins": "*"}
})

@app.route("/start-chat", methods=["POST"])
def start_chat():
    """Handles the conversational food design flow"""
    try:
        data = request.get_json()
        logger.debug(f"Incoming request data: {data}")
        
        if not data:
            return jsonify({"error": "No data provided"}), 400
            
        user_input = data.get("message", "")
        conversation_state = data.get("conversation_state", {})
        
        # Validate conversation state structure
        if not isinstance(conversation_state, dict):
            conversation_state = {}
        if "history" not in conversation_state:
            conversation_state["history"] = []
        
        response, new_state, is_complete = chat_with_gemini(
            user_input,
            conversation_state
        )
        
        logger.debug(f"Gemini response: {response}")
        return jsonify({
            "reply": response,
            "conversation_state": new_state,
            "is_complete": is_complete
        })
        
    except Exception as e:
        logger.error(f"Error in /start-chat: {str(e)}", exc_info=True)
        return jsonify({
            "error": f"Failed to process chat: {str(e)}",
            "type": type(e).__name__,
            "details": "Check server logs for more information"
        }), 500

@app.route("/generate-model", methods=["POST"])
def generate_model():
    try:
        data = request.get_json()
        logger.debug(f"Received generate request: {data}")
        
        # Extract parameters directly
        prompt = data.get("prompt") or data.get("conversation_state", {}).get("final_prompt")
        art_style = data.get("art_style", "realistic")
        should_remesh = data.get("should_remesh", True)
        
        if not prompt:
            return jsonify({
                "error": "No prompt provided",
                "received_data": data
            }), 400
        
        logger.info(f"Generating model for: {prompt}")
        model_url = generate_3d_model(
            prompt, 
            format="glb",
            art_style=art_style,
            should_remesh=should_remesh
        )
        
        return jsonify({
            "model_url": model_url,
            "thumbnail_url": ""  # Add if available
        })
        
    except Exception as e:
        logger.error(f"Generation failed: {str(e)}", exc_info=True)
        return jsonify({
            "error": str(e),
            "type": type(e).__name__,
            "details": "Check server logs"
        }), 500

@app.route("/health")
def health_check():
    return jsonify({
        "status": "healthy",
        "services": {
            "gemini": "enabled",
            "meshy": "enabled"
        }
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
