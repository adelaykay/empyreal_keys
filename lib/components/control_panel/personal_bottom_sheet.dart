
import 'package:empyrealkeys/state/recorder_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../services/play_along_service.dart';
import '../../services/library_service.dart';
import 'collapsible_search_bar.dart';

class PersonalBottomSheet extends StatefulWidget {
  const PersonalBottomSheet({super.key});

  @override
  State<PersonalBottomSheet> createState() => _PersonalBottomSheetState();
}

class _PersonalBottomSheetState extends State<PersonalBottomSheet> {
  bool _isImporting = false;
  bool _searchExpanded = false;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final libraryService = Provider.of<LibraryService>(context, listen: false);
    final playAlongService = Provider.of<PlayAlongService>(context, listen: false);
    final recorderService = Provider.of<RecorderService>(context);

    // Combine imported pieces and recordings
    final importedPieces = libraryService.getPersonalPieces();
    final recordings = recorderService.recordings;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                /// Title and Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Personal Library",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        width: _searchExpanded ? 250 : 48,
                        child: CollapsibleSearchBar(
                          hintText: 'Search files...',
                          onExpandChanged: (exp) => setState(() => _searchExpanded = exp),
                          onChanged: (query) => setState(() => _searchQuery = query.toLowerCase()),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tabs
                const TabBar(
                  labelColor: Colors.white,
                  labelPadding: EdgeInsets.symmetric(vertical: 6),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue,
                  tabs: [
                    Tab(text: "Imported"),
                    Tab(text: "Recordings"),
                  ],
                ),

                // Tab content
                Expanded(
                  child: TabBarView(
                    children: [
                      // Imported MIDI files
                      _buildImportedList(
                        scrollController,
                        importedPieces,
                        libraryService,
                        playAlongService,
                      ),

                      // User recordings
                      _buildRecordingsList(
                        scrollController,
                        recordings,
                        playAlongService,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImportedList(
      ScrollController controller,
      List<dynamic> pieces,
      LibraryService libraryService,
      PlayAlongService playAlongService,
      ) {
    // Filter pieces based on search query
    final filteredPieces = _searchQuery.isEmpty
        ? pieces
        : pieces.where((piece) => piece.title.toLowerCase().contains(_searchQuery)).toList();

    return Column(
      children: [
        // Import button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _isImporting ? null : () => _importMidiFile(libraryService, playAlongService),
            icon: _isImporting
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.upload_file),
            label: Text(_isImporting ? 'Importing...' : 'Import MIDI File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3C3C3E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),

        // List of imported pieces
        Expanded(
          child: filteredPieces.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchQuery.isEmpty ? Icons.folder_open : Icons.search_off,
                  size: 64,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty ? 'No imported files yet' : 'No files found',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
                if (_searchQuery.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tap the button above to import',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ]
              ],
            ),
          )
              : ListView.builder(
            controller: controller,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredPieces.length,
            itemBuilder: (context, index) {
              final piece = filteredPieces[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3C3C3E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.music_note, color: Colors.white),
                  title: Text(
                    piece.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '${piece.events.length ~/ 2} notes',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF2C2C2E),
                          title: const Text(
                            'Delete File?',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: Text(
                            'Are you sure you want to delete "${piece.title}"?',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await libraryService.deletePiece(piece.id);
                        setState(() {});
                      }
                    },
                  ),
                  onTap: () {
                    playAlongService.loadPiece(piece);
                    Navigator.pop(context, piece.title);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingsList(
      ScrollController controller,
      List<dynamic> recordings,
      PlayAlongService playAlongService,
      ) {
    // Filter recordings based on search query
    final filteredRecordings = _searchQuery.isEmpty
        ? recordings
        : recordings.where((rec) => rec.title.toLowerCase().contains(_searchQuery)).toList();

    if (filteredRecordings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.mic_none : Icons.search_off,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No recordings yet' : 'No recordings found',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Record something on the Recorder panel',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ]
          ],
        ),
      );
    }

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredRecordings.length,
      itemBuilder: (context, index) {
        final recording = filteredRecordings[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF3C3C3E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.album, color: Colors.white),
            title: Text(
              recording.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              '${recording.events.length ~/ 2} notes • ${_formatDate(recording.createdAt)}',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
            onTap: () {
              playAlongService.loadPiece(recording);
              Navigator.pop(context, recording.title);
            },
          ),
        );
      },
    );
  }

  Future<void> _importMidiFile(
      LibraryService libraryService,
      PlayAlongService playAlongService,
      ) async {
    setState(() => _isImporting = true);

    try {
      // Pick MIDI file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mid', 'midi'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name.replaceAll(RegExp(r'\.(mid|midi)$'), '');

        // Import the file
        final recording = await libraryService.importMidiFile(file, fileName);

        if (recording != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported: $fileName'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {});
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to import file'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}