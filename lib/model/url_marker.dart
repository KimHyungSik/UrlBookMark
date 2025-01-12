import 'package:uuid/uuid.dart';

class UrlBookmark {
  final String id; // 고유 ID
  final String url; // URL
  final String title; // 제목
  final String? description; // 설명 (optional)
  final DateTime createdAt; // 생성 날짜
  final String? folder; // 폴더 (optional)
  final List<String>? tags; // 태그 리스트 (optional)
  final String? iconPath; // 아이콘 경로 (optional)
  final bool isFavorite; // 즐겨찾기 여부 (optional)

  UrlBookmark({
    String? id,
    required this.url,
    required this.title,
    this.description,
    DateTime? createdAt,
    this.folder,
    this.tags,
    this.iconPath,
    this.isFavorite = false,
  })  : id = id ?? const Uuid().v4(), // UUID 생성
        createdAt = createdAt ?? DateTime.now(); // 생성 날짜 기본값

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'folder': folder,
      'tags': tags,
      'iconPath': iconPath,
      'isFavorite': isFavorite,
    };
  }

  // JSON 역직렬화
  factory UrlBookmark.fromJson(Map<String, dynamic> json) {
    return UrlBookmark(
      id: json['id'],
      url: json['url'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      folder: json['folder'],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      iconPath: json['iconPath'],
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}
