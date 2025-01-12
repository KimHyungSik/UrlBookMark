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
}
