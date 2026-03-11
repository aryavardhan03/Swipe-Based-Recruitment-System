// employer_home.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'job_posting.dart';
import 'login_screen.dart';
import 'employer_matches.dart';
import 'employer_profile.dart';
import 'edit_job.dart';
import 'employer_jobs.dart';
import 'package:url_launcher/url_launcher.dart';

class EmployerHome extends StatefulWidget {
  const EmployerHome({super.key});

  @override
  State<EmployerHome> createState() => _EmployerHomeState();
}

class _EmployerHomeState extends State<EmployerHome> 
  with SingleTickerProviderStateMixin {

  int currentIndex = 0;
  double position = 0;
  String swipeStatus= "";

  List<UserModel> candidates = [];
bool loadingCandidates = true;
String jobId = "";

  late AnimationController _controller;
  late Animation<double> _animation;

  final String employerId =
      FirebaseAuth.instance.currentUser!.uid;
  @override
void initState() {
  super.initState();

  _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  _animation = Tween<double>(begin: 0, end: 0).animate(_controller)
    ..addListener(() {
      setState(() {
        position = _animation.value;
      });
    });

  loadJobId().then((_) {  // ⭐ ADD THIS LINE
  loadCandidates();
  });
}

  Future<List<String>> getEmployerJobIds() async {

  final jobSnapshot = await FirebaseFirestore.instance
      .collection('jobs')
      .where('CompanyId', isEqualTo: employerId)
      .get();

  if (jobSnapshot.docs.isEmpty) return [];

  return jobSnapshot.docs.map((doc) => doc.id).toList();
}
 Future<void> loadJobId() async {

  final jobIds = await getEmployerJobIds();

  if (jobIds.isNotEmpty) {
    setState(() {
      jobId = jobIds.first;
    });
  }

}

  Future<List<UserModel>> 
  fetchCandidatesWhoLiked(String jobId) async {

    final swipeSnapshot = await FirebaseFirestore.instance
        .collection('swipes')
        .where('toId', isEqualTo: employerId)
        .where('jobId', isEqualTo: jobId)
        .where('type', isEqualTo: 'like')
        .get();

    if (swipeSnapshot.docs.isEmpty) return [];

    final candidateIds =
        swipeSnapshot.docs.map((d) => d['fromId'] as String).toList();

    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: candidateIds)
        .get();

    return swipeSnapshot.docs.map((swipeDoc) {

      final candidateId = swipeDoc['fromId'];
      final compatibility = swipeDoc['compatibilityScore'] ?? 0;

      final userDoc = userSnapshot.docs
       .firstWhere((doc) => doc.id == candidateId);

      final data = userDoc.data();

      return UserModel(
        id: userDoc.id,
        name: data['name'],
        role: data['role'],
        skills: List<String>.from(data['skills']),
        compatibilityScore: compatibility,
        profileImage: data['profileImage'],
        resumeUrl: data['resumeUrl'],
      );

    }).toList()
    
  ..sort((a, b) =>
      (b.compatibilityScore ?? 0)
          .compareTo(a.compatibilityScore ?? 0));
  }
  Future<void> loadCandidates() async {

  final jobIds = await getEmployerJobIds();

  if (jobIds.isEmpty) {
    setState(() {
      loadingCandidates = false;
    });
    return;
  }

  jobId = jobIds.first;

  final result = await fetchCandidatesWhoLiked(jobId);

  setState(() {
    candidates = result;
    loadingCandidates = false;
  });
}

  Future<void> saveEmployerSwipe({
    required String candidateId,
    required String jobId,
    required bool isLike,
  }) async {
    await FirebaseFirestore.instance.collection('swipes').add({
      'fromId': employerId,
      'toId': candidateId,
      'jobId': jobId,
      'type': isLike ? 'like' : 'reject',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createMatch({
    required UserModel candidate,
    required String jobId,
  }) async {

    final candidateSwipe = await FirebaseFirestore.instance
        .collection('swipes')
        .where('fromId', isEqualTo: candidate.id)
        .where('toId', isEqualTo: employerId)
        .where('jobId', isEqualTo: jobId)
        .where('type', isEqualTo: 'like')
        .limit(1)
        .get();

    if (candidateSwipe.docs.isEmpty) return;

    final swipeData = candidateSwipe.docs.first.data();

    int compatibility = 0;

    if (swipeData.containsKey('compatibilityScore')) {
      final value = swipeData['compatibilityScore'];
      if (value != null) {
         compatibility = (value as num).toInt();
      }
    }

    final existingMatch = await FirebaseFirestore.instance
        .collection('matches')
        .where('candidateId', isEqualTo: candidate.id)
        .where('jobId', isEqualTo: jobId)
        .limit(1)
        .get();

    if (existingMatch.docs.isNotEmpty) return;

    final matchRef =
        FirebaseFirestore.instance.collection('matches').doc();

    await matchRef.set({
      'candidateId': candidate.id,
      'employerId': employerId,
      'jobId': jobId,
      'compatibilityScore': compatibility,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(matchRef.id)
        .set({
      'candidateId': candidate.id,
      'employerId': employerId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("🎉 It's a Match!"),
          content: Text("Compatibility: $compatibility%"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

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

              // 🔹 Top Bar
            Padding(
  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
  child: Row(
    children: [

      // Title
      const Expanded(
        child: Text(
          "Candidate Feed",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 4, 38, 39),
          ),
        ),
      ),

      // Scrollable Icons (prevents overflow)
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [

            // Jobs List
            IconButton(
              icon: const Icon(Icons.list, color: Color.fromARGB(255, 6, 70, 71)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EmployerJobs(),
                  ),
                );
              },
            ),

            // Company Profile
            IconButton(
              icon: const Icon(Icons.business, color: Color.fromARGB(255, 6, 70, 71)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EmployerProfile(),
                  ),
                );
              },
            ),

            // Matches
            IconButton(
              icon: const Icon(Icons.favorite, color: Color.fromARGB(255, 6, 70, 71)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EmployerMatches(),
                  ),
                );
              },
            ),

            // Post Job
            IconButton(
              icon: const Icon(Icons.work, color: Color.fromARGB(255, 6, 70, 71)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const JobPosting(),
                  ),
                );
              },
            ),

            // Logout
            IconButton(
              icon: const Icon(Icons.logout, color: Color.fromARGB(255, 6, 70, 71)),
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
        ),
      ),
    ],
  ),
),

          Expanded(
  child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('swipes')
        .where('toId', isEqualTo: employerId)
        .where('jobId', isEqualTo: jobId)
        .where('type', isEqualTo: 'like')
        .snapshots(),
    builder: (context, snapshot) {

      if (!snapshot.hasData) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      final swipeDocs = snapshot.data!.docs;

      if (swipeDocs.isEmpty) {
        return const Center(
          child: Text(
            "No candidates liked your job yet",
            style: TextStyle(
              color: Color.fromARGB(255, 11, 12, 12),
              fontSize: 20,
            ),
          ),
        );
      }

if (currentIndex >= candidates.length) {
  return const Center(
    child: Text(
      "No more candidates",
      style: TextStyle(fontSize: 20),
    ),
  );
}

return buildSwipeUI(candidates);
    },
  ),
),
            ],
          ),
        ),
      ),
      );
  }  

Widget buildSwipeUI(List<UserModel> candidates) {

  if (currentIndex >= candidates.length) {
    return const Center(
      child: Text(
        "No more candidates",
        style: TextStyle(fontSize: 20),
      ),
    );
  }

  final candidate = candidates[currentIndex % candidates.length];

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        SizedBox(
          height: 320,
          child: Stack(
  alignment: Alignment.center,
  children: [

    Transform.scale(
      scale: 0.90,
      child: buildCandidateCard(
        candidates[(currentIndex + 2) % candidates.length],
      ),
    ),

    Transform.scale(
      scale: 0.95,
      child: buildCandidateCard(
        candidates[(currentIndex + 1) % candidates.length],
      ),
    ),

    GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          position += details.delta.dx;
        });
      },

      onHorizontalDragEnd: (_) async {

        double screenWidth =
            MediaQuery.of(context).size.width;

        final swipedCandidate =
            candidates[currentIndex % candidates.length];

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
            currentIndex++;
          });

          await saveEmployerSwipe(
            candidateId: swipedCandidate.id,
            jobId: jobId,
            isLike: true,
          );

          await createMatch(
            candidate: swipedCandidate,
            jobId: jobId,
          );
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
            currentIndex++;
          });

          await saveEmployerSwipe(
            candidateId: swipedCandidate.id,
            jobId: jobId,
            isLike: false,
          );
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
      },

      child: Transform.translate(
        offset: Offset(position, 0),
        child: buildCandidateCard(candidate),
      ),
    ),
  ],
)
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
    ),
  );
}

      

  Widget buildCandidateCard(UserModel candidate) {
    return Stack(
      children: [

        Container(
          width: 260,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 221, 225, 225),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(66, 14, 13, 13),
                blurRadius: 15,
                offset: Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              CircleAvatar(
                radius: 30,
                backgroundImage: candidate.profileImage != null
                  ? NetworkImage(candidate.profileImage!)
                  : null,
                child: candidate.profileImage == null
                  ? const Icon(Icons.person, size: 35)
                  : null,
              ),

              const SizedBox(height: 20),

              Text(
                candidate.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Skills",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: candidate.skills
                    .map(
                      (skill) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 20, 97, 103).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(skill),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 20),

              /// ⭐ COMPATIBILITY SCORE (ADDED)
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                   color: getCompatibilityColor(
                     candidate.compatibilityScore ?? 0),
                     borderRadius: BorderRadius.circular(20),
                   ),
                   child: Text(
                      "${candidate.compatibilityScore ?? 0}% Match",
                      style: const TextStyle(
                        color: Color.fromARGB(255, 221, 224, 221),
                        fontWeight: FontWeight.bold,
                      ),
                   ),
              ),
            ],
          ),
        ),
        
        Positioned(
  top: 10,
  right: 10,
  child: IconButton(
    icon: const Icon(
      Icons.picture_as_pdf,
      color: Color.fromARGB(255, 73, 115, 145),
      size: 28,
    ),
    onPressed: () {

      if (candidate.resumeUrl != null) {

        launchUrl(
          Uri.parse(candidate.resumeUrl!),
        );

      }

    },
  ),
),

        if (position > 20)
          const Positioned(
            top: 40,
            left: 20,
            child: Text(
              "LIKE",
              style: TextStyle(
                color: Colors.green,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        if (position < -20)
          const Positioned(
            top: 40,
            right: 20,
            child: Text(
              "NOPE",
              style: TextStyle(
                color: Colors.red,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
}
Color getCompatibilityColor(int score) {

  if (score >= 90) {
    return const Color.fromARGB(255, 98, 196, 101);
  }

  if (score >= 70) {
    return const Color.fromARGB(255, 196, 176, 98);
  }

  return const Color.fromARGB(255, 196, 104, 98);
}