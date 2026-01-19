"""Matching game logic."""
from typing import Dict, List

from ai_utils import generate_matching_pairs
from supabase_client import fetch_user_context


def _score_matching_pairs(pairs: List[Dict[str, str]]) -> Dict[str, object]:
    """Compare learner matches to the answer key."""
    results: List[Dict[str, object]] = []
    score = 0
    for pair in pairs:
        selected = pair.get("selected_match", "")
        correct = pair.get("english_word", "")
        is_correct = bool(selected) and selected.lower().strip() == correct.lower().strip()
        if is_correct:
            score += 1
        results.append(
            {
                "target_word": pair.get("target_word", ""),
                "selected_match": selected,
                "correct_answer": correct,
                "hint": pair.get("hint", ""),
                "is_correct": is_correct,
            }
        )
    return {
        "score": score,
        "total_pairs": len(pairs),
        "details": results,
        "correct_answers": [
            {"target_word": item.get("target_word", ""), "answer": item.get("english_word", "")}
            for item in pairs
        ],
    }


def start_matching_game(user_id: str, num_pairs: int = 4) -> Dict[str, object]:
    """Generate matching flashcards."""
    context = fetch_user_context(user_id)
    language = context["language"]
    data = generate_matching_pairs(language, num_pairs)
    pairs = data.get("pairs", [])
    return {
        "language": language,
        "pairs": pairs, #List of maps/dictionaries
        "total_pairs": len(pairs),
    }


def score_matching_game(user_id: str, pairs: List[Dict[str, str]]) -> Dict[str, object]:
    """Score the matching selections."""
    context = fetch_user_context(user_id)
    summary = _score_matching_pairs(pairs)
    summary["language"] = context["language"]
    return summary