import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RsaKeyManager {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _privateKeyKey = 'rsa_private_key';
  static const String _publicKeyKey = 'rsa_public_key';

  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>? _keyPair;

  Future<AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>>
      generateKeyPair() async {
    final keyGen = RSAKeyGenerator();
    keyGen.init(
      ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
        SecureRandom('Fortuna')
          ..seed(KeyParameter(Uint8List.fromList(_generateSeed()))),
      ),
    );

    final pair = keyGen.generateKeyPair();
    _keyPair = AsymmetricKeyPair(
      pair.publicKey as RSAPublicKey,
      pair.privateKey as RSAPrivateKey,
    );

    await _saveKeys(_keyPair!);
    return _keyPair!;
  }

  Future<AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>?>
      loadOrGenerate() async {
    if (_keyPair != null) return _keyPair;

    final privatePem = await _storage.read(key: _privateKeyKey);
    final publicPem = await _storage.read(key: _publicKeyKey);

    if (privatePem != null && publicPem != null) {
      _keyPair = AsymmetricKeyPair(
        _parsePublicKey(publicPem),
        _parsePrivateKey(privatePem),
      );
      return _keyPair;
    }

    return await generateKeyPair();
  }

  String? getPublicKeyPem() {
    return _keyPair?.publicKey != null
        ? _encodePublicKey(_keyPair!.publicKey)
        : null;
  }

  RSAPrivateKey? getPrivateKey() {
    return _keyPair?.privateKey;
  }

  String _encodePublicKey(RSAPublicKey key) {
    return base64Encode([
      ..._encodeBigInt(key.modulus!),
      ..._encodeBigInt(key.exponent!),
    ]);
  }

  String _encodePrivateKey(RSAPrivateKey key) {
    return base64Encode([
      ..._encodeBigInt(key.modulus!),
      ..._encodeBigInt(key.exponent!),
      ..._encodeBigInt(key.privateExponent!),
    ]);
  }

  RSAPublicKey _parsePublicKey(String pem) {
    final data = base64Decode(pem);
    return RSAPublicKey(
      _decodeBigInt(data.sublist(0, 256)),
      _decodeBigInt(data.sublist(256, 512)),
    );
  }

  RSAPrivateKey _parsePrivateKey(String pem) {
    final data = base64Decode(pem);
    return RSAPrivateKey(
      _decodeBigInt(data.sublist(0, 256)),
      _decodeBigInt(data.sublist(256, 512)),
      _decodeBigInt(data.sublist(512)),
      null,
      null,
    );
  }

  Future<void> _saveKeys(AsymmetricKeyPair pair) async {
    await _storage.write(
      key: _publicKeyKey,
      value: _encodePublicKey(pair.publicKey as RSAPublicKey),
    );
    await _storage.write(
      key: _privateKeyKey,
      value: _encodePrivateKey(pair.privateKey as RSAPrivateKey),
    );
  }

  List<int> _encodeBigInt(BigInt value) {
    final bytes = <int>[];
    var v = value;
    while (v != BigInt.zero) {
      bytes.insert(0, (v & BigInt.from(0xFF)).toInt());
      v = v >> 8;
    }
    return bytes.isEmpty ? [0] : bytes;
  }

  BigInt _decodeBigInt(List<int> bytes) {
    BigInt result = BigInt.zero;
    for (final byte in bytes) {
      result = (result << 8) + BigInt.from(byte);
    }
    return result;
  }

  List<int> _generateSeed() {
    return List.generate(
      32,
      (i) => DateTime.now().microsecondsSinceEpoch % 256,
    );
  }

  static RSAPublicKey parsePublicKey(String pem) {
    final data = base64Decode(pem);
    return RSAPublicKey(
      _decodeBigIntStatic(data.sublist(0, 256)),
      _decodeBigIntStatic(data.sublist(256, 512)),
    );
  }

  static BigInt _decodeBigIntStatic(List<int> bytes) {
    BigInt result = BigInt.zero;
    for (final byte in bytes) {
      result = (result << 8) + BigInt.from(byte);
    }
    return result;
  }
}
