"""FastAPI entry point for LangPal MVP.

Security features:
- Per-user rate limiting on all Gemini-powered endpoints (prevents API abuse)
- Input validation via Pydantic with bounded fields
- CORS restricted to known origins
- Request size caps on question/pair counts
"""
import time
from collections import defaultdict
from typing import List

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from listening import run_listening_practice
from speaking import run_speaking_practice
from writing import run_writing_practice
from fill_blanks import score_fill_blank_game, start_fill_blank_game
from matching import score_matching_game, start_matching_game
from grammar_quest import start_grammar_game


# ── Rate Limiter ─────────────────────────────────────────────────────────────

class RateLimiter:
    """Simple in-memory per-user rate limiter.

    Tracks request timestamps per user_id and rejects requests
    that exceed the configured threshold within the time window.

    Attributes:
        max_requests: Maximum number of requests allowed per window.
        window_seconds: Length of the sliding window in seconds.
    """

    def __init__(self, max_requests: int = 10, window_seconds: int = 60):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        # Maps user_id -> list of request timestamps
        self._requests: dict[str, list[float]] = defaultdict(list)

    def is_allowed(self, user_id: str) -> bool:
        """Check if a user_id is within rate limits.

        Prunes expired timestamps, then checks if the user
        has exceeded the max_requests threshold.
        """
        now = time.time()
        cutoff = now - self.window_seconds

        # Prune old entries
        self._requests[user_id] = [
            ts for ts in self._requests[user_id] if ts > cutoff
        ]

        if len(self._requests[user_id]) >= self.max_requests:
            return False

        self._requests[user_id].append(now)
        return True


# Global rate limiter instance:
# 10 requests per user per 60 seconds across all game endpoints
_rate_limiter = RateLimiter(max_requests=10, window_seconds=60)


def _check_rate_limit(user_id: str) -> None:
    """Raise HTTP 429 if the user has exceeded the rate limit."""
    if not _rate_limiter.is_allowed(user_id):
        raise HTTPException(
            status_code=429,
            detail="Rate limit exceeded. Please wait before starting another game.",
        )


# ── Pydantic Models (with validation) ───────────────────────────────────────

class WritingRequest(BaseModel):
    """Payload for writing practice."""
    user_id: str = Field(..., min_length=1, max_length=128)
    user_text: str = Field(..., min_length=1, max_length=5000)


class SpeakingRequest(BaseModel):
    """Payload for speaking practice."""
    user_id: str = Field(..., min_length=1, max_length=128)
    topic: str = Field(..., min_length=1, max_length=500)


class ListeningRequest(BaseModel):
    """Payload for listening practice."""
    user_id: str = Field(..., min_length=1, max_length=128)


class FillBlankStartRequest(BaseModel):
    """Payload to start the fill-in-the-blank game."""
    user_id: str = Field(..., min_length=1, max_length=128)
    num_questions: int = Field(default=3, ge=1, le=10)


class FillBlankSelection(BaseModel):
    """Learner selection for one blank."""
    sentence: str = Field(..., max_length=1000)
    selected_option: str = Field(..., max_length=200)
    answer: str = Field(..., max_length=200)
    explanation: str | None = Field(default=None, max_length=500)


class FillBlankScoreRequest(BaseModel):
    """Payload to score the fill-in-the-blank game."""
    user_id: str = Field(..., min_length=1, max_length=128)
    questions: List[FillBlankSelection] = Field(..., max_length=10)


class MatchingStartRequest(BaseModel):
    """Payload to start the matching game."""
    user_id: str = Field(..., min_length=1, max_length=128)
    num_pairs: int = Field(default=4, ge=1, le=12)


class MatchingPairSelection(BaseModel):
    """Learner selection for a vocab card."""
    target_word: str = Field(..., max_length=200)
    english_word: str = Field(..., max_length=200)
    selected_match: str = Field(..., max_length=200)
    hint: str | None = Field(default=None, max_length=300)


class MatchingScoreRequest(BaseModel):
    """Payload to score the matching game."""
    user_id: str = Field(..., min_length=1, max_length=128)
    pairs: List[MatchingPairSelection] = Field(..., max_length=12)


# ── FastAPI App ──────────────────────────────────────────────────────────────

app = FastAPI(title="LangPal AI Tutor", version="0.2.0")

# CORS: Allow Flutter dev server and Android emulator
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://10.0.2.2:5173",
        "http://localhost:8000",
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST"],  # Restrict to only needed methods
    allow_headers=["Content-Type", "Authorization"],
)


# ── Endpoints ────────────────────────────────────────────────────────────────

@app.get("/health")
def health_check() -> dict:
    """Simple health check so deployment monitors can probe the API."""
    return {"status": "ok"}


@app.post("/practice/writing")
def practice_writing(payload: WritingRequest) -> dict:
    """Call the writing module and bubble up any errors as HTTP issues."""
    _check_rate_limit(payload.user_id)
    try:
        return run_writing_practice(payload.user_id, payload.user_text)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/practice/speaking")
def practice_speaking(payload: SpeakingRequest) -> dict:
    """Call the speaking module and bubble up any errors as HTTP issues."""
    _check_rate_limit(payload.user_id)
    try:
        return run_speaking_practice(payload.user_id, payload.topic)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/practice/listening")
def practice_listening(payload: ListeningRequest) -> dict:
    """Call the listening module and bubble up any errors as HTTP issues."""
    _check_rate_limit(payload.user_id)
    try:
        return run_listening_practice(payload.user_id)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/games/fill-blanks/start")
def start_fill_blanks(payload: FillBlankStartRequest) -> dict:
    """Generate fill-in-the-blank questions for the learner."""
    _check_rate_limit(payload.user_id)
    try:
        return start_fill_blank_game(payload.user_id, payload.num_questions)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/games/fill-blanks/score")
def score_fill_blanks(payload: FillBlankScoreRequest) -> dict:
    """Score the learner's fill-in-the-blank answers."""
    _check_rate_limit(payload.user_id)
    try:
        questions = [question.model_dump() for question in payload.questions]
        return score_fill_blank_game(payload.user_id, questions)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/games/matching/start")
def start_matching(payload: MatchingStartRequest) -> dict:
    """Generate matching pairs for the learner."""
    _check_rate_limit(payload.user_id)
    try:
        return start_matching_game(payload.user_id, payload.num_pairs)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/games/matching/score")
def score_matching(payload: MatchingScoreRequest) -> dict:
    """Score the learner's matching selections."""
    _check_rate_limit(payload.user_id)
    try:
        pairs = [pair.model_dump() for pair in payload.pairs]
        return score_matching_game(payload.user_id, pairs)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


class GrammarStartRequest(BaseModel):
    """Payload to start the grammar quest game."""
    user_id: str = Field(..., min_length=1, max_length=128)
    num_questions: int = Field(default=6, ge=1, le=10)


@app.post("/games/grammar/start")
def start_grammar(payload: GrammarStartRequest) -> dict:
    """Generate grammar questions for the learner."""
    _check_rate_limit(payload.user_id)
    try:
        return start_grammar_game(payload.user_id, payload.num_questions)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc
