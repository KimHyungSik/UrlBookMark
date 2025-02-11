import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/url_marker.dart';
import '../../model/url_metadata.dart';

final bookmarkProvider = StateProvider<UrlBookmark?>((ref) => null);

class BookmarkEditBottomSheet extends ConsumerWidget {
  final UrlBookmark bookmark;

  const BookmarkEditBottomSheet({Key? key, required this.bookmark})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkState = ref.watch(bookmarkProvider);
    final bookmarkNotifier = ref.read(bookmarkProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      bookmarkNotifier.state = bookmark;
    });

    return ConstrainedBox(
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
              _buildMetadataPreview(bookmark.metadata),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataPreview(UrlMetadata? metadata) {
    if (metadata == null) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (metadata.image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                metadata.image!,
                height: 120,
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
          Text(
            metadata.title ?? "No Title",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (metadata.description != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                metadata.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
        ],
      ),
    );
  }
}
