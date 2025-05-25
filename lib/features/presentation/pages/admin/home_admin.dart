import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:coursefy/features/presentation/pages/login_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'profile_admin.dart';
import 'settings_admin.dart';
import 'courses/create_course.dart';
import 'courses/edit_course.dart';

class HomeAdmin extends StatefulWidget {
final Function(Locale) onLocaleChange;

const HomeAdmin({super.key, required this.onLocaleChange});

@override
State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
int _selectedIndex = 1;
final userId = FirebaseAuth.instance.currentUser?.uid;

Future<void> _deleteCourse(String courseId) async {
await FirebaseFirestore.instance.collection('courses').doc(courseId).delete();
}

void _confirmDeleteCourse(String courseId) {
showDialog(
context: context,
builder: (context) => AlertDialog(
  title: Text(AppLocalizations.of(context)!.deleteCourseTitle),
  content: Text(AppLocalizations.of(context)!.deleteCourseMessage),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: Text(AppLocalizations.of(context)!.cancel),
),
TextButton(
onPressed: () async {
Navigator.pop(context);
await _deleteCourse(courseId);
setState(() {});
},
child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
),
],
),
);
}

Widget _buildCoursesList() {
return StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
    .collection('courses')
    .where('createdBy', isEqualTo: userId)
    .orderBy('createdAt', descending: true)
    .snapshots(),
builder: (context, snapshot) {
if (snapshot.connectionState == ConnectionState.waiting) {
return const Center(child: CircularProgressIndicator());
}
if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
return Center(child: Text(AppLocalizations.of(context)!.noCourses));
}

final courses = snapshot.data!.docs;

return ListView.builder(
shrinkWrap: true,
itemCount: courses.length,
itemBuilder: (context, index) {
final course = courses[index];
final courseName = course['title'];
final courseData = course.data() as Map<String, dynamic>;
final levels = courseData['levels'] as Map<String, dynamic>;

return Container(
margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
decoration: BoxDecoration(
color: Colors.blueAccent[100],
borderRadius: BorderRadius.circular(10),
),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(courseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
Row(
children: [
IconButton(
icon: const Icon(Icons.edit, color: Colors.blue),
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => EditCoursePage(
courseId: course.id,
currentTitle: courseName,
levels: levels,
  finalTest: courseData['finalTest'] ?? {},
  tags: courseData['tags'],
),
),
);
},
),
IconButton(
icon: const Icon(Icons.delete, color: Colors.red),
onPressed: () => _confirmDeleteCourse(course.id),
),
],
),
],
),
);
},
);
},
);
}

Widget _buildCreateCourseButton() {
return Padding(
padding: const EdgeInsets.all(15.0),
child: ElevatedButton.icon(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(builder: (context) => const CreateCoursePage()),
);
},
icon: const Icon(Icons.add),
label: Text(AppLocalizations.of(context)!.createCourse),
style: ElevatedButton.styleFrom(
backgroundColor: Colors.purple[200],
minimumSize: const Size(double.infinity, 50),
textStyle: const TextStyle(fontWeight: FontWeight.bold),
),
),
);
}

@override
Widget build(BuildContext context) {
final List<Widget> _widgetOptions = <Widget>[
const ProfilePage(),
Column(
children: [
const SizedBox(height: 20),
Text(
"\n\n${AppLocalizations.of(context)!.welcome}",
textAlign: TextAlign.center,
style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
),
const SizedBox(height: 10),
Text(
AppLocalizations.of(context)!.coursesCreated,
style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
const SizedBox(height: 20),
Expanded(child: _buildCoursesList()),
_buildCreateCourseButton(),
],
),
SettingsAdminPage(onLocaleChange: widget.onLocaleChange),
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
body: _widgetOptions.elementAt(_selectedIndex),
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
selectedItemColor: Colors.blue[800],
onTap: (index) {
setState(() {
_selectedIndex = index;
});
},
),
);
}
}
