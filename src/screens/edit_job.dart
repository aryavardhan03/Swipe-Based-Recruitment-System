import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditJob extends StatefulWidget {

  final String jobId;
  final String title;
  final String experience;
  final List skills;

  const EditJob({
    super.key,
    required this.jobId,
    required this.title,
    required this.experience,
    required this.skills
  });

  @override
  State<EditJob> createState() => _EditJobState();
}

class _EditJobState extends State<EditJob> {

  late TextEditingController titleController;
  late TextEditingController experienceController;
  late TextEditingController skillsController;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.title);
    experienceController = TextEditingController(text: widget.experience);
    skillsController = TextEditingController(text: widget.skills.join(", "));
  }

  Future<void> updateJob() async {

    List<String> skillsList =
        skillsController.text
            .split(',')
            .map((s) => s.trim())
            .toList();

    await FirebaseFirestore.instance
        .collection('jobs')
        .doc(widget.jobId)
        .update({

      "title": titleController.text,
      "experience": experienceController.text,
      "skills": skillsList

    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Job Updated"))
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Job")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Job Title",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: skillsController,
              decoration: const InputDecoration(
                labelText: "Skills",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: experienceController,
              decoration: const InputDecoration(
                labelText: "Experience",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: updateJob,
              child: const Text("Update Job"),
            )
          ],
        ),
      ),
    );
  }
}