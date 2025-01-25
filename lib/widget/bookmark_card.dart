import 'package:flutter/material.dart';

import '../model/url_marker.dart';

class BookmarkCard extends StatelessWidget {
  final UrlBookmark bookmark;

  const BookmarkCard({
    Key? key,
    required this.bookmark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        bookmark.metadata?.image != null
            ? Image.network(
                bookmark.metadata!.image!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              )
            : Container(
                color: Colors.grey[300],
                height: 200,
                alignment: Alignment.center,
                child: const Icon(Icons.image, color: Colors.grey),
              ),
        Text(
          bookmark.title,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          bookmark.description ?? 'No description available',
          style: const TextStyle(
            fontSize: 14.0,
            color: Colors.grey,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
