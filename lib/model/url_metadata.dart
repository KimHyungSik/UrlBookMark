import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:ogp_data_extract/ogp_data_extract.dart';

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
  Future<UrlMetadata?> fetchMetadata() async {
    try {
      final OgpData? ogpData = await OgpDataExtract.execute(this);
      print("LOGEE ogpData $ogpData");
      return UrlMetadata(
          title: ogpData?.title,
          image: ogpData?.image,
          description: ogpData?.description);
    } catch (e) {
      return null;
    }
  }
}
