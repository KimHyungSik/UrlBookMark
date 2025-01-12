import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'model/url_marker.dart';

class UrlBookmarkManager {
  UrlBookmarkManager._privateConstructor();
  static final UrlBookmarkManager _instance = UrlBookmarkManager._privateConstructor();
  // 4. 외부에서 접근할 수 있는 인스턴스
  factory UrlBookmarkManager() => _instance;

  static const String _storageKey = 'UrlBookmarks'; // 로컬 저장 키
  List<UrlBookmark> _urlBookmarks = [];

  // 북마크 리스트 가져오기
  List<UrlBookmark> get urlBookmarks => List.unmodifiable(_urlBookmarks);

  // 북마크 로드 (SharedPreferences에서 가져오기)
  Future<void> loadUrlBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedData = prefs.getString(_storageKey);

    if (storedData != null) {
      final List<dynamic> jsonList = json.decode(storedData);
      _urlBookmarks = jsonList.map((item) => UrlBookmark.fromJson(item)).toList();
    }
  }

  // 북마크 저장 (SharedPreferences에 저장)
  Future<void> saveUrlBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonData = json.encode(_urlBookmarks.map((b) => b.toJson()).toList());
    await prefs.setString(_storageKey, jsonData);
  }

  // 북마크 추가
  Future<void> addUrlBookmark(UrlBookmark urlBookmark) async {
    _urlBookmarks.add(urlBookmark);
    await saveUrlBookmarks();
  }

  // 북마크 수정
  Future<void> updateUrlBookmark(String id, UrlBookmark updatedUrlBookmark) async {
    final int index = _urlBookmarks.indexWhere((urlBookMark) => urlBookMark.id == id);
    if (index != -1) {
      _urlBookmarks[index] = updatedUrlBookmark;
      await saveUrlBookmarks();
    }
  }

  // 북마크 삭제
  Future<void> deleteUrlBookmark(String id) async {
    _urlBookmarks.removeWhere((urlBookMark) => urlBookMark.id == id);
    await saveUrlBookmarks();
  }

  // 북마크 초기화
  Future<void> clearUrlBookmarks() async {
    _urlBookmarks.clear();
    await saveUrlBookmarks();
  }
}
