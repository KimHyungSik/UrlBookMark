import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:ogp_data_extract/ogp_data_extract.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';

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

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'title': title,
      'description': description,
    };
  }

  // JSON 역직렬화
  factory UrlMetadata.fromJson(Map<String, dynamic> json) {
    return UrlMetadata(
      image: json['image'],
      title: json['title'],
      description: json['description'],
    );
  }
}

extension UrlMetadataFetcher on String {
  Future<UrlMetadata?> fetchUrlMetadata() async {
    try {
      // 1. HTTP GET 요청 보내기
      final response = await http.get(Uri.parse(this));

      print("LOGEE response $response");

      if (response.statusCode != 200) {
        print('Failed to fetch metadata: ${response.statusCode}');
        return null;
      }

      // 2. HTML 파싱
      final document = parse(utf8.decode(response.bodyBytes));
      print("LOGEE document $document");

      // 3. OGP 메타데이터 추출
      final String? title = document
              .querySelector("meta[property='og:title']")
              ?.attributes['content'] ??
          document.querySelector('title')?.text;

      final String? description = document
              .querySelector("meta[property='og:description']")
              ?.attributes['content'] ??
          document
              .querySelector("meta[name='description']")
              ?.attributes['content'];

      final String? image = document
          .querySelector("meta[property='og:image']")
          ?.attributes['content'];

      // 4. UrlMetadata 객체로 반환
      print("LOGEE $title $description $image");
      return UrlMetadata(
        title: title,
        description: description,
        image: image,
      );
    } catch (e) {
      print('LOGEE Error fetching metadata: $e');
      return null;
    }
  }
}
