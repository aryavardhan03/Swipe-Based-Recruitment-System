import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CareerGuidance extends StatefulWidget {
  const CareerGuidance({super.key});

  @override
  State<CareerGuidance> createState() => _CareerGuidanceState();
}

class _CareerGuidanceState extends State<CareerGuidance> {

  final String userId = FirebaseAuth.instance.currentUser!.uid;

  List<String> userSkills = [];
  List<String> recommendedSkills = [];

  bool loading = true;

  // Industry skills list
  final List<String> marketSkills = [
    "Flutter",
    "Dart",
    "Firebase",
    "REST API",
    "Git",
    "Node.js",
    "MongoDB",
    "UI/UX",
  ];

  // Learning resources
  final Map<String, String> learningResources = {
    "Flutter":
        "Learn Flutter - https://docs.flutter.dev",
    "Firebase":
        "Firebase Course - https://firebase.google.com/docs",
    "REST API":
        "REST API Tutorial - https://www.restapitutorial.com/",
    "Git":
        "Git Course - https://git-scm.com/docs",
    "Node.js":
        "Node.js Guide - https://nodejs.org/en/docs",
    "MongoDB":
        "MongoDB University - https://learn.mongodb.com/",
  };

  @override
  void initState() {
    super.initState();
    loadUserSkills();
  }

  Future<void> loadUserSkills() async {

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (doc.exists && doc.data()?['skills'] != null) {
      userSkills = List<String>.from(doc['skills']);
    }

    recommendedSkills = marketSkills
        .where((skill) => !userSkills.contains(skill))
        .toList();

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Career Guidance"),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(23),
              children: [

                const Text(
                  "Your Skills",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: userSkills
                      .map((skill) => Chip(
                            label: Text(skill),
                            backgroundColor:
                                const Color.fromARGB(255, 200, 225, 230),
                          ))
                      .toList(),
                ),

                const SizedBox(height: 30),

                const Text(
                  "Recommended Skills",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                ...recommendedSkills.map(
                  (skill) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.trending_up),
                      title: Text(skill),
                      subtitle: const Text(
                        "Recommended skill for better job opportunities",
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  "Learning Resources",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                ...recommendedSkills.map(
                  (skill) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.school),
                      title: Text(skill),
                      subtitle: Text(
                        learningResources[skill] ??
                            "Search online course",
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}