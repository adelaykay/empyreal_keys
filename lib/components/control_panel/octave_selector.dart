import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:provider/provider.dart';

import '../../state/piano_state.dart';

class OctaveSelector extends StatelessWidget {
  const OctaveSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: const Iconify(
            Mdi.arrow_drop_up,
            color: Colors.white,
            size: 40,
          ),
          onPressed: () {
            final currentOctave =
                Provider.of<PianoState>(context, listen: false)
                    .octave;
            if (currentOctave < 6) {
              Provider.of<PianoState>(context, listen: false)
                  .setOctave(currentOctave + 1);
            }
          },
        ),
        const Text(
          'octave',
          style: TextStyle(color: Colors.white, height: 0.5),
        ),
        IconButton(
          icon: const Iconify(Mdi.arrow_drop_down,
              color: Colors.white, size: 40),
          onPressed: () {
            final currentOctave =
                Provider.of<PianoState>(context, listen: false)
                    .octave;
            if (currentOctave > 0) {
              Provider.of<PianoState>(context, listen: false)
                  .setOctave(currentOctave - 1);
            }
          },
        ),
      ],
    );
  }
}
