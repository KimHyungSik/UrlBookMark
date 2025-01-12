
import 'package:flutter/material.dart';
import 'package:url_book_marker/model/url_metadata.dart';

import '../../bookmark_manager.dart';
import '../../model/url_marker.dart';

class AddBookmarkBottomSheet extends StatefulWidget {
  final VoidCallback onBookmarkAdded;

  const AddBookmarkBottomSheet({
    Key? key,
    required this.onBookmarkAdded,
  }) : super(key: key);

  @override
  State<AddBookmarkBottomSheet> createState() => _AddBookmarkBottomSheetState();
}

class _AddBookmarkBottomSheetState extends State<AddBookmarkBottomSheet> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _addBookmark() async {
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid URL.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final metadata = await url.fetchMetadata();
      print("LOGEE $metadata");
      final newBookmark = UrlBookmark(
        url: url,
        title: metadata.title ?? url,
        description: metadata.description,
        iconPath: metadata.image,
        createdAt: DateTime.now(),
      );

      final bookmarkManager = UrlBookmarkManager();
      await bookmarkManager.addUrlBookmark(newBookmark);

      widget.onBookmarkAdded(); // 부모 위젯에 알림
      Navigator.pop(context); // 바텀시트 닫기
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch metadata for the URL.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Bookmark',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: 'URL',
              border: const OutlineInputBorder(),
              errorText: _errorMessage,
            ),
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
            onPressed: _addBookmark,
            child: const Text('Add Bookmark'),
          ),
        ],
      ),
    );
  }
}