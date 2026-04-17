"""Helpers that talk to Gemini and ElevenLabs."""
from typing import Any, Dict, List

import base64
import os
import re
import json

import google.generativeai as genai

# ## Set ELEVENLABS_API_KEY as an environment variable before running the app.
import requests

# AI Provider Configuration
AI_PROVIDER = os.getenv("AI_PROVIDER", "gemini").lower()
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-1.5-pro")
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434/api/generate")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "qwen3:8b")
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
        generation_config={"temperature": 0.7},
    )
    text = getattr(response, "text", "") or ""
    return text.strip()


def call_ollama(prompt: str) -> str:
    """Send a prompt to local Ollama and return the plain text response."""
    payload = {
        "model": OLLAMA_MODEL,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": 0.7
        }
    }
    try:
        response = requests.post(OLLAMA_URL, json=payload, timeout=120)
        response.raise_for_status()
        return response.json().get("response", "").strip()
    except requests.exceptions.RequestException as e:
        return '{"error": "Failed to connect to Ollama. Is the server running?"}'


def call_ai(prompt: str) -> str:
    """Route the prompt to the correct AI provider based on environment config."""
    if AI_PROVIDER == "ollama":
        return call_ollama(prompt)
    else:
        return call_gemini(prompt)


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
    text = raw_text.strip()
    if text.startswith("```json"):
        text = text[7:]
    elif text.startswith("```"):
        text = text[3:]
    if text.endswith("```"):
        text = text[:-3]
    try:
        return json.loads(text.strip())
    except json.JSONDecodeError as e:
        return {}


def generate_fill_in_blank_questions(language: str, summary: str, num_questions: int = 3) -> Dict[str, List[Dict[str, str]]]:
    """Ask Gemini for fill-in-the-blank prompts plus answer key."""
    prompt = (
        "Create a fill-in-the-blank drill for a language learner.\n"
        f"Language: {language}.\n"
        f"Give {num_questions} completely unique sentences. Replace one word with ___ and provide 3 answer choices.\n"
        "Respond ONLY in valid JSON with this exact shape: \n"
        "{\n  \"questions\": [\n    {\"sentence\": \"<target_language_sentence>\", \"options\": [\"<wrong1>\", \"<correct>\", \"<wrong2>\"], \"answer\": \"<correct_word>\", \"explanation\": \"<short English hint>\"}\n  ],\n  \"tip\": \"<short encouragement>\"\n}\n"
        f"Context: {summary or 'Fresh session.'}"
    )
    raw = call_ai(prompt)
    data = _load_json_response(raw)
    return data or {
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


def generate_matching_pairs(language: str, num_pairs: int = 4) -> Dict[str, List[Dict[str, str]]]:
    """Ask Gemini for vocab pairs for matching exercises."""
    prompt = (
        "Provide vocabulary flashcards for matching.\n"
        f"Language: {language}.\n"
        "Generate completely unique words. Do not copy the placeholder text.\n"
        f"Return {num_pairs} distinct word pairs as JSON with format: \n"
        "{\n  \"pairs\": [\n    {\"target_word\": \"<word_in_target_language>\", \"english_word\": \"<english_translation>\", \"hint\": \"<short_hint>\"}\n  ]\n}\n"
        "Output JSON only. Keep hints short in English."
    )
    raw = call_ai(prompt)
    data = _load_json_response(raw)
    if not data:
        data = {
            "pairs": [
                {"target_word": "bonjour", "english_word": "hello", "hint": "greeting"},
                {"target_word": "merci", "english_word": "thank you", "hint": "gratitude"},
            ]
        }
    return data
    return sections


def generate_language_reply(task: str, language: str, user_input: str, summary: str) -> Dict[str, str]:
    """Generate a grammar-focused response that follows the dual-language rule."""
    prompt = build_dual_language_prompt(task, language, user_input, summary)
    response = call_ai(prompt)
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
    response = call_ai(prompt)
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


def generate_wordle_word(language: str) -> Dict[str, str]:
    """Ask AI for a random 5-letter word in the target language."""
    prompt = (
        f"Provide a completely random, well-known 5-letter word in {language}.\n"
        "You must generate a different word every time. Avoid obscure words.\n"
        "Respond ONLY in valid JSON with this exact shape: \n"
        "{\n  \"word\": \"<your_random_5_letter_word>\", \"hint\": \"<short_english_hint>\"\n}\n"
        "The hint must be written in English."
    )
    raw = call_ai(prompt)
    data = _load_json_response(raw)

    # Validation
    word = data.get("word", "").strip().lower()
    if not word or len(word) != 5:
        # Fallback if AI fails parsing or provides wrong length
        word = "apple" if language.lower() == "english" else "mundo"
        data = {"word": word, "hint": "A common word to get you started."}

    return data

