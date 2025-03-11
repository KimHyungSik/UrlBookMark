import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bookmark_manager.dart';
import '../common/pressable_button.dart';
import '../model/url_marker.dart';
import '../widget/bookmark_card.dart';
import 'bottomsheet/add_bookmark_bottom_sheet.dart';
import 'web_search_screen.dart';

// 저장된 뷰 모드를 로드하는 Provider
final viewModeProvider = StateNotifierProvider<ViewModeNotifier, bool>((ref) {
  return ViewModeNotifier();
});

// 선택된 태그 Provider
final selectedTagsProvider = StateProvider<Set<String>>((ref) => {});

// 모든 사용 가능한 태그 Provider
final availableTagsProvider = Provider<List<String>>((ref) {
  final bookmarks = ref.watch(urlBookmarkProvider);
  final Set<String> tags = {};

  for (final bookmark in bookmarks) {
    if (bookmark.tags != null) {
      tags.addAll(bookmark.tags!);
    }
  }

  return tags.toList()..sort();
});

// 태그로 필터링된 북마크 Provider
final filteredBookmarksProvider = Provider<List<UrlBookmark>>((ref) {
  final bookmarks = ref.watch(urlBookmarkProvider);
  final selectedTags = ref.watch(selectedTagsProvider);

  if (selectedTags.isEmpty) {
    return bookmarks;
  }

  return bookmarks.where((bookmark) {
    if (bookmark.tags == null) return false;

    // 선택된 모든 태그가 북마크에 있는지 확인
    return selectedTags.every((tag) => bookmark.tags!.contains(tag));
  }).toList();
});

// 뷰 모드 상태 관리 (SharedPreferences로 저장 기능 포함)
class ViewModeNotifier extends StateNotifier<bool> {
  static const String _viewModeKey = 'view_mode_grid'; // true = grid, false = list

  ViewModeNotifier() : super(true) {
    _loadViewMode();
  }

  // 저장된 뷰 모드 로드
  Future<void> _loadViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isGridView = prefs.getBool(_viewModeKey) ?? true; // 기본값은 그리드 뷰
      state = isGridView;
    } catch (e) {
      print('뷰 모드 로드 실패: $e');
      // 오류 발생 시 기본값 사용 (그리드 뷰)
      state = true;
    }
  }

  // 뷰 모드 변경 및 저장
  Future<void> toggleViewMode() async {
    state = !state;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_viewModeKey, state);
    } catch (e) {
      print('뷰 모드 저장 실패: $e');
    }
  }
}

// Delete mode provider
final isDeleteModeProvider = StateProvider<bool>((ref) => false);

// Selected bookmarks provider
final selectedBookmarksProvider = StateProvider<Set<String>>((ref) => {});

class BookmarkListScreen extends ConsumerWidget {
  const BookmarkListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredBookmarks = ref.watch(filteredBookmarksProvider);
    final isDeleteMode = ref.watch(isDeleteModeProvider);
    final selectedBookmarks = ref.watch(selectedBookmarksProvider);
    final isGridView = ref.watch(viewModeProvider);
    final selectedTags = ref.watch(selectedTagsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: _buildAppBar(context, ref, isDeleteMode, selectedBookmarks, isGridView),
      body: Column(
        children: [
          // 태그 필터 표시
          if (selectedTags.isNotEmpty)
            _buildTagFilterChips(context, ref, selectedTags),

          // 북마크 목록
          Expanded(
            child: _buildBookmarkList(context, ref, filteredBookmarks, isDeleteMode, selectedBookmarks, isGridView),
          ),
        ],
      ),
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
        // 태그 검색 버튼
        if (!isDeleteMode)
          IconButton(
            icon: Icon(Icons.tag, color: Colors.white),
            onPressed: () => _showTagSearchDialog(context, ref),
            tooltip: "태그로 검색",
          ),

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

  // 태그 필터 표시
  Widget _buildTagFilterChips(BuildContext context, WidgetRef ref, Set<String> selectedTags) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "필터링된 태그:",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  ref.read(selectedTagsProvider.notifier).state = {};
                },
                child: Text("필터 초기화", style: TextStyle(color: Colors.blue[300])),
              ),
            ],
          ),
          SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedTags.map((tag) => Chip(
              label: Text(tag, style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.blue[700],
              deleteIconColor: Colors.white,
              onDeleted: () {
                final updatedTags = Set<String>.from(selectedTags);
                updatedTags.remove(tag);
                ref.read(selectedTagsProvider.notifier).state = updatedTags;
              },
            )).toList(),
          ),
        ],
      ),
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
      return _buildEmptyState(ref);
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

  // 북마크가 없을 때 표시할 빈 상태
  Widget _buildEmptyState(WidgetRef ref) {
    // 태그 필터가 적용되었을 때 다른 메시지 표시
    final selectedTags = ref.watch(selectedTagsProvider);
    final isTagFiltered = selectedTags.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isTagFiltered ? Icons.filter_list : Icons.bookmark_border,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            isTagFiltered ? "해당 태그의 북마크가 없습니다" : "북마크가 없습니다",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            isTagFiltered
                ? "다른 태그를 선택하거나 필터를 초기화하세요"
                : "오른쪽 하단의 + 버튼을 눌러 북마크를 추가해보세요",
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          if (isTagFiltered)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  ref.read(selectedTagsProvider.notifier).state = {};
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text("태그 필터 초기화"),
              ),
            ),
        ],
      ),
    );
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

  // 추가 버튼
  Widget _buildAddButton(BuildContext context) {
    return PressableButton(
      height: 58,
      width: 58,
      onPressed: () => _showAddBookmarkSheet(context),
      child: Icon(Icons.add, size: 32, color: Colors.black),
    );
  }

  // 북마크 추가 옵션 표시 (바텀시트 또는 웹 검색)
  // FIXME :: WebView 이상
  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.link),
              title: Text('URL로 북마크 추가'),
              onTap: () {
                Navigator.pop(context);
                _showAddBookmarkSheet(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.search),
              title: Text('웹 검색으로 북마크 추가'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WebSearchScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 태그 검색 다이얼로그
  void _showTagSearchDialog(BuildContext context, WidgetRef ref) {
    final availableTags = ref.read(availableTagsProvider);
    final selectedTags = ref.read(selectedTagsProvider);

    if (availableTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("사용 가능한 태그가 없습니다")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("태그로 검색"),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "북마크에 포함된 태그를 선택하세요",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableTags.map((tag) {
                        final isSelected = selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: isSelected,
                          selectedColor: Colors.blue[100],
                          onSelected: (selected) {
                            final updatedTags = Set<String>.from(selectedTags);
                            if (selected) {
                              updatedTags.add(tag);
                            } else {
                              updatedTags.remove(tag);
                            }
                            ref.read(selectedTagsProvider.notifier).state = updatedTags;
                            setState(() {}); // 다이얼로그 UI 갱신
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text("초기화"),
                  onPressed: () {
                    ref.read(selectedTagsProvider.notifier).state = {};
                    setState(() {}); // 다이얼로그 UI 갱신
                  },
                ),
                TextButton(
                  child: Text("적용"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
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