import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zalo_flutter/src/model/zalo_login_model.dart';
import 'package:zalo_flutter/zalo_flutter.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
  }) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _indexReset = -1;
  ValueKey<String> _key = const ValueKey<String>('');

  String zaloId = '2961857761415564889';
  String zaloMessage = 'Hello';
  String zaloLink = 'www.google.com';

  String? _accessToken;
  String? _refreshToken;

  String? _oauthCode;
  String? _codeVerifier;

  @override
  void initState() {
    super.initState();
    _initZaloFlutter();
  }

  Future<void> _initZaloFlutter() async {
    if (Platform.isAndroid) {
      final String? hashKey = await ZaloFlutter.instance.getHashKeyAndroid();
      log('HashKey: $hashKey');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CommonButton(
                  text: 'clear log',
                  onPressed: () async {
                    _indexReset++;
                    _key = ValueKey<String>(_indexReset.toString());
                    setState(() {});
                    return null;
                  },
                ),
                CommonButton(
                  text: 'login',
                  onPressed: () async {
                    final ZaloLogin data = await ZaloFlutter.instance.login();
                    try {
                      if (data.isSuccess == true) {
                        setState(() {
                          _codeVerifier = data.data?.codeVerifier;
                          _oauthCode = data.data?.oauthCode;
                        });
                      }
                    } catch (e) {
                      print('login: $e');
                    }
                    return data.toJson();
                  },
                ),
                CommonButton(
                  text: 'getAccessToken',
                  onPressed: () async {
                    final Map<dynamic, dynamic>? data =
                        await ZaloFlutter.instance.getAccessToken(oauthCode: _oauthCode, codeVerifier: _codeVerifier);
                    if (data?['isSuccess'] == true) {
                      setState(() {
                        _accessToken = data?['data']['access_token'] as String?;
                        _refreshToken = data?['data']['refresh_token'] as String?;
                      });
                    }

                    try {
                      print('login: $data');
                    } catch (e) {
                      print('login: $e');
                    }
                    return data;
                  },
                ),
                CommonButton(
                  text: 'logout',
                  onPressed: () async {
                    _accessToken = null;
                    _refreshToken = null;
                    await ZaloFlutter.instance.logout();

                    _indexReset++;
                    _key = ValueKey<String>(_indexReset.toString());
                    setState(() {});
                    return null;
                  },
                ),
                CommonButton(
                  text: 'validateRefreshToken',
                  onPressed: () async {
                    final bool data = await ZaloFlutter.instance.validateRefreshToken(
                      refreshToken: _refreshToken ?? '',
                    );
                    return data.toString();
                  },
                ),
                CommonButton(
                  text: 'getUserProfile',
                  onPressed: () async {
                    final Map<dynamic, dynamic>? data = await ZaloFlutter.instance.getUserProfile(
                      accessToken: _accessToken ?? '',
                    );
                    return data;
                  },
                ),
                CommonButton(
                  text: 'shareMessage',
                  onPressed: () async {
                    final bool result = await ZaloFlutter.instance.shareMessage(
                      link: 'https://huuksocialproduction.page.link/nHKZ',
                      message: 'assadda',
                      appName: 'Huuk Social',
                    );
                    return result;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CommonButton extends StatefulWidget {
  const CommonButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.color = Colors.blue,
  }) : super(key: key);

  final String text;
  final Future<dynamic> Function() onPressed;
  final Color color;

  @override
  _CommonButtonState createState() => _CommonButtonState();
}

class _CommonButtonState extends State<CommonButton> {
  String? result;

  @override
  Widget build(BuildContext context) {
    final Widget childText = Text(
      widget.text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );

    final Widget button = MaterialButton(
      minWidth: double.infinity,
      height: 40,
      color: widget.color,
      padding: const EdgeInsets.all(16),
      onPressed: () async {
        _showLoading(context);
        final DateTime time = DateTime.now();
        print('[$time][commonButton] ${widget.text}');
        final dynamic data = await widget.onPressed();
        if (data == null) {
          result = 'null';
        } else if (data is String) {
          result = data;
        } else if (data is Map) {
          result = jsonEncode(data);
        }
        setState(() {});
        Navigator.pop(context);
      },
      shape: const StadiumBorder(),
      child: childText,
    );

    Widget showResult(String? text) {
      if (text == null) {
        return Container();
      }
      String data;
      try {
        final Map<String, dynamic>? object = jsonDecode(text) as Map<String, dynamic>?;
        data = const JsonEncoder.withIndent('  ').convert(object);
      } catch (e) {
        data = text;
      }
      return Text(data);
    }

    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        children: <Widget>[
          button,
          showResult(result),
        ],
      ),
    );
  }

  Future<void> _showLoading(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
