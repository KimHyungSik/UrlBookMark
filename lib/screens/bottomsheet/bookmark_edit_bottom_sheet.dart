import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_book_marker/bookmark_manager.dart';

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
  late TextEditingController _editTitleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagController;
  Timer? _debounceTimer;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.bookmark.url);
    _editTitleController = TextEditingController(text: widget.bookmark.title);
    _descriptionController =
        TextEditingController(text: widget.bookmark.description);
    _tagController = TextEditingController();
    _tags = widget.bookmark.tags ?? [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookmarkProvider.notifier).state = widget.bookmark;
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _urlController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkState = ref.watch(bookmarkProvider);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Stack(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                minWidth: MediaQuery.of(context).size.width,
                minHeight: MediaQuery.of(context).size.height * 0.2),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMetadataPreviewImage(
                            bookmarkState?.metadata?.image),
                        TextFormField(
                          controller: _urlController,
                          decoration: InputDecoration(labelText: 'URL'),
                          onChanged: _onUrlChanged,
                        ),
                        SizedBox(height: 12),
                        _textFormTitle(),
                        SizedBox(height: 12),
                        _textFormDescription(),
                        SizedBox(height: 12),
                        _editTags(),
                        _addTags(),
                        SizedBox(
                          height: 32,
                        )
                      ],
                    ),
                    Container(
                      height: 18,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: TextButton(
                        onPressed: () {
                          ref
                              .read(urlBookmarkProvider.notifier)
                              .updateUrlBookmark(
                                widget.bookmark.id,
                                bookmarkState!,
                              );
                          Navigator.pop(context);
                        },
                        child: Icon(
                          Icons.check,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextFormField _addTags() {
    return TextFormField(
      controller: _tagController,
      decoration: InputDecoration(labelText: 'Add Tag'),
      onFieldSubmitted: (value) {
        if (value.isNotEmpty) {
          setState(() {
            _tags.add(value);
            _tagController.clear();
          });
        }
      },
    );
  }

  Wrap _editTags() {
    return Wrap(
      spacing: 8,
      children: _tags
          .map((tag) => Chip(
                label: Text(tag),
                onDeleted: () {
                  setState(() {
                    _tags.remove(tag);
                  });
                },
              ))
          .toList(),
    );
  }

  Widget _textFormTitle() {
    return TextFormField(
      controller: _editTitleController,
      decoration: InputDecoration(labelText: 'Title'),
      onChanged: (value) {
        ref.read(bookmarkProvider.notifier).state =
            ref.read(bookmarkProvider.notifier).state?.copyWith(
                  customTitle: value,
                );
      },
    );
  }

  TextFormField _textFormDescription() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(labelText: 'Description'),
      maxLines: 3,
      onChanged: (value) {
        ref.read(bookmarkProvider.notifier).state =
            ref.read(bookmarkProvider.notifier).state?.copyWith(
                  customDescription: value,
                );
      },
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
