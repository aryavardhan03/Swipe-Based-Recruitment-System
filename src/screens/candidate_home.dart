// candidate_home.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';
import 'career_guidance.dart';
import 'resume_upload.dart';
import 'login_screen.dart';
import 'candidate_matches.dart';
import 'candidate_profile.dart';

class CandidateHome extends StatefulWidget {
  const CandidateHome({super.key});

  @override
  State<CandidateHome> createState() => _CandidateHomeState();
}

class _CandidateHomeState extends State<CandidateHome>
    with SingleTickerProviderStateMixin {

  int currentIndex = 0;
  double position = 0;
  String swipeStatus = "";

  late AnimationController _controller;
  late Animation<double> _animation;

  final String candidateId =
      FirebaseAuth.instance.currentUser!.uid;

  List<String> candidateSkills = [];
  bool skillsLoaded = false;

  @override
  void initState() {
    super.initState();
    fetchSkills();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = Tween<double>(begin: 0, end: 0)
        .animate(_controller)
      ..addListener(() {
        setState(() {
          position = _animation.value;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> fetchSkills() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(candidateId)
        .get();

    if (doc.exists && doc.data()?['skills'] != null) {
      candidateSkills =
          List<String>.from(doc.data()!['skills']);
    }

    setState(() => skillsLoaded = true);
  }

  Future<void> saveSwipe({
    required String jobId,
    required String employerId,
    required bool isLike,
    required int compatibilityScore,
  }) async {

    await FirebaseFirestore.instance.collection('swipes').add({
      'fromId': candidateId,
      'toId': employerId,
      'jobId': jobId,
      'type': isLike ? 'like' : 'reject',
      'compatibilityScore': compatibilityScore,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeSwipe(bool isRight, JobModel job) async {

  int score = 0;

  if (isRight && candidateSkills.isNotEmpty) {
    try {

      score = await ApiService.getCompatibilityScore(
        candidateSkills,
        job.requiredSkills,
      );

    } catch (_) {

      final matchedSkills = candidateSkills
          .where((skill) =>
              job.requiredSkills
                  .map((s) => s.toLowerCase())
                  .contains(skill.toLowerCase()))
          .length;

      if (job.requiredSkills.isNotEmpty) {
        score = ((matchedSkills / job.requiredSkills.length) * 100).round();
      }
    }
  }

  saveSwipe(
    jobId: job.id,
    employerId: job.employerId,
    isLike: isRight,
    compatibilityScore: score,
  );
}

  @override
  Widget build(BuildContext context) {

    if (!skillsLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 155, 165, 178),
              Color.fromARGB(255, 34, 45, 63),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              Padding(
  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
  child: Row(
    children: [

      // Title
      const Expanded(
        child: Text(
          "Discover Jobs",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 4, 38, 39),
          ),
        ),
      ),

      // Icons
      Row(
        children: [

          // Profile
          IconButton(
            icon: const Icon(
              Icons.person,
              color: Color.fromARGB(255, 6, 70, 71),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CandidateProfile(),
                ),
              );
            },
          ),

          // Matches
          IconButton(
            icon: const Icon(
              Icons.favorite,
              color: Color.fromARGB(255, 6, 70, 71),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CandidateMatches(),
                ),
              );
            },
          ),

          // Career Guidance
          IconButton(
            icon: const Icon(
              Icons.school,
              color: Color.fromARGB(255, 6, 70, 71),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CareerGuidance(),
                ),
              );
            },
          ),

          // Resume Upload
          IconButton(
            icon: const Icon(
              Icons.upload_file,
              color: Color.fromARGB(255, 6, 70, 71),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ResumeUpload(),
                ),
              );
            },
          ),

          // Logout
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Color.fromARGB(255, 6, 70, 71),
            ),
            onPressed: () async {

              await FirebaseAuth.instance.signOut();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      )
    ],
  ),
),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('jobs')
                      .orderBy('createdAt',descending:true)
                      .snapshots(),
                  builder: (context, snapshot) {

                    if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No jobs available",
                          style: TextStyle(
                              color: Color.fromARGB(255, 28, 29, 26),
                              fontSize: 20),
                        ),
                      );
                    }

                   final jobs = snapshot.data!.docs.map((doc) {

  final data = doc.data() as Map<String, dynamic>;

  // Get job skills
  List<String> jobSkills = List<String>.from(data['skills']);

  // Count matching skills
  int matchCount = jobSkills.where((skill) =>
      candidateSkills
          .map((s) => s.toLowerCase())
          .contains(skill.toLowerCase())
  ).length;

  // Calculate compatibility score
  int score = 0;

  if (jobSkills.isNotEmpty) {
    score = ((matchCount / jobSkills.length) * 100).round();
  }

  // Return JobModel with score
  return JobModel(
    id: doc.id,
    title: data['title'],
    company: data['company'] ?? "",
    location: data['location'] ?? "",
    requiredSkills: List<String>.from(data['skills']),
    experience: data['experience'],
    employerId: data['CompanyId'],
    compatibilityScore: score,   // ⭐ important
  );

}).toList();
                      

                    jobs.sort(
                      (a,b)=> (b.compatibilityScore??0)
                         .compareTo(a.compatibilityScore??0),
                    );

                    if (currentIndex >= jobs.length) {
                      return const Center(
                        child: Text(
                          "No more jobs",
                          style: TextStyle(
                              color: Color.fromARGB(255, 28, 29, 26),
                              fontSize: 20),
                        ),
                      );
                    }

                    final job = jobs[currentIndex];

                   return Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [

    SizedBox(
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [

          /// Third Card
          if (currentIndex + 2 < jobs.length)
            Transform.scale(
              scale: 0.90,
              child: buildJobCard(jobs[currentIndex + 2]),
            ),

          /// Second Card
          if (currentIndex + 1 < jobs.length)
            Transform.scale(
              scale: 0.95,
              child: buildJobCard(jobs[currentIndex + 1]),
            ),

          /// Top Swipe Card
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                position += details.delta.dx;
              });
            },

            onHorizontalDragEnd: (_) async {

              double screenWidth = MediaQuery.of(context).size.width;

              if (position > 120) {

                setState(() {
                  swipeStatus = "LIKED";
                });

                _animation = Tween<double>(
                  begin: position,
                  end: screenWidth,
                ).animate(_controller);

                await _controller.forward();
                _controller.reset();

                setState(() {
                  position = 0;
                });

                final swipedJob = jobs[currentIndex];

setState(() {
  currentIndex++;
});

completeSwipe(true, swipedJob);

              } 
              else if (position < -120) {

                setState(() {
                  swipeStatus = "REJECTED";
                });

                _animation = Tween<double>(
                  begin: position,
                  end: -screenWidth,
                ).animate(_controller);

                await _controller.forward();
                _controller.reset();

                setState(() {
                  position = 0;
                });

                final swipedJob = jobs[currentIndex];

setState(() {
  currentIndex++;
});

completeSwipe(false, swipedJob);
              } 
              else {

                _animation = Tween<double>(
                  begin: position,
                  end: 0,
                ).animate(_controller);

                await _controller.forward();
                _controller.reset();

                setState(() {
                  position = 0;
                });

              }

              Future.delayed(const Duration(milliseconds: 250), () {
                if (mounted) {
                  setState(() {
                    swipeStatus = "";
                  });
                }
              });
            },

            child: Transform.translate(
              offset: Offset(position, 0),
              child: buildJobCard(jobs[currentIndex]),
            ),
          ),

        ],
      ),
    ),

    const SizedBox(height: 30),

    if (swipeStatus.isNotEmpty)
      Text(
        swipeStatus,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: swipeStatus == "LIKED"
              ? Colors.green
              : Colors.red,
        ),
      ),

  ],
                   );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildJobCard(JobModel job) {
  return Container(
    width: 260,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 221, 225, 225),
      borderRadius: BorderRadius.circular(25),
      boxShadow: const [
        BoxShadow(
          color: Color.fromARGB(66, 14, 13, 13),
          blurRadius: 15,
          offset: Offset(0, 8),
        )
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Icon(
          Icons.work,
          size: 55,
          color: Color.fromARGB(255, 50, 91, 118),
        ),

        const SizedBox(height: 16),

        Text(
          job.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          job.company,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          job.location,
          style: const TextStyle(
            color: Color.fromARGB(255, 104, 110, 115),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "Experience: ${job.experience}",
          style: const TextStyle(
            color: Color.fromARGB(255, 104, 110, 115),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "Match Score: ${job.compatibilityScore ?? 0}%",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 52, 119, 54),
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          "Required Skills",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: job.requiredSkills.map(
            (skill) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 20, 97, 103)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(23),
              ),
              child: Text(skill),
            )
  ).toList(),
        ),

      ],
    ),
  );
  }
}