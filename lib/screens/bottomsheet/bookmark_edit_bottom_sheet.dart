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
  ConsumerState<BookmarkEditBottomSheet> createState() => _BookmarkEditBottomSheetState();
}

class _BookmarkEditBottomSheetState extends ConsumerState<BookmarkEditBottomSheet> {
  late TextEditingController _urlController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagController;
  Timer? _debounceTimer;
  List<String> _tags = [];
  bool _isFavorite = false;
  String? _folder;
  bool _isLoading = false;
  bool _isUrlChanged = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.bookmark.url);
    _titleController = TextEditingController(text: widget.bookmark.title);
    _descriptionController = TextEditingController(text: widget.bookmark.description);
    _tagController = TextEditingController();
    _tags = widget.bookmark.tags ?? [];
    _isFavorite = widget.bookmark.isFavorite;
    _folder = widget.bookmark.folder;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookmarkProvider.notifier).state = widget.bookmark;
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _urlController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkState = ref.watch(bookmarkProvider);

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
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPreviewImage(bookmarkState?.metadata?.image),
                    SizedBox(height: 16),
                    _buildUrlField(),
                    SizedBox(height: 16),
                    _buildTitleField(),
                    SizedBox(height: 16),
                    _buildDescriptionField(),
                    SizedBox(height: 24),
                    _buildTagsSection(),
                    SizedBox(height: 24),
                    _buildFolderSelection(),
                    SizedBox(height: 16),
                    _buildFavoriteToggle(),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '북마크 수정',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewImage(String? imageUrl) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : (imageUrl != null
          ? ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        ),
      )
          : Center(
        child: Icon(Icons.image, size: 48, color: Colors.grey),
      )
      ),
    );
  }

  Widget _buildUrlField() {
    return TextFormField(
      controller: _urlController,
      decoration: InputDecoration(
        labelText: 'URL',
        prefixIcon: Icon(Icons.link),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: (value) {
        _isUrlChanged = true;
        _onUrlChanged(value);
      },
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: '제목',
        prefixIcon: Icon(Icons.title),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: (value) {
        ref.read(bookmarkProvider.notifier).state = ref
            .read(bookmarkProvider.notifier)
            .state
            ?.copyWith(customTitle: value);
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: '설명',
        prefixIcon: Icon(Icons.description),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      maxLines: 3,
      onChanged: (value) {
        ref.read(bookmarkProvider.notifier).state = ref
            .read(bookmarkProvider.notifier)
            .state
            ?.copyWith(customDescription: value);
      },
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("태그", style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tags.map((tag) => Chip(
            label: Text(tag),
            deleteIcon: Icon(Icons.close, size: 16),
            onDeleted: () {
              setState(() {
                _tags.remove(tag);
              });
              _updateTags();
            },
          )).toList(),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: '태그 추가',
                  prefixIcon: Icon(Icons.tag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onFieldSubmitted: _addTag,
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _addTag(_tagController.text),
              child: Icon(Icons.add),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.all(16),
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFolderSelection() {
    const List<String> folders = ["Work", "Personal", "Shopping", "Reading", "Recipes"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("폴더", style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(Icons.folder),
          ),
          value: _folder,
          hint: Text("폴더 선택 (선택사항)"),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text("폴더 없음"),
            ),
            ...folders.map((folder) => DropdownMenuItem(
              value: folder,
              child: Text(folder),
            )).toList(),
          ],
          onChanged: (value) {
            setState(() {
              _folder = value;
            });
            ref.read(bookmarkProvider.notifier).state = ref
                .read(bookmarkProvider.notifier)
                .state
                ?.copyWith(folder: value);
          },
        ),
      ],
    );
  }

  Widget _buildFavoriteToggle() {
    return SwitchListTile(
      title: Text("즐겨찾기"),
      secondary: Icon(
        _isFavorite ? Icons.star : Icons.star_border,
        color: _isFavorite ? Colors.amber : null,
      ),
      value: _isFavorite,
      onChanged: (value) {
        setState(() {
          _isFavorite = value;
        });
        ref.read(bookmarkProvider.notifier).state = ref
            .read(bookmarkProvider.notifier)
            .state
            ?.copyWith(isFavorite: value);
      },
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                // 북마크 삭제 확인 대화상자
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("북마크 삭제"),
                    content: Text("이 북마크를 삭제하시겠습니까?"),
                    actions: [
                      TextButton(
                        child: Text("취소"),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      TextButton(
                        child: Text("삭제", style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          ref.read(urlBookmarkProvider.notifier)
                              .deleteUrlBookmark(widget.bookmark.id);
                          Navigator.of(context).pop(); // 대화상자 닫기
                          Navigator.of(context).pop(); // 바텀시트 닫기
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("북마크가 삭제되었습니다")),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text("삭제", style: TextStyle(color: Colors.red)),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text("저장", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
      _updateTags();
    }
  }

  void _updateTags() {
    ref.read(bookmarkProvider.notifier).state = ref
        .read(bookmarkProvider.notifier)
        .state
        ?.copyWith(tags: _tags);
  }

  void _onUrlChanged(String url) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: 800),
          () async {
        if (url.isNotEmpty) {
          setState(() {
            _isLoading = true;
          });

          try {
            final metadata = await url.fetchUrlMetadata();
            if (mounted) {
              setState(() {
                _isLoading = false;
              });

              ref.read(bookmarkProvider.notifier).state = ref
                  .read(bookmarkProvider.notifier)
                  .state
                  ?.copyWithMetadata(metadata: metadata);
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("URL 정보를 가져오는데 실패했습니다")),
              );
            }
          }
        }
      },
    );
  }

  void _saveChanges() async {
    // 현재 상태의 북마크 가져오기
    final updatedBookmark = ref.read(bookmarkProvider.notifier).state;

    if (updatedBookmark != null) {
      // URL이 변경된 경우 최종 상태 업데이트
      if (_isUrlChanged) {
        updatedBookmark.copyWith(url: _urlController.text.trim());
      }

      // 북마크 업데이트
      await ref.read(urlBookmarkProvider.notifier)
          .updateUrlBookmark(widget.bookmark.id, updatedBookmark);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("북마크가 업데이트되었습니다")),
        );
      }
    }
  }
}