import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
import '../services/resume_nlp_service.dart';

class ResumeUpload extends StatefulWidget {
  const ResumeUpload({super.key});

  @override
  State<ResumeUpload> createState() => _ResumeUploadState();
}

class _ResumeUploadState extends State<ResumeUpload> {

  bool isUploading = false;
  List<String> extractedSkills = [];

  Future<void> pickAndUploadResume() async {

    try {

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null) return;

      final file = File(result.files.single.path!);
      final fileName = path.basename(file.path);

      setState(() {
        isUploading = true;
        extractedSkills = [];
      });

      final userId = FirebaseAuth.instance.currentUser!.uid;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('resumes/$userId/$fileName');

      // 1️⃣ Upload
      await storageRef.putFile(file);

      // 2️⃣ Get URL
      final downloadUrl = await storageRef.getDownloadURL();

      // 3️⃣ Save URL
      await FirebaseFirestore.instance
          .collection('resumes')
          .doc(userId)
          .set({
        'resumeUrl': downloadUrl,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
           .collection('users')
           .doc(userId)
           .update({
          'resumeUrl':downloadUrl,
           });

      // 4️⃣ NLP extraction
      final skills =
          await ResumeNLPService.extractSkills(downloadUrl);

      // 5️⃣ Update user skills
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'skills': skills,
      });

      setState(() {
        isUploading = false;
        extractedSkills = skills;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Resume processed successfully"),
        ),
      );

    } catch (e) {

      setState(() => isUploading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
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
          child: Center(
            child: Container(
              height:300,
              width: 260,
              padding: const EdgeInsets.all(23),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 221, 225, 225),
                borderRadius:
                    BorderRadius.circular(25),
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
                children: [

                  const Icon(
                    Icons.description,
                    size: 75,
                    color: Color.fromARGB(255, 50, 91, 118),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Upload Your Resume",
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 40),

                  if (isUploading)
                    Column(
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text("Processing resume..."),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 47, 108, 130),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: pickAndUploadResume,
                        child: const Text(
                          "Upload PDF Resume",
                          style: TextStyle(
                              fontSize: 16),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  if (extractedSkills.isNotEmpty)
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        const Text(
                          "Extracted Skills:",
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: extractedSkills
                              .map(
                                (skill) => Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 10,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color: const Color.fromARGB(255, 20, 97, 103)
                                        .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(
                                            23),
                                  ),
                                  child: Text(skill),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}