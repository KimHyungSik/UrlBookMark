import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../bookmark_manager.dart';
import '../../common/tags.dart';
import '../../model/url_marker.dart';
import '../../model/url_metadata.dart';
import '../web_search_screen.dart';

// URL 메타데이터 Provider
final urlMetadataProvider =
StateNotifierProvider<UrlMetadataNotifier, AsyncValue<UrlMetadata?>>((ref) {
  return UrlMetadataNotifier();
});

// URL 메타데이터 상태 관리
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
  bool _isFavorite = false;
  bool _isProcessing = false;
  bool _showAdditionalFields = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _urlController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  /// 북마크 추가 처리
  Future<void> _addBookmark() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final String url = _prepareUrl(_urlController.text.trim());
        final metadata = ref.read(urlMetadataProvider).value;

        // 제목과 설명 값 처리
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
          isFavorite: _isFavorite,
          metadata: metadata,
        );

        // Provider를 통해 북마크 추가
        await ref.read(urlBookmarkProvider.notifier).addUrlBookmark(newBookmark);
        ref.read(urlMetadataProvider.notifier).reset(); // 상태 초기화

        if (mounted) {
          Navigator.of(context).pop(); // 바텀시트 닫기
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("북마크가 추가되었습니다")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("북마크 추가 실패: ${e.toString()}")),
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

  /// URL 입력 처리 (디바운싱 적용)
  void _onUrlChanged(String url) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (url.isNotEmpty) {
        final preparedUrl = _prepareUrl(url.trim());
        ref.read(urlMetadataProvider.notifier).fetchMetadata(preparedUrl);

        // 자동 태그 생성
        final autoTags = generateTags(preparedUrl);
        if (autoTags.isNotEmpty && _tags.isEmpty) {
          setState(() {
            _tags = autoTags;
          });
        }

        // 추가 필드 표시
        if (!_showAdditionalFields) {
          setState(() {
            _showAdditionalFields = true;
          });
        }
      }
    });
  }

  /// 태그 추가
  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  /// 태그 제거
  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  /// WebView 검색 화면 열기
  void _openWebSearchScreen() {
    Navigator.of(context).pop(); // 현재 바텀시트 닫기

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => WebSearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metadataState = ref.watch(urlMetadataProvider);
    final hasMetadata = metadataState.value != null;

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
                      // 메타데이터 프리뷰는 데이터가 있거나 로딩 중일 때만 표시
                      if (metadataState.isLoading || hasMetadata)
                        _buildMetadataPreview(metadataState),

                      SizedBox(height: 16),
                      _buildUrlField(),

                      // 추가 필드는 URL이 입력되었거나 메타데이터가 있을 때만 표시
                      if (_showAdditionalFields || hasMetadata) ...[
                        SizedBox(height: 16),
                        _buildTitleField(),
                        SizedBox(height: 16),
                        _buildDescriptionField(),
                        SizedBox(height: 16),
                        _buildTagsSection(),
                        SizedBox(height: 16),
                        _buildFavoriteToggle(),
                      ],

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
            '북마크 추가',
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
          return "URL을 입력해주세요";
        }
        // 간단한 URL 검증
        if (!value.contains('.')) {
          return "유효한 URL을 입력해주세요";
        }
        return null;
      },
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: '제목 (선택사항)',
        hintText: '북마크의 제목을 입력하세요',
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
        labelText: '설명 (선택사항)',
        hintText: '북마크에 대한 설명을 추가하세요',
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
        Text("태그", style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildFavoriteToggle() {
    return SwitchListTile(
      title: Text("즐겨찾기에 추가"),
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
            : Text("북마크 추가", style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildMetadataPreview(AsyncValue<UrlMetadata?> metadataState) {
    return metadataState.when(
      data: (metadata) {
        if (metadata == null) return SizedBox.shrink();

        // 제목과 설명이 비어있으면 메타데이터로 자동 채우기
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
                  metadata.title ?? "제목 없음",
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
              Text("웹사이트 정보를 가져오는 중..."),
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
                "웹사이트 정보를 가져오지 못했습니다",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "기본 정보만으로 북마크가 저장됩니다.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}