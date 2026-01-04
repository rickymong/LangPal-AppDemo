"""Helpers that talk to OpenAI and ElevenLabs."""
from typing import Dict, List, Tuple

import os
import re

# ## Set OPENAI_API_KEY as an environment variable before running the app.
from openai import OpenAI

# ## Set ELEVENLABS_API_KEY as an environment variable before running the app.
import requests

OPENAI_MODEL = "gpt-3.5-turbo"
ELEVENLABS_VOICE_ID = "placeholder_voice"
ELEVENLABS_URL = "https://api.elevenlabs.io/v1/text-to-speech"

_openai_client: OpenAI | None = None


def get_openai_client() -> OpenAI:
    """Return a single OpenAI client so we avoid re-creating it."""
    global _openai_client
    if _openai_client is None:
        _openai_client = OpenAI()
    return _openai_client


def call_openai(prompt: str) -> str:
    """Send a prompt to OpenAI and return the plain text response."""
    client = get_openai_client()
    chat = client.chat.completions.create(
        model=OPENAI_MODEL,
        messages=[{"role": "user", "content": prompt}],
        temperature=0.7,
    )
    return chat.choices[0].message.content.strip()


def build_dual_language_prompt(task: str, language: str, user_input: str, summary: str) -> str:
    """Create a prompt that reminds the AI about the language and summary rules."""
    return (
        "You are an encouraging language tutor.\n"
        f"Target language: {language}.\n"
        "Always reply twice: first in the target language, then give an English translation.\n"
        "Add a short grammar or phrasing tip plus a follow-up question in the target language.\n"
        "Reply using exactly these sections, each starting on its own line: \n"
        "TARGET: <target-language guidance>\n"
        "ENGLISH: <English translation/explanation>\n"
        "TIP: <one-sentence grammar insight>\n"
        "FOLLOW_UP: <a friendly question in the target language>.\n"
        "Keep each section to 1-3 sentences.\n"
        f"Recent context: {summary or 'No previous chat yet.'}\n"
        f"Task: {task}.\n"
        f"Learner input or need: {user_input}."
    )


def _extract_section(raw_text: str, section: str) -> str:
    pattern = rf"{section}:(.*?)(?=\n[A-Z_]+:|\Z)"
    match = re.search(pattern, raw_text, flags=re.IGNORECASE | re.DOTALL)
    if not match:
        return ""
    return match.group(1).strip()


def parse_dual_language_response(raw_text: str) -> Dict[str, str]:
    """Split the model output into target/English/tip/follow-up sections."""
    sections = {
        "target_text": _extract_section(raw_text, "TARGET") or raw_text.strip(),
        "english_text": _extract_section(raw_text, "ENGLISH") or "English translation missing.",
        "tip": _extract_section(raw_text, "TIP") or "No tip provided.",
        "follow_up": _extract_section(raw_text, "FOLLOW_UP") or "Peux-tu partager plus?",
    }
    return sections


def generate_language_reply(task: str, language: str, user_input: str, summary: str) -> Dict[str, str]:
    """Generate a grammar-focused response that follows the dual-language rule."""
    prompt = build_dual_language_prompt(task, language, user_input, summary)
    response = call_openai(prompt)
    parsed = parse_dual_language_response(response)
    return {
        "target_text": parsed["target_text"],
        "english_text": parsed["english_text"],
        "tip": parsed["tip"],
        "follow_up": parsed["follow_up"],
        "chat_summary": parsed["target_text"][:120],
    }


def generate_listening_material(language: str, summary: str) -> Dict[str, List[str]]:
    """Ask OpenAI for a short listening passage plus questions."""
    prompt = (
        "Create a short listening passage in {language}.\n"
        "After the passage, give 1-2 comprehension questions in the target language.\n"
        "Then provide English explanations for the answers."
    ).format(language=language)
    prompt = f"{prompt}\nContext: {summary or 'Fresh session.'}"
    response = call_openai(prompt)
    # Simple parsing: assume sections separated by blank lines.
    blocks = [block.strip() for block in response.split("\n\n") if block.strip()]
    passage = blocks[0] if blocks else response
    questions: List[str] = []
    answers: List[str] = []
    for block in blocks[1:]:
        if block.lower().startswith("question"):
            questions.append(block)
        else:
            answers.append(block)
    return {
        "passage": passage,
        "questions": questions or ["Question list missing."],
        "answers": answers or ["English explanations missing."],
        "chat_summary": passage[:120],
    }


def synthesize_speech(text: str) -> str:
    """Call ElevenLabs to generate speech and return a placeholder URL."""
    api_key = os.getenv("ELEVENLABS_API_KEY")
    if not api_key:
        return "## Set ELEVENLABS_API_KEY to enable audio."
    headers = {
        "xi-api-key": api_key,
        "Content-Type": "application/json",
    }
    payload = {
        "text": text,
        "voice_settings": {"stability": 0.3, "similarity_boost": 0.7},
    }
    response = requests.post(
        f"{ELEVENLABS_URL}/{ELEVENLABS_VOICE_ID}",
        json=payload,
        headers=headers,
        timeout=30,
    )
    response.raise_for_status()
    # ## Upload this audio bytes to storage (e.g., Supabase storage) and return the public URL.
    return "Audio generation successful. Upload audio bytes to storage and return URL."
