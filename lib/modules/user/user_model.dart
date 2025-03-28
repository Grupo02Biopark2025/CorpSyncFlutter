class UserModel {
  final String name;
  final String email;
  final String? profileImageBase64;

  UserModel({required this.name, required this.email, this.profileImageBase64});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'],
      email: json['email'],
      profileImageBase64: json['profileImage'],
    );
  }
}