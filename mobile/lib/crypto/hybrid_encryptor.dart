import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class HybridEncryptor {
  static const int _aesKeySize = 32;
  static const int _ivSize = 12;

  Uint8List _generateRandomBytes(int length) {
    final random = FortunaRandom();
    random.seed(
      KeyParameter(
        Uint8List.fromList(
          List.generate(32, (i) => DateTime.now().microsecondsSinceEpoch % 256),
        ),
      ),
    );
    return random.nextBytes(length);
  }

  Map<String, String> encrypt(String plaintext, RSAPublicKey publicKey) {
    final aesKey = _generateRandomBytes(_aesKeySize);
    final iv = _generateRandomBytes(_ivSize);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(aesKey),
          128,
          iv,
          Uint8List(0),
        ),
      );

    final ciphertext =
        cipher.process(Uint8List.fromList(utf8.encode(plaintext)));
    final encryptedKey = _rsaEncrypt(publicKey, aesKey);

    return {
      'payload': base64Encode(ciphertext),
      'iv': base64Encode(iv),
      'encrypted_key': base64Encode(encryptedKey),
    };
  }

  String decrypt(Map<String, String> encrypted, RSAPrivateKey privateKey) {
    final aesKey = _rsaDecrypt(
      privateKey,
      base64Decode(encrypted['encrypted_key']!),
    );
    final iv = base64Decode(encrypted['iv']!);
    final ciphertext = base64Decode(encrypted['payload']!);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(
          KeyParameter(aesKey),
          128,
          iv,
          Uint8List(0),
        ),
      );

    return utf8.decode(cipher.process(ciphertext));
  }

  Uint8List _rsaEncrypt(RSAPublicKey key, Uint8List data) {
    final params = RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64);
    final random = FortunaRandom();
    random.seed(KeyParameter(
        Uint8List.fromList(List.generate(32, (i) => i * 7 % 256))));
    final engine = OAEPEncoding(RSAEngine())
      ..init(true, ParametersWithRandom(params, random));
    return engine.process(data);
  }

  Uint8List _rsaDecrypt(RSAPrivateKey key, Uint8List data) {
    final params = RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64);
    final random = FortunaRandom();
    random.seed(KeyParameter(
        Uint8List.fromList(List.generate(32, (i) => i * 7 % 256))));
    final engine = OAEPEncoding(RSAEngine())
      ..init(false, ParametersWithRandom(params, random));
    return engine.process(data);
  }
}
