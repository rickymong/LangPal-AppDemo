"""
Supabase client for the LivePractice pipeline.

Handles:
    - Fetching user context (language + rolling chat summary)
    - Upserting chat summaries (rolling 3-turn window)
    - Uploading TTS audio to Supabase storage and returning public URL
"""

import os
import time
from dotenv import load_dotenv 
from supabase import create_client, Client

load_dotenv()

_supabase_client: Client | None = None

AUDIO_BUCKET = "audio"  


def _get_client() -> Client:
    """Lazy-init Supabase client."""
    global _supabase_client
    if _supabase_client is None:
        url = os.getenv("SUPABASE_URL")
        key = os.getenv("SUPABASE_PUB_KEY")
        if not url or not key:
            raise RuntimeError(
                "Set SUPABASE_URL and SUPABASE_PUB_KEY in your .env file."
            )
        _supabase_client = create_client(url, key)
    return _supabase_client


def fetch_user_context(user_id: str) -> dict:
    """
    Look up user's language preference and recent chat summary.

    Returns:
        {
            "language": "French",
            "summary": "User: Bonjour | Tutor: Bonjour! Comment allez-vous?"
        }

    Falls back to defaults if user not found.
    """
    client = _get_client()

    try:
        response = (
            client.table("user_profiles")
            .select("current_language, chat_summary")
            .eq("id", user_id)
            .single()
            .execute()
        )
        data = response.data
        return {
            "language": data.get("current_language", "French"),
            "summary": data.get("chat_summary", ""),
        }
    except Exception as e:
        print(f"[WARNING] Could not fetch user context for {user_id}: {e}")
        return {
            "language": "French",
            "summary": "",
        }


def upsert_chat_summary(user_id: str, language: str, summary: str) -> None:
    """
    Save the rolling chat summary (last 3 turns) to the user's profile.

    Uses upsert so it works whether or not a row already exists.
    """
    client = _get_client()

    try:
        client.table("user_profiles").upsert(
            {
                "id": user_id,
                "target_language": language,
                "chat_summary": summary,
            },
            on_conflict="id",
        ).execute()
    except Exception as e:
        print(f"[WARNING] Failed to upsert chat summary for {user_id}: {e}")


def upload_audio(audio_bytes: bytes, user_id: str) -> str:
    """
    Upload TTS audio bytes to Supabase storage bucket.

    Args:
        audio_bytes: Raw MP3 bytes from ElevenLabs TTS.
        user_id:     Used in filename for traceability.

    Returns:
        Public URL to the uploaded audio file.
    """
    client = _get_client()

    timestamp = int(time.time())
    filename = f"{user_id}_{timestamp}.mp3"

    try:
        client.storage.from_(AUDIO_BUCKET).upload(
            path=filename,
            file=audio_bytes,
            file_options={"content-type": "audio/mpeg"},
        )
    except Exception as e:
        raise RuntimeError(f"Supabase audio upload failed: {e}")

    supabase_url = os.getenv("SUPABASE_URL", "")
    public_url = f"{supabase_url}/storage/v1/object/public/{AUDIO_BUCKET}/{filename}"

    return public_url
