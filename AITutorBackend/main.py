"""FastAPI entry point for LangPal MVP."""
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from listening import run_listening_practice
from speaking import run_speaking_practice
from writing import run_writing_practice


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


app = FastAPI(title="LangPal AI Tutor", version="0.1.0")


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
