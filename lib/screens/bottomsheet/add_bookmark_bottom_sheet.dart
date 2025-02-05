import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // 고유 ID 생성을 위한 패키지
import '../../bookmark_manager.dart';
import '../../model/url_marker.dart';
import '../../model/url_metadata.dart';

// 🔹 URL 메타데이터를 가져오는 Provider
final urlMetadataProvider = StateNotifierProvider<UrlMetadataNotifier, AsyncValue<UrlMetadata?>>((ref) {
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
  ConsumerState<AddBookmarkBottomSheet> createState() => _AddBookmarkBottomSheetState();
}

class _AddBookmarkBottomSheetState extends ConsumerState<AddBookmarkBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  /// 사이트 유형에 따라 자동 태그 추가
  List<String> _generateTags(String url) {
    List<String> tags = [];

    if (url.contains("youtube.com") || url.contains("youtu.be")) {
      tags.add("YouTube");
      tags.add("Video");
    } else if (url.contains("instagram.com")) {
      tags.add("Instagram");
      tags.add("Social Media");
    } else if (url.contains("twitter.com") || url.contains("x.com")) {
      tags.add("Twitter");
      tags.add("Social Media");
    } else if (url.contains("github.com")) {
      tags.add("GitHub");
      tags.add("Development");
    }

    return tags;
  }

  /// 북마크 추가
  void _addBookmark() {
    if (_formKey.currentState!.validate()) {
      final url = _urlController.text.trim();
      final metadata = ref.read(urlMetadataProvider).value;
      final newBookmark = UrlBookmark(
        id: const Uuid().v4(),
        url: url,
        tags: _generateTags(url),
        metadata: metadata,
      );

      // Provider를 통해 북마크 추가
      ref.read(urlBookmarkProvider.notifier).addUrlBookmark(newBookmark);
      ref.read(urlMetadataProvider.notifier).reset(); // 상태 초기화
      Navigator.of(context).pop(); // 바텀시트 닫기
    }
  }

  @override
  Widget build(BuildContext context) {
    final metadataState = ref.watch(urlMetadataProvider);

    return SingleChildScrollView(
      child: Padding(
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'URL',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () => ref
                        .read(urlMetadataProvider.notifier)
                        .fetchMetadata(_urlController.text.trim()),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "URL을 입력하세요.";
                  return null;
                },
                onEditingComplete: () => ref
                    .read(urlMetadataProvider.notifier)
                    .fetchMetadata(_urlController.text.trim()),
              ),
              const SizedBox(height: 16.0),

              // 🔹 로딩 상태
              if (metadataState.isLoading)
                Center(child: CircularProgressIndicator()),

              // 🔹 메타데이터 프리뷰
              metadataState.when(
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
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
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
                error: (error, _) => Text("메타데이터 로딩 실패: $error"),
              ),

              // 🔹 자동 태그
              if (_urlController.text.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: _generateTags(_urlController.text.trim()).map((tag) {
                    return Chip(label: Text(tag));
                  }).toList(),
                ),

              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _addBookmark,
                child: const Text('Add Bookmark'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
