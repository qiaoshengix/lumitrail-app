import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/main_shell.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _checking = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    try {
      final loggedIn = await AuthApi.isLoggedIn();
      if (mounted) {
        setState(() {
          _loggedIn = loggedIn;
          _checking = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loggedIn = false;
          _checking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return MaterialApp(
        key: const ValueKey('loading'),
        debugShowCheckedModeBanner: false,
        theme: appTheme(),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return MaterialApp(
      key: const ValueKey('app'),
      title: '光影随行',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      initialRoute: _loggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const MainShell(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/analyze':
          case '/outfit':
          case '/profile':
            return MaterialPageRoute(
              builder: (_) =>
                  MainShell(initialIndex: _indexFor(settings.name!)),
            );
          default:
            return MaterialPageRoute(builder: (_) => const LoginPage());
        }
      },
    );
  }

  int _indexFor(String route) {
    switch (route) {
      case '/analyze':
        return 0;
      case '/outfit':
        return 1;
      case '/profile':
        return 2;
      default:
        return 0;
    }
  }
}
