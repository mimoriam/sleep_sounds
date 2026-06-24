import 'package:flutter/material.dart';
import 'favourite/favourite.dart';
import 'home/home.dart';
import 'profile/profile.dart';
import 'sounds/sounds.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SoundsScreen(),
    const FavouriteScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return NotificationListener<TabSwitchNotification>(
      onNotification: (notification) {
        setState(() {
          _currentIndex = notification.index;
        });
        return true;
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF151C2C), // Matches AppColors.cardColor
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 15,
                offset: const Offset(0, -4),
              ),
            ],
            border: const Border(
              top: BorderSide(
                color: Color(0xFF2A3547), // Matches AppColors.borderLight
                width: 1.0,
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                focusColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                backgroundColor: Colors.transparent, // Handled by container
                selectedItemColor: const Color(
                  0xFF26C6DA,
                ), // AppColors.primaryCyan
                unselectedItemColor: const Color(
                  0xFF8F9BB3,
                ), // AppColors.textSecondary
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
                type: BottomNavigationBarType.fixed,
                elevation: 0, // Handled by container
                items: const [
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4.0),
                      child: Icon(Icons.home, size: 24),
                    ),
                    activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 4.0),
                      child: Icon(Icons.home, size: 24),
                    ),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4.0),
                      child: Icon(Icons.music_note_outlined, size: 24),
                    ),
                    activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 4.0),
                      child: Icon(Icons.music_note, size: 24),
                    ),
                    label: 'Sounds',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4.0),
                      child: Icon(Icons.favorite_border, size: 24),
                    ),
                    activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 4.0),
                      child: Icon(Icons.favorite, size: 24),
                    ),
                    label: 'Favorites',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4.0),
                      child: Icon(Icons.person_outline, size: 24),
                    ),
                    activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 4.0),
                      child: Icon(Icons.person, size: 24),
                    ),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
