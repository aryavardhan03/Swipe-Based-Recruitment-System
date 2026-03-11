import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'edit_job.dart';

class EmployerJobs extends StatelessWidget {
  const EmployerJobs({super.key});

  @override
  Widget build(BuildContext context) {

    final employerId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Jobs"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('CompanyId', isEqualTo: employerId)
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No jobs posted yet"),
            );
          }

          final jobs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {

              final jobDoc = jobs[index];
              final data = jobDoc.data() as Map<String, dynamic>;

              final title = data['title'];
              final experience = data['experience'];
              final skills = List<String>.from(data['skills']);

              return Card(
                margin: const EdgeInsets.all(12),

                child: ListTile(

                  title: Text(title),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text("Experience: $experience"),

                      const SizedBox(height: 5),

                      Text("Skills: ${skills.join(', ')}"),

                    ],
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      /// EDIT BUTTON
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditJob(
                                jobId: jobDoc.id,
                                title: title,
                                experience: experience,
                                skills: skills,
                              ),
                            ),
                          );
                        },
                      ),

                      /// DELETE BUTTON
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),

                        onPressed: () async {

                          await FirebaseFirestore.instance
                              .collection('jobs')
                              .doc(jobDoc.id)
                              .delete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}