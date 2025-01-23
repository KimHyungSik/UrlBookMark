import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/riverpod.dart';
import '../model/url_marker.dart';

class BookmarkListScreen extends ConsumerWidget {
  const BookmarkListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(urlBookmarkProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: ListView.builder(
        itemCount: bookmarks.length,
        itemBuilder: (context, index) {
          final bookmark = bookmarks[index];
          return ListTile(
            title: Text(bookmark.title),
            subtitle: Text(bookmark.url),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => ref.read(urlBookmarkProvider.notifier).deleteUrlBookmark(bookmark.id),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(urlBookmarkProvider.notifier).addUrlBookmark(
            UrlBookmark(id: DateTime.now().toString(), url: 'https://example.com', title: 'Example'),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
