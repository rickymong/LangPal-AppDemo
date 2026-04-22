"""Fill-in-the-blank game logic."""
import logging
from typing import Dict, List, Any

from ai_utils import generate_fill_in_blank_questions
from supabase_client import fetch_user_context

logger = logging.getLogger(__name__)

# Configuration constants
MIN_QUESTIONS = 1
MAX_QUESTIONS = 20


def _sanitize_fill_blank_questions(raw_questions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Keep only the important fields for each blank question."""
    cleaned: List[Dict[str, Any]] = []
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
    """Generate fresh fill-in-the-blank material.
    
    Args:
        user_id: The user's unique identifier
        num_questions: Number of questions to generate (default: 3)
        
    Returns:
        Dictionary containing language, questions, tip, and total count
        
    Raises:
        ValueError: If num_questions is out of valid range
        Exception: If database or API calls fail
    """
    # Validate input
    if not isinstance(num_questions, int):
        raise ValueError(f"num_questions must be an integer, got {type(num_questions)}")
    if num_questions < MIN_QUESTIONS or num_questions > MAX_QUESTIONS:
        raise ValueError(
            f"num_questions must be between {MIN_QUESTIONS} and {MAX_QUESTIONS}, got {num_questions}"
        )
    
    logger.info(f"Starting fill-blank game for user {user_id} with {num_questions} questions")
    
    try:
        context = fetch_user_context(user_id)
        language = context["language"]
        logger.debug(f"User {user_id} language: {language}")
    except Exception as e:
        logger.error(f"Failed to fetch user context for {user_id}: {str(e)}", exc_info=True)
        raise
    
    try:
        data = generate_fill_in_blank_questions(language, context["summary"], num_questions)
        if not data or "questions" not in data:
            logger.warning(f"No questions generated for user {user_id}")
            data = {"questions": [], "tip": "Keep practicing!"}
    except Exception as e:
        logger.error(f"Failed to generate questions for user {user_id}: {str(e)}", exc_info=True)
        raise
    
    questions = _sanitize_fill_blank_questions(data.get("questions", []))
    
    result = {
        "language": language,
        "questions": questions,
        "tip": data.get("tip", "Keep practicing!"),
        "total_questions": len(questions),
    }
    
    logger.info(f"Generated {len(questions)} questions for user {user_id}")
    return result


def score_fill_blank_game(user_id: str, questions: List[Dict[str, str]]) -> Dict[str, object]:
    """Score learner selections for the fill-in-the-blank game.
    
    Args:
        user_id: The user's unique identifier
        questions: List of question dicts with selected_option and answer fields
        
    Returns:
        Dictionary with score, total_questions, details, and language
        
    Raises:
        Exception: If database calls fail
    """
    logger.info(f"Scoring {len(questions)} questions for user {user_id}")
    try:
        context = fetch_user_context(user_id)
    except Exception as e:
        logger.error(f"Failed to fetch user context for {user_id}: {str(e)}", exc_info=True)
        raise
    
    summary = _score_fill_blank_questions(questions)
    summary["language"] = context["language"]
    logger.info(f"User {user_id} scored {summary['score']}/{summary['total_questions']}")
    return summary
