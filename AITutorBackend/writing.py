"""Writing practice module."""
from typing import Dict

from ai_utils import generate_language_reply
from supabase_client import fetch_user_context, upsert_chat_summary


def run_writing_practice(user_id: str, user_text: str) -> Dict[str, str]:
    """Handle a writing practice turn and return dual-language guidance."""
    context = fetch_user_context(user_id)
    language = context["language"]
    reply = generate_language_reply(
        task="Help the learner improve writing accuracy and tone.",
        language=language,
        user_input=user_text,
        summary=context["summary"],
    )
    upsert_chat_summary(user_id, language, reply["chat_summary"])
    markdown = (
        f"**{language} Response**\n\n"
        f"{reply['target_text']}\n\n"
        "**English Translation**\n\n"
        f"{reply['english_text']}"
    )
    return {
        "language": language,
        "target_text": reply["target_text"],
        "english_text": reply["english_text"],
        "markdown": markdown,
    }
