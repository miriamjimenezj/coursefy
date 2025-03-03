import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coursefy/features/user_auth/presentation/pages/login_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'profile_client.dart';
import 'settings_client.dart';

class HomeClient extends StatefulWidget {
  final Function(Locale) onLocaleChange;

  const HomeClient({super.key, required this.onLocaleChange});

  @override
  State<HomeClient> createState() => _HomeClientState();
}

class _HomeClientState extends State<HomeClient> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _widgetOptions = <Widget>[
      const ProfilePage(),
      Center(
        child: Text(
          AppLocalizations.of(context)!.homeClientPage,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      SettingsClientPage(onLocaleChange: widget.onLocaleChange), // ✅ Pasamos onLocaleChange
    ];

    return Scaffold(
      appBar: _selectedIndex == 2
          ? AppBar(
        title: Text(AppLocalizations.of(context)!.settingsPageTitle),
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(onLocaleChange: widget.onLocaleChange),
                ),
              );
            },
            tooltip: AppLocalizations.of(context)!.signOut,
          ),
        ],
      )
          : null,
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppLocalizations.of(context)!.profile,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppLocalizations.of(context)!.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: AppLocalizations.of(context)!.settings,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
