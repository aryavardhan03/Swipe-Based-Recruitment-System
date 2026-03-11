class UserModel {
  final String id;
  final String name;
  final String role; // candidate / employer
  final List<String> skills;

  final int? compatibilityScore;
  final String? profileImage;
  final String? resumeUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.role,
    required this.skills,
    this.compatibilityScore,
    this.profileImage,
    this.resumeUrl,
  });
}
