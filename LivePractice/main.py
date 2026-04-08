"""
LivePractice API — FastAPI backend for the voice conversation pipeline.

Endpoints:
    GET  /              Health check
    GET  /health        Detailed health check (verifies env vars)
    POST /conversation  Run a full conversation turn
"""

import os
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

# Load .env before anything else
load_dotenv()

from conversation import run_conversation

# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------

app = FastAPI(
    title="LangPal LivePractice API",
    description="Voice conversation pipeline: STT → Gemini → TTS",
    version="1.0.0",
)


# ---------------------------------------------------------------------------
# Request / Response models
# ---------------------------------------------------------------------------

class ConversationRequest(BaseModel):
    user_id: str                          # Supabase UUID from user_profiles
    audio_base64: str                     # Base64-encoded audio from Flutter mic
    mime_type: str = "audio/mpeg"         # Audio format (MP3 default)


class ConversationResponse(BaseModel):
    transcript: str | None                # What the user said (None if fallback)
    target_text: str | None               # AI response in French
    english_text: str | None              # English translation
    tip: str | None                       # Grammar / vocab tip
    audio_url: str | None                 # Public URL to AI's spoken response
    fallback: bool                        # True if confidence was too low
    confidence: float | None = None       # STT confidence (included on fallback)
    error: str | None = None              # Error message if something broke


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@app.get("/")
async def root():
    """Basic health check."""
    return {"status": "ok", "service": "LangPal LivePractice API"}


@app.get("/health")
async def health_check():
    """Detailed health check — verifies all required env vars are set."""
    required_vars = [
        "ELEVENLABS_API_KEY",
        "GEMINI_API_KEY",
        "SUPABASE_URL",
        "SUPABASE_PUB_KEY",
    ]
    missing = [var for var in required_vars if not os.getenv(var)]

    if missing:
        return {
            "status": "unhealthy",
            "missing_env_vars": missing,
            "message": "Add these to your .env file.",
        }

    return {
        "status": "healthy",
        "env_vars": "all set",
        "pipeline": "STT → Confidence Check → Gemini → TTS → Supabase",
    }


@app.post("/conversation", response_model=ConversationResponse)
async def conversation(request: ConversationRequest):
    """
    Handle a single voice conversation turn.

    Flow:
        1. Transcribe audio (ElevenLabs STT)
        2. Check confidence — if too low, return fallback
        3. Fetch user context from Supabase
        4. Generate AI response (Gemini)
        5. Synthesize speech (ElevenLabs TTS)
        6. Upload audio to Supabase storage
        7. Update rolling chat summary (last 3 turns)
        8. Return JSON to Flutter
    """
    try:
        result = run_conversation(
            user_id=request.user_id,
            audio_base64=request.audio_base64,
            mime_type=request.mime_type,
        )
        return result

    except Exception as e:
        print(f"[ERROR] Unhandled exception in /conversation: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Pipeline error: {str(e)}",
        )


# ---------------------------------------------------------------------------
# Run with: uvicorn main:app --reload --port 8000
# ---------------------------------------------------------------------------
