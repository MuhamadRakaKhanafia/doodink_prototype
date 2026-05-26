import 'package:flutter/material.dart';

import '../features/main_menu/main_menu_screen.dart';

import '../features/join_room/join_room_screen.dart';
import '../features/lobby/lobby_screen.dart';
import '../features/create_room/create_room_screen.dart';

class AppRouter {
  static const String mainMenu = '/mainMenu';
  static const String joinRoom = '/joinRoom';
  static const String createRoom = '/createRoom';
  static const String lobby = '/lobby';
  static const String writing = '/writing';
  static const String drawing = '/drawing';
  static const String guessing = '/guessing';
  static const String reveal = '/reveal';
  static const String result = '/result';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Saat ini kita hanya punya main menu (placeholders lain untuk iterasi selanjutnya).
    switch (settings.name) {
      case mainMenu:
      case '/':
        return MaterialPageRoute(builder: (_) => const MainMenuScreen());

      case joinRoom:
        return MaterialPageRoute(
          builder: (context) {
            final username = (settings.arguments as Map?)?['username'] as String?;
            final safeUsername = username ?? 'Player';
            return JoinRoomScreen(username: safeUsername);
          },
        );

      case createRoom:
        return MaterialPageRoute(
          builder: (context) {
            final username = (settings.arguments as Map?)?['username'] as String?;
            final safeUsername = username ?? 'Player';
            return CreateRoomScreen(username: safeUsername);
          },
        );

      case lobby:
        return MaterialPageRoute(
          builder: (context) {
            final args = settings.arguments;
            final roomCode = (args is String) ? args : (args as Map?)?['roomCode'] as String?;
            return LobbyScreen(roomCode: roomCode ?? '????');
          },
        );

      default:
        return MaterialPageRoute(builder: (_) => const MainMenuScreen());

    }
  }
}

