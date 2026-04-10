"""Helpers that talk to Gemini and ElevenLabs."""
from typing import Any, Dict, List

import base64
import os
import re
import json
import hashlib
import time

import google.generativeai as genai

# ## Set ELEVENLABS_API_KEY as an environment variable before running the app.
import requests

GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.0-flash")
ELEVENLABS_VOICE_ID = "placeholder_voice"
ELEVENLABS_TTS_URL = os.getenv(
    "ELEVENLABS_TTS_URL", "https://api.elevenlabs.io/v1/text-to-speech"
)
ELEVENLABS_STT_URL = os.getenv(
    "ELEVENLABS_STT_URL", "https://api.elevenlabs.io/v1/speech-to-text"
)
ELEVENLABS_STT_MODEL = os.getenv(
    "ELEVENLABS_STT_MODEL", "eleven_multilingual_v2"
)

_gemini_model: Any | None = None


def get_gemini_model() -> Any:
    """Return a single Gemini model so we avoid re-configuring it."""
    global _gemini_model
    if _gemini_model is None:
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise RuntimeError("Set GEMINI_API_KEY before running the app.")
        genai.configure(api_key=api_key)
        _gemini_model = genai.GenerativeModel(GEMINI_MODEL)
    return _gemini_model


def call_gemini(prompt: str) -> str:
    """Send a prompt to Gemini and return the plain text response."""
    model = get_gemini_model()
    response = model.generate_content(
        prompt,
        generation_config={"temperature": 0.7, "max_output_tokens": 1024},
    )
    text = getattr(response, "text", "") or ""
    return text.strip()


# Simple in-memory cache: key -> (timestamp, data)
_response_cache: dict[str, tuple[float, dict]] = {}
_CACHE_TTL = 300  # 5 minutes


def _cache_key(prefix: str, language: str, count: int) -> str:
    """Build a short hash key for caching."""
    raw = f"{prefix}:{language}:{count}"
    return hashlib.md5(raw.encode()).hexdigest()


def get_cached(key: str) -> dict | None:
    """Return cached data if still fresh, else None."""
    entry = _response_cache.get(key)
    if entry and (time.time() - entry[0]) < _CACHE_TTL:
        return entry[1]
    return None


def set_cache(key: str, data: dict) -> None:
    """Store data in cache with current timestamp."""
    _response_cache[key] = (time.time(), data)


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


def _load_json_response(raw_text: str) -> Dict[str, Any]:
    try:
        return json.loads(raw_text)
    except json.JSONDecodeError:
        return {}


def generate_fill_in_blank_questions(language: str, summary: str, num_questions: int = 3) -> Dict[str, List[Dict[str, str]]]:
    """Ask Gemini for fill-in-the-blank prompts plus answer key."""
    # Check cache first
    ck = _cache_key("fill", language, num_questions)
    cached = get_cached(ck)
    if cached:
        return cached

    prompt = (
        "Create a fill-in-the-blank drill for a language learner.\n"
        f"Language: {language}.\n"
        f"Give {num_questions} sentences. Replace one word with ___ and provide 3 answer choices.\n"
        "Respond ONLY in valid JSON with this shape: \n"
        "{\n  \"questions\": [\n    {\"sentence\": \"... ___ ...\", \"options\": [\"option\"], \"answer\": \"correct word\", \"explanation\": \"short English hint\"}\n  ],\n  \"tip\": \"short encouragement\"\n}\n"
        f"Context: {summary or 'Fresh session.'}"
    )
    raw = call_gemini(prompt)
    data = _load_json_response(raw)
    result = data or {
        "questions": [
            {
                "sentence": "Je ___ au marché chaque dimanche.",
                "options": ["vais", "allons", "allez"],
                "answer": "vais",
                "explanation": "Use je + vais for 'I go'.",
            }
        ],
        "tip": "Focus on verb agreement in the present tense.",
    }
    set_cache(ck, result)
    return result


def generate_matching_pairs(language: str, num_pairs: int = 4) -> Dict[str, List[Dict[str, str]]]:
    """Ask Gemini for vocab pairs for matching exercises."""
    # Check cache first
    ck = _cache_key("match", language, num_pairs)
    cached = get_cached(ck)
    if cached:
        return cached

    prompt = (
        "Provide vocabulary flashcards for matching.\n"
        f"Language: {language}.\n"
        f"Return {num_pairs} distinct word pairs as JSON with format: \n"
        "{\n  \"pairs\": [\n    {\"target_word\": \"bonjour\", \"english_word\": \"hello\", \"hint\": \"greeting\"}\n  ]\n}\n"
        "Output JSON only. Keep hints short in English."
    )
    raw = call_gemini(prompt)
    data = _load_json_response(raw)
    if not data:
        data = {
            "pairs": [
                {"target_word": "bonjour", "english_word": "hello", "hint": "greeting"},
                {"target_word": "merci", "english_word": "thank you", "hint": "gratitude"},
            ]
        }
    set_cache(ck, data)
    return data


def generate_grammar_questions(
    language: str, summary: str, num_questions: int = 6
) -> Dict[str, List[Dict[str, str]]]:
    """Ask Gemini for multiple-choice grammar questions."""
    # Check cache first
    ck = _cache_key("grammar", language, num_questions)
    cached = get_cached(ck)
    if cached:
        return cached

    prompt = (
        "Create a grammar quiz for a language learner.\n"
        f"Language: {language}.\n"
        f"Generate {num_questions} multiple-choice questions testing grammar rules "
        "(verb conjugation, articles, tenses, prepositions, etc.).\n"
        "Each question should have exactly 4 options with one correct answer.\n"
        "Respond ONLY in valid JSON with this shape:\n"
        '{\n  "questions": [\n    {"question": "Which is correct?\\n...", '
        '"options": ["a", "b", "c", "d"], "answer": "correct option", '
        '"explanation": "short English explanation"}\n  ]\n}\n'
        f"Context: {summary or 'Fresh session.'}"
    )
    raw = call_gemini(prompt)
    data = _load_json_response(raw)
    result = data or {
        "questions": [
            {
                "question": "Which article is correct? ___ chat est noir.",
                "options": ["Le", "La", "Les", "Un"],
                "answer": "Le",
                "explanation": "'Chat' is masculine singular, so use 'Le'.",
            }
        ],
    }
    set_cache(ck, result)
    return result


def generate_language_reply(task: str, language: str, user_input: str, summary: str) -> Dict[str, str]:
    """Generate a grammar-focused response that follows the dual-language rule."""
    prompt = build_dual_language_prompt(task, language, user_input, summary)
    response = call_gemini(prompt)
    parsed = parse_dual_language_response(response)
    return {
        "target_text": parsed["target_text"],
        "english_text": parsed["english_text"],
        "tip": parsed["tip"],
        "follow_up": parsed["follow_up"],
        "chat_summary": parsed["target_text"][:120],
    }


def generate_listening_material(language: str, summary: str) -> Dict[str, List[str]]:
    """Ask Gemini for a short listening passage plus questions."""
    prompt = (
        "Create a short listening passage in {language}.\n"
        "After the passage, give 1-2 comprehension questions in the target language.\n"
        "Then provide English explanations for the answers."
    ).format(language=language)
    prompt = f"{prompt}\nContext: {summary or 'Fresh session.'}"
    response = call_gemini(prompt)
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
        f"{ELEVENLABS_TTS_URL}/{ELEVENLABS_VOICE_ID}",
        json=payload,
        headers=headers,
        timeout=30,
    )
    response.raise_for_status()
    # ## Upload this audio bytes to storage (e.g., Supabase storage) and return the public URL.
    return "Audio generation successful. Upload audio bytes to storage and return URL."


def transcribe_speech(audio_base64: str, mime_type: str = "audio/mpeg") -> str:
    """Call ElevenLabs speech-to-text and return the transcript."""
    api_key = os.getenv("ELEVENLABS_API_KEY")
    if not api_key:
        raise RuntimeError("Set ELEVENLABS_API_KEY to enable transcription.")
    if not audio_base64:
        raise ValueError("audio_base64 is required for transcription.")

    audio_bytes = base64.b64decode(audio_base64)
    headers = {"xi-api-key": api_key}
    data = {"model_id": ELEVENLABS_STT_MODEL}
    files = {
        "file": ("speech_input", audio_bytes, mime_type or "application/octet-stream")
    }
    response = requests.post(
        ELEVENLABS_STT_URL,
        headers=headers,
        data=data,
        files=files,
        timeout=60,
    )
    response.raise_for_status()
    payload = response.json()
    return payload.get("text", "").strip()

