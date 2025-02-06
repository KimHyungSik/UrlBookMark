import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bookmark_manager.dart';
import '../common/pressable_button.dart';
import '../widget/bookmark_card.dart';
import 'bottomsheet/add_bookmark_bottom_sheet.dart';

// 🔹 삭제 모드 여부를 관리하는 Provider
final isDeleteModeProvider = StateProvider<bool>((ref) => false);

// 🔹 선택된 북마크 목록을 관리하는 Provider
final selectedBookmarksProvider = StateProvider<Set<String>>((ref) => {});

class BookmarkListScreen extends ConsumerWidget {
  const BookmarkListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(urlBookmarkProvider);
    final isDeleteMode = ref.watch(isDeleteModeProvider);
    final selectedBookmarks = ref.watch(selectedBookmarksProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                pinned: isDeleteMode,
                snap: true,
                backgroundColor: Colors.grey[900],
                title: Consumer(
                  builder: (context, ref, _) {
                    final isDeleteMode = ref.watch(isDeleteModeProvider);
                    final selectedBookmarks =
                        ref.watch(selectedBookmarksProvider);

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isDeleteMode)
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () => ref
                                .read(isDeleteModeProvider.notifier)
                                .state = false,
                          )
                        else
                          SizedBox(width: 48), // 삭제 모드 아닐 때 균형 맞추기

                        if (!isDeleteMode)
                          Text(
                            "Bookmarks",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),

                        if (isDeleteMode)
                          IconButton(
                            icon: Icon(Icons.delete,
                                color: selectedBookmarks.isNotEmpty
                                    ? Colors.red
                                    : Colors.grey),
                            onPressed: selectedBookmarks.isNotEmpty
                                ? () {
                                    ref
                                        .read(urlBookmarkProvider.notifier)
                                        .deleteUrlBookmarks(
                                            selectedBookmarks.toList());
                                    ref
                                        .read(
                                            selectedBookmarksProvider.notifier)
                                        .state = {};
                                    ref
                                        .read(isDeleteModeProvider.notifier)
                                        .state = false;
                                  }
                                : null,
                          )
                        else
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.white),
                            onPressed: () => ref
                                .read(isDeleteModeProvider.notifier)
                                .state = true,
                          ),
                      ],
                    );
                  },
                ),
                centerTitle: true,
              ),
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = bookmarks[index];
                    final isSelected = selectedBookmarks.contains(bookmark.id);

                    return GestureDetector(
                      child: Stack(
                        children: [
                          BookmarkCard(
                            bookmark: bookmark,
                            onTap: () {
                              if (isDeleteMode) {
                                final updatedSelection =
                                    Set<String>.from(selectedBookmarks);
                                if (isSelected) {
                                  updatedSelection.remove(bookmark.id);
                                } else {
                                  updatedSelection.add(bookmark.id);
                                }
                                ref
                                    .read(selectedBookmarksProvider.notifier)
                                    .state = updatedSelection;
                              } else {
                                try {
                                  _launchUrl(Uri.parse(bookmark.url));
                                } catch (e) {
                                  print('Failed to launch URL: $e');
                                }
                              }
                            },
                          ),
                          if (isDeleteMode)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor:
                                    isSelected ? Colors.red : Colors.white54,
                                radius: 12,
                                child: isSelected
                                    ? Icon(Icons.check,
                                        color: Colors.white, size: 16)
                                    : Icon(Icons.circle_outlined,
                                        color: Colors.black, size: 16),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (!isDeleteMode)
            Positioned(
              bottom: 32,
              right: 16,
              child: PressableButton(
                height: 58,
                width: 58,
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) {
                      return const AddBookmarkBottomSheet();
                    },
                  );
                },
                child: Icon(Icons.add, size: 32, color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url = url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
