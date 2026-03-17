import os
from typing import List
from dotenv import load_dotenv

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# Load environment variables from .env file
load_dotenv()

from listening import run_listening_practice
from speaking import run_speaking_practice
from writing import run_writing_practice
from fill_blanks import score_fill_blank_game, start_fill_blank_game
from matching import score_matching_game, start_matching_game
from wordle import start_wordle_game


class WritingRequest(BaseModel):
    """Payload for writing practice."""
    user_id: str
    user_text: str


class SpeakingRequest(BaseModel):
    """Payload for speaking practice."""
    user_id: str
    topic: str


class ListeningRequest(BaseModel):
    """Payload for listening practice."""
    user_id: str


class FillBlankStartRequest(BaseModel):
    """Payload to start the fill-in-the-blank game."""
    user_id: str
    num_questions: int = 3


class FillBlankSelection(BaseModel):
    """Learner selection for one blank."""
    sentence: str
    selected_option: str
    answer: str
    explanation: str | None = None


class FillBlankScoreRequest(BaseModel):
    """Payload to score the fill-in-the-blank game."""
    user_id: str
    questions: List[FillBlankSelection]


class MatchingStartRequest(BaseModel):
    """Payload to start the matching game."""
    user_id: str
    num_pairs: int = 4


class MatchingPairSelection(BaseModel):
    """Learner selection for a vocab card."""
    target_word: str
    english_word: str
    selected_match: str
    hint: str | None = None


class MatchingScoreRequest(BaseModel):
    """Payload to score the matching game."""
    user_id: str
    pairs: List[MatchingPairSelection]


class WordleStartRequest(BaseModel):
    """Payload to start the Wordle game."""
    user_id: str


app = FastAPI(title="LangPal AI Tutor", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health_check() -> dict:
    """Simple health check so deployment monitors can probe the API."""
    return {"status": "ok"}


@app.post("/practice/writing")
def practice_writing(payload: WritingRequest) -> dict:
    """Call the writing module and bubble up any errors as HTTP issues."""
    try:
        return run_writing_practice(payload.user_id, payload.user_text)
    except Exception as exc:  
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/practice/speaking")
def practice_speaking(payload: SpeakingRequest) -> dict:
    """Call the speaking module and bubble up any errors as HTTP issues."""
    try:
        return run_speaking_practice(payload.user_id, payload.topic)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/practice/listening")
def practice_listening(payload: ListeningRequest) -> dict:
    """Call the listening module and bubble up any errors as HTTP issues."""
    try:
        return run_listening_practice(payload.user_id)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/games/fill-blanks/start")
def start_fill_blanks(payload: FillBlankStartRequest) -> dict:
    """Generate fill-in-the-blank questions for the learner."""
    try:
        return start_fill_blank_game(payload.user_id, payload.num_questions)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/games/fill-blanks/score")
def score_fill_blanks(payload: FillBlankScoreRequest) -> dict:
    """Score the learner's fill-in-the-blank answers."""
    try:
        questions = [question.model_dump() for question in payload.questions]
        return score_fill_blank_game(payload.user_id, questions)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/games/matching/start")
def start_matching(payload: MatchingStartRequest) -> dict:
    """Generate matching pairs for the learner."""
    try:
        return start_matching_game(payload.user_id, payload.num_pairs)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/games/matching/score")
def score_matching(payload: MatchingScoreRequest) -> dict:
    """Score the learner's matching selections."""
    try:
        pairs = [pair.model_dump() for pair in payload.pairs]
        return score_matching_game(payload.user_id, pairs)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/games/wordle/start")
def start_wordle(payload: WordleStartRequest) -> dict:
    """Generate a target word for the Wordle game."""
    print(payload.user_id)
    try:
        return start_wordle_game(payload.user_id)
    except Exception as exc:
        import traceback; traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(exc)) from exc

