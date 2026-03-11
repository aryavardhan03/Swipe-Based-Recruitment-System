// employer_matches.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class EmployerMatches extends StatelessWidget {
  const EmployerMatches({super.key});

  @override
  Widget build(BuildContext context) {

    final String employerId =
        FirebaseAuth.instance.currentUser!.uid;

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

              // 🔹 Top Title
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 25, vertical: 15),
                child: Row(
                  children: const [
                    Text(
                      "My Matches",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 4, 38, 39),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('matches')
                      .where('employerId',
                          isEqualTo: employerId)
                      .snapshots(),
                  builder: (context, snapshot) {

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color.fromARGB(255, 24, 20, 20),
                        ),
                      );
                    }

                    if (snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No matches yet",
                          style: TextStyle(
                              color: Color.fromARGB(255, 15, 13, 13),
                              fontSize: 18),
                        ),
                      );
                    }

                    final matches =
                        snapshot.data!.docs;

                    return ListView.builder(
                      padding:
                          const EdgeInsets.all(24),
                      itemCount: matches.length,
                      itemBuilder:
                          (context, index) {

                        final matchDoc =
                            matches[index];
                        final data =
                            matchDoc.data()
                                as Map<String,
                                    dynamic>;

                        final compatibility =
                            data['compatibilityScore'] ??
                                0;

                        return buildMatchCard(
                          context,
                          matchDoc.id,
                          employerId,
                          compatibility,
                          data['profileImage'],
                        );
                      },
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

  Widget buildMatchCard(
    BuildContext context,
    String chatId,
    String employerId,
    int compatibility,
    String? profileImage,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 16),
      padding:
          const EdgeInsets.all(18),
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundImage: profileImage != null
                  ? NetworkImage(profileImage)
                  : null,
                child: profileImage == null
                  ? const Icon(Icons.person)
                  : null,
              ),
              const SizedBox(width: 12),
              const Text(
                "Matched Candidate",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.chat,
                color: Color.fromARGB(255, 13, 99, 110),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Text(
            "Compatibility: $compatibility%",
            style: const TextStyle(
                fontWeight:
                    FontWeight.w600),
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: compatibility / 100,
              minHeight: 6,
              backgroundColor:
                  const Color.fromARGB(255, 172, 176, 178),
              valueColor:
                  const AlwaysStoppedAnimation(
                      Color.fromARGB(255, 44, 125, 145)),
            ),
          ),

          const SizedBox(height: 15),

          Align(
            alignment:
                Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color.fromARGB(255, 30, 94, 114),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                          15),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ChatScreen(
                      chatId: chatId,
                      currentUserId:
                          employerId,
                    ),
                  ),
                );
              },
              child:
                  const Text("Open Chat"),
            ),
          ),
        ],
      ),
    );
  }
}