"""
AI utilities for the LivePractice pipeline.

Handles:
    - ElevenLabs STT  (transcribe_speech)
    - Gemini LLM      (generate_language_reply)
    - ElevenLabs TTS  (synthesize_speech)
"""

import io
import os
import json
import base64

from elevenlabs import ElevenLabs
import google.generativeai as genai


_eleven_client: ElevenLabs | None = None
_gemini_model = None


def _get_eleven_client() -> ElevenLabs:
    """Lazy-init ElevenLabs client."""
    global _eleven_client
    if _eleven_client is None:
        api_key = os.getenv("ELEVENLABS_API_KEY")
        if not api_key:
            raise RuntimeError("Set ELEVENLABS_API_KEY in your .env file.")
        _eleven_client = ElevenLabs(api_key=api_key)
    return _eleven_client


def _get_gemini_model():
    """Lazy-init Gemini model."""
    global _gemini_model
    if _gemini_model is None:
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise RuntimeError("Set GEMINI_API_KEY in your .env file.")
        genai.configure(api_key=api_key)
        model_name = os.getenv("GEMINI_MODEL", "gemini-2.0-flash")
        _gemini_model = genai.GenerativeModel(model_name)
    return _gemini_model



def transcribe_speech(
    audio_base64: str,
    mime_type: str = "audio/mpeg",
    language_code: str = "fra",
) -> dict:
    """
    Transcribe audio using ElevenLabs Scribe v1.

    Args:
        audio_base64:  Base64-encoded audio from Flutter.
        mime_type:     MIME type of the audio (e.g. "audio/mpeg").
        language_code: ISO 639-3 language code. "fra" for French.

    Returns:
        dict with keys:
            text       — transcribed text
            confidence — language_probability (0.0–1.0)
            words      — list of per-word data (if available)
    """
    client = _get_eleven_client()

    audio_bytes = base64.b64decode(audio_base64)

    if len(audio_bytes) == 0:
        return {"text": "", "confidence": 0.0, "words": []}

    result = client.speech_to_text.convert(
        file=("audio", io.BytesIO(audio_bytes), mime_type),
        model_id="scribe_v1",
        language_code=language_code,
    )

    words = []
    if hasattr(result, "words") and result.words:
        words = [
            {
                "text": w.text,
                "logprob": getattr(w, "logprob", None),
                "type": getattr(w, "type", "word"),
            }
            for w in result.words
        ]

    return {
        "text": getattr(result, "text", "").strip(),
        "confidence": getattr(result, "language_probability", 0.0),
        "words": words,
    }


SYSTEM_PROMPT_TEMPLATE = """You are an encouraging French language tutor having a spoken conversation with a learner.

Target language: {language}

IMPORTANT CONTEXT ABOUT THE LEARNER:
- They are still learning proper pronunciation and grammar.
- Their speech is transcribed by an AI, so the transcript may contain errors, misspellings, or oddly split words caused by their accent — NOT by lack of knowledge.
- Use the conversation history below to infer what they probably meant, even if the transcript looks wrong.
- Respond naturally and encouragingly. Do not correct the transcription itself.
- Keep your responses concise (1-3 sentences) since they will be spoken aloud.

Conversation so far:
{summary}

Respond ONLY with a valid JSON object in this exact format (no markdown, no backticks, no extra text):
{{
    "target_text": "Your response in {language}",
    "english_text": "English translation of your response",
    "tip": "One short grammar or vocabulary tip relevant to this exchange",
    "follow_up": "A follow-up question in {language} to keep the conversation going",
    "chat_summary": "Brief 1-sentence summary of this exchange for context"
}}
"""


def generate_language_reply(
    task: str,
    language: str,
    user_input: str,
    summary: str = "",
) -> dict:
    """Demo mode: hardcoded response for demo."""
    return {
        "target_text": "Très bien! Vous parlez très bien le français.",
        "english_text": "Very good! You speak French very well.",
        "tip": "Use 'Très' (very) before adjectives to intensify them.",
        "follow_up": "Quel est votre hobby préféré?",
        "chat_summary": f"User said: {user_input}",
    }


def _parse_gemini_response(raw_text: str, user_input: str, language: str) -> dict:
    """
    Parse Gemini's JSON response with fallback handling.
    Gemini sometimes wraps JSON in markdown backticks or adds preamble.
    """
    cleaned = raw_text
    if cleaned.startswith("```"):
        
        first_newline = cleaned.index("\n") if "\n" in cleaned else 3
        cleaned = cleaned[first_newline + 1:]
    if cleaned.endswith("```"):
        cleaned = cleaned[:-3]
    cleaned = cleaned.strip()

    try:
        parsed = json.loads(cleaned)
    except json.JSONDecodeError:
        
        start = cleaned.find("{")
        end = cleaned.rfind("}")
        if start != -1 and end != -1 and end > start:
            try:
                parsed = json.loads(cleaned[start : end + 1])
            except json.JSONDecodeError:
                parsed = None
        else:
            parsed = None

    if parsed is None:
   
        print(f"[WARNING] Gemini returned malformed response. Raw: {raw_text[:200]}")
        return {
            "target_text": raw_text[:300] if raw_text else "Désolé, pouvez-vous répéter ?",
            "english_text": "Sorry, could you repeat that?",
            "tip": "",
            "follow_up": "",
            "chat_summary": f"User said: {user_input}. Tutor had trouble responding.",
        }


    defaults = {
        "target_text": "Désolé, pouvez-vous répéter ?",
        "english_text": "Sorry, could you repeat that?",
        "tip": "",
        "follow_up": "",
        "chat_summary": f"User said: {user_input}",
    }

    for key, default in defaults.items():
        if key not in parsed or not parsed[key]:
            parsed[key] = default

    return parsed



def synthesize_speech(text: str) -> bytes:
    """
    Convert text to speech using ElevenLabs TTS.

    Args:
        text: The text to speak (in French for this MVP).

    Returns:
        Raw audio bytes (MP3).
    """
    client = _get_eleven_client()

    voice_id = os.getenv("ELEVENLABS_VOICE_ID", "EXAVITQu4vr4xnSDxMaL")  

    audio_generator = client.text_to_speech.convert(
        voice_id=voice_id,
        text=text,
        model_id="eleven_multilingual_v2",
    )

    audio_bytes = b"".join(chunk for chunk in audio_generator)

    if len(audio_bytes) == 0:
        raise RuntimeError("ElevenLabs TTS returned empty audio.")

    return audio_bytes
