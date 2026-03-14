import 'package:equatable/equatable.dart';
import 'package:langpal_prototype/games/wordle/models/letterModel.dart';
import 'package:langpal_prototype/games/wordle/wordle.dart';

class Word extends Equatable {
  const Word({required this.letters});

  factory Word.fromString(String word) =>
      Word(letters: word.split("").map((e) => Letter(val: e)).toList());

  final List<Letter> letters;

  String get wordString => letters.map((e) => e.val).join();

  void addLetter(String val) {
    final currentIndex = letters.indexWhere((e) => e.val.isEmpty);
    if (currentIndex != -1) {
      letters[currentIndex] = Letter(val: val);
    }
  }

  void removeLetter() {
    final recentletterindex = letters
        .lastIndexWhere((e) => e.val.isNotEmpty); //finds last index of the word
    if (recentletterindex != -1) {
      letters[recentletterindex] = Letter.empty();
    }
  }

  @override
  List<Object?> get props => (letters);
}
