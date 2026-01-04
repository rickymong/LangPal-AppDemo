"""Speaking practice module."""
from typing import Dict

from ai_utils import generate_language_reply, synthesize_speech
from supabase_client import fetch_user_context, upsert_chat_summary


def run_speaking_practice(user_id: str, topic: str) -> Dict[str, str]:
    """Generate a spoken response plus English translation and audio info."""
    context = fetch_user_context(user_id)
    language = context["language"]
    reply = generate_language_reply(
        task="Hold a short speaking drill with natural phrases.",
        language=language,
        user_input=topic,
        summary=context["summary"],
    )
    audio_url = synthesize_speech(reply["target_text"])
    upsert_chat_summary(user_id, language, reply["chat_summary"])
    return {
        "language": language,
        "target_text": reply["target_text"],
        "english_text": reply["english_text"],
        "audio_url": audio_url,
    }
