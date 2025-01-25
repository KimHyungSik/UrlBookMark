import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../bookmark_manager.dart';
import '../widget/bookmark_card.dart';
import 'bottomsheet/add_bookmark_bottom_sheet.dart';

class BookmarkListScreen extends ConsumerWidget {
  const BookmarkListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(urlBookmarkProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: Expanded(
        child: MasonryGridView.builder(
          gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
          shrinkWrap: true,
          itemCount: bookmarks.length,
          itemBuilder: (context, index) {
            final bookmark = bookmarks[index];
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: BookmarkCard(
                bookmark: bookmark,
              ),
            );
          },
        ),
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
