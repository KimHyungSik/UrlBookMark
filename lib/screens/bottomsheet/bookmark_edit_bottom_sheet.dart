import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/url_marker.dart';
import '../../model/url_metadata.dart';

final bookmarkProvider = StateProvider<UrlBookmark?>((ref) => null);

class BookmarkEditBottomSheet extends ConsumerStatefulWidget {
  final UrlBookmark bookmark;

  BookmarkEditBottomSheet({Key? key, required this.bookmark}) : super(key: key);

  @override
  ConsumerState<BookmarkEditBottomSheet> createState() =>
      _BookmarkEditBottomSheetState();
}

class _BookmarkEditBottomSheetState
    extends ConsumerState<BookmarkEditBottomSheet> {
  late TextEditingController _urlController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.bookmark.url);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookmarkProvider.notifier).state = widget.bookmark;
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkState = ref.watch(bookmarkProvider);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            minWidth: MediaQuery.of(context).size.width,
            minHeight: MediaQuery.of(context).size.height * 0.2),
        child: IntrinsicHeight(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMetadataPreviewImage(bookmarkState?.metadata?.image),
                TextFormField(
                  controller: _urlController,
                  decoration: InputDecoration(labelText: 'URL'),
                  onChanged: _onUrlChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataPreviewImage(String? imageUrl) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  color: Colors.grey[300],
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _onUrlChanged(String url) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(seconds: 1),
      () {
        url.fetchUrlMetadata().then(
          (metadata) {
            ref.read(bookmarkProvider.notifier).state = ref
                .read(bookmarkProvider.notifier)
                .state
                ?.copyWithMetadata(metadata: metadata);
          },
        );
      },
    );
  }
}
