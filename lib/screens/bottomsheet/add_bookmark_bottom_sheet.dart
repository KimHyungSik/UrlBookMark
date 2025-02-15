import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // 고유 ID 생성을 위한 패키지
import '../../bookmark_manager.dart';
import '../../common/tags.dart';
import '../../model/url_marker.dart';
import '../../model/url_metadata.dart';

// 🔹 URL 메타데이터를 가져오는 Provider
final urlMetadataProvider =
    StateNotifierProvider<UrlMetadataNotifier, AsyncValue<UrlMetadata?>>((ref) {
  return UrlMetadataNotifier();
});

// 🔹 URL 메타데이터 상태 관리
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
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _urlController.dispose();
    super.dispose();
  }

  /// 북마크 추가
  void _addBookmark() {
    if (_formKey.currentState!.validate()) {
      final url = _urlController.text.trim();
      final metadata = ref.read(urlMetadataProvider).value;
      final newBookmark = UrlBookmark(
        id: const Uuid().v4(),
        url: url,
        tags: generateTags(url),
        metadata: metadata,
      );

      // Provider를 통해 북마크 추가
      ref.read(urlBookmarkProvider.notifier).addUrlBookmark(newBookmark);
      ref.read(urlMetadataProvider.notifier).reset(); // 상태 초기화
      Navigator.of(context).pop(); // 바텀시트 닫기
    }
  }

  /// 입력 후 1초 동안 추가 입력이 없으면 자동으로 미리보기 로드
  void _onUrlChanged(String url) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      ref.read(urlMetadataProvider.notifier).fetchMetadata(url.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final metadataState = ref.watch(urlMetadataProvider);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: IntrinsicHeight(
          // 내용에 따라 자동 조정
          child: Column(
            mainAxisSize: MainAxisSize.min, // 내용에 따라 크기 조절
            children: [
              Expanded(
                child: SingleChildScrollView(
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
                        const Text(
                          'Add Bookmark',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16.0),
                        if (metadataState.isLoading)
                          Center(child: CircularProgressIndicator()),

                        _buildMetadataPreview(metadataState), // 미리보기 위젯

                        if (_urlController.text.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            children: generateTags(_urlController.text.trim())
                                .map((tag) => Chip(label: Text(tag)))
                                .toList(),
                          ),
                        const SizedBox(height: 16.0),
                      ],
                    ),
                  ),
                ),
              ),
              _buildUrlInputField(), // URL 입력 폼을 최하단에 배치
              _buildAddButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrlInputField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextFormField(
        controller: _urlController,
        decoration: InputDecoration(labelText: 'URL'),
        validator: (value) {
          if (value == null || value.isEmpty) return "URL을 입력하세요.";
          return null;
        },
        onChanged: _onUrlChanged, // 입력 시 debounce 적용
      ),
    );
  }

  SafeArea _buildAddButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ElevatedButton(
          onPressed: _addBookmark,
          child: const Text('Add Bookmark'),
        ),
      ),
    );
  }

  Widget _buildMetadataPreview(AsyncValue<UrlMetadata?> metadataState) {
    return metadataState.when(
      data: (metadata) {
        if (metadata == null) return SizedBox.shrink();
        return Card(
          margin: EdgeInsets.symmetric(vertical: 10),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Padding(
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
          ),
        );
      },
      loading: () => SizedBox.shrink(),
      error: (error, _) => SizedBox.shrink(),
    );
  }
}
