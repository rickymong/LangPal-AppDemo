"""Helper utilities for talking to Supabase."""
from typing import Dict, Optional

import os

from supabase import Client, create_client

# ## Set SUPABASE_URL and SUPABASE_ANON_KEY as environment variables before running the app.
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY")
_client: Optional[Client] = None


def get_supabase_client() -> Client:
    """Return a singleton Supabase client so we reuse the same connection."""
    global _client
    if _client is None:
        if not SUPABASE_URL or not SUPABASE_KEY:
            raise RuntimeError("Supabase credentials are missing.")
        _client = create_client(SUPABASE_URL, SUPABASE_KEY)
    return _client


def fetch_user_context(user_id: str) -> Dict[str, str]:
    """Read the user's preferred language and chat summary from Supabase."""
    client = get_supabase_client()
    response = (
        client.table("user_profiles")
        .select("current_language, chat_summary")
        .eq("user_id", user_id)
        .single()
        .execute()
    )
    data = response.data or {}
    language = data.get("current_language", "French")
    summary = data.get("chat_summary", "")
    return {"language": language, "summary": summary}


def upsert_chat_summary(user_id: str, language: str, chat_summary: str) -> None:
    """Store a short summary of the latest exchange so the tutor stays consistent."""
    client = get_supabase_client()
    client.table("user_profiles").upsert(
        {
            "user_id": user_id,
            "current_language": language,
            "chat_summary": chat_summary,
        }
    ).execute()
