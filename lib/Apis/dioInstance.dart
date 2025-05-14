import 'dart:convert';
// import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:rdpms_tablet/Apis/auth.dart';


class DioInterceptor {
  var dio = Dio();
  get(url) async {
    Map<String, dynamic> decodedToken = JwtDecoder.decode(auth.jwt);
    dio.options.headers["authorization"] = "Bearer ${auth.jwt}";
    dio.options.headers['content-Type'] = 'application/json';
    String key = auth.username + decodedToken['exp'].toString();
    if (key.length == 16) {
      key = key;
    } else if (key.length < 16) {
      key = key.padRight(16, '0');
    } else if (key.length > 16) {
      key = key.substring(0, 16);
    }

    Response res = await dio.get(url);
    final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8(key),
        mode: encrypt.AESMode.ecb, padding: null));
    var iv = encrypt.IV.fromUtf8(key);
    var resp = encrypter.decrypt64(res.data, iv: iv).trim().replaceAll(
        RegExp(r'''[^a-zA-Z0-9\t\n ./<>?;:"',`!@#$%^&*()\[\]{}_+=|\\-]'''), '');

    return jsonDecode(resp);
  }

  post(url, Map<String, dynamic> data) async {


    Map<String, dynamic> decodedToken = JwtDecoder.decode(auth.jwt);
    dio.options.headers["authorization"] = "Bearer ${auth.jwt}";
    dio.options.headers['content-Type'] = 'application/json';
    String key = auth.username + decodedToken['exp'].toString();
    if (key.length == 16) {
      key = key;
    } else if (key.length < 16) {
      key = key.padRight(16, '0');
    } else if (key.length > 16) {
      key = key.substring(0, 16);
    }
    var iv = encrypt.IV.fromUtf8(key);

    final encrypter = encrypt.Encrypter(
        encrypt.AES(encrypt.Key.fromUtf8(key), mode: encrypt.AESMode.ecb));

    var encrypted = encrypter.encrypt(jsonEncode(data), iv: iv);


    Response res = await dio.post(url, data: {"data": encrypted.base64});
    var resp = encrypter.decrypt64(res.data, iv: iv).trim().replaceAll(
        RegExp(r'''[^a-zA-Z0-9\t\n ./<>?;:"',`!@#$%^&*()\[\]{}_+=|\\-]'''), '');
    print('resp - ${jsonDecode(resp)}');
    return jsonDecode(resp);
  }
}

var dioInstance = DioInterceptor();