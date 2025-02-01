import 'dart:convert';

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
      final response = await http.get(
        Uri.parse(
          this,
        ),
        headers: {
          'user-agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3',
          'accept': 'gzip, deflate, br',
          'accept-language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
        },
      );

      if (response.statusCode != 200) {
        print('Failed to fetch metadata: ${response.statusCode}');
        return null;
      }

      // 2. HTML 파싱
      final document = parse(utf8.decode(response.bodyBytes));

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
      return UrlMetadata(
        title: title,
        description: description,
        image: image,
      );
    } catch (e) {
      return null;
    }
  }
}
