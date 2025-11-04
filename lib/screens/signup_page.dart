import 'package:flutter/material.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    bool staySignedIn = false;

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
                  child: Text("Create Account",
                      style:
                      TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 30),
                const Text("Full Name", style: TextStyle(fontWeight: FontWeight.w600)),
                const TextField(decoration: InputDecoration(hintText: "Enter your name")),
                const SizedBox(height: 16),
                const Text("Email", style: TextStyle(fontWeight: FontWeight.w600)),
                const TextField(decoration: InputDecoration(hintText: "Enter your email")),
                const SizedBox(height: 16),
                const Text("Password", style: TextStyle(fontWeight: FontWeight.w600)),
                const TextField(
                    obscureText: true,
                    decoration: InputDecoration(hintText: "Create a password")),
                const SizedBox(height: 6),
                const Text("Must be at least 8 characters",
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Switch(
                      value: staySignedIn,
                      onChanged: (v) {},
                      activeColor: Colors.deepPurple,
                    ),
                    const Text("Stay signed in"),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {},
                  child: const Text("Create Account",
                      style: TextStyle(color: Colors.white)),
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
                        child: const Text("Log in",
                            style: TextStyle(color: Colors.deepPurple)),
                      )
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
