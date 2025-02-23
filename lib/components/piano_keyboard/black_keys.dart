import 'package:flutter/material.dart';

class BlackKey extends StatefulWidget {
  final double keyWidth;
  final int idx;
  const BlackKey({
    super.key,
    required this.keyWidth,
    required this.idx,
  });

  @override
  State<BlackKey> createState() => _BlackKeyState();
}

class _BlackKeyState extends State<BlackKey> {
  @override
  Widget build(BuildContext context) {

        return Container(
          decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10)),
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF000000),
                    Color(0xFF222222),
                  ])),
          width: widget.keyWidth,
          height: MediaQuery.of(context).size.height * 0.35,
        );
  }
}
