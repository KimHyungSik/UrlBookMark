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
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedData = prefs.getString(_storageKey);

      if (storedData != null) {
        final List<dynamic> jsonList = json.decode(storedData);
        state = jsonList.map((item) => UrlBookmark.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error loading bookmarks: $e');
      // Fallback to empty state if loading fails
      state = [];
    }
  }

  Future<void> addUrlBookmark(UrlBookmark bookmark) async {
    try {
      final metadata = await bookmark.url.fetchUrlMetadata();
      final bookmarkWithMetadata = bookmark.copyWith(metadata: metadata);
      final updatedBookmarks = [bookmarkWithMetadata, ...state];
      state = updatedBookmarks;
      await _saveUrlBookmarks(updatedBookmarks);
    } catch (e) {
      print('Error adding bookmark: $e');
      // Add without metadata if fetching fails
      final updatedBookmarks = [bookmark, ...state];
      state = updatedBookmarks;
      await _saveUrlBookmarks(updatedBookmarks);
    }
  }

  Future<void> updateUrlBookmark(String id, UrlBookmark updatedBookmark) async {
    try {
      final updatedBookmarks = [
        for (final bookmark in state)
          if (bookmark.id == id) updatedBookmark else bookmark,
      ];
      state = updatedBookmarks;
      await _saveUrlBookmarks(updatedBookmarks);
    } catch (e) {
      print('Error updating bookmark: $e');
    }
  }

  Future<void> deleteUrlBookmark(String id) async {
    try {
      final updatedBookmarks = state.where((bookmark) => bookmark.id != id).toList();
      state = updatedBookmarks;
      await _saveUrlBookmarks(updatedBookmarks);
    } catch (e) {
      print('Error deleting bookmark: $e');
    }
  }

  Future<void> deleteUrlBookmarks(List<String> ids) async {
    try {
      final updatedBookmarks = state.where((bookmark) => !ids.contains(bookmark.id)).toList();
      state = updatedBookmarks;
      await _saveUrlBookmarks(updatedBookmarks);
    } catch (e) {
      print('Error deleting bookmarks: $e');
    }
  }

  Future<void> toggleFavorite(String id) async {
    try {
      final updatedBookmarks = state.map((bookmark) {
        if (bookmark.id == id) {
          return bookmark.copyWith(isFavorite: !bookmark.isFavorite);
        }
        return bookmark;
      }).toList();

      state = updatedBookmarks;
      await _saveUrlBookmarks(updatedBookmarks);
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  Future<void> _saveUrlBookmarks(List<UrlBookmark> bookmarks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonData = json.encode(bookmarks.map((b) => b.toJson()).toList());
      await prefs.setString(_storageKey, jsonData);
    } catch (e) {
      print('Error saving bookmarks: $e');
    }
  }
}

// Keep the original provider
final urlBookmarkProvider = StateNotifierProvider<UrlBookmarkManager, List<UrlBookmark>>(
      (ref) => UrlBookmarkManager(),
);