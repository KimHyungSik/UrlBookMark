import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../bookmark_manager.dart';
import '../common/pressable_button.dart';
import '../widget/bookmark_card.dart';
import 'bottomsheet/add_bookmark_bottom_sheet.dart';

class BookmarkListScreen extends ConsumerWidget {
  const BookmarkListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(urlBookmarkProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // SliverAppBar: 스크롤 동작에 따라 숨겨졌다 나타나는 앱바
              SliverAppBar(
                floating: true,
                // 스크롤 시 나타남
                pinned: false,
                // 스크롤 고정 해제
                snap: true,
                // 빠르게 나타나도록 설정
                backgroundColor: Colors.grey[900],
                flexibleSpace: const FlexibleSpaceBar(
                  title: Text(
                    'Bookmarks',
                    style: TextStyle(color: Colors.white),
                  ),
                  centerTitle: true,
                ),
              ),
              // MasonryGridView를 SliverToBoxAdapter로 감싸서 사용
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = bookmarks[index];
                    return BookmarkCard(
                      bookmark: bookmark,
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 32,
            right: 16,
            child: PressableButton(
              height: 58,
              width: 58,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
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
}
