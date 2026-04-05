import os
import base64
from dotenv import load_dotenv
from elevenlabs.client import ElevenLabs

load_dotenv()

client = ElevenLabs(api_key=os.getenv("ELEVENLABS_API_KEY"))

with open("test_output.mp3", "rb") as f:
    result = client.speech_to_text.convert(
        file=f,
        model_id="scribe_v1",
    )

print("Transcript:", result.text)
