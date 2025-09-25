import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:empyrealkeys/screens/piano_screen.dart';
import 'package:empyrealkeys/services/soundfont.dart';
import 'package:empyrealkeys/state/midi_provider.dart';
import 'package:empyrealkeys/state/piano_state.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'components/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocDir.path);
  await Hive.openBox('pianoPrefs');
  try {
    if (kDebugMode) {
      print('///...Initializing...///');
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      print('///...Initializion complete...///');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Failed to initialize Firebase: $e');
    }
  }
  try {
    // String recaptchaSiteKey = 'xxxxx';
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.debug,
    );
    if (kDebugMode) {
      print('///...App check complete...///');
    }
  } catch (e) {
    if (kDebugMode) {
      print("Failed to activate Firebase App Check: $e");
    }
  }
  final soundfontService = SoundfontService();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (BuildContext context) => PianoState()),
    ChangeNotifierProvider(create: (context) {
      // Access the selectedInstrument from PianoState when initializing MidiProvider
      final pianoState = Provider.of<PianoState>(context, listen: false);
      return MidiProvider(
          font: pianoState.selectedInstrument,
          soundfontService: soundfontService);
    }),
  ], child: const PiaKnowApp()));
}

class PiaKnowApp extends StatelessWidget {
  const PiaKnowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pia-Know',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const PianoScreen(),
      routes: {
        PianoScreen.name: (context) => const PianoScreen(),
      },
    );
  }
}
