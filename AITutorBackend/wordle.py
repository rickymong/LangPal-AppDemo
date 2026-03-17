"""Wordle game logic."""
from typing import Dict
from ai_utils import generate_wordle_word
from supabase_client import fetch_user_context

def start_wordle_game(user_id: str) -> Dict[str, str]:
    """Generate a target word and hint for a new Wordle session."""
    print("in start_wordle_game")
    context = fetch_user_context(user_id)
    language = context["language"]
    
    data = generate_wordle_word(language)
    
    return {
        "language": language,
        "word": data["word"],
        "hint": data["hint"]
    }
