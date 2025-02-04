import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Registro con rol
  Future<User?> signUpWithEmailAndPassword(String email, String password, String role) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = credential.user;

      if (user != null) {
        // Guardar información en Firestore con el rol
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'role': role, // Se guarda el rol en Firestore
          'createdAt': DateTime.now(),
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('Error: ${e.code}');
      return null;
    }
  }

  // Inicio de sesión con validación de rol
  Future<String?> getUserRole(String uid) async {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
    return userDoc.exists ? userDoc['role'] as String : null;
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print('Error: ${e.code}');
      return null;
    }
  }
}