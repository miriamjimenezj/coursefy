import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'features/presentation/widgets/themeNotifier.dart';

import 'package:coursefy/features/presentation/pages/splash_screen/splash_screen.dart';
import 'package:coursefy/features/presentation/pages/auth/login_page.dart';
import 'package:coursefy/features/presentation/pages/auth/sign_up_page.dart';
import 'package:coursefy/features/presentation/pages/admin/home_admin.dart';
import 'package:coursefy/features/presentation/pages/client/home_client.dart';
import 'package:coursefy/features/presentation/pages/admin/settings_admin.dart';
import 'package:coursefy/features/presentation/pages/client/settings_client.dart';

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

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en'); // Idioma predeterminado

  void _changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  Future<Widget> _getHomeScreen() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    if (user == null) {
      return LoginPage(onLocaleChange: _changeLanguage); // ✅ Se pasa onLocaleChange
    }

    // Obtener el rol del usuario desde Firestore
    try {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String? role = userDoc.exists ? userDoc['role'] as String? : null;

      if (role == "admin") {
        return HomeAdmin(onLocaleChange: _changeLanguage);
      } else {
        return HomeClient(onLocaleChange: _changeLanguage);
      }
    } catch (e) {
      print("Error obteniendo el rol del usuario: $e");
      return LoginPage(onLocaleChange: _changeLanguage); // ✅ Se pasa onLocaleChange
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Coursefy',
      locale: _locale,
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeNotifier.isDark ? ThemeMode.dark : ThemeMode.light,
      // 👆
      home: FutureBuilder<Widget>(
        future: _getHomeScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen(child: Center(child: CircularProgressIndicator()));
          } else {
            return SplashScreen(child: snapshot.data ?? LoginPage(onLocaleChange: _changeLanguage));
          }
        },
      ),
      routes: {
        '/login': (context) => LoginPage(onLocaleChange: _changeLanguage),
        '/signUp': (context) => SignUpPage(onLocaleChange: _changeLanguage),
        '/homeAdmin': (context) => HomeAdmin(onLocaleChange: _changeLanguage),
        '/homeClient': (context) => HomeClient(onLocaleChange: _changeLanguage),
        '/settingsAdmin': (context) => SettingsAdminPage(onLocaleChange: _changeLanguage),
        '/settingsClient': (context) => SettingsClientPage(onLocaleChange: _changeLanguage),
      },
    );
  }
}