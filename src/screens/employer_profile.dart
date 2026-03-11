import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmployerProfile extends StatefulWidget {
  const EmployerProfile({super.key});

  @override
  State<EmployerProfile> createState() => _EmployerProfileState();
}

class _EmployerProfileState extends State<EmployerProfile> {

  final userId = FirebaseAuth.instance.currentUser!.uid;

  String logoUrl = "";
  bool loading = false;
  bool editing = false;

  final companyNameController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (doc.exists) {

      final data = doc.data()!;

      companyNameController.text = data['companyName'] ?? "";
      locationController.text = data['location'] ?? "";
      descriptionController.text = data['companyDescription'] ?? "";

      if (data['companyLogo'] != null) {
        logoUrl = data['companyLogo'];
      }

      setState(() {});
    }
  }

  Future<void> pickLogo() async {

    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() {
      loading = true;
    });

    final file = File(picked.path);

    final ref = FirebaseStorage.instance
        .ref()
        .child("company_logos/$userId.jpg");

    await ref.putFile(file);

    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
      "companyLogo": url
    });

    setState(() {
      logoUrl = url;
      loading = false;
    });
  }

  Future<void> updateProfile() async {

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({

      "companyName": companyNameController.text,
      "location": locationController.text,
      "companyDescription": descriptionController.text

    });

    setState(() {
      editing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Company Profile Updated"))
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Company Profile"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            GestureDetector(
              onTap: pickLogo,
              child: CircleAvatar(
                radius: 60,
                backgroundImage:
                    logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
                child: logoUrl.isEmpty
                    ? const Icon(Icons.business, size: 60)
                    : null,
              ),
            ),

            const SizedBox(height: 20),

            loading
                ? const CircularProgressIndicator()
                : const Text("Tap logo to change"),

            const SizedBox(height: 30),

            editing
                ? TextField(
                    controller: companyNameController,
                    decoration: const InputDecoration(
                      labelText: "Company Name",
                      border: OutlineInputBorder(),
                    ),
                  )
                : Text(
                    companyNameController.text,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),

            const SizedBox(height: 20),

            editing
                ? TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: "Location",
                      border: OutlineInputBorder(),
                    ),
                  )
                : Text(locationController.text),

            const SizedBox(height: 20),

            editing
                ? TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Company Description",
                      border: OutlineInputBorder(),
                    ),
                  )
                : Text(descriptionController.text),

            const SizedBox(height: 30),

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
    );
  }
}