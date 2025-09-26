      import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class SoundfontService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Check if the soundfont exists in assets
  Future<bool> isSoundfontInAssets(String filename) async {
    try {
      await rootBundle.load('assets/sounds/soundfonts/$filename');
      return true;
    } catch (e) {
      return false;
    }
  }
  // Checks if the soundfont file is downloaded locally
  Future<bool> isSoundfontDownloaded(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename';
    return File(filePath).exists();
  }

  // Downloads the soundfont from Firebase Storage
  Future<void> downloadSoundfont(String filename) async {
    // final directory = await getApplicationDocumentsDirectory();
    // final filePath = '${directory.path}/$filename';
    // print('Downloading to: $filePath');

    // Get the temporary directory instead of application documents directory
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$filename';
    if (kDebugMode) {
      print('Downloading to: $filePath');
    }


    final ref = _storage.ref().child('soundfonts/$filename');
    try {
      // Fetch download URL
      final downloadUrl = await ref.getDownloadURL();
      if (kDebugMode) {
        print('Download URL: $downloadUrl');
      }

      // Use Dio for downloading the soundfont
      final dio = Dio();
      await dio.download(downloadUrl, filePath);

      // Verify the file was downloaded
      bool fileExists = await File(filePath).exists();
      if (kDebugMode) {
        print(fileExists ? 'File downloaded successfully' : 'File download failed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading soundfont: $e');
      }
      throw Exception('Failed to download soundfont');
    }
  }

  // Get the local path of the soundfont file
  Future<String> getSoundfontPath(String filename) async {
    if (await isSoundfontInAssets(filename)){
      return 'assets/sounds/soundfonts/$filename'; // assets folder path
    }

    // if not in assets, chech temp storage
    final directory = await getTemporaryDirectory();
    return '${directory.path}/$filename';
  }

  // Main function to handle loading soundfont (checks and downloads if needed)
  Future<void> loadSoundfont(String filename) async {
    if (!(await isSoundfontInAssets(filename)) && !(await isSoundfontDownloaded(filename))) {
      await downloadSoundfont(filename);
    }
  }
}
