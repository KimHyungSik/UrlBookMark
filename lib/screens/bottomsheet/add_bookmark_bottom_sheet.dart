import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../bookmark_manager.dart';
import '../../common/tags.dart';
import '../../model/url_marker.dart';
import '../../model/url_metadata.dart';
import '../../widget/custom_dialog.dart';

// URL 메타데이터 Provider - 고유 ID를 사용하여 매번 리셋되도록 함
final urlMetadataProvider = StateNotifierProvider.autoDispose<UrlMetadataNotifier, AsyncValue<UrlMetadata?>>((ref) {
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

// 바텀시트가 열릴 때마다 새로운 인스턴스를 생성하도록 함수 추가
void showAddBookmarkSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddBookmarkBottomSheet(key: UniqueKey()),
  );
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
  late final TextEditingController _urlController;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagController;
  late final FocusNode _urlFocusNode;
  final ScrollController _scrollController = ScrollController();

  Timer? _debounceTimer;
  List<String> _tags = [];
  bool _isFavorite = false;
  bool _isProcessing = false;
  bool _showAdditionalFields = false;

  @override
  void initState() {
    super.initState();

    // 모든 컨트롤러를 초기화
    _urlController = TextEditingController();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _tagController = TextEditingController();
    _urlFocusNode = FocusNode();

    // 변수 초기화
    _tags = [];
    _isFavorite = false;
    _isProcessing = false;
    _showAdditionalFields = false;

    // 포커스 변경 리스너 추가 - 텍스트 필드에 포커스가 갈 때 스크롤 조정
    _urlFocusNode.addListener(_scrollToFocusedField);

    // 포커스를 URL 필드에 주기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _urlFocusNode.requestFocus();
    });
  }

  // 포커스된 필드로 스크롤하는 함수
  void _scrollToFocusedField() {
    if (_urlFocusNode.hasFocus && _scrollController.hasClients) {
      // URL 필드가 포커스를 받으면 스크롤을 조정
      _scrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    // 디바운스 타이머 해제
    _debounceTimer?.cancel();

    // 컨트롤러 해제
    _urlController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    _urlFocusNode.removeListener(_scrollToFocusedField);
    _urlFocusNode.dispose();
    _scrollController.dispose();

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
        await ref
            .read(urlBookmarkProvider.notifier)
            .addUrlBookmark(newBookmark);

        if (mounted) {
          Navigator.of(context).pop(); // 바텀시트 닫기
          // 추가 성공 알림 표시
          showCustomAlertDialog(
            context: context,
            title: 'dialog.update_success'.tr(),
            message: 'dialog.bookmark_updated'.tr(),
            buttonText: 'actions.confirm'.tr(),
            icon: Icons.check_circle,
            iconColor: Colors.green,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          // 오류 발생 알림
          showCustomAlertDialog(
            context: context,
            title: 'dialog.error'.tr(),
            message: 'dialog.update_error'.tr(),
            buttonText: 'actions.confirm'.tr(),
            icon: Icons.error_outline,
            iconColor: Colors.red,
          );
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
    final trimmedTag = tag.trim();
    if (trimmedTag.isNotEmpty && !_tags.contains(trimmedTag)) {
      setState(() {
        _tags.add(trimmedTag);
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

  @override
  Widget build(BuildContext context) {
    final metadataState = ref.watch(urlMetadataProvider);
    final hasMetadata = metadataState.value != null;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.85; // 화면 높이의 85%로 제한

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: IntrinsicHeight(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
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
            'bookmarks.add_title'.tr(),
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
      focusNode: _urlFocusNode,
      decoration: InputDecoration(
        labelText: 'form.url'.tr(),
        hintText: 'form.url_hint'.tr(),
        prefixIcon: Icon(Icons.link),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: _urlController.text.isNotEmpty
            ? IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            _urlController.clear();
            ref.read(urlMetadataProvider.notifier).reset();
            setState(() {
              _showAdditionalFields = false;
            });
          },
        )
            : null,
      ),
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.next,
      onChanged: _onUrlChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'error.enter_url'.tr();
        }

        // 간단한 URL 검증
        String url = value;
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          url = 'https://$url';
        }

        try {
          final uri = Uri.parse(url);
          if (!uri.isAbsolute || !uri.host.contains('.')) {
            return 'error.invalid_url'.tr();
          }
        } catch (e) {
          return 'error.url_format'.tr();
        }

        return null;
      },
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'form.title_optional'.tr(),
        hintText: 'form.title_hint'.tr(),
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
        labelText: 'form.description_optional'.tr(),
        hintText: 'form.description_hint'.tr(),
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
        Text('form.tags'.tr(), style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _tags
              .map((tag) => Chip(
            label: Text(tag),
            deleteIcon: Icon(Icons.close, size: 18),
            onDeleted: () => _removeTag(tag),
            backgroundColor: Colors.grey[200],
          ))
              .toList(),
        ),
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
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isFavorite
              ? [Color(0xFFFFF8E1), Color(0xFFFFECB3)]
              : [Colors.white, Colors.grey.shade50],
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
            },
            splashColor: _isFavorite ? Colors.amber.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
            highlightColor: _isFavorite ? Colors.amber.withOpacity(0.2) : Colors.transparent,
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
                      color: _isFavorite ? Colors.amber.withOpacity(0.2) : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Icon(
                        _isFavorite ? Icons.star : Icons.star_border,
                        key: ValueKey<bool>(_isFavorite),
                        color: _isFavorite ? Colors.amber : Colors.grey.shade600,
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
                          'favorite.add'.tr(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isFavorite ? Colors.amber.shade800 : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _isFavorite
                              ? 'favorite.description'.tr()
                              : 'favorite.add_description'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: _isFavorite ? Colors.amber.shade600 : Colors.grey.shade600,
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

  Widget _buildAddButton() {
    final metadataState = ref.watch(urlMetadataProvider);
    final isUrlEmpty = _urlController.text.trim().isEmpty;
    final isMetadataLoading = metadataState.isLoading;

    // 버튼이 비활성화 되어야 하는 조건
    final isButtonDisabled = _isProcessing || isUrlEmpty || isMetadataLoading;

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
        onPressed: isButtonDisabled ? null : _addBookmark,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: Colors.grey,
        ),
        child: _isProcessing
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('actions.processing'.tr(), style: TextStyle(fontSize: 16)),
          ],
        )
            : isMetadataLoading
            ? Text('loading.url_info'.tr(), style: TextStyle(fontSize: 16))
            : Text('bookmarks.add_title'.tr(), style: TextStyle(fontSize: 16)),
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

        if (_descriptionController.text.isEmpty &&
            metadata.description != null) {
          _descriptionController.text = metadata.description!;
        }

        return Card(
          margin: EdgeInsets.symmetric(vertical: 10),
          elevation: 3,
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
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        metadata.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: Icon(Icons.broken_image,
                              color: Colors.grey, size: 48),
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 12),
                Text(
                  metadata.title ?? 'form.no_title'.tr(),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (metadata.description != null &&
                    metadata.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      metadata.description!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (metadata.favicon != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: Image.network(
                            metadata.favicon!,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.link,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _urlController.text,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'loading.website_info'.tr(),
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            Text(
              'loading.please_wait'.tr(),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
      error: (error, stack) => Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              'error.url_fetch'.tr(),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'error.basic_info'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 12),
            TextButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('actions.try_again'.tr()),
              onPressed: () {
                if (_urlController.text.isNotEmpty) {
                  final preparedUrl = _prepareUrl(_urlController.text.trim());
                  ref.read(urlMetadataProvider.notifier).fetchMetadata(preparedUrl);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}