import 'package:flutter/material.dart';

class PianoState with ChangeNotifier {
  final Map<String, List<Map<String, String>>> _instruments = {
    'Piano': [
      {'Electric Grand': '198_u20_Electric_Grand.sf2'},
      {'Yamaha SY1': '198_Yamaha_SY1_piano.sf2'},
      {'Stein Grand': 'Default.SF2'},
      {'Rock Organ': 'Rock Organ.sf2'},
      {'Jazz Organ': '1_M3R_Jazz_Organ.SF2'},
      {'Organ': '361_Organ_B3.SF2'},
    ],
    'Strings': [
      {'Violin': 'ensemble violin.sf2'},
      {'Cello': 'Concerto Cello.SF2'},
      {'Viola': 'ViolasLong.sf2'},
      {'Guitar (Acoustic)': 'Guitar Acoustic (963KB).sf2'},
      {'Guitar (Electric)': 'Ibanez Electric Guitar.SF2'},
      {'Bass': '241-Bassguitars.SF2'},
    ],
    'Brass': [
      {'Trumpet': 'Joshua_Melodic_Trumpet.SF2'},
      {'Trombone': 'JL_Trombone_New.sf2'},
      {'Saxophone': '198_u20_alto_sax.SF2'},
    ],
    'Woodwind': [
      {'Flute': 'CamsFlute.SF2'},
      {'Clarinet': 'SJO - Clarinet.sf2'},
      {'Oboe': '142_Oboe_Stereo.sf2'},
    ],
    'Percussion': [
      {'Drums': 'HS African Percussion.sf2'}
    ],
    'Voice': [
      {'Choir': 'KBH-Real-Choir-V2.5.sf2'},
      {'Boy Choir': 'Boychoir.sf2'},
      {'Opera Female': 'OperaSingerFemale3.sf2'},
      {'Heaven': 'VoiceOfHeaven.sf2'},
    ],
  };

  final List<String> _notes = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
    "C'"
  ];
  String _currentNote = '..';
  int _volume = 50;
  int _octave = 4;
  int _numberOfKeys = 15;
  String _selectedInstrument = 'Default.SF2';
  String _selectedInstrumentType = 'Stein Grand';

  Map<String, List<Map<String, String>>> get instruments => _instruments;
  List<String> get notes => _notes;
  String get currentNote => _currentNote;
  int get volume => _volume;
  int get octave => _octave;
  int get numberOfKeys => _numberOfKeys;
  String get selectedInstrument => _selectedInstrument;
  String get selectedInstrumentType => _selectedInstrumentType;

  void setCurrentNote(String note) {
    _currentNote = note;
    notifyListeners(); // notifies all listeners to rebuild
  }

  void setVolume(int volume) {
    _volume = volume;
    notifyListeners();
  }

  void setOctave(int octave) {
    _octave = octave;
    notifyListeners();
  }

  void setNumberOfKeys(int numberOfKeys) {
    _numberOfKeys = numberOfKeys;
    notifyListeners();
  }

  void setInstrument(String newInstrument) {
    _selectedInstrument = newInstrument;
    notifyListeners();
  }

  void setInstrumentType(String newInstrumentType) {
    _selectedInstrumentType = newInstrumentType;
    notifyListeners();
  }
}
