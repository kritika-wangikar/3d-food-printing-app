import google.generativeai as genai
from typing import Dict, Tuple
import logging
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# API key configuration - Get from environment
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    raise ValueError("GEMINI_API_KEY not found in environment variables. Please create a .env file with your API key.")

genai.configure(api_key=GEMINI_API_KEY)

# Simplified system instruction
SYSTEM_INSTRUCTION = """You're a 3D food printing assistant. Guide users through these one by one:
1. Food selection
2. Toppings choice 
3. Allergy info
4. Final confirmation

Rules:
- Use [brackets] for each individual options of toppings and allergies at first.
- When done, only repeat the details in simple words and NOTHING else.
- Keep responses brief"""

def chat_with_gemini(user_input: str, conversation_state: Dict = None) -> Tuple[str, Dict, bool]:
    """Handle conversation with Gemini"""
    try:
        # Initialize conversation state
        if conversation_state is None:
            conversation_state = {"history": [], "stage": "start"}
            
        # Ensure history exists and is serializable
        if "history" not in conversation_state:
            conversation_state["history"] = []
            
        # Create model instance
        model = genai.GenerativeModel(
            'gemini-2.0-flash',
            system_instruction=SYSTEM_INSTRUCTION
        )
        
        # Prepare chat history
        serializable_history = []
        for item in conversation_state["history"]:
            if isinstance(item, dict):
                serializable_history.append({
                    "role": item.get("role", "user"),
                    "parts": [{"text": part.get("text", "")} for part in item.get("parts", [])]
                })
        
        # Start chat session
        chat = model.start_chat(history=serializable_history)
        response = chat.send_message(user_input)
        response_text = response.text
        
        # Update conversation state with serializable history
        conversation_state["history"] = [
            {
                "role": msg.role,
                "parts": [{"text": part.text} for part in msg.parts]
            } for msg in chat.history
        ]
        
        # Detect conversation completion
        is_complete = any(
            phrase in response_text.lower()
            for phrase in [
                "ready to generate", 
                "that's all",
                "final confirmation",
                "here's your design",
                "3d model can be generated",
                "proceed to generation"
            ]
        ) or "[generate]" in response_text.lower()
        
        return response_text, conversation_state, is_complete
        
    except Exception as e:
        logger.error(f"Gemini API Error: {str(e)}", exc_info=True)
        return f"Error: Please try again. ({str(e)})", conversation_state or {}, False
