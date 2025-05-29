import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coursefy/features/presentation/pages/auth/login_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'profile_client.dart';
import 'settings_client.dart';
import 'courses/courses.dart';

class HomeClient extends StatefulWidget {
  final Function(Locale) onLocaleChange;

  const HomeClient({super.key, required this.onLocaleChange});

  @override
  State<HomeClient> createState() => _HomeClientState();
}

class _HomeClientState extends State<HomeClient> {
  int _selectedIndex = 1;
  String? _selectedTag;
  List<String> _allTags = [];

  @override
  void initState() {
    super.initState();
    _fetchAllTags();
  }

  Future<void> _fetchAllTags() async {
    final snapshot = await FirebaseFirestore.instance.collection('courses').get();
    final Set<String> tags = {};
    for (var doc in snapshot.docs) {
      if (doc.data().containsKey('tags')) {
        final List<dynamic>? courseTags = doc['tags'];
        if (courseTags != null) {
          tags.addAll(courseTags.map((e) => e.toString()));
        }
      }
    }
    setState(() {
      _allTags = [''].followedBy(tags).toSet().toList(); // '' → opción "Todos"
    });
  }

  Widget _buildCoursesList() {
    Query query = FirebaseFirestore.instance
        .collection('courses')
        .orderBy('createdAt', descending: true);

    if (_selectedTag != null && _selectedTag!.isNotEmpty) {
      query = query.where('tags', arrayContains: _selectedTag);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text(AppLocalizations.of(context)!.noCourses));
        }

        final courses = snapshot.data!.docs;

        return ListView.builder(
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            final courseTitle = course['title'] ?? '';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(courseTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(AppLocalizations.of(context)!.startCourse),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CoursesPage(
                        courseId: course.id,
                        courseTitle: course['title'] ?? '',
                        //levels: course['levels'] ?? {},
                        //levelKey: key,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: DropdownButtonFormField<String>(
        value: _selectedTag,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.filterByTag,
          border: const OutlineInputBorder(),
        ),
        items: _allTags.map((tag) {
          return DropdownMenuItem(
            value: tag,
            child: Text(tag.isEmpty ? AppLocalizations.of(context)!.allTags : tag),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedTag = value;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _widgetOptions = <Widget>[
      const ProfilePage(),
      Column(
        children: [
          const SizedBox(height: 90),
          _buildFilterDropdown(),
          const SizedBox(height: 16),
          Expanded(child: _buildCoursesList()),
        ],
      ),
      SettingsClientPage(onLocaleChange: widget.onLocaleChange),
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