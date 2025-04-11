
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutDialogWidget extends StatefulWidget {
  const AboutDialogWidget({super.key});

  @override
  State<AboutDialogWidget> createState() => _AboutDialogWidgetState();
}

class _AboutDialogWidgetState extends State<AboutDialogWidget> {
  String appName = 'Empyreal Keys';
  String packageName = '';
  String version = '0.2.1';
  String buildNumber = '';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appName = info.appName;
      packageName = info.packageName;
      version = info.version;
      buildNumber = info.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // final screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Container(
        width: screenWidth / 2,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'About $appName',
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Text('App Name: $appName'),
            Text('Package Name: $packageName'),
            Text('Version: $version'),
            Text('Build Number: $buildNumber'),
            const SizedBox(height: 20.0),
            const Text(
              'Developed by: Adeleke Olasope', // Replace with your name
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20.0),
            const Text(
              '© 2025 Empyreal Works. All rights reserved.', // Replace with your copyright
              style: TextStyle(fontSize: 12.0),
            ),
            const SizedBox(height: 20.0),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close', style: TextStyle(fontSize: MediaQuery.sizeOf(context).height * 0.03)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}