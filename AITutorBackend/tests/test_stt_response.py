# test_stt_response.py
import os
from dotenv import load_dotenv
from elevenlabs.client import ElevenLabs

load_dotenv()

api_key = os.getenv("ELEVENLABS_API_KEY")
if not api_key:
    print("❌ ELEVENLABS_API_KEY not found")
    exit(1)

print("✅ API key loaded\n")

client = ElevenLabs(api_key=api_key)

# Open your test audio file
with open("test_audio.wav", "rb") as audio_file:  # Changed .mp3 to .wav
    print("🎙️ Sending audio to 11Labs STT...")
    result = client.speech_to_text.convert(
        file=("test_audio.wav", audio_file, "audio/wav"),  # Changed mime type
        model_id="scribe_v1"
    )
    
    print("\n📊 Result object attributes:")
    print(vars(result))
    
    print(f"\n✅ Transcribed text: {result.text}")
