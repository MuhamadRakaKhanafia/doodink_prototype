import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/supabase/services/lobby_room_service.dart';

final lobbyRoomServiceProvider = Provider<LobbyRoomService>((ref) {
  return LobbyRoomService();
});

