import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart'; // easy_localization 추가

import '../bookmark_manager.dart';
import '../common/pressable_button.dart';
import '../model/url_marker.dart';
import '../widget/bookmark_card.dart';
import '../widget/custom_dialog.dart';
import 'bookmark_list_screen_view_model.dart';
import 'bottomsheet/add_bookmark_bottom_sheet.dart';

// Delete mode provider
final isDeleteModeProvider = StateProvider<bool>((ref) => false);

// Selected bookmarks provider
final selectedBookmarksProvider = StateProvider<Set<String>>((ref) => {});

// Selected tags for filtering (내장 태그 검색 기능용)
final selectedTagsProvider = StateProvider<Set<String>>((ref) => {});

// Search mode provider
final isSearchModeProvider = StateProvider<bool>((ref) => false);

class BookmarkListScreen extends ConsumerStatefulWidget {
  const BookmarkListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BookmarkListScreen> createState() => _BookmarkListScreenState();
}

class _BookmarkListScreenState extends ConsumerState<BookmarkListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _allTags = [];
  List<String> _filteredTags = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // 검색어가 변경될 때 태그 필터링
  void _onSearchTextChanged() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _filteredTags = List.from(_allTags);
      });
    } else {
      setState(() {
        _filteredTags = _allTags
            .where((tag) => tag.toLowerCase().contains(query))
            .toList();
      });
    }
  }

  // 모든 북마크에서 태그 추출
  void _extractAllTags() {
    final bookmarks = ref.read(urlBookmarkProvider);
    final Set<String> tagSet = {};

    for (var bookmark in bookmarks) {
      if (bookmark.tags != null) {
        tagSet.addAll(bookmark.tags!);
      }
    }

    setState(() {
      _allTags = tagSet.toList()..sort();
      _filteredTags = List.from(_allTags);
    });
  }

  // 태그 선택 토글
  void _toggleTagSelection(String tag) {
    final selectedTags = Set<String>.from(ref.read(selectedTagsProvider));

    if (selectedTags.contains(tag)) {
      selectedTags.remove(tag);
    } else {
      selectedTags.add(tag);
    }

    ref.read(selectedTagsProvider.notifier).state = selectedTags;
  }

  // 태그 선택 초기화
  void _clearTagSelection() {
    ref.read(selectedTagsProvider.notifier).state = {};
  }

  // 선택된 태그로 북마크 필터링
  List<UrlBookmark> _getFilteredBookmarks(List<UrlBookmark> bookmarks) {
    final selectedTags = ref.watch(selectedTagsProvider);

    if (selectedTags.isEmpty) {
      return bookmarks;
    }

    return bookmarks.where((bookmark) {
      if (bookmark.tags == null || bookmark.tags!.isEmpty) {
        return false;
      }

      for (final tag in bookmark.tags!) {
        if (selectedTags.contains(tag)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarks = ref.watch(urlBookmarkProvider);
    final isDeleteMode = ref.watch(isDeleteModeProvider);
    final selectedBookmarks = ref.watch(selectedBookmarksProvider);
    final isGridView = ref.watch(viewModeProvider);
    final isSearchMode = ref.watch(isSearchModeProvider);
    final selectedTags = ref.watch(selectedTagsProvider);

    // 검색 모드 시작 시 태그 로드
    if (isSearchMode && _allTags.isEmpty) {
      _extractAllTags();
    }

    // 태그로 필터링된 북마크
    final filteredBookmarks = _getFilteredBookmarks(bookmarks);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: _buildAppBar(
          context, isDeleteMode, selectedBookmarks, isGridView, isSearchMode),
      body: Column(
        children: [
          // 검색 모드일 때 검색 인터페이스 표시
          if (isSearchMode) _buildSearchInterface(selectedTags),

          // 북마크 목록
          Expanded(
            child: _buildBookmarkList(
                context,
                isSearchMode ? filteredBookmarks : bookmarks,
                isDeleteMode,
                selectedBookmarks,
                isGridView),
          ),
        ],
      ),
      floatingActionButton:
      !isDeleteMode && !isSearchMode ? _buildAddButton() : null,
    );
  }

  // 앱바 구성
  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDeleteMode,
      Set<String> selectedBookmarks, bool isGridView, bool isSearchMode) {
    if (isSearchMode) {
      // 검색 모드 앱바
      return AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        title: Text(
            'search.tags'.tr(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            ref.read(isSearchModeProvider.notifier).state = false;
            _clearTagSelection();
          },
        ),
      );
    } else if (isDeleteMode) {
      // 삭제 모드 앱바
      return AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        title: Text("${selectedBookmarks.length} selected",
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () {
            ref.read(selectedBookmarksProvider.notifier).state = {};
            ref.read(isDeleteModeProvider.notifier).state = false;
          },
        ),
        actions: [
          // 삭제 확인 버튼
          IconButton(
            icon: Icon(
              Icons.delete,
              color: selectedBookmarks.isNotEmpty ? Colors.red : Colors.grey,
            ),
            onPressed: selectedBookmarks.isNotEmpty
                ? () => _showDeleteConfirmation(context, selectedBookmarks)
                : null,
            tooltip: 'actions.delete'.tr(),
          ),
        ],
      );
    } else {
      // 기본 앱바
      return AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        actions: [
          // 태그 검색 버튼
          IconButton(
            icon: Icon(Icons.tag, color: Colors.white),
            onPressed: () =>
            ref.read(isSearchModeProvider.notifier).state = true,
            tooltip: 'search.tags'.tr(),
          ),

          // 그리드/리스트 뷰 전환 버튼
          IconButton(
            icon: Icon(isGridView ? Icons.view_list : Icons.grid_view,
                color: Colors.white),
            onPressed: () =>
                ref.read(viewModeProvider.notifier).toggleViewMode(),
            tooltip: isGridView ? 'view.list'.tr() : 'view.grid'.tr(),
          ),

          // 삭제 모드 버튼
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () =>
            ref.read(isDeleteModeProvider.notifier).state = true,
            tooltip: 'actions.delete'.tr(),
          ),
        ],
      );
    }
  }

  // 검색 인터페이스 빌드
  Widget _buildSearchInterface(Set<String> selectedTags) {
    return Container(
      color: Colors.grey[850],
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 검색 필드
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'search.hint'.tr(),
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 12),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                },
              )
                  : null,
            ),
          ),

          // 필터링된 태그 목록
          Container(
            height: 50,
            margin: EdgeInsets.only(top: 12),
            child: _filteredTags.isEmpty
                ? Center(
                child: Text(
                    'search.no_tags'.tr(),
                    style: TextStyle(color: Colors.grey)
                )
            )
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filteredTags.length,
              itemBuilder: (context, index) {
                final tag = _filteredTags[index];
                final isSelected = selectedTags.contains(tag);

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (_) => _toggleTagSelection(tag),
                    backgroundColor: Colors.grey[800],
                    selectedColor: Colors.blue,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[300],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 북마크 목록 표시 (그리드 또는 리스트)
  Widget _buildBookmarkList(BuildContext context, List<UrlBookmark> bookmarks,
      bool isDeleteMode, Set<String> selectedBookmarks, bool isGridView) {
    // 북마크가 없는 경우 빈 상태 표시
    if (bookmarks.isEmpty) {
      return _buildEmptyState();
    }

    // 그리드 뷰 표시
    if (isGridView) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: MasonryGridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          itemCount: bookmarks.length,
          itemBuilder: (context, index) => _buildBookmarkItem(context,
              bookmarks[index], isDeleteMode, selectedBookmarks, isGridView),
        ),
      );
    }
    // 리스트 뷰 표시
    else {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.builder(
          itemCount: bookmarks.length,
          itemBuilder: (context, index) => _buildBookmarkItem(context,
              bookmarks[index], isDeleteMode, selectedBookmarks, isGridView),
        ),
      );
    }
  }

  // 개별 북마크 아이템 구성
  Widget _buildBookmarkItem(BuildContext context, UrlBookmark bookmark,
      bool isDeleteMode, Set<String> selectedBookmarks, bool isGridView) {
    final isSelected = selectedBookmarks.contains(bookmark.id);

    return GestureDetector(
      onLongPress: !isDeleteMode
          ? () {
        ref.read(isDeleteModeProvider.notifier).state = true;
        ref.read(selectedBookmarksProvider.notifier).state = {
          bookmark.id
        };
      }
          : null,
      child: Stack(
        children: [
          BookmarkCard(
            bookmark: bookmark,
            isDeleteMode: isDeleteMode,
            isGridMode: isGridView,
            onTap: () {
              if (isDeleteMode) {
                _toggleBookmarkSelection(bookmark.id, selectedBookmarks);
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
                  color:
                  isSelected ? Colors.red : Colors.white.withOpacity(0.8),
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

  // 북마크가 없을 때 표시할 빈 상태 (개선된 버전)
  Widget _buildEmptyState() {
    // 검색 결과가 없는 경우와 북마크가 없는 경우 구분
    final isSearchMode = ref.read(isSearchModeProvider);
    final hasSelectedTags = ref.read(selectedTagsProvider).isNotEmpty;

    if (isSearchMode && hasSelectedTags) {
      // 태그 검색 결과가 없는 경우
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 24),
            Text(
              'search.no_results'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _clearTagSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text('search.reset_selection'.tr()),
            ),
          ],
        ),
      );
    } else {
      // 북마크가 없는 경우
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_border,
                size: 64,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'bookmarks.empty'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'bookmarks.add_first_hint'.tr(),
                style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 32),
            PressableButton(
              height: 55,
              width: 200,
              onPressed: _showAddBookmarkSheet,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 24, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    'bookmarks.add_first'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  // 추가 버튼
  Widget _buildAddButton() {
    return PressableButton(
      height: 58,
      width: 58,
      onPressed: _showAddBookmarkSheet,
      child: Icon(Icons.add, size: 32, color: Colors.black),
    );
  }

  // 북마크 선택 토글 함수
  void _toggleBookmarkSelection(
      String bookmarkId, Set<String> currentSelection) {
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
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {}
  }

  // 북마크 추가 시트 표시
  void _showAddBookmarkSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddBookmarkBottomSheet(),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, Set<String> selectedBookmarks) {
    showCustomConfirmDialog(
      context: context,
      title: 'dialog.delete_title'.tr(),
      message: 'dialog.delete_selected'.tr(args: [selectedBookmarks.length.toString()]),
      cancelText: 'actions.cancel'.tr(),
      confirmText: 'actions.delete'.tr(),
      isDestructive: true,
      icon: Icons.delete_forever,
    ).then(
          (confirmed) {
        if (confirmed == true) {
          ref
              .read(urlBookmarkProvider.notifier)
              .deleteUrlBookmarks(selectedBookmarks.toList());
          ref.read(selectedBookmarksProvider.notifier).state = {};
          ref.read(isDeleteModeProvider.notifier).state = false;
        }
      },
    );
  }
}