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
    return SafeArea(
        child: isGridMode ? _buildGridCard(context) : _buildListCard(context));
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
      child: Stack(
        children: [
          // 카드 본체
          Container(
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
            child: IntrinsicHeight( // 내용물 높이에 맞춤
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch, // 세로로 늘림
                children: [
                  // 썸네일 영역
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: SizedBox(
                      width: 100,
                      child: AspectRatio(
                        aspectRatio: 1, // 정사각형 비율
                        child: _buildThumbnail(),
                      ),
                    ),
                  ),

                  // 내용 영역
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTitle(),
                          SizedBox(height: 4),
                          Flexible(child: _buildDescription()),
                          SizedBox(height: 4),
                          if (bookmark.tags != null && bookmark.tags!.isNotEmpty)
                            _buildTagsCompact(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 플로팅 즐겨찾기 아이콘
          if (bookmark.isFavorite && !isDeleteMode)
            Positioned(
              top: 16,
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

          // 플로팅 수정 버튼
          if (!isDeleteMode)
            Positioned(
              top: 16,
              right: bookmark.isFavorite ? 40 : 8,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) =>
                        BookmarkEditBottomSheet(bookmark: bookmark),
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
                  builder: (context) =>
                      BookmarkEditBottomSheet(bookmark: bookmark),
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
      return Image.network(
        bookmark.metadata!.image!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder(showLoader: true);
        },
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder({bool showLoader = false}) {
    return Container(
      height: 130,
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
      maxLines: isGridMode ? 3 : 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // 리스트 뷰용 컴팩트 태그 표시
  Widget _buildTagsCompact() {
    if (bookmark.tags == null || bookmark.tags!.isEmpty) {
      return SizedBox();
    }

    // 태그가 2개 이상인 경우, 첫 번째만 표시하고 나머지는 +N으로 표시
    if (bookmark.tags!.length > 1) {
      return Row(
        children: [
          _buildTagChip(bookmark.tags![0]),
          SizedBox(width: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "+${bookmark.tags!.length - 1}",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      );
    } else {
      // 태그가 1개인 경우
      return _buildTagChip(bookmark.tags![0]);
    }
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
}