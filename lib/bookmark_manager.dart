import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_book_marker/model/url_metadata.dart';

import 'model/url_marker.dart';

class UrlBookmarkManager extends StateNotifier<List<UrlBookmark>> {
  UrlBookmarkManager() : super([]) {
    loadUrlBookmarks();
  }

  static const String _storageKey = 'UrlBookmarks';

  Future<void> loadUrlBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedData = prefs.getString(_storageKey);

    if (storedData != null) {
      final List<dynamic> jsonList = json.decode(storedData);
      state = jsonList.map((item) => UrlBookmark.fromJson(item)).toList();
    }
  }

  Future<void> addUrlBookmark(UrlBookmark bookmark) async {
    final metadata = await bookmark.url.fetchUrlMetadata();
    final bookmarkWithMetadata = bookmark.copyWith(metadata: metadata);
    final updatedBookmarks = [...state, bookmarkWithMetadata];
    state = updatedBookmarks;
    await _saveUrlBookmarks(updatedBookmarks);
  }

  Future<void> updateUrlBookmark(String id, UrlBookmark updatedBookmark) async {
    final updatedBookmarks = [
      for (final bookmark in state)
        if (bookmark.id == id) updatedBookmark else bookmark,
    ];
    state = updatedBookmarks;
    await _saveUrlBookmarks(updatedBookmarks);
  }

  Future<void> deleteUrlBookmark(String id) async {
    final updatedBookmarks = state.where((bookmark) => bookmark.id != id).toList();
    state = updatedBookmarks;
    await _saveUrlBookmarks(updatedBookmarks);
  }

  Future<void> _saveUrlBookmarks(List<UrlBookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonData = json.encode(bookmarks.map((b) => b.toJson()).toList());
    await prefs.setString(_storageKey, jsonData);
  }
}

final urlBookmarkProvider = StateNotifierProvider<UrlBookmarkManager, List<UrlBookmark>>(
      (ref) => UrlBookmarkManager(),
);
