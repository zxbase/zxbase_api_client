/// RPS (Registration and pairing service) client.

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:zxbase_crypto/zxbase_crypto.dart';
import 'package:zxbase_model/zxbase_model.dart';

import 'package:http/http.dart' as http;

class RpsClient {
  static const component = 'RpsClient'; // logging component
  static const _proto = 'https';

  final _zxbClient = http.Client();

  late String _host;
  late int _port;

  late Identity _identity;
  late SimpleKeyPair _keyPair;

  Token? token;
  String? tokenStr;
  late DateTime tokenDateTime; // time the token was received

  /// Headers will be updated with token.
  Map<String, String> headers = {
    'Content-Type': 'application/json; charset=UTF-8'
  };

  get httpClient => _zxbClient;

  /// Initialize client.
  void init(
      {required String host,
      int port = 7070,
      required Identity identity,
      required SimpleKeyPair keyPair}) {
    _host = host;
    _port = port;
    _identity = identity;
    _keyPair = keyPair;
  }

  /// Obtain token to access the service anonymously.
  Future<bool> obtainToken({required String topic}) async {
    final postParams = jsonEncode({
      'identity': _identity.toBase64Url(),
      'access': {'tier': 1, 'topic': topic}
    });

    final url = Uri.parse('$_proto://$_host:$_port/auth');
    http.Response res =
        await _zxbClient.post(url, headers: headers, body: postParams);
    if (res.statusCode != 200) {
      log('Failed to get challenge: ${res.body}.', name: component);
      return false;
    }

    Map<String, dynamic> resObject = jsonDecode(res.body);
    Map<String, dynamic> challenge = resObject['challenge'];
    final response = Hashcash.solveChallenge((challenge['msg']));
    final sig = await PKCrypto.sign(response, _keyPair);

    final putParams = jsonEncode({
      'challenge': resObject['challenge'],
      'response': {
        'msg': response,
        'sig': sig,
      },
      'access': {'tier': 1, 'topic': topic}
    });

    res = await _zxbClient.put(url, headers: headers, body: putParams);
    if (res.statusCode != 200) {
      log('Failed to obtain token: ${res.body}.', name: component);
      return false;
    }

    Map<String, dynamic> body = jsonDecode(res.body);
    tokenStr = body['token'];
    token = Token.fromString(tokenStr!);
    tokenDateTime = DateTime.now().toUtc();
    headers[HttpHeaders.authorizationHeader] = tokenStr!;
    log('Token acquired at $tokenDateTime.', name: component);
    return true;
  }

  /// Register device.
  Future<bool> register({required String metadata}) async {
    try {
      final params = jsonEncode({'metadata': metadata});
      final url =
          Uri.parse('$_proto://$_host:$_port/devices/${_identity.deviceId}');
      final res = await _zxbClient.post(url, headers: headers, body: params);
      if (res.statusCode == 200) {
        log('Device registration succeeded.', name: component);
        return true;
      }
      return false;
    } catch (e) {
      log('Device registration failed.', name: component, error: e);
      return false;
    }
  }

  /// Pair device with a peer.
  /// Returns true if a mutual trust was established as a result of this
  /// pairing.
  ///  Mutual trust requires both peers to express their consent.
  Future<bool> pair({required String peerIdentity}) async {
    try {
      final params = jsonEncode({'peerIdentity': peerIdentity});
      final url = Uri.parse(
          '$_proto://$_host:$_port/devices/${_identity.deviceId}/peers');
      final res = await _zxbClient.post(url, headers: headers, body: params);

      if (res.statusCode == 200) {
        Map<String, dynamic> body = jsonDecode(res.body);
        return body['paired'];
      }
      log('Pairing error.', name: component, error: res.statusCode);
      return false;
    } catch (e) {
      log('Pairing failed', name: component, error: e);
      return false;
    }
  }

  /// Get list of peers.
  Future<List<dynamic>> getPeers() async {
    try {
      final url = Uri.parse(
          '$_proto://$_host:$_port/devices/${_identity.deviceId}/peers');
      final res = await _zxbClient.get(url, headers: headers);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      log('Peers error.', name: component, error: res.statusCode);
      return [];
    } catch (e) {
      log('Peers failed.', name: component, error: e);
      return [];
    }
  }

  /// Get or create application channel.
  Future<String> channel({required String peerId, required String app}) async {
    try {
      final url = Uri.parse('$_proto://$_host:$_port/channels');
      final params = jsonEncode({'peerId': peerId, 'app': app});
      final res = await _zxbClient.post(url, headers: headers, body: params);

      if (res.statusCode == 200) {
        Map<String, dynamic> body = jsonDecode(res.body);
        return body['channelId'];
      }
      log('No channel.', name: component, error: res.statusCode);
      return '';
    } catch (e) {
      log('Failed to get channel.', name: component, error: e);
      return '';
    }
  }
}
