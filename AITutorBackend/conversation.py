"""Spoken conversation practice with AI tutor."""
import logging
from typing import Dict

from ai_utils import synthesize_speech, transcribe_speech, generate_language_reply
from supabase_client import fetch_user_context, upsert_chat_summary

logger = logging.getLogger(__name__)


def run_conversation(user_id: str, audio_base64: str, mime_type: str = "audio/mpeg") -> Dict[str, object]:
    """Full conversation loop with fallback handling.
    
    Args:
        user_id: The user's unique identifier
        audio_base64: Audio file encoded as base64 string
        mime_type: MIME type of audio file (default: audio/mpeg)
    
    Returns:
        Dictionary with transcript, AI reply, audio URL, and fallback info
    """
    
    transcript = ""
    is_fallback = False
    fallback_reason = None
    
    try:
        # Decode audio and transcribe using the utility function
        transcript = transcribe_speech(audio_base64, mime_type)
        logger.info(f"Successfully transcribed audio for user {user_id}")
    except ValueError as e:
        # This happens when audio_base64 is empty or invalid
        logger.warning(f"Empty or invalid audio for user {user_id}: {str(e)}")
        is_fallback = True
        fallback_reason = "empty_audio"
    except Exception as e:
        # This happens when ElevenLabs fails or other API errors
        logger.error(f"Transcription failed for user {user_id}: {str(e)}", exc_info=True)
        is_fallback = True
        fallback_reason = "transcription_error"
    
    
    # Fetch user context to get their language preference
    try:
        context = fetch_user_context(user_id)
        language = context["language"]
        logger.debug(f"User {user_id} language: {language}")
    except Exception as e:
        logger.error(f"Failed to fetch user context for {user_id}: {str(e)}", exc_info=True)
        raise
    
    # Determine the task based on whether transcription succeeded
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
    
    # Generate AI response
    try:
        reply = generate_language_reply(
            task=task,
            language=language,
            user_input=transcript if transcript else "[learner did not speak clearly]",
            summary=context["summary"]
        )
        logger.info(f"Generated reply for user {user_id}")
    except Exception as e:
        logger.error(f"Failed to generate reply for user {user_id}: {str(e)}", exc_info=True)
        raise
    
    # Synthesize speech from the AI's response
    try:
        audio_url = synthesize_speech(reply["target_text"])
        logger.info(f"Synthesized audio for user {user_id}")
    except Exception as e:
        logger.error(f"Failed to synthesize speech for user {user_id}: {str(e)}", exc_info=True)
        raise
    
    # Store the conversation summary for next time
    try:
        upsert_chat_summary(user_id, language, reply["chat_summary"])
        logger.debug(f"Stored chat summary for user {user_id}")
    except Exception as e:
        logger.error(f"Failed to store chat summary for user {user_id}: {str(e)}", exc_info=True)
        # Don't raise here - conversation still succeeded even if summary storage failed
    
    return {
        "transcript": transcript if transcript else None,
        "target_text": reply["target_text"],
        "english_text": reply["english_text"],
        "audio_url": audio_url,
        "is_fallback": is_fallback,
        "fallback_reason": fallback_reason,  # "empty_audio" or "low_confidence"
    }
