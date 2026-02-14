import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppState _appState = AppState();
  late final MyRouterDelegate _routerDelegate;
  final _routeInformationParser = MyRouteInformationParser();

  @override
  void initState() {
    super.initState();
    _routerDelegate = MyRouterDelegate(_appState);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Navigator 2.0 Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerDelegate: _routerDelegate,
      routeInformationParser: _routeInformationParser,
    );
  }
}

class AppState extends ChangeNotifier {
  String _currentPage = "first";

  String get currentPage => _currentPage;

  void navigatToFirstPage() {
    _currentPage = "first";
    notifyListeners();
  }

  void navigatToSecondPage() {
    _currentPage = "second";
    notifyListeners();
  }
}

// Route Information Parser
class MyRouteInformationParser extends RouteInformationParser<String> {
  @override
  Future<String> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final uri = routeInformation.uri;

    if (uri.pathSegments.isEmpty) {
      return 'first';
    } else if (uri.pathSegments.length == 1) {
      final path = uri.pathSegments[0];
      if (path == 'second') {
        return 'second';
      }
    }
    return 'first';
  }

  @override
  RouteInformation? restoreRouteInformation(String configuration) {
    if (configuration == 'second') {
      return RouteInformation(uri: Uri.parse('/second'));
    }
    return RouteInformation(uri: Uri.parse('/'));
  }
}

// Router Delegate
class MyRouterDelegate extends RouterDelegate<String>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<String> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final AppState _appState;

  MyRouterDelegate(this._appState) {
    _appState.addListener(notifyListeners);
  }

  @override
  void dispose() {
    _appState.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  String get currentConfiguration => _appState.currentPage;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        MaterialPage(
          key: const ValueKey('FirstPage'),
          child: FirstPage(
            onNavigate: () {
              _appState.navigatToSecondPage();
            },
          ),
        ),
        if (_appState.currentPage == 'second')
          MaterialPage(
            key: const ValueKey('SecondPage'),
            child: SecondPage(
              onNavigate: () {
                _appState.navigatToFirstPage();
              },
            ),
          ),
      ],
      onDidRemovePage: (page) {
        if (page.key == const ValueKey('SecondPage')) {
          Future.microtask(() => _appState.navigatToFirstPage());
        }
      },
    );
  }

  @override
  Future<void> setNewRoutePath(String configuration) async {
    if (configuration == 'second') {
      _appState.navigatToSecondPage();
    } else {
      _appState.navigatToFirstPage();
    }
  }
}

class FirstPage extends StatelessWidget {
  final VoidCallback onNavigate;

  const FirstPage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('First Page')),
      body: Center(
        child: ElevatedButton(
          onPressed: onNavigate,
          child: const Text('Go to Second Page'),
        ),
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  final VoidCallback onNavigate;
  const SecondPage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Second Page')),
      body: Center(
        child: ElevatedButton(
          onPressed: onNavigate,
          child: const Text('Go to First Page'),
        ),
      ),
    );
  }
}
