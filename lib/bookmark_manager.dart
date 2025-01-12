import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'model/url_marker.dart';

class UrlBookmarkManager {
  static const String _storageKey = 'UrlBookmarks'; // 로컬 저장 키

  List<UrlBookmark> _UrlBookmarks = [];

  // 북마크 리스트 가져오기
  List<UrlBookmark> get UrlBookmarks => List.unmodifiable(_UrlBookmarks);

  // 북마크 로드 (SharedPreferences에서 가져오기)
  Future<void> loadUrlBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedData = prefs.getString(_storageKey);

    if (storedData != null) {
      final List<dynamic> jsonList = json.decode(storedData);
      _UrlBookmarks = jsonList.map((item) => UrlBookmark.fromJson(item)).toList();
    }
  }

  // 북마크 저장 (SharedPreferences에 저장)
  Future<void> saveUrlBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonData = json.encode(_UrlBookmarks.map((b) => b.toJson()).toList());
    await prefs.setString(_storageKey, jsonData);
  }

  // 북마크 추가
  Future<void> addUrlBookmark(UrlBookmark UrlBookmark) async {
    _UrlBookmarks.add(UrlBookmark);
    await saveUrlBookmarks();
  }

  // 북마크 수정
  Future<void> updateUrlBookmark(String id, UrlBookmark updatedUrlBookmark) async {
    final int index = _UrlBookmarks.indexWhere((UrlBookmark) => UrlBookmark.id == id);
    if (index != -1) {
      _UrlBookmarks[index] = updatedUrlBookmark;
      await saveUrlBookmarks();
    }
  }

  // 북마크 삭제
  Future<void> deleteUrlBookmark(String id) async {
    _UrlBookmarks.removeWhere((UrlBookmark) => UrlBookmark.id == id);
    await saveUrlBookmarks();
  }

  // 북마크 초기화
  Future<void> clearUrlBookmarks() async {
    _UrlBookmarks.clear();
    await saveUrlBookmarks();
  }
}
