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

import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'package:zxbase_api_client/zxbase_api_client.dart';
import 'package:zxbase_crypto/zxbase_crypto.dart';
import 'package:zxbase_model/zxbase_model.dart';

void main() {
  const host = 'alpha.zxbase.com';

  final metadata = 'Test:APC:T1';
  final metadata2 = 'Test:APC:T1:D2';

  String deviceId = const Uuid().v4().toString();
  String deviceId2 = const Uuid().v4().toString();
  String peerId = const Uuid().v4().toString();

  SimpleKeyPair kp;
  SimplePublicKey pubK;
  late Identity me;
  RpsClient rpsClient = RpsClient();
  http.Client? httpClient;

  SimpleKeyPair peerKp;
  SimplePublicKey peerPubK;
  late Identity peer;

  late SimpleKeyPair kp2;
  late SimplePublicKey pubK2;
  late Identity idnt2;
  RpsClient rpsClient2 = RpsClient();

  setUpAll(() async {
    kp = await PKCrypto.generateKeyPair();
    pubK = await kp.extractPublicKey();
    me = Identity(deviceId: deviceId, publicKey: pubK);
    rpsClient.init(host: host, identity: me, keyPair: kp);

    kp2 = await PKCrypto.generateKeyPair();
    pubK2 = await kp2.extractPublicKey();
    idnt2 = Identity(deviceId: deviceId2, publicKey: pubK2);
    rpsClient2.init(host: host, identity: idnt2, keyPair: kp2);
  });

  test('Acquire registration token', () async {
    httpClient = rpsClient.httpClient;
    final result = await rpsClient.obtainToken(topic: registrationTopic);
    expect(result, equals(true));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Register the device', () async {
    final result = await rpsClient.register(metadata: metadata);
    expect(result, equals(true));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Acquire default token', () async {
    bool result = await rpsClient.obtainToken(topic: defaultTopic);
    expect(result, equals(true));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Pair the device with unknown peer', () async {
    peerKp = await PKCrypto.generateKeyPair();
    peerPubK = await peerKp.extractPublicKey();
    peer = Identity(deviceId: peerId, publicKey: peerPubK);
    final result = await rpsClient.pair(peerIdentity: peer.toBase64Url());
    expect(result, equals(false));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Get device peers should be empty', () async {
    final result = await rpsClient.getPeers();
    expect(result, equals([]));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Create channel should fail', () async {
    final result = await rpsClient.channel(peerId: peerId, app: 'messenger');
    expect(result, equals(''));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Check http client is preserved', () async {
    expect(identityHashCode(rpsClient.httpClient),
        equals(identityHashCode(httpClient)));
  });

  test('Get vault channel should fail', () async {
    final result = await rpsClient.channel(peerId: 'a', app: 'vault');
    expect(result, equals(''));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Acquire registration token 2', () async {
    final result = await rpsClient2.obtainToken(topic: registrationTopic);
    expect(result, equals(true));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Register the device 2', () async {
    final result = await rpsClient2.register(metadata: metadata2);
    expect(result, equals(true));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Acquire default token device 2', () async {
    bool result = await rpsClient2.obtainToken(topic: defaultTopic);
    expect(result, equals(true));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Pair device 2 and device 1', () async {
    final result = await rpsClient2.pair(peerIdentity: me.toBase64Url());
    expect(result, equals(false));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Pair device 1 and device 2', () async {
    final result = await rpsClient.pair(peerIdentity: idnt2.toBase64Url());
    expect(result, equals(true));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Get device peers', () async {
    final result = await rpsClient.getPeers();
    expect(
        result,
        equals([
          {'deviceid': idnt2.deviceId, 'metadata': 'Test:APC:T1:D2'}
        ]));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Create channel', () async {
    final result =
        await rpsClient.channel(peerId: idnt2.deviceId, app: 'messenger');
    Uuid.parse(result);
    expect(result, isNot(equals('')));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Get vault channel', () async {
    final result =
        await rpsClient.channel(peerId: idnt2.deviceId, app: 'vault');
    Uuid.parse(result);
    expect(result, isNot(equals('')));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Get MOTD', () async {
    MOTD dummyMOTD = MOTD(
        id: 1,
        message: 'Message',
        notes: 'Notes',
        date: DateTime.now().toUtc());
    expect(dummyMOTD.id, equals(1));

    MOTD anotherMOTD = MOTD.fromJson({
      'id': 1,
      'message': 'Message',
      'notes': 'Notes',
      'date': DateTime.now().toUtc().toIso8601String()
    });
    expect(anotherMOTD.id, equals(1));

    var rv = await rpsClient.getMotd();
    expect(rv, isNot(equals(null)));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
