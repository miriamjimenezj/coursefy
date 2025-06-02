import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coursefy/features/presentation/pages/auth/login_page.dart';
import 'package:coursefy/features/presentation/widgets/form_container_widget.dart';
import 'package:coursefy/features/presentation/pages/admin/home_admin.dart';
import 'package:coursefy/features/presentation/pages/client/home_client.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignUpPage extends StatefulWidget {
  final Function(Locale) onLocaleChange;

  const SignUpPage({super.key, required this.onLocaleChange});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _adminCodeController = TextEditingController();

  bool isSigningUp = false;
  String _selectedRole = "client";
  String? _adminCode;

  @override
  void initState() {
    super.initState();
    _fetchAdminCode();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _adminCodeController.dispose();
    super.dispose();
  }

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

  Future<void> _signUpWithGoogle() async {
    setState(() => isSigningUp = true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => isSigningUp = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await _firebaseAuth.signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email,
            'role': 'client',
            'createdAt': DateTime.now(),
          });
        }
        _redirectUser(user.uid);
      }
    } catch (e) {
      _showErrorDialog("Google Sign-In Error", "Could not sign in with Google. Please try again.");
    } finally {
      setState(() => isSigningUp = false);
    }
  }

  void _signUp() async {
    setState(() {
      isSigningUp = true;
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String adminCodeInput = _adminCodeController.text.trim();

    if (email.isEmpty || password.isEmpty || (_selectedRole == "admin" && adminCodeInput.isEmpty)) {
      _showErrorDialog("Error", "All fields must be filled in.");
      setState(() => isSigningUp = false);
      return;
    }

    if (password.length < 8) {
      _showErrorDialog("Invalid password", "Password must be at least 8 characters.");
      setState(() => isSigningUp = false);
      return;
    }

    if (_selectedRole == "admin") {
      if (_adminCode == null) {
        _showErrorDialog("Admin Code Error", "The admin code could not be found in the database.");
        setState(() => isSigningUp = false);
        return;
      }
      if (adminCodeInput != _adminCode) {
        _showErrorDialog("Invalid Admin Code", "The admin code is incorrect.");
        setState(() => isSigningUp = false);
        return;
      }
    }

    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'role': _selectedRole,
          'createdAt': DateTime.now(),
        });

        await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
        _redirectUser(user.uid);
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = "No se ha podido registrar el usuario. Inténtalo de nuevo.";
      if (e.code == 'email-already-in-use') {
        errorMsg = "Este email ya está registrado. Prueba con otro.";
      } else if (e.code == 'invalid-email') {
        errorMsg = "El email no es válido.";
      } else if (e.code == 'weak-password') {
        errorMsg = "La contraseña es demasiado débil.";
      }
      _showErrorDialog("Error de registro", errorMsg);
    } catch (e) {
      _showErrorDialog("Error de registro", "No se ha podido registrar el usuario. Inténtalo de nuevo.");
    } finally {
      setState(() => isSigningUp = false);
    }
  }

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
              if (_selectedRole == "client") ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  label: const Text("Sign Up with Google"),
                  onPressed: _signUpWithGoogle,
                ),
              ],
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
