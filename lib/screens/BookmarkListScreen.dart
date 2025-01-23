import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bookmark_manager.dart';
import 'bottomsheet/add_bookmark_bottom_sheet.dart';

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
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
            ),
            builder: (_) => const AddBookmarkBottomSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}



