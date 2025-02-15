import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common/colors.dart';
import '../model/url_marker.dart';
import '../screens/bottomsheet/bookmark_edit_bottom_sheet.dart';

class BookmarkCard extends StatelessWidget {
  final UrlBookmark bookmark;
  final VoidCallback? onTap;
  final bool isDeleteMode;

  const BookmarkCard({
    super.key,
    required this.bookmark,
    this.isDeleteMode = false,
    this.onTap,
  });

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
            Stack(
              children: [
                if (bookmark.metadata?.image != null)
                  _networkImage()
                else
                  _unknownImagae(),
                if (!isDeleteMode) _moreIcon(context)
              ],
            ),
            _cardTitle(),
            if (bookmark.tags != null && bookmark.tags!.isNotEmpty) _tags(),
            _description(bookmark.metadata?.description),
          ],
        ),
      ),
    );
  }

  GestureDetector _moreIcon(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return BookmarkEditBottomSheet(
              bookmark: bookmark,
            );
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Align(
          alignment: Alignment.topRight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(100),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                Icons.more_vert,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Padding _tags() {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: bookmark.tags!
              .map(
                (tag) => Chip(
                  label: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: Colors.white,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Padding _cardTitle() {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
      child: Text(
        bookmark.title,
        style: TextStyle(
            fontSize: 16.0, fontWeight: FontWeight.bold, color: titleTextColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Container _unknownImagae() {
    return Container(
      color: Colors.grey[300],
      height: 150,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image,
        color: Colors.grey,
      ),
    );
  }

  Image _networkImage() {
    return Image.network(
      bookmark.metadata!.image!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[300],
        alignment: Alignment.center,
        height: 150,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  Widget _description(String? description) {
    if (description == null) {
      return SizedBox(height: 10);
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4, left: 8, right: 8),
        child: Text(
          bookmark.metadata!.description!,
          style: TextStyle(
            fontSize: 14.0,
            color: descriptionTextColor,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
  }
}
