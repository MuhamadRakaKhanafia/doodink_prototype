import 'package:supabase_flutter/supabase_flutter.dart';



/// Realtime helper for Lobby.
///
/// Subscribes to:
/// - `room_players` changes for a given `room_id`
/// - `rooms` changes for a given `room_id`
class LobbyRealtimeService {
  LobbyRealtimeService({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  RealtimeChannel? _playersChannel;
  RealtimeChannel? _roomChannel;

  /// Subscribe to room_players changes, calling [onPlayersChanged] when data changes.
  void subscribeRoomPlayers({
    required String roomId,
    required void Function(List<Map<String, dynamic>> players) onPlayersChanged,
  }) {
    _playersChannel?.unsubscribe();

    _playersChannel = _client
        .channel('room_players:room_id=$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'room_players',
          callback: (payload) async {

            // Easiest + robust: refetch players after a change event.
            final res = await _client
                .from('room_players')
                .select()
                .eq('room_id', roomId)
                .order('joined_at', ascending: true);

            onPlayersChanged(List<Map<String, dynamic>>.from(res));
          },
        )
        .subscribe();
  }

  /// Subscribe to rooms changes, calling [onRoomChanged] when data changes.
  void subscribeRooms({
    required String roomId,
    required void Function(Map<String, dynamic>? room) onRoomChanged,
  }) {
    _roomChannel?.unsubscribe();

    _roomChannel = _client
        .channel('rooms:id=$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'rooms',

          callback: (payload) async {
            final res = await _client
                .from('rooms')
                .select()
                .eq('id', roomId)
                .maybeSingle();

            onRoomChanged(res is Map<String, dynamic> ? res : null);
          },
        )
        .subscribe();
  }

  void unsubscribeAll() {
    _playersChannel?.unsubscribe();
    _roomChannel?.unsubscribe();
    _playersChannel = null;
    _roomChannel = null;
  }
}

