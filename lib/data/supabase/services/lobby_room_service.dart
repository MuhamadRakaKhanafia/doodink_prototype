import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_client_factory.dart';

/// Convenience wrapper (separate file for now) for lobby membership operations.
///
/// Note: This is intentionally minimal for the campus project demo.
class LobbyRoomService {
  final SupabaseClient _client;

  LobbyRoomService({SupabaseClient? client}) : _client = client ?? SupabaseClientFactory.client;

  Future<void> upsertRoomPlayer({
    required String roomId,
    required String playerId,
    required String username,
    required bool isHost,
  }) async {
    // Rely on UNIQUE(room_id, player_id)
    await _client.from('room_players').upsert({
      'room_id': roomId,
      'player_id': playerId,
      'username': username,
      'is_host': isHost,
      'is_ready': false,
    }, onConflict: 'room_id,player_id');
  }

  Future<void> setPlayerReady({
    required String roomId,
    required String playerId,
    required bool isReady,
  }) async {
    await _client
        .from('room_players')
        .update({'is_ready': isReady})
        .eq('room_id', roomId)
        .eq('player_id', playerId);
  }

  Future<List<Map<String, dynamic>>> fetchRoomPlayers({required String roomId}) async {
    final res = await _client
        .from('room_players')
        .select()
        .eq('room_id', roomId)
        .order('joined_at', ascending: true);

    return List<Map<String, dynamic>>.from(res);
  }
}


