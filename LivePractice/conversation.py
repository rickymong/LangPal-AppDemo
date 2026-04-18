"""
LivePractice conversation orchestrator.
Runs the full pipeline: STT → Confidence Check → Gemini → TTS → Storage.
"""

from ai_utils import transcribe_speech, generate_language_reply, synthesize_speech
from supabase_client import fetch_user_context, upsert_chat_summary, upload_audio

CONFIDENCE_THRESHOLD = 0.7
TARGET_LANGUAGE = "French"
LANGUAGE_CODE = "fra"       # ISO 639-3 code for ElevenLabs Scribe


def run_conversation(user_id: str, audio_base64: str, mime_type: str = "audio/mpeg") -> dict:
    """
    Full conversation turn: STT → Confidence Check → Gemini → TTS → Save.

    Returns a dict that Flutter can consume directly:
        - transcript:    what the user said (None if fallback triggered)
        - target_text:   AI response in French
        - english_text:  AI response in English
        - audio_url:     public URL to the AI's spoken response
        - tip:           grammar / vocab tip (optional)
        - fallback:      True if confidence was too low
    """

    try:
        stt_result = transcribe_speech(
            audio_base64=audio_base64,
            mime_type=mime_type,
            language_code=LANGUAGE_CODE,
        )
    except Exception as e:
        return _error_response(f"Transcription failed: {e}")

    transcript = stt_result["text"]
    confidence = stt_result["confidence"]

    if confidence < CONFIDENCE_THRESHOLD or not transcript.strip():
        return _low_confidence_response(user_id, confidence)

    try:
        context = fetch_user_context(user_id)
    except Exception as e:
        return _error_response(f"Failed to fetch user context: {e}")

    summary = context.get("summary", "")

    try:
        reply = generate_language_reply(
            task="Have a natural spoken conversation with the language learner.",
            language=TARGET_LANGUAGE,
            user_input=transcript,
            summary=summary,
        )
    except Exception as e:
        return _error_response(f"AI response generation failed: {e}")

    try:
        audio_bytes = synthesize_speech(reply["target_text"])
        audio_url = upload_audio(audio_bytes, user_id)
    except Exception as e:
        return _error_response(f"Speech synthesis / upload failed: {e}")


    try:
        new_turn = f"User: {transcript} | Tutor: {reply['target_text']}"
        updated_summary = _update_rolling_summary(summary, new_turn, max_turns=3)
        upsert_chat_summary(user_id, TARGET_LANGUAGE, updated_summary)
    except Exception as e:
        print(f"[WARNING] Failed to save chat summary: {e}")

    return {
        "transcript": transcript,
        "target_text": reply["target_text"],
        "english_text": reply["english_text"],
        "tip": reply.get("tip", ""),
        "audio_url": audio_url,
        "fallback": False,
    }

def _low_confidence_response(user_id: str, confidence: float) -> dict:
    """
    When STT confidence is below threshold, return a fallback response
    that tells the user to try again or type instead.
    Does NOT send garbage transcript to Gemini.
    """
    fallback_text_fr = "Désolé, je n'ai pas bien compris. Pouvez-vous répéter ou taper votre réponse ?"
    fallback_text_en = "Sorry, I didn't quite catch that. Could you repeat or type your response?"

    try:
        audio_bytes = synthesize_speech(fallback_text_fr)
        audio_url = upload_audio(audio_bytes, user_id)
    except Exception:
        audio_url = None

    return {
        "transcript": None,
        "target_text": fallback_text_fr,
        "english_text": fallback_text_en,
        "tip": "Try speaking closer to the microphone, or use the text input.",
        "audio_url": audio_url,
        "fallback": True,
        "confidence": round(confidence, 3),
    }


def _update_rolling_summary(current_summary: str, new_turn: str, max_turns: int = 3) -> str:
    """
    Keep only the last `max_turns` exchanges in the summary.
    Each turn is separated by a newline.
    """
    turns = [t.strip() for t in current_summary.strip().split("\n") if t.strip()]
    turns.append(new_turn)
    return "\n".join(turns[-max_turns:])


def _error_response(message: str) -> dict:
    """Standardised error response that won't crash Flutter."""
    print(f"[ERROR] {message}")
    return {
        "transcript": None,
        "target_text": None,
        "english_text": None,
        "tip": None,
        "audio_url": None,
        "fallback": False,
        "error": message,
    }

