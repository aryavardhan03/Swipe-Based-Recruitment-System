import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JobPosting extends StatefulWidget {
  const JobPosting({super.key});

  @override
  State<JobPosting> createState() => _JobPostingState();
}

class _JobPostingState extends State<JobPosting> {

  final TextEditingController companyController =
      TextEditingController();

  final TextEditingController locationController =
      TextEditingController();

  final TextEditingController titleController =
      TextEditingController();

  final TextEditingController skillsController =
      TextEditingController();

  final TextEditingController experienceController =
      TextEditingController();

  bool isLoading = false;

  Future<void> postJob() async {

    if (companyController.text.isEmpty ||
        locationController.text.isEmpty ||
        titleController.text.isEmpty||
        skillsController.text.isEmpty||
        experienceController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {

      final employerId =
          FirebaseAuth.instance.currentUser!.uid;

      List<String> skillsList =
          skillsController.text
              .split(',')
              .map((skill) => skill.trim())
              .toList();

      await FirebaseFirestore.instance
          .collection('jobs')
          .add({
        'company': companyController.text.trim(),
        'location': locationController.text.trim(), 
        'title': titleController.text.trim(),
        'skills': skillsList,
        'experience': experienceController.text.trim(),
        'CompanyId': employerId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Job posted successfully"),
        ),
      );

      Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 155, 165, 178),
              Color.fromARGB(255, 80, 97, 128),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                const Text(
                  "Post a Job",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 4, 38, 39),
                  ),
                ),

                const SizedBox(height: 35),

                Container(
                  padding: const EdgeInsets.all(20),
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
                    children: [
                      buildInputField(
                        controller: companyController,
                        label: "Company Name",
                        
                        icon: Icons.business,
                        
                      ),

                      const SizedBox(height: 15),

                      buildInputField(
                        controller: locationController,
                        label: "Job Location",
                        icon: Icons.location_on,
                      ),
                       
                      const SizedBox(height: 15),

                      buildInputField(
                        controller: titleController,
                        label: "Job Title",
                        icon: Icons.work,
                      ),

                      const SizedBox(height: 15),

                      buildInputField(
                        controller: skillsController,
                        label: "Required Skills",
                        hint:
                            "Flutter, Dart, Firebase",
                        icon: Icons.code,
                      ),

                      const SizedBox(height: 15),

                      buildInputField(
                        controller:
                            experienceController,
                        label:
                            "Experience Required",
                        hint: "1–3 years",
                        icon:
                            Icons.timeline,
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 13, 63, 84),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          15),
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : postJob,
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color:
                                      Color.fromARGB(255, 13, 51, 61),
                                )
                              : const Text(
                                  "Post Job",
                                  style: TextStyle(
                                      fontSize:
                                          17),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInputField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: const Color.fromARGB(255, 6, 85, 86),
        ),
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
        ),
      ),
    );
  }
}