import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart';

class UrlMetadata {
  final String? image;
  final String? title;
  final String? description;
  final String? favicon;

  UrlMetadata({
    this.image,
    this.title,
    this.description,
    this.favicon,
  });

  @override
  String toString() {
    return 'UrlMetadata(image: $image, title: $title, description: $description, favicon: $favicon)';
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'title': title,
      'description': description,
      'favicon': favicon,
    };
  }

  // JSON deserialization
  factory UrlMetadata.fromJson(Map<String, dynamic> json) {
    return UrlMetadata(
      image: json['image'],
      title: json['title'],
      description: json['description'],
      favicon: json['favicon'],
    );
  }

  UrlMetadata copyWith({
    String? image,
    String? title,
    String? description,
    String? favicon,
  }) {
    return UrlMetadata(
      image: image ?? this.image,
      title: title ?? this.title,
      description: description ?? this.description,
      favicon: favicon ?? this.favicon,
    );
  }
}

extension UrlMetadataFetcher on String {
  Future<UrlMetadata?> fetchUrlMetadata({int retries = 2}) async {
    String url = this;

    // Add https:// if missing
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        // HTTP GET request with timeout
        final response = await http.get(
          Uri.parse(url),
          headers: {'User-Agent': 'FlutterUrlBookmarker/1.0'},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) {
          print('Failed to fetch metadata: ${response.statusCode}');
          if (attempt < retries) continue;
          return null;
        }

        // Parse HTML
        final document = parse(utf8.decode(response.bodyBytes));

        // Extract metadata
        String? title = document.querySelector("meta[property='og:title']")?.attributes['content'] ??
            document.querySelector('title')?.text;

        String? description = document.querySelector("meta[property='og:description']")?.attributes['content'] ??
            document.querySelector("meta[name='description']")?.attributes['content'];

        String? image = document.querySelector("meta[property='og:image']")?.attributes['content'];

        // Extract favicon
        String? favicon;
        final faviconLink = document.querySelector("link[rel='icon']") ??
            document.querySelector("link[rel='shortcut icon']");
        if (faviconLink != null && faviconLink.attributes.containsKey('href')) {
          favicon = faviconLink.attributes['href'];
          // Handle relative paths
          if (favicon!.startsWith('/')) {
            final uri = Uri.parse(url);
            favicon = '${uri.scheme}://${uri.host}$favicon';
          }
        }

        return UrlMetadata(
          title: title,
          description: description,
          image: image,
          favicon: favicon,
        );
      } catch (e) {
        print('Error fetching metadata: $e');
        if (attempt < retries) {
          // Wait before retrying
          await Future.delayed(Duration(seconds: 1));
          continue;
        }
        return null;
      }
    }
    return null;
  }
}