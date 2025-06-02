import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:coursefy/features/presentation/pages/auth/login_page.dart';
import 'package:provider/provider.dart';
import '../../widgets/themeNotifier.dart';

class SettingsClientPage extends StatelessWidget {
  final Function(Locale) onLocaleChange;

  const SettingsClientPage({super.key, required this.onLocaleChange});

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    if (user != null) {
      try {
        await firestore.collection('users').doc(user.uid).delete();
        await user.delete();
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        _showErrorDialog(context, AppLocalizations.of(context)!.errorTitle,
            AppLocalizations.of(context)!.deleteAccountError);
      }
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteAccountTitle),
        content: Text(AppLocalizations.of(context)!.deleteAccountMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      LoginPage(onLocaleChange: onLocaleChange),
                ),
                    (route) => false,
              );
            },
            child: Text(AppLocalizations.of(context)!.delete,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final _currentPasswordController = TextEditingController();
    final _newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.changePassword),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.currentPassword),
            ),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.newPassword),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              final currentPassword = _currentPasswordController.text.trim();
              final newPassword = _newPasswordController.text.trim();
              final user = FirebaseAuth.instance.currentUser;

              if (newPassword.length < 8) {
                _showErrorDialog(
                  context,
                  AppLocalizations.of(context)!.errorTitle,
                  AppLocalizations.of(context)!.errorPswd,
                );
                return;
              }

              if (currentPassword.isNotEmpty &&
                  newPassword.isNotEmpty &&
                  user != null &&
                  user.email != null) {
                try {
                  final cred = EmailAuthProvider.credential(
                      email: user.email!, password: currentPassword);
                  await user.reauthenticateWithCredential(cred);

                  await user.updatePassword(newPassword);

                  Navigator.pop(context);
                  _showErrorDialog(
                    context,
                    AppLocalizations.of(context)!.success,
                    AppLocalizations.of(context)!.passwordUpdatedSuccessfully,
                  );
                } on FirebaseAuthException catch (e) {
                  Navigator.pop(context);
                  if (e.code == 'wrong-password' ||
                      e.code == 'user-mismatch' ||
                      e.code == 'invalid-credential' ||
                      e.code == 'invalid-password') {
                    _showErrorDialog(
                      context,
                      AppLocalizations.of(context)!.errorTitle,
                      AppLocalizations.of(context)!.incorrectPswd,
                    );
                  } else {
                    _showErrorDialog(
                      context,
                      AppLocalizations.of(context)!.errorTitle,
                      AppLocalizations.of(context)!.changePasswordError,
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  _showErrorDialog(
                    context,
                    AppLocalizations.of(context)!.errorTitle,
                    AppLocalizations.of(context)!.changePasswordError,
                  );
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Locale _selectedLocale = Localizations.localeOf(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              Text(
                AppLocalizations.of(context)!.selectLanguage,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              DropdownButton<Locale>(
                value: _selectedLocale.languageCode == 'es'
                    ? const Locale('es')
                    : const Locale('en'),
                items: const [
                  DropdownMenuItem(value: Locale('en'), child: Text("English")),
                  DropdownMenuItem(value: Locale('es'), child: Text("Español")),
                ],
                onChanged: (Locale? locale) {
                  if (locale != null) {
                    onLocaleChange(locale);
                  }
                },
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(themeNotifier.isDark ? Icons.nightlight : Icons.wb_sunny),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.theme,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: themeNotifier.isDark,
                    onChanged: (value) {
                      themeNotifier.setDark(value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _showChangePasswordDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[300],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.changePassword),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => _showDeleteConfirmationDialog(context),
                child: Text(
                  AppLocalizations.of(context)!.deleteAccount,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}