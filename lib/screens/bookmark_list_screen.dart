import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bookmark_manager.dart';
import '../common/pressable_button.dart';
import '../model/url_marker.dart';
import '../widget/bookmark_card.dart';
import 'bottomsheet/add_bookmark_bottom_sheet.dart';

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Sort options for bookmarks
enum SortOption {
  newest,
  oldest,
  alphabetical,
  favorites,
}

// Current sort option provider
final sortOptionProvider = StateProvider<SortOption>((ref) => SortOption.newest);

// Filtered and sorted bookmarks provider
final filteredBookmarksProvider = Provider<List<UrlBookmark>>((ref) {
  final bookmarks = ref.watch(urlBookmarkProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final sortOption = ref.watch(sortOptionProvider);

  // Filter bookmarks based on search query
  List<UrlBookmark> filteredBookmarks = bookmarks;
  if (searchQuery.isNotEmpty) {
    final query = searchQuery.toLowerCase();
    filteredBookmarks = bookmarks.where((bookmark) {
      return bookmark.title.toLowerCase().contains(query) ||
          bookmark.description.toLowerCase().contains(query) ||
          bookmark.url.toLowerCase().contains(query) ||
          (bookmark.tags?.any((tag) => tag.toLowerCase().contains(query)) ?? false);
    }).toList();
  }

  // Sort bookmarks based on selected option
  switch (sortOption) {
    case SortOption.newest:
      filteredBookmarks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    case SortOption.oldest:
      filteredBookmarks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      break;
    case SortOption.alphabetical:
      filteredBookmarks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      break;
    case SortOption.favorites:
      filteredBookmarks.sort((a, b) => b.isFavorite ? 1 : (a.isFavorite ? -1 : 0));
      break;
  }

  return filteredBookmarks;
});

// Delete mode provider
final isDeleteModeProvider = StateProvider<bool>((ref) => false);

// Selected bookmarks provider
final selectedBookmarksProvider = StateProvider<Set<String>>((ref) => {});

class BookmarkListScreen extends ConsumerWidget {
  const BookmarkListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(filteredBookmarksProvider);
    final isDeleteMode = ref.watch(isDeleteModeProvider);
    final selectedBookmarks = ref.watch(selectedBookmarksProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: _buildAppBar(context, ref, isDeleteMode, selectedBookmarks),
      body: _buildBody(context, ref, bookmarks, isDeleteMode, selectedBookmarks),
      floatingActionButton: !isDeleteMode ? _buildFloatingActionButton(context) : null,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref, bool isDeleteMode, Set<String> selectedBookmarks) {
    return AppBar(
      backgroundColor: Colors.grey[900],
      elevation: 0,
      title: isDeleteMode
          ? Text("${selectedBookmarks.length} selected", style: TextStyle(color: Colors.white))
          : Text("Bookmarks", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      leading: isDeleteMode
          ? IconButton(
        icon: Icon(Icons.close, color: Colors.white),
        onPressed: () {
          ref.read(selectedBookmarksProvider.notifier).state = {};
          ref.read(isDeleteModeProvider.notifier).state = false;
        },
      )
          : null,
      actions: [
        if (!isDeleteMode) ...[
          PopupMenuButton<SortOption>(
            icon: Icon(Icons.sort, color: Colors.white),
            onSelected: (SortOption option) {
              ref.read(sortOptionProvider.notifier).state = option;
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: SortOption.newest,
                child: Text("Newest First"),
              ),
              PopupMenuItem(
                value: SortOption.oldest,
                child: Text("Oldest First"),
              ),
              PopupMenuItem(
                value: SortOption.alphabetical,
                child: Text("Alphabetical"),
              ),
              PopupMenuItem(
                value: SortOption.favorites,
                child: Text("Favorites First"),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.white),
            onPressed: () {
              ref.read(isDeleteModeProvider.notifier).state = true;
            },
          ),
        ],
        if (isDeleteMode)
          IconButton(
            icon: Icon(Icons.delete, color: selectedBookmarks.isNotEmpty ? Colors.red : Colors.grey),
            onPressed: selectedBookmarks.isNotEmpty
                ? () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Delete Bookmarks"),
                  content: Text("Are you sure you want to delete ${selectedBookmarks.length} bookmark(s)?"),
                  actions: [
                    TextButton(
                      child: Text("Cancel"),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    TextButton(
                      child: Text("Delete", style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        ref.read(urlBookmarkProvider.notifier).deleteUrlBookmarks(selectedBookmarks.toList());
                        ref.read(selectedBookmarksProvider.notifier).state = {};
                        ref.read(isDeleteModeProvider.notifier).state = false;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Bookmarks deleted successfully")),
                        );
                      },
                    ),
                  ],
                ),
              );
            }
                : null,
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, List<UrlBookmark> bookmarks, bool isDeleteMode, Set<String> selectedBookmarks) {
    if (bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No bookmarks yet",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              "Add your first bookmark by tapping the + button",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        itemCount: bookmarks.length,
        itemBuilder: (context, index) {
          final bookmark = bookmarks[index];
          final isSelected = selectedBookmarks.contains(bookmark.id);

          return GestureDetector(
            onLongPress: !isDeleteMode ? () {
              ref.read(isDeleteModeProvider.notifier).state = true;
              ref.read(selectedBookmarksProvider.notifier).state = {bookmark.id};
            } : null,
            child: Stack(
              children: [
                BookmarkCard(
                  bookmark: bookmark,
                  isDeleteMode: isDeleteMode,
                  onTap: () {
                    if (isDeleteMode) {
                      final updatedSelection = Set<String>.from(selectedBookmarks);
                      if (isSelected) {
                        updatedSelection.remove(bookmark.id);
                      } else {
                        updatedSelection.add(bookmark.id);
                      }
                      ref.read(selectedBookmarksProvider.notifier).state = updatedSelection;
                    } else {
                      try {
                        _launchUrl(Uri.parse(bookmark.url));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Failed to open URL: ${e.toString()}")),
                        );
                      }
                    }
                  },
                ),
                if (isDeleteMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: isSelected ? Colors.red : Colors.white54,
                      radius: 12,
                      child: isSelected
                          ? Icon(Icons.check, color: Colors.white, size: 16)
                          : Icon(Icons.circle_outlined, color: Colors.black, size: 16),
                    ),
                  ),
                if (!isDeleteMode && bookmark.isFavorite)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.star, color: Colors.amber, size: 16),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return PressableButton(
      height: 58,
      width: 58,
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return const AddBookmarkBottomSheet();
          },
        );
      },
      child: Icon(Icons.add, size: 32, color: Colors.black),
    );
  }

  // Fixed URL launcher function (original had a bug with url = url assignment)
  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}