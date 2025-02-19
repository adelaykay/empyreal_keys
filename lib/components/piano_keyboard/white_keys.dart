import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/midi_provider.dart';
import '../../state/piano_state.dart';

class WhiteKey extends StatefulWidget {
  final String keyType;
  final int idx;
  const WhiteKey({
    super.key,
    required this.keyType,
    required this.idx,
  });

  @override
  State<WhiteKey> createState() => _WhiteKeyState();
}

class _WhiteKeyState extends State<WhiteKey> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details){
        setState(() {
          _isPressed = false;
        });
      },
      onTapDown: (details){
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (details){
        setState(() {
          _isPressed = false;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: _isPressed ? Colors.grey[300] : Colors.white,
          borderRadius: _getBorderRadius(widget.keyType),
        ),
        margin: const EdgeInsets.all(2),
      ),
    );
  }

  BorderRadius _getBorderRadius(String keyType) {
    switch (keyType) {
      case 'rightKey':
        return const BorderRadius.only(
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(5),
        );
      case 'leftKey':
        return const BorderRadius.only(
          topLeft: Radius.circular(10),
          bottomRight: Radius.circular(5),
          bottomLeft: Radius.circular(20),
        );
      default:
        return const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
          bottomRight: Radius.circular(5),
          bottomLeft: Radius.circular(5),
        );
    }
  }
}
