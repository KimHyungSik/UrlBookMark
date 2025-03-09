import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common/colors.dart';
import '../model/url_marker.dart';
import '../screens/bottomsheet/bookmark_edit_bottom_sheet.dart';

class BookmarkCard extends StatelessWidget {
  final UrlBookmark bookmark;
  final VoidCallback? onTap;
  final bool isDeleteMode;
  final bool isGridMode;

  const BookmarkCard({
    Key? key,
    required this.bookmark,
    this.isDeleteMode = false,
    this.onTap,
    this.isGridMode = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isGridMode ? _buildGridCard(context) : _buildListCard(context);
  }

  Widget _buildGridCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            _buildImageSection(context),

            // Content section
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(),
                  SizedBox(height: 4),
                  _buildUrl(),
                  SizedBox(height: 8),
                  _buildDescription(),
                  if (bookmark.tags != null && bookmark.tags!.isNotEmpty)
                    _buildTags(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: SizedBox(
                width: 100,
                height: 100,
                child: _buildThumbnail(),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(),
                    SizedBox(height: 4),
                    _buildUrl(),
                    SizedBox(height: 4),
                    _buildDescription(),
                    if (bookmark.tags != null && bookmark.tags!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _buildTags(),
                      ),
                  ],
                ),
              ),
            ),

            // Actions
            if (!isDeleteMode)
              _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Stack(
      children: [
        _buildThumbnail(),
        if (bookmark.isFavorite && !isDeleteMode)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star,
                color: Colors.amber,
                size: 16,
              ),
            ),
          ),
        // Add edit button to grid view
        if (!isDeleteMode)
          Positioned(
            top: 8,
            right: bookmark.isFavorite ? 40 : 8,
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => BookmarkEditBottomSheet(bookmark: bookmark),
                );
              },
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildThumbnail() {
    if (bookmark.metadata?.image != null) {
      return Container(
        constraints: BoxConstraints(minHeight: 150), // Add minimum height
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            bookmark.metadata!.image!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildPlaceholder(showLoader: true);
            },
          ),
        ),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder({bool showLoader = false}) {
    return Container(
      height: 150, // Fixed minimum height for placeholders
      color: Colors.grey[200],
      child: Center(
        child: showLoader
            ? CircularProgressIndicator(strokeWidth: 2)
            : Icon(Icons.image, color: Colors.grey, size: 32),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      bookmark.title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: titleTextColor,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildUrl() {
    return Text(
      bookmark.url,
      style: TextStyle(
        fontSize: 12,
        color: Colors.blue[700],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription() {
    if (bookmark.description.isEmpty) {
      return SizedBox();
    }

    return Text(
      bookmark.description,
      style: TextStyle(
        fontSize: 14,
        color: descriptionTextColor,
      ),
      maxLines: isGridMode ? 2 : 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: bookmark.tags!.map((tag) => _buildTagChip(tag)).toList(),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Edit button
        IconButton(
          icon: Icon(Icons.edit, color: Colors.grey[700]),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) {
                return BookmarkEditBottomSheet(
                  bookmark: bookmark,
                );
              },
            );
          },
          tooltip: "Edit bookmark",
        ),

        // Visit link button
        IconButton(
          icon: Icon(Icons.open_in_new, color: Colors.blue[700]),
          onPressed: () async {
            try {
              final url = Uri.parse(bookmark.url);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            } catch (e) {
              print('Failed to launch URL: $e');
            }
          },
          tooltip: "Open in browser",
        ),
      ],
    );
  }
}