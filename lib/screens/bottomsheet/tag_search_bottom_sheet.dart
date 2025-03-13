import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bookmark_manager.dart';
import '../../model/url_marker.dart';

// Selected tags filter provider
final selectedTagsFilterProvider = StateProvider<Set<String>>((ref) => {});

// Filtered bookmarks provider
final filteredBookmarksProvider = Provider<List<UrlBookmark>>((ref) {
  final allBookmarks = ref.watch(urlBookmarkProvider);
  final selectedTags = ref.watch(selectedTagsFilterProvider);

  // If no tags selected, return all bookmarks
  if (selectedTags.isEmpty) {
    return allBookmarks;
  }

  // Filter bookmarks that contain at least one of the selected tags
  return allBookmarks.where((bookmark) {
    if (bookmark.tags == null || bookmark.tags!.isEmpty) {
      return false;
    }
    return bookmark.tags!.any((tag) => selectedTags.contains(tag));
  }).toList();
});

class TagSearchBottomSheet extends ConsumerStatefulWidget {
  const TagSearchBottomSheet({Key? key}) : super(key: key);

  @override
  ConsumerState<TagSearchBottomSheet> createState() =>
      _TagSearchBottomSheetState();
}

class _TagSearchBottomSheetState extends ConsumerState<TagSearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _availableTags = [];
  List<String> _filteredTags = [];

  @override
  void initState() {
    super.initState();
    _loadAllTags();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadAllTags() {
    final bookmarks = ref.read(urlBookmarkProvider);
    final Set<String> tags = {};

    // Collect all unique tags from bookmarks
    for (final bookmark in bookmarks) {
      if (bookmark.tags != null) {
        tags.addAll(bookmark.tags!);
      }
    }

    setState(() {
      _availableTags = tags.toList()..sort();
      _filteredTags = _availableTags;
    });
  }

  void _filterTags(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredTags = _availableTags;
      });
      return;
    }

    setState(() {
      _filteredTags = _availableTags
          .where((tag) => tag.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedTags = ref.watch(selectedTagsFilterProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildSearchField(),
          _buildTagsList(selectedTags),
          _buildApplyButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '태그 검색',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '태그 검색',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: _filterTags,
      ),
    );
  }

  Widget _buildTagsList(Set<String> selectedTags) {
    if (_filteredTags.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            '태그가 없습니다',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredTags.length,
        itemBuilder: (context, index) {
          final tag = _filteredTags[index];
          final isSelected = selectedTags.contains(tag);

          return ListTile(
            title: Text(tag),
            leading: Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
            onTap: () {
              final updatedTags = Set<String>.from(selectedTags);
              if (isSelected) {
                updatedTags.remove(tag);
              } else {
                updatedTags.add(tag);
              }
              ref.read(selectedTagsFilterProvider.notifier).state = updatedTags;
            },
          );
        },
      ),
    );
  }

  Widget _buildApplyButton() {
    final selectedTags = ref.watch(selectedTagsFilterProvider);
    final filteredCount = ref.watch(filteredBookmarksProvider).length;
    final totalCount = ref.watch(urlBookmarkProvider).length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                '검색 결과: $filteredCount / $totalCount 북마크',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: Size(double.infinity, 54),
            ),
            child: Text(
              selectedTags.isEmpty ? "모든 북마크 보기" : "필터 적용하기",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
