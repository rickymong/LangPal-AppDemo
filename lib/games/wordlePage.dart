import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../userNotifier.dart';

class WordleGame extends StatefulWidget {
  final int xp;
  const WordleGame({Key? key, required this.xp}) : super(key: key);

  @override
  State<WordleGame> createState() => _WordleGameState();
}

class _WordleGameState extends State<WordleGame> {
  String targetWord = "";
  String hint = "";
  bool isLoading = true;

  List<String> guesses = List.filled(6, "");
  int currentAttempt = 0;
  String currentGuess = "";

  List<String> keyboardRows1 = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"];
  List<String> keyboardRows2 = ["A", "S", "D", "F", "G", "H", "J", "K", "L"];
  List<String> keyboardRows3 = ["ENTER", "Z", "X", "C", "V", "B", "N", "M", "DEL"];

  Map<String, Color> keyColors = {};

  // UI Theme Colors (Modern/Premium)
  final Color greenColor = const Color(0xFF58CC02);
  final Color yellowColor = const Color(0xFFCEB02C); 
  final Color greyColor = const Color(0xFFE5E5E5);
  final Color darkGreyColor = const Color(0xFF777777);

  @override
  void initState() {
    super.initState();
    _fetchWordData();
  }

  Future<void> _fetchWordData() async {
    final userNotifier = Provider.of<UserNotifier>(context, listen: false);
    final userId = userNotifier.user?.id ?? "582d83ec-488d-4edd-85ca-2eaf8dfb8718";
    
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/games/wordle/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"user_id": userId}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          targetWord = (data["word"] ?? "apple").toUpperCase();
          hint = data["hint"] ?? "";
          isLoading = false;
        });
      } else {
        _setFallback();
      }
    } catch (e) {
      _setFallback();
    }
  }

  void _setFallback() {
    setState(() {
      targetWord = "APPLE";
      hint = "A fallback word (Check backend connection)";
      isLoading = false;
    });
  }

  void _onKeyPress(String key) {
    if (currentAttempt >= 6) return;

    setState(() {
      if (key == "ENTER") {
        if (currentGuess.length == 5) {
          _submitGuess();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not enough letters', style: TextStyle(fontWeight: FontWeight.bold))),
          );
        }
      } else if (key == "DEL") {
        if (currentGuess.isNotEmpty) {
          currentGuess = currentGuess.substring(0, currentGuess.length - 1);
          guesses[currentAttempt] = currentGuess;
        }
      } else {
        if (currentGuess.length < 5) {
          currentGuess += key;
          guesses[currentAttempt] = currentGuess;
        }
      }
    });
  }

  void _submitGuess() {
    if (currentGuess.length != 5) return;

    guesses[currentAttempt] = currentGuess;
    
    // Evaluate colors
    for (int i = 0; i < 5; i++) {
      String letter = currentGuess[i];
      if (targetWord[i] == letter) {
        keyColors[letter] = greenColor;
      } else if (targetWord.contains(letter)) {
        if (keyColors[letter] != greenColor) {
           keyColors[letter] = yellowColor;
        }
      } else {
        if (keyColors[letter] != greenColor && keyColors[letter] != yellowColor) {
          keyColors[letter] = darkGreyColor;
        }
      }
    }

    if (currentGuess == targetWord) {
      _showGameOver(true);
    } else if (currentAttempt == 5) {
      _showGameOver(false);
    } else {
      setState(() {
        currentAttempt++;
        currentGuess = "";
      });
    }
  }

  Color _getTileColor(int row, int col) {
    if (row >= currentAttempt) return Colors.transparent; 
    
    String guess = guesses[row];
    if (guess.length <= col) return Colors.transparent;
    
    String letter = guess[col];
    if (letter == targetWord[col]) return greenColor;
    if (targetWord.contains(letter)) return yellowColor;
    return darkGreyColor;
  }

  Color _getTextColor(int row, int col) {
    if (row >= currentAttempt) return Colors.black; 
    return Colors.white; 
  }

  void _showGameOver(bool won) {
    final userNotifier = Provider.of<UserNotifier>(context, listen: false);
    if (won) {
      userNotifier.completeGame(widget.xp);
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(won ? "You Won!" : "Game Over", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(won ? "Great job! The word was $targetWord.\n+${widget.xp} XP" : "The word was $targetWord."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); 
              Navigator.pop(context); 
            },
            child: const Text("Go Back"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1CB0F6))),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Wordle', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Dynamic Hint Box
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Color(0xFF1CB0F6)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hint: $hint',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // The 6x5 Grid
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 350, maxHeight: 420),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 30, // 6 rows * 5 cols
                  itemBuilder: (context, index) {
                    int r = index ~/ 5;
                    int c = index % 5;
                    String letter = "";
                    if (guesses[r].length > c) {
                      letter = guesses[r][c];
                    }
                    
                    bool submitted = r < currentAttempt;
                    Color tileColor = submitted ? _getTileColor(r, c) : Colors.transparent;
                    Color borderColor = submitted ? Colors.transparent : (letter.isNotEmpty ? darkGreyColor : greyColor);
                    Color textColor = _getTextColor(r, c);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: tileColor,
                        border: Border.all(color: borderColor, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        letter,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          
          // Modern Keyboard
          Container(
            padding: const EdgeInsets.only(bottom: 32, left: 8, right: 8),
            child: Column(
              children: [
                _buildKeyboardRow(keyboardRows1, screenWidth),
                const SizedBox(height: 8),
                _buildKeyboardRow(keyboardRows2, screenWidth),
                const SizedBox(height: 8),
                _buildKeyboardRow(keyboardRows3, screenWidth),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardRow(List<String> rowKeys, double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: rowKeys.map((keyStr) {
        bool isAction = keyStr == "ENTER" || keyStr == "DEL";
        double baseWidth = (screenWidth - 16 - (rowKeys.length * 4)) / rowKeys.length;
        if (baseWidth > 45) baseWidth = 45; 
        double finalWidth = isAction ? baseWidth * 1.5 : baseWidth;
        
        Color bg = keyColors[keyStr] ?? const Color(0xFFE5E5E5); 
        Color fg = (keyColors.containsKey(keyStr)) ? Colors.white : Colors.black87;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: () => _onKeyPress(keyStr),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: finalWidth,
                height: 52,
                alignment: Alignment.center,
                child: Text(
                  keyStr,
                  style: TextStyle(
                    fontSize: isAction ? 12 : 16,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
