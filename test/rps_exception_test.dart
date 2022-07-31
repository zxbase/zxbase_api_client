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

import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'package:zxbase_api_client/zxbase_api_client.dart';
import 'package:zxbase_crypto/zxbase_crypto.dart';
import 'package:zxbase_model/zxbase_model.dart';

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
      throw ('mock exception');
    });

    kp2 = await PKCrypto.generateKeyPair();
    pubK2 = await kp2.extractPublicKey();
    idnt2 = Identity(deviceId: deviceId2, publicKey: pubK2);
  });

  test('Register response is not 200', () async {
    final result = await rpsClient.register(metadata: metadata);
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

  test('Get peers throws exception', () async {
    final result = await rpsClient.getPeers();
    expect(result, equals([]));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Pairing throws exception', () async {
    final result = await rpsClient.pair(peerIdentity: idnt2.toBase64Url());
    expect(result, equals(false));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
