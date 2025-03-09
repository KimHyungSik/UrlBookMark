import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../bookmark_manager.dart';
import '../../common/tags.dart';
import '../../model/url_marker.dart';
import '../../model/url_metadata.dart';

// URL metadata provider
final urlMetadataProvider =
StateNotifierProvider<UrlMetadataNotifier, AsyncValue<UrlMetadata?>>((ref) {
  return UrlMetadataNotifier();
});

// URL metadata state management
class UrlMetadataNotifier extends StateNotifier<AsyncValue<UrlMetadata?>> {
  UrlMetadataNotifier() : super(const AsyncValue.data(null));

  Future<void> fetchMetadata(String url) async {
    if (url.isEmpty) return;
    state = const AsyncValue.loading();
    try {
      final metadata = await url.fetchUrlMetadata();
      state = AsyncValue.data(metadata);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

class AddBookmarkBottomSheet extends ConsumerStatefulWidget {
  const AddBookmarkBottomSheet({Key? key}) : super(key: key);

  @override
  ConsumerState<AddBookmarkBottomSheet> createState() =>
      _AddBookmarkBottomSheetState();
}

class _AddBookmarkBottomSheetState
    extends ConsumerState<AddBookmarkBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();
  Timer? _debounceTimer;
  List<String> _tags = [];
  String? _customFolder;
  bool _isFavorite = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _urlController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  /// Bookmark adding process
  Future<void> _addBookmark() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final String url = _prepareUrl(_urlController.text.trim());
        final metadata = ref.read(urlMetadataProvider).value;

        // Handle title and description values
        String? customTitle;
        if (_titleController.text.isNotEmpty) {
          customTitle = _titleController.text;
        }

        String? customDescription;
        if (_descriptionController.text.isNotEmpty) {
          customDescription = _descriptionController.text;
        }

        final newBookmark = UrlBookmark(
          id: const Uuid().v4(),
          url: url,
          customTitle: customTitle,
          customDescription: customDescription,
          tags: _tags.isEmpty ? generateTags(url) : _tags,
          folder: _customFolder,
          isFavorite: _isFavorite,
          metadata: metadata,
        );

        // Add bookmark via provider
        await ref.read(urlBookmarkProvider.notifier).addUrlBookmark(newBookmark);
        ref.read(urlMetadataProvider.notifier).reset(); // Reset state

        if (mounted) {
          Navigator.of(context).pop(); // Close the bottom sheet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Bookmark added successfully")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to add bookmark: ${e.toString()}")),
          );
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  String _prepareUrl(String url) {
    if (url.isEmpty) return url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'https://$url';
    }
    return url;
  }

  /// URL change handler with debouncing
  void _onUrlChanged(String url) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (url.isNotEmpty) {
        final preparedUrl = _prepareUrl(url.trim());
        ref.read(urlMetadataProvider.notifier).fetchMetadata(preparedUrl);

        // Auto-generate tags
        final autoTags = generateTags(preparedUrl);
        if (autoTags.isNotEmpty && _tags.isEmpty) {
          setState(() {
            _tags = autoTags;
          });
        }
      }
    });
  }

  /// Add a tag
  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  /// Remove a tag
  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    final metadataState = ref.watch(urlMetadataProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildMetadataPreview(metadataState),
                      SizedBox(height: 16),
                      _buildUrlField(),
                      SizedBox(height: 12),
                      _buildTitleField(),
                      SizedBox(height: 12),
                      _buildDescriptionField(),
                      SizedBox(height: 16),
                      _buildTagsSection(),
                      SizedBox(height: 16),
                      _buildFolderSelection(),
                      SizedBox(height: 16),
                      _buildFavoriteToggle(),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            _buildAddButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Add Bookmark',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlField() {
    return TextFormField(
      controller: _urlController,
      decoration: InputDecoration(
        labelText: 'URL',
        hintText: 'https://example.com',
        prefixIcon: Icon(Icons.link),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.next,
      onChanged: _onUrlChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please enter a URL";
        }
        // Simple URL validation
        if (!value.contains('.')) {
          return "Please enter a valid URL";
        }
        return null;
      },
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Title (Optional)',
        hintText: 'Custom title for the bookmark',
        prefixIcon: Icon(Icons.title),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description (Optional)',
        hintText: 'Add custom description',
        prefixIcon: Icon(Icons.description),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      maxLines: 2,
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Tags", style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _tags.map((tag) => Chip(
            label: Text(tag),
            deleteIcon: Icon(Icons.close, size: 18),
            onDeleted: () => _removeTag(tag),
          )).toList(),
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: 'Add a tag',
                  prefixIcon: Icon(Icons.tag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onFieldSubmitted: _addTag,
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => _addTag(_tagController.text.trim()),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFolderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Folder (Optional)", style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(Icons.folder),
          ),
          hint: Text("Select a folder"),
          value: _customFolder,
          items: ["Work", "Personal", "Shopping", "Reading", "Recipes"]
              .map((folder) => DropdownMenuItem(
            value: folder,
            child: Text(folder),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _customFolder = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildFavoriteToggle() {
    return SwitchListTile(
      title: Text("Add to Favorites"),
      secondary: Icon(
        _isFavorite ? Icons.star : Icons.star_border,
        color: _isFavorite ? Colors.amber : null,
      ),
      value: _isFavorite,
      onChanged: (value) {
        setState(() {
          _isFavorite = value;
        });
      },
    );
  }

  Widget _buildAddButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _addBookmark,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isProcessing
            ? SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Text("Add Bookmark", style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildMetadataPreview(AsyncValue<UrlMetadata?> metadataState) {
    return metadataState.when(
      data: (metadata) {
        if (metadata == null) return SizedBox.shrink();

        // Auto-fill the title and description if they're empty
        if (_titleController.text.isEmpty && metadata.title != null) {
          _titleController.text = metadata.title!;
        }

        if (_descriptionController.text.isEmpty && metadata.description != null) {
          _descriptionController.text = metadata.description!;
        }

        return Card(
          margin: EdgeInsets.symmetric(vertical: 10),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (metadata.image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      metadata.image!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                      ),
                    ),
                  ),
                SizedBox(height: 12),
                Text(
                  metadata.title ?? "No Title",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (metadata.description != null && metadata.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      metadata.description!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Loading website information..."),
            ],
          ),
        ),
      ),
      error: (error, stack) => Card(
        margin: EdgeInsets.symmetric(vertical: 10),
        color: Colors.red[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                "Failed to load website information",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "The bookmark will be saved with basic information only.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}