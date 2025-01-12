import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;

class UrlMetadata {
  final String? image; // 이미지 URL
  final String? title; // 페이지 제목
  final String? description; // 페이지 설명

  UrlMetadata({
    this.image,
    this.title,
    this.description,
  });

  @override
  String toString() {
    return 'UrlMetadata(image: $image, title: $title, description: $description)';
  }
}

extension UrlMetadataFetcher on String {
  Future<UrlMetadata> fetchMetadata() async {
    try {
      // URL 요청
      final response = await http.get(Uri.parse(this));

      // 상태 코드 확인
      if (response.statusCode != 200) {
        throw Exception('Failed to load URL metadata');
      }

      // HTML 파싱
      final document = html.parse(response.body);

      // 메타데이터 추출
      final String? image = _extractMetaContent(document, ['og:image', 'twitter:image']);
      final String? title = _extractMetaContent(document, ['og:title', 'twitter:title']) ?? document.querySelector('title')?.text;
      final String? description = _extractMetaContent(document, ['og:description', 'twitter:description']) ??
          document.querySelector('meta[name="description"]')?.attributes['content'];

      return UrlMetadata(
        image: image,
        title: title,
        description: description,
      );
    } catch (e) {
      // 실패 시 빈 UrlMetadata 반환
      return UrlMetadata();
    }
  }

  // 내부 메서드: HTML에서 메타 태그 내용 추출
  String? _extractMetaContent(dynamic document, List<String> metaNames) {
    for (final name in metaNames) {
      final metaTag = document.querySelector('meta[property="$name"], meta[name="$name"]');
      if (metaTag != null) {
        return metaTag.attributes['content'];
      }
    }
    return null;
  }
}