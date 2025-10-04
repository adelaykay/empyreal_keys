
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/play_along_service.dart';
import '../../services/library_service.dart';
import 'collapsible_search_bar.dart';

class LibraryBottomSheet extends StatefulWidget {
  const LibraryBottomSheet({super.key});

  @override
  State<LibraryBottomSheet> createState() => _LibraryBottomSheetState();
}

class _LibraryBottomSheetState extends State<LibraryBottomSheet> {
  bool _isLoading = false;
  String? _loadingPiece;
  bool _searchExpanded = false;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final libraryService = Provider.of<LibraryService>(context, listen: false);
    final playAlongService = Provider.of<PlayAlongService>(context, listen: false);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: DefaultTabController(
            length: 3,
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

                // Title and Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Music Library",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: _searchExpanded ? 0 : 0),
                        child: SizedBox(
                          width: _searchExpanded ? 250 : 48,
                          child: CollapsibleSearchBar(
                            hintText: 'Search pieces...',
                            onExpandChanged: (exp) => setState(() => _searchExpanded = exp),
                            onChanged: (query) => setState(() => _searchQuery = query.toLowerCase()),
                          ),
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
                    Tab(text: "Easy"),
                    Tab(text: "Intermediate"),
                    Tab(text: "Pro"),
                  ],
                ),

                // Tab content
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildSongList(
                        scrollController,
                        LibraryService.libraryPieces['Easy']!.keys.toList(),
                        libraryService,
                        playAlongService,
                      ),
                      _buildSongList(
                        scrollController,
                        LibraryService.libraryPieces['Intermediate']!.keys.toList(),
                        libraryService,
                        playAlongService,
                      ),
                      _buildSongList(
                        scrollController,
                        LibraryService.libraryPieces['Pro']!.keys.toList(),
                        libraryService,
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

  Widget _buildSongList(
      ScrollController controller,
      List<String> pieces,
      LibraryService libraryService,
      PlayAlongService playAlongService,
      ) {
    // Filter pieces based on search query
    final filteredPieces = _searchQuery.isEmpty
      ? pieces
        : pieces.where((piece)=> piece.toLowerCase().contains(_searchQuery)).toList();

    if (filteredPieces.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No pieces found',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredPieces.length,
      itemBuilder: (context, index) {
        final piece = filteredPieces[index];
        final isLoading = _isLoading && _loadingPiece == piece;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF3C3C3E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.music_note, color: Colors.white),
            title: Text(
              piece,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
            onTap: isLoading
                ? null
                : () async {
              setState(() {
                _isLoading = true;
                _loadingPiece = piece;
              });

              try {
                // Load the piece from library
                final recording = await libraryService.loadLibraryPiece(piece);

                if (recording != null) {
                  // Load into PlayAlong service
                  playAlongService.loadPiece(recording);

                  // Return the piece name to show score
                  if (mounted) {
                    Navigator.pop(context, piece);
                  }
                } else {
                  // Show error
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to load $piece'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _loadingPiece = null;
                  });
                }
              }
            },
          ),
        );
      },
    );
  }
}