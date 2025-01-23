import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // 고유 ID 생성을 위한 패키지
import '../../bookmark_manager.dart';
import '../../model/url_marker.dart';

class AddBookmarkBottomSheet extends ConsumerStatefulWidget {
  const AddBookmarkBottomSheet({Key? key}) : super(key: key);

  @override
  ConsumerState<AddBookmarkBottomSheet> createState() => _AddBookmarkBottomSheetState();
}

class _AddBookmarkBottomSheetState extends ConsumerState<AddBookmarkBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _addBookmark() {
    if (_formKey.currentState!.validate()) {
      final newBookmark = UrlBookmark(
        id: const Uuid().v4(), // 고유 ID 생성
        url: _urlController.text.trim(),
      );

      // Provider를 통해 북마크 추가
      ref.read(urlBookmarkProvider.notifier).addUrlBookmark(newBookmark);

      Navigator.of(context).pop(); // 바텀시트 닫기
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
          top: 16.0,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Bookmark',
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: 'URL'),
                validator: (value) {
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _addBookmark,
                child: const Text('Add Bookmark'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
