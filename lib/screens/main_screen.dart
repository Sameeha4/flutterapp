import 'package:flutter/material.dart';
import 'features_tab.dart';
import 'gallery_tab.dart';
import 'maps_tab.dart';
import 'main_chat_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Screens for each tab (only body content, no Scaffold)
  late final List<Widget> _widgetOptions;

  // Titles for AppBar
  final List<String> _titles = ['Chats', 'Gallery', 'Maps', 'Features'];

  @override
  void initState() {
    super.initState();
    _widgetOptions = [
      const MainChatScreen(), // Chats
      const GalleryTab(),
      const MapsTab(),
      const FeaturesTab(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/auth', (route) => false);
            },
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Maps'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Features'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}
