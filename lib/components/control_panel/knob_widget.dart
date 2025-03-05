import 'dart:math';
import 'package:flutter/material.dart';

class CustomKnob extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double size;
  final double minValue;
  final double maxValue;
  final Color? markerColor;
  final Gradient? outerRingGradient;
  final Gradient? innerKnobGradient;
  final Widget? knobLabel;

  const CustomKnob({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 150.0,
    this.minValue = 0,
    this.maxValue = 100,
    this.markerColor,
    this.outerRingGradient,
    this.innerKnobGradient,
    this.knobLabel,
  });

  @override
  _CustomKnobState createState() => _CustomKnobState();
}

class _CustomKnobState extends State<CustomKnob> {
  late double _angle;
  late double _value;

  // Define min and max angles based on clock positions
  final double minAngle = 3 * pi / 4; // 225° (7 O'Clock)
  final double maxAngle = 9 * pi / 4; // 405° (same as 45° but normalized)

  @override
  void initState() {
    super.initState();
    _value = widget.value;
    _angle = _valueToAngle(_value);
  }

  // Update the knob's value based on user interaction
  void _updateValue(Offset localPosition) {
    final center = Offset(widget.size / 2, widget.size / 2);
    double angle = atan2(localPosition.dy - center.dy, localPosition.dx - center.dx);

    // Normalize angle to range [minAngle, maxAngle]
    if (angle < minAngle) {
      angle += 2 * pi;
    }
    // angle = angle.clamp(minAngle, maxAngle);

    // Convert angle to a normalized value between minValue and maxValue
    final normalizedValue = (angle - minAngle) / (maxAngle - minAngle);
    final newValue = widget.minValue + normalizedValue * (widget.maxValue - widget.minValue);

    // prevent abrupt jumps between 0 and 100
    if((newValue - widget.maxValue) > 15.0 && newValue > widget.maxValue) {
      setState(() {
        _value = widget.minValue;
        _angle = _valueToAngle(_value);
      });
    } else {
      setState(() {
        _value = newValue.clamp(widget.minValue, widget.maxValue);
        _angle = _valueToAngle(_value);
      });
    }

    widget.onChanged(_value);
  }

  // Convert a value to its corresponding angle within the defined range
  double _valueToAngle(double value) {
    return minAngle + ((value - widget.minValue) / (widget.maxValue - widget.minValue)) * (maxAngle - minAngle);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onPanUpdate: (details) {
            _updateValue(details.localPosition);
          },
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: KnobPainter(
              angle: _angle,
              markerColor: widget.markerColor ?? Colors.greenAccent,
              outerRingGradient: widget.outerRingGradient ?? const LinearGradient(
                colors: [Colors.black, Colors.grey],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              innerKnobGradient: widget.innerKnobGradient ?? const LinearGradient(
                colors: [Colors.grey, Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        if (widget.knobLabel != null) Padding(padding: const EdgeInsets.only(top: 10), child: widget.knobLabel!),
      ],
    );
  }
}

class KnobPainter extends CustomPainter {
  final double angle;
  final Color markerColor;
  final Gradient outerRingGradient;
  final Gradient innerKnobGradient;

  KnobPainter({
    required this.angle,
    required this.markerColor,
    required this.outerRingGradient,
    required this.innerKnobGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Paint for the outer ring
    final outerRingPaint = Paint()
      ..shader = outerRingGradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    // Paint for the inner knob
    final innerKnobPaint = Paint()
      ..shader = innerKnobGradient.createShader(Rect.fromCircle(center: center, radius: radius * 0.8))
      ..style = PaintingStyle.fill;

    // Paint for the marker line
    final markerPaint = Paint()
      ..color = markerColor
      ..strokeWidth = 3.0;

    // Draw outer ring
    canvas.drawCircle(center, radius, outerRingPaint);

    // Draw inner knob
    canvas.drawCircle(center, radius * 0.7, innerKnobPaint);

    // Calculate marker line positions
    final markerStart = Offset(center.dx + cos(angle) * radius * 0.6, center.dy + sin(angle) * radius * 0.6);
    final markerEnd = Offset(center.dx + cos(angle) * radius * 0.75, center.dy + sin(angle) * radius * 0.75);
    // Draw marker line
    canvas.drawLine(markerStart, markerEnd, markerPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
