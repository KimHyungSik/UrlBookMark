import 'package:flutter/material.dart';
import 'package:url_book_marker/model/url_marker.dart';
import '../bookmark_manager.dart';
import '../common/bottomsheet/add_url_bookmark_bottom_sheet.dart';

class BookmarkListScreen extends StatefulWidget {
  const BookmarkListScreen({Key? key}) : super(key: key);

  @override
  State<BookmarkListScreen> createState() => _BookmarkListScreenState();
}

class _BookmarkListScreenState extends State<BookmarkListScreen> {
  final UrlBookmarkManager _bookmarkManager = UrlBookmarkManager();

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    await _bookmarkManager.loadUrlBookmarks();
    setState(() {}); // 상태 업데이트
  }

  Future<void> _showAddBookmarkBottomSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 키보드 올라올 때 전체 화면 조정
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => AddBookmarkBottomSheet(
        onBookmarkAdded: () async {
          await _loadBookmarks(); // 새 북마크 추가 후 리스트 갱신
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
      ),
      body: _bookmarkManager.urlBookmarks.isEmpty
          ? const Center(child: Text('No bookmarks found.'))
          : ListView.builder(
        itemCount: _bookmarkManager.urlBookmarks.length,
        itemBuilder: (context, index) {
          final bookmark = _bookmarkManager.urlBookmarks[index];
          return BookmarkTile(
            bookmark: bookmark,
            onDelete: () async {
              await _bookmarkManager.deleteUrlBookmark(bookmark.id);
              setState(() {});
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBookmarkBottomSheet, // 바텀시트 연결
        child: const Icon(Icons.add),
      ),
    );
  }
}

class BookmarkTile extends StatelessWidget {
  final UrlBookmark bookmark;
  final VoidCallback onDelete;

  const BookmarkTile({
    Key? key,
    required this.bookmark,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: bookmark.iconPath != null
            ? Image.network(
          bookmark.iconPath!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.image_not_supported),
        )
            : const Icon(Icons.link, size: 50),
        title: Text(
          bookmark.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          bookmark.description ?? 'No description available.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
        onTap: () {
          // Navigate to detail view or open URL
        },
      ),
    );
  }
}
