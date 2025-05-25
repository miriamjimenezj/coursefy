import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coursefy/features/user_auth/firebase_auth/firebase_auth_services.dart';
import 'package:coursefy/features/presentation/pages/login_page.dart';
import 'package:coursefy/features/presentation/widgets/form_container_widget.dart';
import 'package:coursefy/features/presentation/pages/admin/home_admin.dart';
import 'package:coursefy/features/presentation/pages/client/home_client.dart';

class SignUpPage extends StatefulWidget {
  final Function(Locale) onLocaleChange;

  const SignUpPage({super.key, required this.onLocaleChange});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  //final FirebaseAuthService _auth = FirebaseAuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _adminCodeController = TextEditingController(); // Admin code

  bool isSigningUp = false;
  String _selectedRole = "client"; // Rol por defecto
  String? _adminCode; // Código de administrador desde Firestore

  @override
  void initState() {
    super.initState();
    _fetchAdminCode(); // Obtener código de admin desde Firebase
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _adminCodeController.dispose();
    super.dispose();
  }

  /// **Obtener el Admin Code desde Firestore**
  Future<void> _fetchAdminCode() async {
    try {
      DocumentSnapshot adminSettings =
      await _firestore.collection('config').doc('admin_settings').get();

      if (adminSettings.exists && adminSettings.data() != null) {
        setState(() {
          _adminCode = adminSettings['admin_code'];
        });
      }
    } catch (e) {
      _showErrorDialog("Error", "Could not fetch admin code. Please try again.");
    }
  }

  /// **Función para registrarse con email y contraseña**
  void _signUp() async {
    setState(() {
      isSigningUp = true;
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String adminCodeInput = _adminCodeController.text.trim();

    // Validar si el usuario quiere ser admin
    if (_selectedRole == "admin") {
      if (_adminCode == null) {
        _showErrorDialog("Admin Code Error", "No admin code found in Firestore.");
        setState(() {
          isSigningUp = false;
        });
        return;
      }

      if (adminCodeInput != _adminCode) {
        _showErrorDialog("Invalid Admin Code", "The admin code you entered is incorrect.");
        setState(() {
          isSigningUp = false;
        });
        return;
      }
    }

    try {
      // Crear usuario en Firebase Authentication
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Guardar el rol del usuario en Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'role': _selectedRole,
          'createdAt': DateTime.now(),
        });

        // Iniciar sesión automáticamente
        await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);

        // Obtener el rol del usuario y redirigir a la pantalla correcta
        _redirectUser(user.uid);
      }
    } catch (e) {
      _showErrorDialog("Registration Error", "Could not register user. Please try again.");
    } finally {
      setState(() {
        isSigningUp = false;
      });
    }
  }

  /// **Obtener el rol del usuario y redirigir a la pantalla correcta**
  Future<void> _redirectUser(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        String role = userDoc['role'];

        if (role == "admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeAdmin(onLocaleChange: widget.onLocaleChange)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeClient(onLocaleChange: widget.onLocaleChange)),
          );
        }
      }
    } catch (e) {
      _showErrorDialog("Error", "Could not determine user role.");
    }
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

              // Campo extra solo si se elige "Admin"
              if (_selectedRole == "admin") ...[
                const SizedBox(height: 10),
                FormContainerWidget(
                  controller: _adminCodeController,
                  hintText: "Admin Code",
                  isPasswordField: true,
                ),
              ],

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

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage(onLocaleChange: widget.onLocaleChange)),
                      );
                    },
                    child: const Text("Log In", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
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
