// import 'package:final_app/screens/add_item.dart';
import 'package:final_app/screens/home_page.dart';
import 'package:final_app/screens/menu_page.dart';
import 'package:final_app/screens/settings_page.dart';
import 'package:final_app/screens/special_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _BottomNavAppState();
}

class _BottomNavAppState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    MenuPage(),
    SpecialPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 195, 136, 116),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.house), label: 'Home'),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.utensils),
            label: 'Menu',
          ),
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.award,color: Color.fromARGB(255, 255, 106, 0),), label: 'Special'),
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.personDrowning), label: 'Profile'),
        ],
      ),
    );
  }
}
