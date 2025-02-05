import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common/colors.dart';
import '../model/url_marker.dart';

class BookmarkCard extends StatelessWidget {
  final UrlBookmark bookmark;
  final VoidCallback? onTap;

  const BookmarkCard({
    Key? key,
    required this.bookmark,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
          return;
        }
      },
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            bookmark.metadata?.image != null
                ? Image.network(
                    bookmark.metadata!.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      height: 150,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  )
                : Container(
                    color: Colors.grey[300],
                    height: 150,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image,
                      color: Colors.grey,
                    ),
                  ),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
              child: Text(
                bookmark.title,
                style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: titleTextColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (bookmark.metadata?.description == null) SizedBox(height: 10),
            if (bookmark.metadata?.description != null)
              Padding(
                padding: const EdgeInsets.only(
                    bottom: 10, top: 4, left: 8, right: 8),
                child: Text(
                  bookmark.metadata!.description!,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: descriptionTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
