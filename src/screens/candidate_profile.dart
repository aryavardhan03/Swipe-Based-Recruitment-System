import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CandidateProfile extends StatefulWidget {
  const CandidateProfile({super.key});

  @override
  State<CandidateProfile> createState() => _CandidateProfileState();
}

class _CandidateProfileState extends State<CandidateProfile> {

  String imageUrl = "";
  bool loading = false;
  bool editing = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController skillsController = TextEditingController();

  final picker = ImagePicker();
  final userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  /// LOAD PROFILE DATA
  Future<void> loadProfile() async {

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (doc.exists) {

      final data = doc.data()!;

      if (data['profileImage'] != null) {
        imageUrl = data['profileImage'];
      }

      if (data['name'] != null) {
        nameController.text = data['name'];
      }

      if (data['skills'] != null) {
        skillsController.text =
            (data['skills'] as List).join(", ");
      }

      setState(() {});
    }
  }

  /// PICK PROFILE IMAGE
  Future<void> pickImage() async {

    final picked =
        await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() {
      loading = true;
    });

    final file = File(picked.path);

    final ref = FirebaseStorage.instance
        .ref()
        .child("profile_images/$userId.jpg");

    await ref.putFile(file);

    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
      "profileImage": url
    });

    setState(() {
      imageUrl = url;
      loading = false;
    });
  }

  /// UPDATE PROFILE
  Future<void> updateProfile() async {

    List<String> skillsList =
        skillsController.text
            .split(',')
            .map((s) => s.trim())
            .toList();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
      "name": nameController.text,
      "skills": skillsList
    });

    setState(() {
      editing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Profile Updated Successfully"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(23),
            child: Column(
              children: [

                /// PROFILE IMAGE
                GestureDetector(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: 70,
                    backgroundImage:
                        imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : null,
                    child: imageUrl.isEmpty
                        ? const Icon(Icons.person, size: 70)
                        : null,
                  ),
                ),

                const SizedBox(height: 25),

                loading
                    ? const CircularProgressIndicator()
                    : const Text(
                        "Tap image to change profile picture",
                      ),

                const SizedBox(height: 30),

                /// NAME FIELD
                editing
                    ? TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Name",
                          border: OutlineInputBorder(),
                        ),
                      )
                    : Text(
                        nameController.text,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                const SizedBox(height: 20),

                /// SKILLS FIELD
                editing
                    ? TextField(
                        controller: skillsController,
                        decoration: const InputDecoration(
                          labelText: "Skills (comma separated)",
                          border: OutlineInputBorder(),
                        ),
                      )
                    : Text(
                        skillsController.text,
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),

                const SizedBox(height: 30),

                /// BUTTON
                editing
                    ? ElevatedButton(
                        onPressed: updateProfile,
                        child: const Text("Save Profile"),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          setState(() {
                            editing = true;
                          });
                        },
                        child: const Text("Edit Profile"),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}