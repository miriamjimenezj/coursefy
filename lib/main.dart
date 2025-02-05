import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:coursefy/features/app/splash_screen/splash_screen.dart';
import 'package:coursefy/features/user_auth/presentation/pages/login_page.dart';
import 'package:coursefy/features/user_auth/presentation/pages/sign_up_page.dart';
import 'package:coursefy/features/user_auth/presentation/pages/admin/home_admin.dart';
import 'package:coursefy/features/user_auth/presentation/pages/client/home_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyDZGgLT_AixDiEweE_paakUg0Svri_nllo",
        authDomain: "coursefy-6bc1d.firebaseapp.com",
        projectId: "coursefy-6bc1d",
        storageBucket: "coursefy-6bc1d.firebasestorage.app",
        messagingSenderId: "575785652048",
        appId: "1:575785652048:web:05d7e098f9266b1b1b6655",
        measurementId: "G-LHFM056FGZ",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getHomeScreen() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    if (user == null) {
      return const LoginPage(); // Si no hay usuario autenticado, mostrar la página de login
    }

    // Obtener el rol del usuario desde Firestore
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String? role = userDoc.exists ? userDoc['role'] as String? : null;

      if (role == "admin") {
        return const HomeAdmin();
      } else {
        return const HomeClient();
      }
    } catch (e) {
      print("Error obteniendo el rol del usuario: $e");
      return const LoginPage(); // Si hay un error, devolver la página de login
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Firebase',
      home: FutureBuilder<Widget>(
        future: _getHomeScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen(child: Center(child: CircularProgressIndicator()));
          } else {
            return SplashScreen(child: snapshot.data ?? const LoginPage());
          }
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signUp': (context) => const SignUpPage(),
        '/homeAdmin': (context) => const HomeAdmin(),
        '/homeClient': (context) => const HomeClient(),
      },
    );
  }
}