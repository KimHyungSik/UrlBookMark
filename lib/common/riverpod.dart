import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bookmark_manager.dart';
import '../model/url_marker.dart';

final urlBookmarkProvider = StateNotifierProvider<UrlBookmarkManager, List<UrlBookmark>>(
      (ref) => UrlBookmarkManager(),
);