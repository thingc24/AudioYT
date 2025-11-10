import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool staySignedIn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text("Create Account", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 30),
                const Text("Full Name", style: TextStyle(fontWeight: FontWeight.w600)),
                TextField(controller: _nameController, decoration: const InputDecoration(hintText: "Enter your name")),
                const SizedBox(height: 16),
                const Text("Email", style: TextStyle(fontWeight: FontWeight.w600)),
                TextField(controller: _emailController, decoration: const InputDecoration(hintText: "Enter your email")),
                const SizedBox(height: 16),
                const Text("Password", style: TextStyle(fontWeight: FontWeight.w600)),
                TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(hintText: "Create a password")),
                const SizedBox(height: 6),
                const Text("Must be at least 8 characters", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Switch(
                      value: staySignedIn,
                      onChanged: (v) {
                        setState(() {
                          staySignedIn = v;
                        });
                      },
                      activeColor: Colors.deepPurple,
                    ),
                    const Text("Stay signed in"),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () async {
                    try {
                      await FirebaseAuth.instance.createUserWithEmailAndPassword(
                        email: _emailController.text.trim(),
                        password: _passwordController.text.trim(),
                      );
                      Navigator.pushReplacementNamed(context, '/home');
                    } on FirebaseAuthException catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Error")));
                    }
                  },
                  child: const Text("Create Account", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 16),
                const Center(child: Text("Or continue with")),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.g_mobiledata, size: 40),
                    SizedBox(width: 16),
                    Icon(Icons.facebook, color: Colors.blue, size: 30),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/login'),
                        child: const Text("Log in", style: TextStyle(color: Colors.deepPurple)),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
