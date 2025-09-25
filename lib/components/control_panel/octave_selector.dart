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
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            final currentOctave =
                Provider.of<PianoState>(context, listen: false).octave;
            if (currentOctave < 6) {
              Provider.of<PianoState>(context, listen: false)
                  .setOctave(currentOctave + 1);
            }
          },
          child: Iconify(
            Mdi.arrow_drop_up,
            color: Colors.white,
            size: MediaQuery.of(context).size.width * 0.04,
          ),
        ),
        GestureDetector(
          onTap: () {
            final currentOctave =
                Provider.of<PianoState>(context, listen: false).octave;
            if (currentOctave > 0) {
              Provider.of<PianoState>(context, listen: false)
                  .setOctave(currentOctave - 1);
            }
          },
          child: Iconify(
            Mdi.arrow_drop_down,
            color: Colors.white,
            size: MediaQuery.of(context).size.width * 0.04,
          ),
        ),
      ],
    );
  }
}
