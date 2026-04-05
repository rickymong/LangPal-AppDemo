import os
from dotenv import load_dotenv
from ai_utils import synthesize_speech

load_dotenv()

url = synthesize_speech("Bonjour! Je suis votre tuteur de français.")
print("Audio URL:", url)
