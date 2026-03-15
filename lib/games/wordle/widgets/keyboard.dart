import 'package:flutter/material.dart';
import 'package:langpal_prototype/games/wordle/models/letterModel.dart';

const _qwerty = [
  ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
  ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
  ['ENTER', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'DEL']
];

class Keyboard extends StatelessWidget{
  const Keyboard({Key? key, required this.onKeyTapped, required this.onDeleteTapped, required this.onEnterTapped, required this.letters}) : super(key: key);

  final void Function(String) onKeyTapped;
  final VoidCallback onDeleteTapped;
  final VoidCallback onEnterTapped;
  final Set<Letter> letters;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _qwerty.map((keyrow) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: keyrow.map(
          (letter) {
            if(letter == 'DEL'){
              return _KeyboardButton.delete(onTap: onDeleteTapped);
            } else if (letter == "ENTER"){
              return _KeyboardButton.enter(onTap: onEnterTapped);
            }

            final letterKey = letters.firstWhere((e) => e.val == letter, orElse: () => Letter.empty());

            return _KeyboardButton(
              height: height * 0.05,
              width: width * 0.08,
              onTap: () => onKeyTapped(letter),
              letter: letter,
              backgroundColor: letterKey != Letter.empty() ? letterKey.backgroundColor : Colors.grey
            );
            }
          
        ).toList()
      )
      ).toList()
    );
  }
}

class _KeyboardButton extends StatelessWidget {
  const _KeyboardButton({Key? key, this.height = 48, this.width = 48, required this.onTap, required this.backgroundColor, required this.letter}) : super(key: key);


  factory _KeyboardButton.delete({
    required VoidCallback onTap,
  }) => _KeyboardButton(height: 48, width: 56, onTap: onTap, backgroundColor: Colors.grey, letter: "DEL");

  factory _KeyboardButton.enter({
    required VoidCallback onTap,
  }) => _KeyboardButton(width: 56, onTap: onTap, backgroundColor: Colors.grey, letter: 'ENTER');

  final double height, width;
  final  VoidCallback onTap;
  final Color backgroundColor;
  final String letter;

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.symmetric( //do these need to be made relative - do they cause overflow errors ever?
        vertical: 3.0,
        horizontal: 2.0,
      ),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: height,
            width: width,
            alignment: Alignment.center,
            child: Text(letter, style: TextStyle(fontSize: 12 , fontWeight: FontWeight.w600)),)
          ),
        ),
      );
  }
}