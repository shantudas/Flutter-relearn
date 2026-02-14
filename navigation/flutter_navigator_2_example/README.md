# Flutter Navigator 2.0 Example

A complete implementation of Flutter's Navigator 2.0 API demonstrating declarative routing, deep linking, and URL-based navigation.

## What is Navigator 2.0?

Navigator 2.0 (also called the Router API) is Flutter's declarative navigation system introduced to provide better control over the navigation stack and enable advanced features like:

- **Deep Linking**: Direct URL navigation to any screen in your app
- **Web Support**: Browser back/forward buttons and URL bar integration
- **Declarative Navigation**: Define your navigation state, and Flutter builds the appropriate screen stack
- **State Restoration**: Preserve and restore navigation state across app restarts

## Navigator 2.0 vs Navigator 1.0

### Navigator 1.0 (Imperative)
```dart
// Push screens imperatively
Navigator.push(context, MaterialPageRoute(builder: (_) => SecondPage()));
Navigator.pop(context);
```

**Limitations:**
- No URL support for web
- Hard to sync navigation with app state
- Back button handling is complex
- No deep linking support
- Navigation state is hidden in the Navigator widget

### Navigator 2.0 (Declarative)
```dart
// Declare pages based on state
pages: [
  MaterialPage(child: FirstPage()),
  if (showSecond) MaterialPage(child: SecondPage()),
]
```

**Benefits:**
- ✅ Full URL and deep linking support
- ✅ Navigation state is explicit and manageable
- ✅ Works seamlessly with browser back/forward
- ✅ Better state restoration
- ✅ Easier to test and debug
- ✅ Single source of truth for navigation

## How Navigator 2.0 Works

Navigator 2.0 uses three main components working together:

```
URL/Deep Link → RouteInformationParser → Configuration
                                              ↓
                                        RouterDelegate
                                              ↓
                                         Page Stack
```

1. **RouteInformationParser**: Converts URLs to app configuration
2. **RouterDelegate**: Builds the Navigator widget with appropriate pages based on configuration
3. **App State**: Holds the current navigation state (which pages to show)

## Project Implementation

### Architecture Overview

```
MyApp (StatefulWidget)
  ├── AppState (ChangeNotifier) - Navigation state
  ├── MyRouteInformationParser - URL parsing
  └── MyRouterDelegate - Page building
```

### Class Descriptions

#### 1. `MyApp` & `_MyAppState`

The root widget that sets up the Router infrastructure.

```dart
class _MyAppState extends State<MyApp> {
  final AppState _appState = AppState();
  late final MyRouterDelegate _routerDelegate;
  final _routeInformationParser = MyRouteInformationParser();
```

**Key Features:**
- Creates single instances of AppState, RouterDelegate, and RouteInformationParser
- Uses `MaterialApp.router` instead of `MaterialApp` to enable Navigator 2.0
- Passes the state to RouterDelegate for coordination

**Why:** Centralizes navigation setup and ensures all components share the same state.

---

#### 2. `AppState` (extends ChangeNotifier)

The single source of truth for navigation state.

```dart
class AppState extends ChangeNotifier {
  String _currentPage = "first";
  
  void navigatToFirstPage() {
    _currentPage = "first";
    notifyListeners();
  }
  
  void navigatToSecondPage() {
    _currentPage = "second";
    notifyListeners();
  }
}
```

**Key Features:**
- Holds `_currentPage` state ("first" or "second")
- Extends `ChangeNotifier` to notify listeners when state changes
- Provides methods to change navigation state

**Why:** 
- Separates navigation logic from UI
- Makes navigation state observable and testable
- Single source of truth prevents state synchronization issues

---

#### 3. `MyRouteInformationParser` (extends RouteInformationParser<String>)

Converts between URLs and app configuration.

```dart
class MyRouteInformationParser extends RouteInformationParser<String> {
  @override
  Future<String> parseRouteInformation(RouteInformation routeInformation) async {
    final uri = routeInformation.uri;
    
    if (uri.pathSegments.isEmpty) return 'first';
    if (uri.pathSegments[0] == 'second') return 'second';
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
```

**Key Features:**
- **`parseRouteInformation`**: URL → Configuration
  - `/` → "first"
  - `/second` → "second"
- **`restoreRouteInformation`**: Configuration → URL
  - "first" → `/`
  - "second" → `/second`

**Why:**
- Enables deep linking (direct URL navigation)
- Updates browser URL bar on web
- Handles app state restoration from URLs

---

#### 4. `MyRouterDelegate` (extends RouterDelegate<String>)

The heart of Navigator 2.0 - builds the page stack based on state.

```dart
class MyRouterDelegate extends RouterDelegate<String>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<String> {
  
  final AppState _appState;
  
  MyRouterDelegate(this._appState) {
    _appState.addListener(notifyListeners);
  }
```

**Key Components:**

##### Mixins:
- **`ChangeNotifier`**: Notifies Router when navigation state changes
- **`PopNavigatorRouterDelegateMixin`**: Handles system back button

##### Constructor:
```dart
MyRouterDelegate(this._appState) {
  _appState.addListener(notifyListeners);
}
```
- Listens to AppState changes
- Calls `notifyListeners()` to rebuild when state changes

##### `currentConfiguration` getter:
```dart
@override
String get currentConfiguration => _appState.currentPage;
```
- Returns current route configuration
- Used by RouteInformationParser to update URLs

##### `build` method:
```dart
@override
Widget build(BuildContext context) {
  return Navigator(
    key: navigatorKey,
    pages: [
      MaterialPage(
        key: const ValueKey('FirstPage'),
        child: FirstPage(onNavigate: () => _appState.navigatToSecondPage()),
      ),
      if (_appState.currentPage == 'second')
        MaterialPage(
          key: const ValueKey('SecondPage'),
          child: SecondPage(onNavigate: () => _appState.navigatToFirstPage()),
        ),
    ],
    onDidRemovePage: (page) {
      if (page.key == const ValueKey('SecondPage')) {
        Future.microtask(() => _appState.navigatToFirstPage());
      }
    },
  );
}
```

**Declarative Pages:**
- FirstPage is always in the stack
- SecondPage is conditionally added when `_appState.currentPage == 'second'`
- Each page has a unique `ValueKey` for identification

**`onDidRemovePage` callback:**
- Called when user presses back button or pops a page
- Uses `Future.microtask()` to defer state update (avoids "setState during build" error)
- Updates AppState to reflect the page removal

##### `setNewRoutePath` method:
```dart
@override
Future<void> setNewRoutePath(String configuration) async {
  if (configuration == 'second') {
    _appState.navigatToSecondPage();
  } else {
    _appState.navigatToFirstPage();
  }
}
```
- Called when URL changes (deep link or browser navigation)
- Updates AppState based on the new route configuration

**Why:**
- Centralizes all navigation logic
- Makes navigation state explicit and visible
- Handles both programmatic navigation and system back button

---

#### 5. `FirstPage` & `SecondPage`

Simple stateless widgets representing app screens.

```dart
class FirstPage extends StatelessWidget {
  final VoidCallback onNavigate;
  
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
```

**Key Features:**
- Accept `onNavigate` callback for navigation
- Don't manage navigation state themselves
- Pure presentation components

**Why:**
- Separation of concerns (UI vs navigation logic)
- Makes pages reusable and testable
- Navigation logic stays in AppState

---

## Navigation Flow Example

### User clicks "Go to Second Page":

1. Button calls `onNavigate()` → `_appState.navigatToSecondPage()`
2. AppState updates `_currentPage = "second"` and calls `notifyListeners()`
3. RouterDelegate's listener triggers `notifyListeners()` to Router
4. Router calls `build()` → SecondPage is added to pages list
5. Navigator displays SecondPage with transition animation
6. Router calls `currentConfiguration` → returns "second"
7. RouteInformationParser converts "second" → `/second`
8. Browser URL updates to `/second` (on web)

### User presses system back button:

1. System triggers Navigator to remove SecondPage
2. `onDidRemovePage` callback is called
3. `Future.microtask()` defers state update to next frame
4. AppState calls `navigatToFirstPage()`
5. RouterDelegate rebuilds → SecondPage removed from pages
6. Navigator animates back to FirstPage
7. URL updates back to `/`

### User navigates directly to `/second` URL:

1. RouteInformationParser receives URL `/second`
2. `parseRouteInformation` returns configuration "second"
3. Router calls `setNewRoutePath("second")`
4. RouterDelegate updates AppState to show second page
5. `build()` includes SecondPage in pages list
6. Navigator displays SecondPage

---

## Key Concepts

### Declarative Pages
Instead of pushing/popping screens, you declare which pages should be in the stack based on state:
```dart
pages: [
  MaterialPage(child: FirstPage()),
  if (showSecond) MaterialPage(child: SecondPage()),  // Conditional page
  if (showThird) MaterialPage(child: ThirdPage()),
]
```

### State Synchronization
All navigation state flows through AppState:
```
User Action → AppState → RouterDelegate → Pages → UI
Deep Link → RouteInformationParser → RouterDelegate → AppState → Pages
```

### Future.microtask() for Back Button
```dart
onDidRemovePage: (page) {
  Future.microtask(() => _appState.navigatToFirstPage());
}
```
Required because `onDidRemovePage` is called during build phase. Deferring the state update avoids "setState during build" errors.

---

## Running the Project

```bash
# Run on mobile/desktop
flutter run

# Run on web (see URL changes in browser)
flutter run -d chrome

# Test deep linking on web
# Navigate to: http://localhost:port/#/second
```

---

## Benefits of This Implementation

1. **Testable**: Navigation logic is in AppState, easy to unit test
2. **Maintainable**: Clear separation of concerns
3. **Scalable**: Easy to add more pages by extending AppState
4. **Web-Ready**: Full URL support out of the box
5. **State-Driven**: Navigation always matches app state
6. **Debuggable**: Can inspect AppState to see current navigation state

---

## Further Enhancements

To extend this example:

1. **Add more pages**: Extend AppState with more page states
2. **Route parameters**: Parse IDs from URLs (`/user/123`)
3. **Nested navigation**: Multiple Navigators for tab-based apps
4. **Authentication**: Guard routes based on login state
5. **Transitions**: Custom page transitions with CustomPage
6. **404 handling**: Add unknown route handling in parser

---

## References

- [Flutter Navigator 2.0 Documentation](https://docs.flutter.dev/development/ui/navigation)
- [Learning Flutter's new navigation and routing system](https://medium.com/flutter/learning-flutters-new-navigation-and-routing-system-7c9068155ade)
- [MaterialApp.router API](https://api.flutter.dev/flutter/material/MaterialApp/MaterialApp.router.html)
