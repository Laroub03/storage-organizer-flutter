import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'global.dart';
import 'queue_page.dart';
import 'setting_page.dart';
import 'login_page.dart';
import 'home_page.dart';

class TabPage extends StatefulWidget {
  const TabPage({super.key});

  @override
  State<TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<TabPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<CustomTab> myTabs = <CustomTab>[
    CustomTab(
        text: 'Home',
        icon: 'images/icon-home-gray.png',
        selectedIcon: 'images/icon-home-blue.png'),
    CustomTab(
        text: 'Queue',
        icon: 'images/icon-history-gray.png',
        selectedIcon: 'images/icon-history-blue.png'),
    CustomTab(
        text: 'Settings',
        icon: 'images/icon-about-gray.png',
        selectedIcon: 'images/icon-home-blue.png'),
  ];

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 3);
  }
  
  Future<void> _logout() async {
    // Show confirmation dialog
    final bool shouldLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorBackground,
          title: const Text('Logout', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: colorSubtitle)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Logout', style: TextStyle(color: colorBlue)),
            ),
          ],
        );
      },
    ) ?? false;
    
    if (shouldLogout) {
      // Clear login status and auth token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('auth_token');
      
      // Navigate to login page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: TabBarView(
          controller: _tabController,
          children: [
            const HomePage(),
            const QueuePage(),
            SettingPage(onLogout: _logout),
          ],
        ),
        bottomNavigationBar: SizedBox(
          height: 83,
          child: TabBar(
            labelColor: Colors.blue,
            controller: _tabController,
            onTap: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
            tabs: myTabs.map((CustomTab tab) {
              return MyTab(
                  tab: tab, isSelected: myTabs.indexOf(tab) == selectedIndex);
            }).toList(),
          ),
        ));
  }
}

class MyTab extends StatelessWidget {
  final CustomTab tab;
  final bool isSelected;

  const MyTab({super.key, required this.tab, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset(
            isSelected ? tab.selectedIcon : tab.icon,
            width: 48,
            height: 32,
          ),
          Text(tab.text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: isSelected ? colorBlue : colorSelect,
              ))
        ],
      ),
    );
  }
}

class CustomTab {
  final String text;
  final String icon;
  final String selectedIcon;

  CustomTab(
      {required this.text, required this.icon, required this.selectedIcon});
}
