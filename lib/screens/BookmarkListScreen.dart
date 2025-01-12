import 'package:flutter/material.dart';
import 'package:url_book_marker/model/url_marker.dart';
import '../bookmark_manager.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
      ),
      body: _bookmarkManager.UrlBookmarks.isEmpty
          ? const Center(child: Text('No bookmarks found.'))
          : ListView.builder(
        itemCount: _bookmarkManager.UrlBookmarks.length,
        itemBuilder: (context, index) {
          final bookmark = _bookmarkManager.UrlBookmarks[index];
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
        onPressed: () async {
          // Navigate to Add Bookmark Screen (not implemented yet)
          // Add bookmark functionality can go here
        },
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
