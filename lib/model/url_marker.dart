import 'package:url_book_marker/model/url_metadata.dart';
import 'package:uuid/uuid.dart';

class UrlBookmark {
  final String id; // 고유 ID
  final String url; // URL
  final String? customTitle; // 제목
  final String? customDescription; // 설명 (optional)
  final DateTime createdAt; // 생성 날짜
  final String? folder; // 폴더 (optional)
  final List<String>? tags; // 태그 리스트 (optional)
  final String? iconPath; // 아이콘 경로 (optional)
  final bool isFavorite; // 즐겨찾기 여부 (optional)
  final UrlMetadata? metadata;

  String get title => customTitle ?? metadata?.title ?? url;

  String get description => customDescription ?? metadata?.description ?? '';

  UrlBookmark(
      {String? id,
      required this.url,
      this.customTitle,
      this.customDescription,
      DateTime? createdAt,
      this.folder,
      this.tags,
      this.iconPath,
      this.isFavorite = false,
      this.metadata})
      : id = id ?? const Uuid().v4(),
        // UUID 생성
        createdAt = createdAt ?? DateTime.now(); // 생성 날짜 기본값

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': customTitle,
      'description': customDescription,
      'createdAt': createdAt.toIso8601String(),
      'folder': folder,
      'tags': tags,
      'iconPath': iconPath,
      'isFavorite': isFavorite,
      'metadata': metadata?.toJson(),
    };
  }

  // JSON 역직렬화
  factory UrlBookmark.fromJson(Map<String, dynamic> json) {
    return UrlBookmark(
      id: json['id'],
      url: json['url'],
      customTitle: json['title'],
      customDescription: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      folder: json['folder'],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      iconPath: json['iconPath'],
      isFavorite: json['isFavorite'] ?? false,
      metadata: json['metadata'] != null
          ? UrlMetadata.fromJson(json['metadata'])
          : null,
    );
  }

  @override
  String toString() {
    return 'Bookmark('
        'id: $id, '
        'url: $url, '
        'title: $customTitle, '
        'description: ${customDescription ?? "N/A"}, '
        'createdAt: $createdAt, '
        'folder: ${folder ?? "N/A"}, '
        'tags: ${tags?.join(", ") ?? "N/A"}, '
        'iconPath: ${iconPath ?? "N/A"}, '
        'isFavorite: $isFavorite,'
        'metadata: ${metadata?.toString()},'
        ')';
  }

  UrlBookmark copyWith({
    String? id,
    String? url,
    String? title,
    String? description,
    DateTime? createdAt,
    String? folder,
    List<String>? tags,
    String? iconPath,
    bool? isFavorite,
    UrlMetadata? metadata,
  }) {
    return UrlBookmark(
      id: id ?? this.id,
      url: url ?? this.url,
      customTitle: title ?? this.customTitle,
      customDescription: description ?? this.customDescription,
      createdAt: createdAt ?? this.createdAt,
      folder: folder ?? this.folder,
      tags: tags ?? this.tags,
      iconPath: iconPath ?? this.iconPath,
      isFavorite: isFavorite ?? this.isFavorite,
      metadata: metadata ?? this.metadata,
    );
  }

  UrlBookmark copyWithMetadata({
    UrlMetadata? metadata,
  }) {
    return UrlBookmark(
      id: id,
      url: url,
      customTitle: customTitle,
      customDescription: customDescription,
      createdAt: createdAt,
      folder: folder,
      tags: tags,
      iconPath: iconPath,
      isFavorite: isFavorite,
      metadata: metadata,
    );
  }
}
