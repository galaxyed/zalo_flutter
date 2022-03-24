import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import '../model/model.dart';

class ZaloFlutter {
  ZaloFlutter._();

  static final ZaloFlutter _instance = ZaloFlutter._();

  static ZaloFlutter get instance => _instance;

  MethodChannel channel = const MethodChannel('zalo_flutter');

  /// * Get HashKey Android for register app in dashboard Zalo
  /// * Dashboard: https://developers.zalo.me/app/{your_app_id}/login
  Future<String?> getHashKeyAndroid() async {
    if (Platform.isAndroid) {
      final String? rs = await channel.invokeMethod<String?>('getHashKey');
      return rs;
    }
  }

  /// * Logout - SDK clear oauth code in cache
  /// * More info Android: https://developers.zalo.me/docs/sdk/android-sdk/login/dang-xuat-post-429
  /// * More info Ios: https://developers.zalo.me/docs/sdk/ios-sdk/login/dang-xuat-post-485
  Future<void> logout() async {
    await channel.invokeMethod<void>('logout');
  }

  /// * Check if authenticated
  /// * More info Android: https://developers.zalo.me/docs/sdk/android-sdk/login/xac-minh-lai-oauth-code-post-427
  /// * More info Ios: https://developers.zalo.me/docs/sdk/ios-sdk/login/xac-minh-lai-oauth-code-post-483
  Future<bool> isLogin() async {
    final bool? rs = await channel.invokeMethod<bool?>('isAuthenticated');
    return rs == true;
  }

  /// * Authenticate (with app or webview)
  /// * More info Android: https://developers.zalo.me/docs/sdk/android-sdk/login/dang-nhap-bang-zalo-post-250
  /// * More info Ios: https://developers.zalo.me/docs/sdk/ios-sdk/login/dang-nhap-post-480
  Future<ZaloLogin> login() async {
    final Map<dynamic, dynamic>? rs = await channel.invokeMethod<Map<dynamic, dynamic>?>('login');
    final ZaloLogin data = ZaloLogin.fromJson(rs);
    return data;
  }
}
