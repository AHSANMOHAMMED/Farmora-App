import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/localization/l10n.dart';

/// X25519 + AES-GCM chat crypto. Public keys live on the user profile;
/// private keys stay in secure storage (`farmora_x25519_sk`).
class ChatCrypto {
  ChatCrypto._();
  static final ChatCrypto instance = ChatCrypto._();

  static const _skKey = 'farmora_x25519_sk';
  static const ciphertextPrefix = 'farmora2:';
  static const currentCiphertextPrefix = 'farmora3:';

  final _storage = const FlutterSecureStorage();
  final _x25519 = X25519();
  final _aesGcm = AesGcm.with256bits();
  final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  SimpleKeyPair? _cachedPair;

  Future<SimpleKeyPair> ensureKeyPair() async {
    if (_cachedPair != null) return _cachedPair!;
    final existing = await _storage.read(key: _skKey);
    if (existing != null && existing.isNotEmpty) {
      final seed = base64Url.decode(existing);
      _cachedPair = await _x25519.newKeyPairFromSeed(seed);
      return _cachedPair!;
    }
    final pair = await _x25519.newKeyPair();
    final seed = await pair.extractPrivateKeyBytes();
    await _storage.write(key: _skKey, value: base64UrlEncode(seed));
    _cachedPair = pair;
    return pair;
  }

  Future<String> publicKeyBase64() async {
    final pair = await ensureKeyPair();
    final pub = await pair.extractPublicKey();
    return base64UrlEncode(pub.bytes);
  }

  Future<SecretKey> _sharedSecret(String peerPublicKeyB64) async {
    final pair = await ensureKeyPair();
    final peerBytes = base64Url.decode(peerPublicKeyB64);
    final peerKey = SimplePublicKey(peerBytes, type: KeyPairType.x25519);
    return _x25519.sharedSecretKey(keyPair: pair, remotePublicKey: peerKey);
  }

  /// Encrypt plaintext for [peerPublicKeyB64]. Returns `farmora3:<b64>`.
  Future<String> encrypt({
    required String plaintext,
    required String peerPublicKeyB64,
  }) async {
    final shared = await _sharedSecret(peerPublicKeyB64);
    // HKDF domain-separates chat encryption keys from other X25519 uses.
    final aesKey = await _hkdf.deriveKey(
      secretKey: shared,
      info: utf8.encode('farmora/chat/message/aes-gcm/v3'),
    );
    final secretBox = await _aesGcm.encrypt(
      utf8.encode(plaintext),
      secretKey: aesKey,
    );
    final packed = BytesBuilder()
      ..add(secretBox.nonce)
      ..add(secretBox.cipherText)
      ..add(secretBox.mac.bytes);
    return '$currentCiphertextPrefix${base64UrlEncode(packed.toBytes())}';
  }

  /// Decrypt `farmora2:` ciphertext. Falls back for legacy `farmora1:` pad.
  Future<String> decrypt({
    required String ciphertext,
    required String peerPublicKeyB64,
  }) async {
    if (ciphertext.startsWith('farmora1:')) {
      var out = ciphertext.substring('farmora1:'.length);
      return out.replaceAll(RegExp(r'\.+$'), '');
    }
    final isV3 = ciphertext.startsWith(currentCiphertextPrefix);
    final isV2 = ciphertext.startsWith(ciphertextPrefix);
    if (!isV3 && !isV2) {
      return ciphertext;
    }
    final prefix = isV3 ? currentCiphertextPrefix : ciphertextPrefix;
    final raw = base64Url.decode(ciphertext.substring(prefix.length));
    if (raw.length < 12 + 16) return L10n.current.chatUndecryptable;
    final nonce = raw.sublist(0, 12);
    final mac = Mac(raw.sublist(raw.length - 16));
    final cipherText = raw.sublist(12, raw.length - 16);
    final shared = await _sharedSecret(peerPublicKeyB64);
    final SecretKey aesKey;
    if (isV3) {
      aesKey = await _hkdf.deriveKey(
        secretKey: shared,
        info: utf8.encode('farmora/chat/message/aes-gcm/v3'),
      );
    } else {
      // Read existing farmora2 messages during migration.
      final sharedBytes = await shared.extractBytes();
      final digest = await Sha256().hash(sharedBytes);
      aesKey = SecretKey(digest.bytes);
    }
    final clear = await _aesGcm.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: mac),
      secretKey: aesKey,
    );
    return utf8.decode(clear);
  }
}
