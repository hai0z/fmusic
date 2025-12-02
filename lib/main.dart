import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'services/audio_player_service.dart';
import 'providers/player_provider.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'widgets/mini_player.dart';

// Global key để access MainScreen state
final GlobalKey<MainScreenState> mainScreenKey = GlobalKey<MainScreenState>();

// Helper để navigate trong shell (giữ tabbar + mini player)
void navigateInShell(BuildContext context, Widget screen) {
  mainScreenKey.currentState?.pushScreen(screen);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid || Platform.isIOS) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.fmusic.audio',
      androidNotificationChannelName: 'FMusic',
      androidNotificationOngoing: true,
    );
  }

  await audioPlayer.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlayerProvider(),
      child: MaterialApp(
        title: 'FMusic',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            elevation: 0,
          ),
        ),
        home: MainScreen(key: mainScreenKey),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screenStack = [];

  void pushScreen(Widget screen) {
    setState(() => _screenStack.add(screen));
  }

  void popScreen() {
    if (_screenStack.isNotEmpty) {
      setState(() => _screenStack.removeLast());
    }
  }

  bool get canPop => _screenStack.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _screenStack.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _screenStack.isNotEmpty) {
          popScreen();
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Tab screens (luôn ở dưới)
                  IndexedStack(
                    index: _currentIndex,
                    children: const [HomeScreen(), SearchScreen()],
                  ),
                  // Pushed screens overlay lên trên
                  for (int i = 0; i < _screenStack.length; i++)
                    Positioned.fill(
                      child: Material(
                        color: Colors.black,
                        child: _screenStack[i],
                      ),
                    ),
                ],
              ),
            ),
            // Mini player luôn hiển thị
            const MiniPlayer(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border(
              top: BorderSide(color: Colors.grey[900]!, width: 0.5),
            ),
          ),
          child: NavigationBar(
            backgroundColor: Colors.black,
            indicatorColor: Colors.transparent,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _screenStack.clear(); // Clear stack khi chuyển tab
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: Colors.grey),
                selectedIcon: Icon(Icons.home, color: Colors.white),
                label: 'Trang chủ',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined, color: Colors.grey),
                selectedIcon: Icon(Icons.search, color: Colors.white),
                label: 'Tìm kiếm',
              ),
            ],
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          ),
        ),
      ),
    );
  }
}
