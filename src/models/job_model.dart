class JobModel {
  final String id;
  final String company;
  final String location;
  final String title;
  final List<String> requiredSkills;
  final String experience;
  final String employerId;   // ✅ ADD THIS

  final int? compatibilityScore;

  JobModel({
    required this.id,
    required this.company,
    required this.location,
    required this.title,
    required this.requiredSkills,
    required this.experience,
    required this.employerId,   // ✅ ADD THIS
    this.compatibilityScore,
  });
}