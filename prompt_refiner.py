import google.generativeai as genai
from typing import Dict, List
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class FoodPromptRefiner:
    def __init__(self):
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise ValueError("GEMINI_API_KEY not found in environment variables. Please create a .env file with your API key.")
        
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel('gemini-2.0-flash')
    
    def refine_prompt(self, user_input: str) -> Dict[str, List[str]]:
        """
        Returns: {
            "enhanced_prompt": str,
            "toppings": List[str],
            "allergies": List[str],
            "technical_parameters": str
        }
        """
        response = self.model.generate_content(f"""
        As a 3D food printing assistant, expand this request:
        USER INPUT: "{user_input}"

        Generate:
        1. A detailed technical prompt for Meshy API
        2. 3-5 common toppings as bullet points
        3. 3-5 common allergies as bullet points
        4. Key 3D printing parameters

        Format your response as:
        TECHNICAL PROMPT: <text>
        TOPPINGS: - <item1> - <item2>
        ALLERGIES: - <item1> - <item2>
        PARAMETERS: <text>
        """)

        return self._parse_response(response.text)

    def _parse_response(self, text: str) -> Dict[str, List[str]]:
        """Extracts structured data from Gemini's response."""
        sections = {
            "TECHNICAL PROMPT": "",
            "TOPPINGS": [],
            "ALLERGIES": [],
            "PARAMETERS": ""
        }

        current_section = None
        for line in text.split('\n'):
            line = line.strip()
            if line.startswith(("TECHNICAL PROMPT:", "TOPPINGS:", "ALLERGIES:", "PARAMETERS:")):
                current_section = line.split(':')[0]
                line = line.split(':', 1)[1].strip()
            
            if current_section:
                if current_section in ["TOPPINGS", "ALLERGIES"]:
                    if line.startswith('-'):
                        sections[current_section].append(line[1:].strip())
                else:
                    sections[current_section] += line + '\n'

        return {
            "enhanced_prompt": sections["TECHNICAL PROMPT"].strip(),
            "toppings": sections["TOPPINGS"],
            "allergies": sections["ALLERGIES"],
            "technical_parameters": sections["PARAMETERS"].strip()
        }
