import 'package:empyrealkeys/components/control_panel/knob_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconify_flutter/icons/dashicons.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:empyrealkeys/components/control_panel/display.dart';
import 'package:provider/provider.dart';
import '../../state/piano_state.dart';
import 'about_dialog.dart';
import 'keyboard_settings.dart';
import 'metronome_panel.dart';
import 'octave_selector.dart';

class ControlPanel extends StatefulWidget {
  const ControlPanel({super.key});

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  bool _knobActive = false;
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    Future<bool> showExitConfirmationDialog(BuildContext context) async {
      return await showDialog<bool>(
            context: context,
            barrierDismissible: false, // User must tap a button
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.surface,
                titleTextStyle: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: screenHeight * 0.04),
                title: Row(
                  children: [
                    Iconify(
                      Mdi.emergency_exit,
                      color: Theme.of(context).primaryColor,
                      size: 30,
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    const Text('Leaving so soon?'),
                  ],
                ),
                contentPadding:
                    EdgeInsets.only(top: 0, bottom: 20, left: 20, right: 20),
                contentTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: screenHeight * 0.03),
                content: const SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      Divider(),
                      Text('Are you sure you want to exit the app?'),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(
                      'No',
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: screenHeight * 0.035),
                    ),
                    onPressed: () {
                      Navigator.of(context)
                          .pop(false); // Return false (don't exit)
                    },
                  ),
                  TextButton(
                    child: Text(
                      'Yes',
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: screenHeight * 0.035),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(true); // Return true (exit)
                    },
                  ),
                ],
              );
            },
          ) ??
          false;
    }

    return Container(
      decoration: const BoxDecoration(
          color: Color(0xFF333333),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
              bottomRight: Radius.circular(15),
              bottomLeft: Radius.circular(15))),
      width: double.infinity,
      height: screenHeight / 3.5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Exit Button
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 10,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: IconButton(
                      onPressed: () async {
                        final shouldExit =
                            await showExitConfirmationDialog(context);
                        if (shouldExit) {
                          SystemNavigator.pop();
                        }
                      },
                      icon: const Iconify(
                        Dashicons.exit,
                        color: Color(0xFFFFFFFF),
                        size: 30,
                      )),
                ),
              ),
              SizedBox(
                height: 10,
              )
            ],
          ),

          // Page indicator dots (left side)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                );
              }),
            ),
          ),
          // Octave Selector, Display, and Volume Control (swipeable)
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: _knobActive ? const NeverScrollableScrollPhysics() : PageScrollPhysics(),
              scrollDirection: Axis.vertical,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                // --- Page 0: Piano Controls ---
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OctaveSelector(),
                        Display(),
                        Listener(
                          onPointerDown: (_) {
                            setState(() {
                              _knobActive = true;
                            });
                          },
                          onPointerUp: (_) {
                            setState(() {
                              _knobActive = false;
                            });
                          },
                          child: CustomKnob(
                            markerColor: Theme.of(context).primaryColor,
                            size: screenWidth * 0.08,
                            value: Provider.of<PianoState>(context, listen: false).volume.toDouble(),
                            onChanged: (newVolume) {
                              Provider.of<PianoState>(context, listen: false)
                                  .setVolume(newVolume.toInt());
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // --- Page 1: Metronome Controls ---
                MetronomePanel(screenWidth: screenWidth, screenHeight: screenHeight),
              ],
            ),
          ),
          // Settings Button
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 10,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: IconButton(
                      onPressed: () {
                        showSettingsDialog(context, screenWidth, screenHeight);
                      },
                      icon: const Iconify(
                        Mdi.equalizer_vertical,
                        color: Color(0xFFFFFFFF),
                        size: 30,
                      )),
                ),
              ),
              SizedBox(
                height: 10,
              ),
            ],
          ),
        ],
      ),
    );
  }


  void showSettingsDialog(BuildContext context, screenWidth, screenHeight) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            contentPadding: EdgeInsets.symmetric(
              horizontal: screenWidth / 20,
            ),
            actionsPadding: EdgeInsets.symmetric(
                horizontal: screenWidth / 20, vertical: screenHeight / 20),
            titlePadding: EdgeInsets.only(
              left: screenWidth / 20,
              top: screenHeight / 20,
              right: screenWidth / 20,
            ),
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.all(Radius.circular(screenWidth * 0.04))),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Settings', style: TextStyle(fontSize: screenHeight * 0.05)),
                IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return const AboutDialogWidget();
                        },
                      );
                    },
                    icon: Icon(
                      Icons.info_outline,
                      color: Theme.of(context).primaryColor,
                      size: 30,
                    )),
              ],
            ),
            content: SizedBox(
              child: SingleChildScrollView(
                child: KeyboardSettings(),
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).secondaryHeaderColor,
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: screenHeight * 0.02)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Close',
                  style: TextStyle(
                      fontSize: screenWidth * 0.018,
                      color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
