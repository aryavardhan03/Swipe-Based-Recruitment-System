import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // READ JOBS
  Future<List<JobModel>> fetchJobs() async {
    final snapshot = await _db.collection('jobs').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return JobModel(
        id: doc.id,
        title: data['title'],
        company: data['company']??"",
        location: data['location']??"",
        requiredSkills: List<String>.from(data['skills']),
        experience: data['experience'],
        employerId: data['CompanyId'], // ✅ FIXED
      );
    }).toList();
  }
}
