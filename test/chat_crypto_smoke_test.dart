import 'package:flutter_test/flutter_test.dart';
import 'package:cryptography/cryptography.dart';

/// Smoke checks that X25519 + AES-GCM primitives used by ChatCrypto work.
void main() {
  test('X25519 shared secrets match and AES-GCM round-trips', () async {
    final x25519 = X25519();
    final alice = await x25519.newKeyPair();
    final bob = await x25519.newKeyPair();
    final alicePub = await alice.extractPublicKey();
    final bobPub = await bob.extractPublicKey();

    final aShared = await x25519.sharedSecretKey(
      keyPair: alice,
      remotePublicKey: bobPub,
    );
    final bShared = await x25519.sharedSecretKey(
      keyPair: bob,
      remotePublicKey: alicePub,
    );
    expect(await aShared.extractBytes(), await bShared.extractBytes());

    final digest = await Sha256().hash(await aShared.extractBytes());
    final key = SecretKey(digest.bytes);
    final aes = AesGcm.with256bits();
    final box = await aes.encrypt(utf8Encode('hello farmora'), secretKey: key);
    final clear = await aes.decrypt(box, secretKey: key);
    expect(String.fromCharCodes(clear), 'hello farmora');
  });
}

List<int> utf8Encode(String s) => s.codeUnits;
