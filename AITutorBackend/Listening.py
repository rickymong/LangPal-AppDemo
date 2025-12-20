"""Listening practice module."""
from typing import Dict, List

from ai_utils import generate_listening_material, synthesize_speech
from supabase_client import fetch_user_context, upsert_chat_summary


def run_listening_practice(user_id: str) -> Dict[str, List[str]]:
    """Create a listening passage, questions, answers, and audio info."""
    context = fetch_user_context(user_id)
    language = context["language"]
    material = generate_listening_material(
        language=language,
        summary=context["summary"],
    )
    audio_url = synthesize_speech(material["passage"])
    upsert_chat_summary(user_id, language, material["chat_summary"])
    return {
        "language": language,
        "passage": material["passage"],
        "questions": material["questions"],
        "answers": material["answers"],
        "audio_url": audio_url,
    }
