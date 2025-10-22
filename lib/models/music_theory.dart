// models/music_theory.dart

/// Represents a musical key signature
class KeySignature {
  final int sharps; // Positive for sharps, negative for flats, 0 for C major/A minor
  final bool isMinor;

  const KeySignature({
    required this.sharps,
    this.isMinor = false,
  });

  // Common key signatures
  static const KeySignature cMajor = KeySignature(sharps: 0, isMinor: false);
  static const KeySignature gMajor = KeySignature(sharps: 1, isMinor: false);
  static const KeySignature dMajor = KeySignature(sharps: 2, isMinor: false);
  static const KeySignature aMajor = KeySignature(sharps: 3, isMinor: false);
  static const KeySignature eMajor = KeySignature(sharps: 4, isMinor: false);
  static const KeySignature bMajor = KeySignature(sharps: 5, isMinor: false);
  static const KeySignature fSharpMajor = KeySignature(sharps: 6, isMinor: false);
  static const KeySignature cSharpMajor = KeySignature(sharps: 7, isMinor: false);

  static const KeySignature fMajor = KeySignature(sharps: -1, isMinor: false);
  static const KeySignature bFlatMajor = KeySignature(sharps: -2, isMinor: false);
  static const KeySignature eFlatMajor = KeySignature(sharps: -3, isMinor: false);
  static const KeySignature aFlatMajor = KeySignature(sharps: -4, isMinor: false);
  static const KeySignature dFlatMajor = KeySignature(sharps: -5, isMinor: false);
  static const KeySignature gFlatMajor = KeySignature(sharps: -6, isMinor: false);
  static const KeySignature cFlatMajor = KeySignature(sharps: -7, isMinor: false);

  static const KeySignature aMinor = KeySignature(sharps: 0, isMinor: true);
  static const KeySignature eMinor = KeySignature(sharps: 1, isMinor: true);
  static const KeySignature bMinor = KeySignature(sharps: 2, isMinor: true);
  static const KeySignature fSharpMinor = KeySignature(sharps: 3, isMinor: true);
  static const KeySignature cSharpMinor = KeySignature(sharps: 4, isMinor: true);
  static const KeySignature gSharpMinor = KeySignature(sharps: 5, isMinor: true);
  static const KeySignature dSharpMinor = KeySignature(sharps: 6, isMinor: true);
  static const KeySignature aSharpMinor = KeySignature(sharps: 7, isMinor: true);

  static const KeySignature dMinor = KeySignature(sharps: -1, isMinor: true);
  static const KeySignature gMinor = KeySignature(sharps: -2, isMinor: true);
  static const KeySignature cMinor = KeySignature(sharps: -3, isMinor: true);
  static const KeySignature fMinor = KeySignature(sharps: -4, isMinor: true);
  static const KeySignature bFlatMinor = KeySignature(sharps: -5, isMinor: true);
  static const KeySignature eFlatMinor = KeySignature(sharps: -6, isMinor: true);
  static const KeySignature aFlatMinor = KeySignature(sharps: -7, isMinor: true);

  /// Returns which notes should be sharp/flat in this key
  /// Returns array of pitch classes (0-11) that are altered
  List<int> getAlteredPitchClasses() {
    if (sharps == 0) return [];

    // Order of sharps: F C G D A E B (pitch classes: 5 0 7 2 9 4 11)
    const sharpOrder = [5, 0, 7, 2, 9, 4, 11];
    // Order of flats: B E A D G C F (pitch classes: 11 4 9 2 7 0 5)
    const flatOrder = [11, 4, 9, 2, 7, 0, 5];

    if (sharps > 0) {
      return sharpOrder.take(sharps).toList();
    } else {
      return flatOrder.take(-sharps).toList();
    }
  }

  /// Get the name of this key
  String get name {
    const majorNames = ['C', 'G', 'D', 'A', 'E', 'B', 'F♯', 'C♯'];
    const minorNames = ['A', 'E', 'B', 'F♯', 'C♯', 'G♯', 'D♯', 'A♯'];
    const flatMajorNames = ['F', 'B♭', 'E♭', 'A♭', 'D♭', 'G♭', 'C♭'];
    const flatMinorNames = ['D', 'G', 'C', 'F', 'B♭', 'E♭', 'A♭'];

    if (sharps >= 0) {
      return isMinor ? '${minorNames[sharps]} minor' : '${majorNames[sharps]} major';
    } else {
      final index = (-sharps) - 1;
      return isMinor ? '${flatMinorNames[index]} minor' : '${flatMajorNames[index]} major';
    }
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is KeySignature &&
              runtimeType == other.runtimeType &&
              sharps == other.sharps &&
              isMinor == other.isMinor;

  @override
  int get hashCode => sharps.hashCode ^ isMinor.hashCode;
}

/// Represents a time signature
class TimeSignature {
  final int numerator; // beats per measure
  final int denominator; // note value that gets one beat (4 = quarter note)

  const TimeSignature({
    required this.numerator,
    required this.denominator,
  });

  // Common time signatures
  static const TimeSignature fourFour = TimeSignature(numerator: 4, denominator: 4);
  static const TimeSignature threeFour = TimeSignature(numerator: 3, denominator: 4);
  static const TimeSignature sixEight = TimeSignature(numerator: 6, denominator: 8);
  static const TimeSignature twoFour = TimeSignature(numerator: 2, denominator: 4);
  static const TimeSignature twoTwo = TimeSignature(numerator: 2, denominator: 2);

  /// How many quarter note beats in one measure
  double get beatsPerMeasure => (numerator * 4.0) / denominator;

  @override
  String toString() => '$numerator/$denominator';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is TimeSignature &&
              runtimeType == other.runtimeType &&
              numerator == other.numerator &&
              denominator == other.denominator;

  @override
  int get hashCode => numerator.hashCode ^ denominator.hashCode;
}

/// Represents a note with its pitch spelling (C, C#, Db, etc.)
enum NoteName { C, D, E, F, G, A, B }

enum Accidental {
  doubleFlat,  // 𝄫
  flat,        // ♭
  natural,     // ♮
  sharp,       // ♯
  doubleSharp, // 𝄪
}

class PitchSpelling {
  final NoteName noteName;
  final Accidental accidental;
  final int octave;

  const PitchSpelling({
    required this.noteName,
    required this.accidental,
    required this.octave,
  });

  /// Convert to MIDI note number
  int toMidiNote() {
    const baseValues = {
      NoteName.C: 0,
      NoteName.D: 2,
      NoteName.E: 4,
      NoteName.F: 5,
      NoteName.G: 7,
      NoteName.A: 9,
      NoteName.B: 11,
    };

    final accidentalOffset = {
      Accidental.doubleFlat: -2,
      Accidental.flat: -1,
      Accidental.natural: 0,
      Accidental.sharp: 1,
      Accidental.doubleSharp: 2,
    };

    return baseValues[noteName]! +
        accidentalOffset[accidental]! +
        ((octave + 1) * 12);
  }

  /// Create from MIDI note with key signature context
  static PitchSpelling fromMidiNote(int midiNote, KeySignature keySignature) {
    final octave = (midiNote ~/ 12) - 1;
    final pitchClass = midiNote % 12;

    // Get which notes are altered in this key
    final alteredNotes = keySignature.getAlteredPitchClasses();
    final usesSharps = keySignature.sharps >= 0;

    // Map pitch class to note name and accidental
    const naturalPitchClasses = [0, 2, 4, 5, 7, 9, 11]; // C D E F G A B

    if (naturalPitchClasses.contains(pitchClass)) {
      // It's a natural note
      final noteNames = [
        NoteName.C, NoteName.D, NoteName.E, NoteName.F,
        NoteName.G, NoteName.A, NoteName.B
      ];
      final index = naturalPitchClasses.indexOf(pitchClass);

      // Check if this natural note should be shown as an accidental in this key
      if (alteredNotes.contains(pitchClass)) {
        // This note is altered in the key signature, so we don't show accidental
        return PitchSpelling(
          noteName: noteNames[index],
          accidental: Accidental.natural,
          octave: octave,
        );
      }

      return PitchSpelling(
        noteName: noteNames[index],
        accidental: Accidental.natural,
        octave: octave,
      );
    } else {
      // It's a black key - decide between sharp and flat
      if (usesSharps) {
        // Use sharp spelling
        final sharpNoteNames = {
          1: NoteName.C,  // C#
          3: NoteName.D,  // D#
          6: NoteName.F,  // F#
          8: NoteName.G,  // G#
          10: NoteName.A, // A#
        };

        final noteName = sharpNoteNames[pitchClass]!;
        final isInKey = alteredNotes.contains(pitchClass);

        return PitchSpelling(
          noteName: noteName,
          accidental: isInKey ? Accidental.natural : Accidental.sharp,
          octave: octave,
        );
      } else {
        // Use flat spelling
        final flatNoteNames = {
          1: NoteName.D,  // Db
          3: NoteName.E,  // Eb
          6: NoteName.G,  // Gb
          8: NoteName.A,  // Ab
          10: NoteName.B, // Bb
        };

        final noteName = flatNoteNames[pitchClass]!;
        final isInKey = alteredNotes.contains(pitchClass);

        return PitchSpelling(
          noteName: noteName,
          accidental: isInKey ? Accidental.natural : Accidental.flat,
          octave: octave,
        );
      }
    }
  }

  /// Get display string with accidental symbol
  String get displayName {
    final accidentalSymbol = {
      Accidental.doubleFlat: '𝄫',
      Accidental.flat: '♭',
      Accidental.natural: '',
      Accidental.sharp: '♯',
      Accidental.doubleSharp: '𝄪',
    };

    return '${noteName.name}${accidentalSymbol[accidental]}$octave';
  }

  @override
  String toString() => displayName;
}