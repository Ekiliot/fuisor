import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'create_post_screen.dart';
import 'media_selection_screen.dart';
import 'shorts_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const CreatePostScreen(),
    const ShortsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Color(0xFF262626),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 2) {
              // Кнопка создания поста - открываем MediaSelectionScreen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MediaSelectionScreen(),
                ),
              );
            } else {
              setState(() {
                _currentIndex = index;
              });
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF000000),
          selectedItemColor: Colors.white,
          unselectedItemColor: const Color(0xFF8E8E8E),
          selectedFontSize: 0,
          unselectedFontSize: 0,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(EvaIcons.homeOutline, size: 28),
              activeIcon: Icon(EvaIcons.home, size: 28),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(EvaIcons.searchOutline, size: 28),
              activeIcon: Icon(EvaIcons.search, size: 28),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(EvaIcons.plusSquareOutline, size: 28),
              activeIcon: Icon(EvaIcons.plusSquare, size: 28),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(EvaIcons.videoOutline, size: 28),
              activeIcon: Icon(EvaIcons.video, size: 28),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(EvaIcons.personOutline, size: 28),
              activeIcon: Icon(EvaIcons.person, size: 28),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}
