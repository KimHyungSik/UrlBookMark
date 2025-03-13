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

  // 즐겨찾기 순으로 정렬하는 도우미 함수
  List<UrlBookmark> _sortByFavorites(List<UrlBookmark> bookmarks) {
    // 즐겨찾기된 항목(isFavorite=true)을 먼저 정렬하고 그 다음에 일반 항목 정렬
    final favoriteBookmarks = bookmarks.where((bookmark) => bookmark.isFavorite).toList();
    final regularBookmarks = bookmarks.where((bookmark) => !bookmark.isFavorite).toList();

    // 두 리스트를 합치기 (즐겨찾기가 앞에 오게 됨)
    return [...favoriteBookmarks, ...regularBookmarks];
  }

  Future<void> loadUrlBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedData = prefs.getString(_storageKey);

      if (storedData != null) {
        final List<dynamic> jsonList = json.decode(storedData);
        final bookmarks = jsonList.map((item) => UrlBookmark.fromJson(item)).toList();

        // 즐겨찾기 항목이 앞에 오도록 정렬
        state = _sortByFavorites(bookmarks);
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

      // 새로운 북마크를 추가하고 즐겨찾기 순으로 정렬
      final updatedBookmarks = [bookmarkWithMetadata, ...state];
      state = _sortByFavorites(updatedBookmarks);

      await _saveUrlBookmarks(state);
    } catch (e) {
      print('Error adding bookmark: $e');
      // Add without metadata if fetching fails
      final updatedBookmarks = [bookmark, ...state];
      state = _sortByFavorites(updatedBookmarks);
      await _saveUrlBookmarks(state);
    }
  }

  Future<void> updateUrlBookmark(String id, UrlBookmark updatedBookmark) async {
    try {
      final updatedBookmarks = [
        for (final bookmark in state)
          if (bookmark.id == id) updatedBookmark else bookmark,
      ];
      // 업데이트 후 즐겨찾기 순으로 정렬
      state = _sortByFavorites(updatedBookmarks);
      await _saveUrlBookmarks(state);
    } catch (e) {
      print('Error updating bookmark: $e');
    }
  }

  Future<void> deleteUrlBookmark(String id) async {
    try {
      final updatedBookmarks = state.where((bookmark) => bookmark.id != id).toList();
      state = _sortByFavorites(updatedBookmarks);
      await _saveUrlBookmarks(state);
    } catch (e) {
      print('Error deleting bookmark: $e');
    }
  }

  Future<void> deleteUrlBookmarks(List<String> ids) async {
    try {
      final updatedBookmarks = state.where((bookmark) => !ids.contains(bookmark.id)).toList();
      state = _sortByFavorites(updatedBookmarks);
      await _saveUrlBookmarks(state);
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

      // 즐겨찾기 변경 후 재정렬
      state = _sortByFavorites(updatedBookmarks);
      await _saveUrlBookmarks(state);
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