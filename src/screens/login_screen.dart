import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'candidate_home.dart';
import 'employer_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  String role = 'candidate';
  final AuthService auth = AuthService();

  Future<void> login() async {
    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMsg('Email and password required');
      return;
    }

    try {
      final user = await auth.login(email, password);
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userRole = doc['role'];

      if (userRole == 'candidate') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CandidateHome()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EmployerHome()),
        );
      }

    } on FirebaseAuthException catch (e) {
      showMsg(e.message ?? 'Login failed');
    }
  }

  Future<void> register() async {

    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMsg('Email and password required');
      return;
    }

    if (password.length < 6) {
      showMsg('Password must be at least 6 characters');
      return;
    }

    try {
      final user = await auth.register(email, password);
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name': email.split('@')[0],
        'email': email,
        'role': role,
        'skills': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      await login();

    } on FirebaseAuthException catch (e) {
      showMsg(e.message ?? 'Registration failed');
    }
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            backgroundColor: const Color.fromARGB(221, 16, 13, 13),
            content: Text(msg),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 161, 168, 171),
              Color.fromARGB(255, 10, 10, 11),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 148, 163, 165).withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(66, 15, 18, 20),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  const Icon(
                    Icons.swipe,
                    size: 60,
                    color: Color.fromARGB(255, 79, 116, 128),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "SwipeRecruit",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      color: Color.fromARGB(255, 12, 72, 93),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    "Smart Hiring with AI Matching",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color.fromARGB(255, 9, 55, 73),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Email
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      hintText: "Email",
                      prefixIcon: const Icon(Icons.email),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 214, 218, 219),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Password
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 214, 218, 219),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Role Toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 117, 124, 126),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => role = 'candidate'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: role == 'candidate'
                                    ? const Color.fromARGB(255, 60, 70, 73)
                                    : const Color.fromARGB(0, 126, 105, 105),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "Candidate",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: role == 'candidate'
                                      ? const Color.fromARGB(255, 248, 246, 246)
                                      : Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => role = 'employer'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: role == 'employer'
                                    ? const Color.fromARGB(255, 60, 70, 73)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "Employer",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: role == 'employer'
                                      ? const Color.fromARGB(255, 248, 246, 246)
                                      : Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Login Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 77, 110, 121),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: login,
                    child: const Text(
                      "Login",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Register Button
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(
                        color: Color.fromARGB(255, 45, 114, 161),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: register,
                    child: const Text(
                      "Create Account",
                      style: TextStyle(
                        color: Color.fromARGB(255, 27, 70, 89),
                        fontSize: 16,
                      ),
                    ),
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