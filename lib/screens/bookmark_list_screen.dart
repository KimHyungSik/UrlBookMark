import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bookmark_manager.dart';
import '../common/pressable_button.dart';
import '../model/url_marker.dart';
import '../widget/bookmark_card.dart';
import 'bookmark_list_screen_view_model.dart';
import 'bottomsheet/add_bookmark_bottom_sheet.dart';

// Delete mode provider
final isDeleteModeProvider = StateProvider<bool>((ref) => false);

// Selected bookmarks provider
final selectedBookmarksProvider = StateProvider<Set<String>>((ref) => {});

class BookmarkListScreen extends ConsumerWidget {
  const BookmarkListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(urlBookmarkProvider);
    final isDeleteMode = ref.watch(isDeleteModeProvider);
    final selectedBookmarks = ref.watch(selectedBookmarksProvider);
    final isGridView = ref.watch(viewModeProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: _buildAppBar(context, ref, isDeleteMode, selectedBookmarks, isGridView),
      body: _buildBookmarkList(context, ref, bookmarks, isDeleteMode, selectedBookmarks, isGridView),
      floatingActionButton: !isDeleteMode ? _buildAddButton(context) : null,
    );
  }

  // 앱바 구성
  PreferredSizeWidget _buildAppBar(
      BuildContext context,
      WidgetRef ref,
      bool isDeleteMode,
      Set<String> selectedBookmarks,
      bool isGridView
      ) {
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
        // 그리드/리스트 뷰 전환 버튼
        if (!isDeleteMode)
          IconButton(
            icon: Icon(isGridView ? Icons.view_list : Icons.grid_view, color: Colors.white),
            onPressed: () => ref.read(viewModeProvider.notifier).toggleViewMode(),
            tooltip: isGridView ? "리스트 뷰로 전환" : "그리드 뷰로 전환",
          ),

        // 삭제 모드 버튼
        if (!isDeleteMode)
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () => ref.read(isDeleteModeProvider.notifier).state = true,
            tooltip: "삭제 모드",
          ),

        // 삭제 확인 버튼 (삭제 모드일 때)
        if (isDeleteMode)
          IconButton(
            icon: Icon(
              Icons.delete,
              color: selectedBookmarks.isNotEmpty ? Colors.red : Colors.grey,
            ),
            onPressed: selectedBookmarks.isNotEmpty
                ? () => _showDeleteConfirmation(context, ref, selectedBookmarks)
                : null,
            tooltip: "선택 항목 삭제",
          ),
      ],
    );
  }

  // 북마크 목록 표시 (그리드 또는 리스트)
  Widget _buildBookmarkList(
      BuildContext context,
      WidgetRef ref,
      List<UrlBookmark> bookmarks,
      bool isDeleteMode,
      Set<String> selectedBookmarks,
      bool isGridView
      ) {
    // 북마크가 없는 경우 빈 상태 표시
    if (bookmarks.isEmpty) {
      return _buildEmptyState();
    }

    // 그리드 뷰 표시
    if (isGridView) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: MasonryGridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          itemCount: bookmarks.length,
          itemBuilder: (context, index) => _buildBookmarkItem(
              context, ref, bookmarks[index], isDeleteMode, selectedBookmarks, isGridView
          ),
        ),
      );
    }
    // 리스트 뷰 표시
    else {
      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: bookmarks.length,
        itemBuilder: (context, index) => _buildBookmarkItem(
            context, ref, bookmarks[index], isDeleteMode, selectedBookmarks, isGridView
        ),
      );
    }
  }

  // 개별 북마크 아이템 구성
  Widget _buildBookmarkItem(
      BuildContext context,
      WidgetRef ref,
      UrlBookmark bookmark,
      bool isDeleteMode,
      Set<String> selectedBookmarks,
      bool isGridView
      ) {
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
            isGridMode: isGridView,
            onTap: () {
              if (isDeleteMode) {
                _toggleSelection(ref, bookmark.id, selectedBookmarks);
              } else {
                _launchBookmarkUrl(context, bookmark.url);
              }
            },
          ),

          // 선택 표시 (삭제 모드일 때)
          if (isDeleteMode)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.red : Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                padding: EdgeInsets.all(2),
                child: Icon(
                  isSelected ? Icons.check : Icons.circle_outlined,
                  color: isSelected ? Colors.white : Colors.grey[800],
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 북마크가 없을 때 표시할 빈 상태
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "북마크가 없습니다",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            "오른쪽 하단의 + 버튼을 눌러 북마크를 추가해보세요",
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 추가 버튼
  Widget _buildAddButton(BuildContext context) {
    return PressableButton(
      height: 58,
      width: 58,
      onPressed: () => _showAddBookmarkSheet(context),
      child: Icon(Icons.add, size: 32, color: Colors.black),
    );
  }

  // 선택 토글 함수
  void _toggleSelection(WidgetRef ref, String bookmarkId, Set<String> currentSelection) {
    final updatedSelection = Set<String>.from(currentSelection);
    if (updatedSelection.contains(bookmarkId)) {
      updatedSelection.remove(bookmarkId);
    } else {
      updatedSelection.add(bookmarkId);
    }
    ref.read(selectedBookmarksProvider.notifier).state = updatedSelection;
  }

  // URL 열기
  Future<void> _launchBookmarkUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("URL을 열 수 없습니다: $url")),
      );
    }
  }

  // 북마크 추가 시트 표시
  void _showAddBookmarkSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddBookmarkBottomSheet(),
    );
  }

  // 삭제 확인 대화상자
  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Set<String> selectedBookmarks) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("북마크 삭제"),
        content: Text("선택한 ${selectedBookmarks.length}개의 북마크를 삭제하시겠습니까?"),
        actions: [
          TextButton(
            child: Text("취소"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text("삭제", style: TextStyle(color: Colors.red)),
            onPressed: () {
              ref.read(urlBookmarkProvider.notifier).deleteUrlBookmarks(selectedBookmarks.toList());
              ref.read(selectedBookmarksProvider.notifier).state = {};
              ref.read(isDeleteModeProvider.notifier).state = false;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("북마크가 삭제되었습니다")),
              );
            },
          ),
        ],
      ),
    );
  }
}