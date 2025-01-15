import 'package:flutter/material.dart';
import 'dart:math';

import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:provider/provider.dart';

import '../../state/piano_state.dart';

class RotaryKnob extends StatefulWidget {
  @override
  _RotaryKnobState createState() => _RotaryKnobState();
}

class _RotaryKnobState extends State<RotaryKnob> {
  double _rotationAngle = 0;  // Rotation angle in radians
  int _volume = 50;  // Default volume

  // Detect drag and calculate the angle
  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _rotationAngle += details.delta.dx * 0.02; // Adjust sensitivity
      // Clamp the angle between -5/6 * pi (7 o'clock) and 5/6 * pi (5 o'clock)
      _rotationAngle = _rotationAngle.clamp(-5 / 6 * pi, 5 / 6 * pi);
      // Calculate the volume based on the clamped angle
      _volume = ((_rotationAngle + 5 / 6 * pi) / (10 / 6 * pi) * 100).clamp(0, 100).toInt();
      // Notify PianoState or other state management that the volume has changed
      Provider.of<PianoState>(context, listen: false)
          .setVolume(_volume);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,  // Detect drag to rotate the knob
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Knob background
          Container(
            width: 50,  // Adjust size as needed
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[800],  // Knob color
              shape: BoxShape.circle,  // Circular knob
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  offset: const Offset(-2, -2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),

          // Rotating knob
          Transform.rotate(
            angle: _rotationAngle,  // Rotate based on user input
            child: Container(
              width: 80,  // Inner part of the knob
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[600],  // Adjust the color for effect
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(4, 4),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Iconify(Mdi.volume_control, color: Colors.white, size: 70,),  // Icon to indicate volume control
              ),
            ),
          ),

          // Display the current volume
          Positioned(
            bottom: -20,  // Display the volume below the knob
            child: Text(
              _volume.toInt().toString(),  // Display volume percentage
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
