import 'package:flutter/material.dart';
import 'package:iconify_flutter/icons/dashicons.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:empyrealkeys/components/control_panel/display.dart';
import 'package:empyrealkeys/components/control_panel/rotary_knob.dart';
import 'keyboard_settings.dart';
import 'octave_selector.dart';

class ControlPanel extends StatefulWidget {
  const ControlPanel({super.key});

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Color(0xFF333333),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
              bottomRight: Radius.circular(15),
              bottomLeft: Radius.circular(15))),
      width: double.infinity,
      height: MediaQuery.of(context).size.height / 3.5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      print('go back');
                    },
                    icon: const Iconify(
                      Dashicons.exit,
                      color: Color(0xFFFFFFFF),
                      size: 30,
                    )),
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  // Octave Selector
                  const OctaveSelector(),
                  // Display
                  const Display(),
                  // Volume Control
                  RotaryKnob(),
                ],
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: IconButton(
                    onPressed: () {
                      showSettingsDialog(context);
                    },
                    icon: const Iconify(
                      Mdi.equalizer_vertical,
                      color: Color(0xFFFFFFFF),
                      size: 30,
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        return AlertDialog(
          contentPadding: EdgeInsets.symmetric(horizontal: screenWidth / 20,),
          actionsPadding: EdgeInsets.symmetric(horizontal: screenWidth / 20, vertical: screenHeight / 20),
          titlePadding: EdgeInsets.only(left: screenWidth / 20, top: screenHeight / 20, right: screenWidth / 20, bottom: 10),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(50))),
          title: const Text('Settings'),
          content: SizedBox(
            width: screenWidth / 3,
            child: SingleChildScrollView(
              child: KeyboardSettings(),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFFFdddd), backgroundColor: const Color(0xFF4A90E2), padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20)),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
