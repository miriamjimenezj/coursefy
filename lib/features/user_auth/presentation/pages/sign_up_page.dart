import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coursefy/features/user_auth/firebase_auth/firebase_auth_services.dart';
import 'package:coursefy/features/user_auth/presentation/pages/login_page.dart';
import 'package:coursefy/features/user_auth/presentation/widgets/form_container_widget.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuthService _auth = FirebaseAuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  bool isSigningUp = false;
  String _selectedRole = "client"; // Rol por defecto

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// **Función para registrarse con email y contraseña**
  void _signUp() async {
    setState(() {
      isSigningUp = true;
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    User? user = await _auth.signUpWithEmailAndPassword(email, password, _selectedRole);

    setState(() {
      isSigningUp = false;
    });

    if (user != null) {
      print("Usuario creado con éxito");
      Navigator.pushNamed(context, "/home");
    } else {
      print("Ocurrió un error en el registro");
    }
  }

  /// **Función para iniciar sesión con Google**
  void _signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleSignInAuthentication.idToken,
          accessToken: googleSignInAuthentication.accessToken,
        );

        UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
        User? user = userCredential.user;

        if (user != null) {
          String? role = await _getUserRole(user.uid);

          // Si el usuario no tiene rol en Firestore, asignar "client" por defecto
          if (role == null) {
            await _firestore.collection('users').doc(user.uid).set({
              'email': user.email,
              'role': 'client',
              'createdAt': DateTime.now(),
            });
            role = "client";
          }

          Navigator.pushNamed(context, "/home");
        }
      }
    } catch (e) {
      print("Error en el inicio de sesión con Google: $e");
    }
  }

  /// **Obtener el rol del usuario desde Firestore**
  Future<String?> _getUserRole(String uid) async {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
    return userDoc.exists ? userDoc['role'] as String? : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Sign Up", style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              FormContainerWidget(controller: _usernameController, hintText: "Username", isPasswordField: false),
              const SizedBox(height: 10),
              FormContainerWidget(controller: _emailController, hintText: "Email", isPasswordField: false),
              const SizedBox(height: 10),
              FormContainerWidget(controller: _passwordController, hintText: "Password", isPasswordField: true),
              const SizedBox(height: 10),

              // Selector de rol
              DropdownButton<String>(
                value: _selectedRole,
                items: const [
                  DropdownMenuItem(value: "admin", child: Text("Admin")),
                  DropdownMenuItem(value: "client", child: Text("Client")),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),

              const SizedBox(height: 30),
              GestureDetector(
                onTap: _signUp,
                child: Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: isSigningUp
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Sign Up", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              // Botón de "Sign Up with Google"
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
                          "Sign Up with Google",
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

              // Opción de volver al login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      "Log In",
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
}