
// 저장된 뷰 모드를 로드하는 Provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final viewModeProvider = StateNotifierProvider<ViewModeNotifier, bool>((ref) {
  return ViewModeNotifier();
});

// 뷰 모드 상태 관리 (SharedPreferences로 저장 기능 포함)
class ViewModeNotifier extends StateNotifier<bool> {
  static const String _viewModeKey = 'view_mode_grid'; // true = grid, false = list

  ViewModeNotifier() : super(true) {
    _loadViewMode();
  }

  // 저장된 뷰 모드 로드
  Future<void> _loadViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isGridView = prefs.getBool(_viewModeKey) ?? true; // 기본값은 그리드 뷰
      state = isGridView;
    } catch (e) {
      print('뷰 모드 로드 실패: $e');
      // 오류 발생 시 기본값 사용 (그리드 뷰)
      state = true;
    }
  }

  // 뷰 모드 변경 및 저장
  Future<void> toggleViewMode() async {
    state = !state;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_viewModeKey, state);
    } catch (e) {
      print('뷰 모드 저장 실패: $e');
    }
  }
}