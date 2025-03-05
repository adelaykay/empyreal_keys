import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import '../components/control_panel/piano_controls.dart';
import '../components/piano_keyboard/piano_keys.dart';

class PianoScreen extends StatefulWidget {
  static const name = '/piano/';
  const PianoScreen({super.key});

  @override
  State<PianoScreen> createState() => _PianoScreenState();
}

class _PianoScreenState extends State<PianoScreen> {
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  @override
  void initState() {
    super.initState();
    _setOrientationForDevice();
  }

  Future<void> _setOrientationForDevice() async {
    if (await _isMobileDevice()) {
      SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.immersiveSticky); // For fullscreen mode
      // Lock to landscape for mobile devices (smartphones and tablets)
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    // No orientation change for desktops
  }

  Future<bool> _isMobileDevice() async {
    final deviceData = await deviceInfoPlugin.deviceInfo;
    if (deviceData is AndroidDeviceInfo || deviceData is IosDeviceInfo) {
      return true;
    }
    return false; // For desktop platforms
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge); // Restores the UI on exit
    // Allow other screens to rotate freely
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
              Color(0xFF4A4A4A),
              Color(0xFF333333),
            ])),
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: [
              ControlPanel(),
              SizedBox(
                height: 10,
              ),
              PianoKeys(),
            ],
          ),
        ),
      ),
    );
  }
}
