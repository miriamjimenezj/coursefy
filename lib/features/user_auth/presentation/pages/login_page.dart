import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coursefy/features/user_auth/presentation/pages/sign_up_page.dart';
import 'package:coursefy/features/user_auth/presentation/widgets/form_container_widget.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../firebase_auth/firebase_auth_services.dart';
import 'admin/home_admin.dart';
import 'client/home_client.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isSigning = false;
  final FirebaseAuthService _auth = FirebaseAuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Login"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Login",
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              FormContainerWidget(
                controller: _emailController,
                hintText: "Email",
                isPasswordField: false,
              ),
              const SizedBox(height: 10),
              FormContainerWidget(
                controller: _passwordController,
                hintText: "Password",
                isPasswordField: true,
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _signIn,
                child: Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: _isSigning
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _signInWithGoogle,
                child: Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(FontAwesomeIcons.google, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          "Sign in with Google",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpPage()),
                            (route) => false,
                      );
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// **Función para iniciar sesión con correo y contraseña**
  void _signIn() async {
    setState(() {
      _isSigning = true;
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    try {
      User? user = await _auth.signInWithEmailAndPassword(email, password);

      if (user != null) {
        String? role = await _getUserRole(user.uid);

        if (role == "admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeAdmin()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeClient()),
          );
        }
      } else {
        _showErrorDialog("Login Failed", "Invalid email or password.");
      }
    } catch (e) {
      _showErrorDialog("Login Error", e.toString());
    }

    setState(() {
      _isSigning = false;
    });
  }

  /// **Función para iniciar sesión con Google**
  void _signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleSignInAuthentication.idToken,
          accessToken: googleSignInAuthentication.accessToken,
        );

        UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
        User? user = userCredential.user;

        if (user != null) {
          String? role = await _getUserRole(user.uid);

          if (role == null) {
            await _firestore.collection('users').doc(user.uid).set({
              'email': user.email,
              'role': 'client', // Por defecto, usuarios de Google serán clientes
              'createdAt': DateTime.now(),
            });
            role = "client";
          }

          if (role == "admin") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeAdmin()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeClient()),
            );
          }
        }
      }
    } catch (e) {
      _showErrorDialog("Google Login Error", e.toString());
    }
  }

  /// **Obtener el rol del usuario desde Firestore**
  Future<String?> _getUserRole(String uid) async {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
    return userDoc.exists ? userDoc['role'] as String : null;
  }

  /// **Mostrar un cuadro de diálogo de error**
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}