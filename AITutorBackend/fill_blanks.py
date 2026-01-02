"""Fill-in-the-blank game logic."""
from typing import Dict, List

from ai_utils import generate_fill_in_blank_questions
from supabase_client import fetch_user_context


def _sanitize_fill_blank_questions(raw_questions: List[Dict[str, str]]) -> List[Dict[str, str]]:
    """Keep only the important fields for each blank question."""
    cleaned: List[Dict[str, str]] = []
    for item in raw_questions:
        cleaned.append(
            {
                "sentence": item.get("sentence", ""),
                "options": item.get("options", []),
                "answer": item.get("answer", ""),
                "explanation": item.get("explanation", ""),
            }
        )
    return cleaned


def _score_fill_blank_questions(questions: List[Dict[str, str]]) -> Dict[str, object]:
    """Compare selected options to the answer key and build a summary."""
    results: List[Dict[str, object]] = []
    score = 0
    for question in questions:
        selected = question.get("selected_option", "")
        correct = question.get("answer", "")
        is_correct = bool(selected) and selected == correct
        if is_correct:
            score += 1
        results.append(
            {
                "sentence": question.get("sentence", ""),
                "selected_option": selected,
                "correct_answer": correct,
                "is_correct": is_correct,
                "explanation": question.get("explanation", ""),
            }
        )
    return {
        "score": score,
        "total_questions": len(questions),
        "details": results,
        "correct_answers": [
            {"sentence": item.get("sentence", ""), "answer": item.get("answer", "")}
            for item in questions
        ],
    }


def start_fill_blank_game(user_id: str, num_questions: int = 3) -> Dict[str, object]:
    """Generate fresh fill-in-the-blank material."""
    context = fetch_user_context(user_id)
    language = context["language"]
    data = generate_fill_in_blank_questions(language, context["summary"], num_questions)
    questions = _sanitize_fill_blank_questions(data.get("questions", []))
    return {
        "language": language,
        "questions": questions,
        "tip": data.get("tip", "Keep practicing!"),
        "total_questions": len(questions),
    }


def score_fill_blank_game(user_id: str, questions: List[Dict[str, str]]) -> Dict[str, object]:
    """Score learner selections for the fill-in-the-blank game."""
    context = fetch_user_context(user_id)
    summary = _score_fill_blank_questions(questions)
    summary["language"] = context["language"]
    return summary
