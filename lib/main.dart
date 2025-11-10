import 'package:audio/screens/forgot_password_page.dart';
import 'package:audio/screens/login_page.dart';
import 'package:audio/screens/player_page.dart';
import 'package:audio/screens/signup_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio/providers/audio_provider.dart';
import 'package:audio/widgets/mini_player.dart';
import 'package:audio/screens/home_page.dart';
import 'package:audio/screens/search_page.dart';
import 'package:audio/screens/library_page.dart';
import 'package:audio/screens/history_page.dart';
import 'package:audio/screens/profile_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AudioApp());
}

class AudioApp extends StatelessWidget {
  const AudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AudioProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Audio App',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.deepPurple,
        ),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasData) {
              return const MainScreen();
            }
            return const LoginPage();
          },
        ),
        routes: {
          '/home': (context) => const MainScreen(),
          '/search': (context) => const MainScreen(initialIndex: 1),
          '/library': (context) => const MainScreen(initialIndex: 2),
          '/history': (context) => const MainScreen(initialIndex: 3),
          '/profile': (context) => const MainScreen(initialIndex: 4),
          '/player': (context) => const PlayerPage(),
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignUpPage(),
          '/forgot': (context) => const ForgotPasswordPage(),
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final List<Widget> _screens = const [
    HomePage(),
    SearchPage(),
    LibraryPage(),
    HistoryPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (audioProvider.hasCurrentSong) const MiniPlayer(),
          NavigationBar(
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: "Home"),
              NavigationDestination(icon: Icon(Icons.search), label: "Search"),
              NavigationDestination(icon: Icon(Icons.library_music), label: "Library"),
              NavigationDestination(icon: Icon(Icons.history), label: "History"),
              NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
            ],
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ],
      ),
    );
  }
}
