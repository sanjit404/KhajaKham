// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:final_app/screens/main_page.dart';
import 'package:flutter/material.dart';
import 'package:elegant_notification/elegant_notification.dart';
import '../repositories/auth_repository.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  final AuthRepository _authRepository = AuthRepository();

  void _showNotification(String title, String message, {bool error = true}) {
    ElegantNotification.info(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      description: Text(message, style: const TextStyle(color: Colors.white)),
      background: Color.fromARGB(255, 19, 69, 149),
      icon: Icon(error ? Icons.error : Icons.check, color: Colors.white),
      toastDuration: const Duration(seconds: 2),
    ).show(context);
  }

  Future<void> _loginWithEmail() async {
    setState(() => _loading = true);
    final result = await _authRepository.loginWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    setState(() => _loading = false);

    if (result != null) {
      _showNotification("Error", result);
    } else {
      _showNotification("Success", "Logged In" , error: false);
      _navigateToHome();
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    final result = await _authRepository.signInWithGoogle();
    setState(() => _loading = false);

    if (result != null) {
      _showNotification("Error", result);
    } else {
      _navigateToHome();
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showNotification("Error", "Enter your email first");
      return;
    }
    setState(() => _loading = true);
    final result = await _authRepository.sendPasswordResetEmail(
      _emailController.text.trim(),
    );
    setState(() => _loading = false);

    if (result != null) {
      _showNotification("Error", result);
    } else {
      _showNotification("Success", "Password reset email sent", error: false);
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/bg.webp", fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.3)),
          Center(
            child: SingleChildScrollView(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: size.width * 0.9,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset("assets/MainLogo.png", height: 200),
                        const Text(
                          'Login to Khaja Kham',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(_emailController, 'Email', Icons.email),
                        const SizedBox(height: 16),
                        _buildPasswordField(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _forgotPassword,
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(color: Colors.black87),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _loading
                            ? const CircularProgressIndicator(
                                color: Colors.black87,
                              )
                            : Column(
                                children: [
                                  _gradientButton('Login', _loginWithEmail),
                                  const SizedBox(height: 12),
                                  _googleButton(),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const SignupPage(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "Don't have an account? Register",
                                      style: TextStyle(color: Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black45),
        prefixIcon: Icon(icon, color: Colors.black54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        hintText: 'Password',
        hintStyle: const TextStyle(color: Colors.black45),
        prefixIcon: const Icon(Icons.lock, color: Colors.black54),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.black54,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _gradientButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 67, 131, 233),
            Color.fromARGB(255, 67, 131, 233),
            Color.fromARGB(255, 101, 56, 249),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _googleButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton.icon(
        onPressed: _loginWithGoogle,
        icon: Image.asset('assets/google.webp', height: 24),
        label: const Text(
          'Sign in with Google',
          style: TextStyle(color: Colors.black87),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
