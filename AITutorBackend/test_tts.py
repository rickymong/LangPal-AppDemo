import os
from dotenv import load_dotenv
from elevenlabs.client import ElevenLabs

load_dotenv()

client = ElevenLabs(api_key=os.getenv("ELEVENLABS_API_KEY"))

audio = client.text_to_speech.convert(
    voice_id="EXAVITQu4vr4xnSDxMaL",
    text="Bonjour! Je suis votre tuteur de français. Comment puis-je vous aider aujourd'hui?",
    model_id="eleven_multilingual_v2"
)

with open("test_output.mp3", "wb") as f:
    for chunk in audio:
        f.write(chunk)

print("Done! Check test_output.mp3")
