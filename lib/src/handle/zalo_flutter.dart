import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:zalo_flutter/src/model/model.dart';

/// * Đăng nhập và lấy thông tin của user
/// * Login and get user profile
class ZaloFlutter {
  ZaloFlutter._();

  static final ZaloFlutter _instance = ZaloFlutter._();

  static ZaloFlutter get instance => _instance;

  MethodChannel channel = const MethodChannel('zalo_flutter');

  Duration _timeout = const Duration(seconds: 30);

  /// Set timeout
  void setTimeout(Duration timeout) {
    _timeout = timeout;
  }

  /// * Get HashKey Android for register app in dashboard Zalo
  /// * Dashboard: https://developers.zalo.me/app/{your_app_id}/login
  Future<String?> getHashKeyAndroid() async {
    if (Platform.isAndroid) {
      final String? rs = await channel.invokeMethod<String?>('getHashKey').setTimeout(_timeout);
      return rs;
    }
    return null;
  }

  /// * Lấy CodeVerifier cho việc xác thực PCKE
  /// * Get CodeVerifier for PCKE authencation
  /// * More info: https://developers.zalo.me/docs/sdk/ios-sdk/dang-nhap/dang-nhap-post-6006
  String _getCodeVerifier() {
    const int length = 43;
    final Random random = Random.secure();
    final String verifier = base64UrlEncode(List<int>.generate(length, (_) => random.nextInt(256))).split('=')[0];
    return verifier;
  }

  /// * Lấy CodeChallenge cho việc xác thực PCKE
  /// * Get CodeChallenge for PCKE authencation
  /// * More info: https://developers.zalo.me/docs/sdk/ios-sdk/dang-nhap/dang-nhap-post-6006
  String _getCodeChallenge(String codeVerifier) {
    final String rs = base64UrlEncode(sha256.convert(ascii.encode(codeVerifier)).bytes).split('=')[0];
    return rs;
  }

  /// * Logout - SDK clear oauth code in cache
  /// * More info Android: https://developers.zalo.me/docs/sdk/android-sdk/dang-nhap/dang-xuat-post-6020
  /// * More info Ios: https://developers.zalo.me/docs/sdk/ios-sdk/dang-nhap/dang-xuat-post-5728
  Future<void> logout() async {
    await channel.invokeMethod<void>('logout').setTimeout(_timeout);
  }

  /// * Xác minh lại refresh token
  /// * Check validate refresh token
  /// * More info Android: https://developers.zalo.me/docs/sdk/android-sdk/dang-nhap/xac-minh-lai-refreshtoken-post-6023
  /// * More info Ios: https://developers.zalo.me/docs/sdk/ios-sdk/dang-nhap/xac-minh-lai-refreshtoken-post-5730
  Future<bool> validateRefreshToken({
    required String refreshToken,
    List<Object> externalInfo = const <Object>[],
  }) async {
    final bool? rs = await channel.invokeMethod<bool?>(
      'validateRefreshToken',
      <String, dynamic>{
        'refreshToken': refreshToken,
        'extInfo': externalInfo,
      },
    ).setTimeout(_timeout);
    return rs == true;
  }

  /// * Authenticate (with app or webview)
  /// * More info Android: https://developers.zalo.me/docs/sdk/android-sdk/dang-nhap/dang-nhap-post-6027
  /// * More info Ios: https://developers.zalo.me/docs/sdk/ios-sdk/dang-nhap/dang-nhap-post-6006
  Future<ZaloLogin> login({
    String? refreshToken,
    Map<String, dynamic> externalInfo = const <String, dynamic>{},
  }) async {
    final String codeVerifier = _getCodeVerifier();
    final String codeChallenge = _getCodeChallenge(codeVerifier);
    final Map<dynamic, dynamic>? rs = await channel.invokeMethod<Map<dynamic, dynamic>?>(
      'login',
      <String, dynamic>{
        'codeVerifier': codeVerifier,
        'codeChallenge': codeChallenge,
        'extInfo': externalInfo,
        'refreshToken': refreshToken,
      },
    );
    final ZaloLogin data = ZaloLogin.fromJson(rs);
    return data;
  }

  /// * Lấy access token bằng oauth code và code verifier
  /// * Authenticate (with app or webview)
  /// * More info Android: https://developers.zalo.me/docs/sdk/android-sdk/dang-nhap/dang-nhap-post-6027
  /// * More info Ios: https://developers.zalo.me/docs/sdk/ios-sdk/dang-nhap/dang-nhap-post-6006
  Future<Map<dynamic, dynamic>?> getAccessToken({required String? oauthCode, required String? codeVerifier}) async {
    if (oauthCode == null || oauthCode.isEmpty || codeVerifier == null || codeVerifier.isEmpty) {
      return null;
    }

    final Map<dynamic, dynamic>? rs = await channel.invokeMethod<Map<dynamic, dynamic>?>(
      'getAccessToken',
      <String, dynamic>{
        'codeVerifier': codeVerifier,
        'oauthCode': oauthCode,
      },
    );

    return rs;
  }

  /// * Lấy thông tin người dùng
  /// * Get Zalo user profile
  /// * More info Android: https://developers.zalo.me/docs/sdk/android-sdk/open-api/lay-thong-tin-profile-post-6050
  /// * More info Ios: https://developers.zalo.me/docs/sdk/ios-sdk/open-api/lay-thong-tin-profile-post-5736
  /// * More info Web: https://developers.zalo.me/docs/api/open-api/tai-lieu/thong-tin-nguoi-dung-post-28
  Future<Map<dynamic, dynamic>?> getUserProfile({
    required String accessToken,
  }) async {
    final String newAccessToken = accessToken == '' ? 'x' : accessToken;
    final Map<dynamic, dynamic>? rs = await channel.invokeMethod<Map<dynamic, dynamic>?>(
      'getUserProfile',
      <String, dynamic>{
        'accessToken': newAccessToken,
      },
    ).setTimeout(_timeout);
    return rs;
  }

  /// * Chia sẻ tin nhắn - SDK mở zalo app với text
  /// * Share Message - SDK open zalo app with some text
  /// * More info Android: https://developers.zalo.me/docs/sdk/android-sdk/tuong-tac-voi-app-zalo/dang-bai-viet-post-6047
  /// * More info Ios: https://developers.zalo.me/docs/sdk/ios-sdk/tuong-tac-voi-app-zalo/dang-bai-viet-post-5843
  Future<bool> shareMessage({
    required String link,
    required String appName,
    required String message,
  }) async {
    final bool? result = await channel.invokeMethod<bool?>(
      'shareMessage',
      <String, dynamic>{
        'link': link,
        'appName': appName,
        'message': message,
      },
    ).setTimeout(_timeout);
    return result == true;
  }
}

extension _InvokeMethodExt<T> on Future<T> {
  Future<T?> setTimeout(Duration timeout, {FutureOr<T> Function()? onTimeout}) async {
    try {
      return await this.timeout(timeout, onTimeout: onTimeout);
    } catch (e) {
      return null;
    }
  }
}
