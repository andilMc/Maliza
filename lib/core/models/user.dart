class User {
  final int? id;
  final String email;
  final String? password;

  User({this.id, required this.email, this.password});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['account_id'] as int,
      email: json['email'] as String,
      password: json['password'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'account_id': id, 'email': email, 'password': password};
  }
}
