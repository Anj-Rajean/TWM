class User {
  final String username;
  final String? publicKey;

  User({required this.username, this.publicKey});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] as String,
      publicKey: json['public_key'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'username': username,
    'public_key': publicKey,
  };
}
