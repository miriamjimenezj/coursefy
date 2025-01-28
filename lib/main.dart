import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:coursefy/features/app/splash_screen/splash_screen.dart';
import 'package:coursefy/features/user_auth/presentation/pages/home_page.dart';
import 'package:coursefy/features/user_auth/presentation/pages/login_page.dart';
import 'package:coursefy/features/user_auth/presentation/pages/sign_up_page.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: "AIzaSyDZGgLT_AixDiEweE_paakUg0Svri_nllo",
          authDomain: "coursefy-6bc1d.firebaseapp.com",
          projectId: "coursefy-6bc1d",
          storageBucket: "coursefy-6bc1d.firebasestorage.app",
          messagingSenderId: "575785652048",
          appId: "1:575785652048:web:05d7e098f9266b1b1b6655",
          measurementId: "G-LHFM056FGZ"
        // Web Firebase config options
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Firebase',
      routes: {
        '/': (context) => SplashScreen(
          child: LoginPage(),
        ),
        '/login': (context) => LoginPage(),
        '/signUp': (context) => SignUpPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}