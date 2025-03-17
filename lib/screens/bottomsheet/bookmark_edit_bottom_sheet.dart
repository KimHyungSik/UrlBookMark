import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_book_marker/bookmark_manager.dart';

import '../../model/url_marker.dart';
import '../../model/url_metadata.dart';
import '../../widget/custom_dialog.dart';

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
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagController;
  Timer? _debounceTimer;
  List<String> _tags = [];
  bool _isFavorite = false;
  bool _isLoading = false;
  bool _isUrlChanged = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.bookmark.url);
    _titleController = TextEditingController(text: widget.bookmark.title);
    _descriptionController =
        TextEditingController(text: widget.bookmark.description);
    _tagController = TextEditingController();
    _tags = widget.bookmark.tags ?? [];
    _isFavorite = widget.bookmark.isFavorite;

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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.8; // 화면 높이의 80%로 제한
    final bookmarkState = ref.watch(bookmarkProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16),
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
                    SizedBox(height: 16),
                    _buildTagsSection(),
                    SizedBox(height: 16),
                    _buildFavoriteToggle(),
                    SizedBox(height: 24),
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
            'bookmarks.edit_title'.tr(),
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
      height: 160, // 이미지 높이 축소
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
                      child: Icon(Icons.broken_image,
                          size: 48, color: Colors.grey),
                    ),
                  ),
                )
              : Center(
                  child: Icon(Icons.image, size: 48, color: Colors.grey),
                )),
    );
  }

  Widget _buildUrlField() {
    return TextFormField(
      controller: _urlController,
      decoration: InputDecoration(
        labelText: 'form.url'.tr(),
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
        labelText: 'form.title'.tr(),
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
        labelText: 'form.title'.tr(),
        prefixIcon: Icon(Icons.description),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      maxLines: 2,
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
        Text('form.tags'.tr(), style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tags
              .map((tag) => Chip(
                    label: Text(tag),
                    deleteIcon: Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        _tags.remove(tag);
                      });
                      _updateTags();
                    },
                  ))
              .toList(),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: 'form.add_tag'.tr(),
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
              onPressed: () => _addTag(_tagController.text),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFavoriteToggle() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isFavorite
              ? [Color(0xFFFFF8E1), Color(0xFFFFECB3)] // 즐겨찾기 활성화 시 따뜻한 그라데이션
              : [Colors.white, Colors.grey.shade50], // 비활성화 시 기본 그라데이션
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _isFavorite
                ? Colors.amber.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
              // 리버팟 상태 업데이트 (필요한 경우)
              ref.read(bookmarkProvider.notifier).state = ref
                  .read(bookmarkProvider.notifier)
                  .state
                  ?.copyWith(isFavorite: _isFavorite);
            },
            splashColor: _isFavorite
                ? Colors.amber.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            highlightColor: _isFavorite
                ? Colors.amber.withOpacity(0.2)
                : Colors.transparent,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // 아이콘 부분
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isFavorite
                          ? Colors.amber.withOpacity(0.2)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Icon(
                        _isFavorite ? Icons.star : Icons.star_border,
                        key: ValueKey<bool>(_isFavorite),
                        color:
                            _isFavorite ? Colors.amber : Colors.grey.shade600,
                        size: 28,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),

                  // 텍스트 부분
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'favorite.title'.tr(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isFavorite
                                ? Colors.amber.shade800
                                : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _isFavorite
                              ? 'favorite.description'.tr()
                              : 'favorite.add_description'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: _isFavorite
                                ? Colors.amber.shade600
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 스위치 부분
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _isFavorite,
                      activeColor: Colors.amber,
                      activeTrackColor: Colors.amber.shade200,
                      inactiveThumbColor: Colors.grey.shade400,
                      inactiveTrackColor: Colors.grey.shade300,
                      onChanged: (value) {
                        setState(() {
                          _isFavorite = value;
                        });
                        // 리버팟 상태 업데이트 (필요한 경우)
                        ref.read(bookmarkProvider.notifier).state = ref
                            .read(bookmarkProvider.notifier)
                            .state
                            ?.copyWith(isFavorite: value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
              onPressed: _isSaving
                  ? null
                  : () {
                      _showDeleteConfirmation();
                    },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('actions.delete'.tr(),
                  style: TextStyle(color: Colors.red)),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('actions.save'.tr(),
                      style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _addTag(String tag) {
    tag = tag.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
      _updateTags();
    }
  }

  void _updateTags() {
    ref.read(bookmarkProvider.notifier).state =
        ref.read(bookmarkProvider.notifier).state?.copyWith(tags: _tags);
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
                SnackBar(content: Text('error.fetch_failed'.tr())),
              );
            }
          }
        }
      },
    );
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // 현재 상태의 북마크 가져오기
      final updatedBookmark = ref.read(bookmarkProvider.notifier).state;

      if (updatedBookmark != null) {
        // URL이 변경된 경우 최종 상태 업데이트
        if (_isUrlChanged) {
          updatedBookmark.copyWith(url: _urlController.text.trim());
        }

        // 북마크 업데이트
        await ref
            .read(urlBookmarkProvider.notifier)
            .updateUrlBookmark(widget.bookmark.id, updatedBookmark);

        if (mounted) {
          Navigator.pop(context);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showDeleteConfirmation() {
    showCustomConfirmDialog(
      context: context,
      title: 'dialog.delete_title'.tr(),
      message: 'dialog.delete_message'.tr(),
      cancelText: 'actions.cancel'.tr(),
      confirmText: 'actions.delete'.tr(),
      isDestructive: true,
      icon: Icons.delete_forever,
    ).then(
      (confirmed) async {
        if (confirmed == true) {
          // 북마크 삭제
          await ref
              .read(urlBookmarkProvider.notifier)
              .deleteUrlBookmark(widget.bookmark.id);

          if (mounted) {
            Navigator.of(context).pop(); // 바텀시트 닫기
          }
        }
      },
    );
  }
}
