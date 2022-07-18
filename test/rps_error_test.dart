// Copyright (C) 2022 Zxbase, LLC. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:convert';
import 'package:zxbase_api_client/zxbase_api_client.dart';
import 'package:zxbase_crypto/zxbase_crypto.dart';
import 'package:zxbase_model/zxbase_model.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final challenge = {
  'challenge': {
    'msg':
        '1:12:1658174941021:501820f1-8e2f-436c-b987-66a78482aa26:eyJrdHkiOiJPS1AiLCJjcnYiOiJFZDI1NTE5IiwieCI6Imt0d3RodXJFTW50cXF0Z2VfZEVjYWs4N3hIUmdYdnVGZkc4SUt0OFJYdUk9Iiwia2lkIjoiOGI4ZjI2YjctZGZjNS00ZDI3LWEzYmMtY2M3ZjBiMTg2ODBhIiwidmVyIjoxfQ==:Q47C5KizCohQ2kmO2SOdqehiL58BpzmBXwDDbEJDjtY%3D',
    'sig':
        'tvQusAJd58T%2FgXPgni5pZc6jdAqMXh6ocBO4P4Bex5lyKCu%2BgCa0rBlOd1APTJ6ncxC2R%2FEru9nyZ9wQHh4aoXzg0IgyKt7MXFBXWKYuopPMC7w2G%2BAKO6iWkA%2BqLRJnDLtPk6BVGmetTeQl2PTTdmIGSbC94I%2Bt2L6Hy1dGNrQHt0%2FhPf9FvVLrXTDjUAx9BTvpuYEQCBFsOM8YrGC%2FrQgThPdHOOAptG0cOeiF74gyX9t8X8TCah3O07%2FVEPlfDIYjIm8Ch3YPbG1uzGGN8IPmvjDsEacxDmzkBp9F%2FK4%2FwM6GEn1HWOGEw3F9qBBr9qTNgB5w1U02nwsbhjRPQQ%3D%3D',
    'x5c': 'x5c'
  }
};

void main() {
  const host = 'alpha.zxbase.com';

  final metadata = 'Test:APC:T1';

  String deviceId = const Uuid().v4().toString();
  String deviceId2 = const Uuid().v4().toString();

  SimpleKeyPair kp;
  SimplePublicKey pubK;
  late Identity me;
  RpsClient rpsClient = RpsClient();

  late SimpleKeyPair kp2;
  late SimplePublicKey pubK2;
  late Identity idnt2;

  setUpAll(() async {
    kp = await PKCrypto.generateKeyPair();
    pubK = await kp.extractPublicKey();
    me = Identity(deviceId: deviceId, publicKey: pubK);
    rpsClient.init(host: host, identity: me, keyPair: kp);
    rpsClient.httpClient = MockClient((request) async {
      if (request.url.toString().contains('auth') && request.method == 'POST') {
        return http.Response(jsonEncode(challenge), 200);
      }
      return http.Response('bla', 409);
    });

    kp2 = await PKCrypto.generateKeyPair();
    pubK2 = await kp2.extractPublicKey();
    idnt2 = Identity(deviceId: deviceId2, publicKey: pubK2);
  });

  test('Registration put response is not 200', () async {
    final result = await rpsClient.obtainToken(topic: 'bla');
    expect(result, equals(false));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('MOTD response is not 200', () async {
    final result = await rpsClient.getMotd();
    expect(result, equals(null));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Channel response is not 200', () async {
    final result =
        await rpsClient.channel(peerId: idnt2.deviceId, app: 'messenger');
    expect(result, equals(''));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Peers response is not 200', () async {
    final result = await rpsClient.getPeers();
    expect(result, equals([]));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Register response is not 200', () async {
    final result = await rpsClient.register(metadata: metadata);
    expect(result, equals(false));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Pairing response is not 200', () async {
    final result = await rpsClient.pair(peerIdentity: idnt2.toBase64Url());
    expect(result, equals(false));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Registration post response is not 200', () async {
    rpsClient.httpClient = MockClient((request) async {
      return http.Response('bla', 409);
    });
    final result = await rpsClient.obtainToken(topic: 'bla');
    expect(result, equals(false));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
