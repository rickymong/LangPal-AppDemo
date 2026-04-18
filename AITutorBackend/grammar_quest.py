"""Grammar Quest game logic.

Generates multiple-choice grammar questions via Gemini, targeting
verb conjugation, article usage, tense selection, etc.
"""
from typing import Dict, List

from ai_utils import generate_grammar_questions
from supabase_client import fetch_user_context


def _sanitize_grammar_questions(raw_questions: List[Dict]) -> List[Dict]:
    """Keep only the fields the frontend needs."""
    return [
        {
            "question": q.get("question", ""),
            "options": q.get("options", []),
            "answer": q.get("answer", ""),
            "explanation": q.get("explanation", ""),
        }
        for q in raw_questions
    ]


def start_grammar_game(user_id: str, num_questions: int = 6) -> Dict:
    """Generate grammar questions personalized to the user's target language."""
    context = fetch_user_context(user_id)
    language = context["language"]
    data = generate_grammar_questions(language, context["summary"], num_questions)
    questions = _sanitize_grammar_questions(data.get("questions", []))
    return {
        "language": language,
        "questions": questions,
        "total_questions": len(questions),
    }
