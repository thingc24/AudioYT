import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:audio/services/auth_service.dart'; // file chứa AuthService

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

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
                  child: Text(
                    "Welcome ....",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 30),
                const Text("Email", style: TextStyle(fontWeight: FontWeight.w600)),
                TextField(controller: emailController, decoration: const InputDecoration(hintText: "Enter your email")),
                const SizedBox(height: 16),
                const Text("Password", style: TextStyle(fontWeight: FontWeight.w600)),
                TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(hintText: "Enter your password")),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/forgot'),
                      child: const Text("Forgot Password?"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  onPressed: () async {
                    // Login bằng email/password (có thể thêm FirebaseAuth ở đây)
                  },
                  child: const Text("Log In", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 16),
                const Center(child: Text("Or continue with")),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google Sign-In
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.google, size: 28),
                      onPressed: () async {
                        final userCredential = await AuthService.signInWithGoogle();
                        if (userCredential != null) {
                          Navigator.pushReplacementNamed(context, '/home');
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    const FaIcon(FontAwesomeIcons.facebook, color: Colors.blue, size: 28),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/signup'),
                        child: const Text("Sign up", style: TextStyle(color: Colors.deepPurple)),
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
