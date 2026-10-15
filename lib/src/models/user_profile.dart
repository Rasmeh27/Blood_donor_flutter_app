import 'gender.dart';

// Corresponde a UserResponse del backend
class UserProfile {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final Gender? gender;
  final String? location;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.gender,
    this.location,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      gender: Gender.fromApi(json['gender'] as String?),
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'gender': gender?.apiValue,
        'location': location,
      };
}
