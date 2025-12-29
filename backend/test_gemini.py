from gemini_utils import chat_with_gemini

def test_chat():
    user_input = "I want to design a heart-shaped vegetarian pizza with olives."
    reply, history = chat_with_gemini(user_input, history=[])
    print("Bot reply:", reply)
    print("Updated history:", history)

if __name__ == "__main__":
    test_chat()
