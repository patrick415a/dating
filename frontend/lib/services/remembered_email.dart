import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RememberedEmail {
  RememberedEmail(this._key);

  final String _key;
  final _preferences = SharedPreferencesAsync();

  Future<String?> read() async {
    try {
      return await _preferences.getString(_key);
    } catch (_) {
      debugPrint('저장된 아이디를 불러오지 못했습니다.');
      return null;
    }
  }

  Future<void> save(String? email) async {
    try {
      if (email == null) {
        await _preferences.remove(_key);
      } else {
        await _preferences.setString(_key, email);
      }
    } catch (_) {
      debugPrint('아이디 저장 설정을 반영하지 못했습니다.');
    }
  }
}
