import 'zalo_error_model.dart';

class ZaloLogin {
  ZaloLogin.fromJson(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return;
    }
    isSuccess = map['isSuccess'] as bool?;
    error = ZaloError.fromJson(map['error'] as Map<dynamic, dynamic>?);
    data = ZaloLoginData.fromJson(map['data'] as Map<dynamic, dynamic>?);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = <String, dynamic>{};
    map['isSuccess'] = isSuccess;
    map['error'] = error?.toJson();
    map['data'] = data?.toJson();
    return map;
  }

  bool? isSuccess;
  ZaloError? error;
  ZaloLoginData? data;
}

class ZaloLoginData {
  ZaloLoginData.fromJson(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return;
    }
    oauthCode = map['oauthCode'] as String?;
    userId = map['userId'] as String?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = <String, dynamic>{};
    map['oauthCode'] = oauthCode;
    map['userId'] = userId;
    return map;
  }

  /// Use for android and ios
  String? oauthCode;

  /// Use for android and ios
  String? userId;
}
