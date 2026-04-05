# Ruth's 11Labs integration (STT/TTS + /conversation endpoint)
# Test code

from ai_utils import synthesize_speech, transcribe_speech
from supabase_client import fetch_user_context, upsert_chat_summary
from ai_utils import generate_language_reply


def run_conversation(user_id: str, audio_base64: str, mime_type: str = "audio/mpeg") -> dict:
    """Full conversation loop with fallback handling."""
    
    try:
        result = client.speech_to_text.convert(
            file=("audio", io.BytesIO(audio_bytes), mime_type),
            model_id="scribe_v1",
        )
        transcript = result.text.strip()
        confidence = result.language_probability
    except Exception as e:
        transcript = ""
        confidence = 0.0
    
    is_fallback = False
    fallback_reason = None
    
    if not transcript:
        is_fallback = True
        fallback_reason = "empty_audio"
    elif confidence < 0.7:
        is_fallback = True
        fallback_reason = "low_confidence"
    
    context = fetch_user_context(user_id)
    language = context["language"]
    
    if is_fallback:
        task = (
            "The learner didn't speak clearly or their microphone is muted. "
            "Continue the conversation by either:\n"
            "1. Repeating your previous question in a different way\n"
            "2. Asking a new question to keep them engaged\n"
            "3. Saying 'Are you still there?' if appropriate"
        )
    else:
        task = "Have a natural spoken conversation with the language learner."
    
    reply = generate_language_reply(
        task=task,
        language=language,
        user_input=transcript if transcript else "[learner did not speak clearly]",
        summary=context["summary"]
    )
    
    audio_url = synthesize_speech(reply["target_text"])
    
    upsert_chat_summary(user_id, language, reply["chat_summary"])
    
    return {
        "transcript": transcript if transcript else None,
        "target_text": reply["target_text"],
        "english_text": reply["english_text"],
        "audio_url": audio_url,
        "is_fallback": is_fallback,
        "fallback_reason": fallback_reason,  # "empty_audio" or "low_confidence"
    }