import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client_factory.dart';

class RoomService {
  final SupabaseClient _client;

  RoomService({SupabaseClient? client}) : _client = client ?? SupabaseClientFactory.client;

  void _logSupabaseError(String operation, Object e) {
    debugPrint('[RoomService][$operation] Error: $e');
  }


  Future<Map<String, dynamic>?> createRoom({
    required String roomCode,
    required String hostPlayerId,
  }) async {
    try {
      final res = await _client
          .from('rooms')
          .insert({
            'room_code': roomCode,
            'host_player_id': hostPlayerId,
            'game_phase': 'lobby',
          })
          .select()
          .maybeSingle();

      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      _logSupabaseError('createRoom', e);
      rethrow;
    }

  }


  Future<Map<String, dynamic>?> joinRoomByCode({required String roomCode}) async {
    try {
      final res = await _client
          .from('rooms')
          .select()
          .eq('room_code', roomCode)
          .maybeSingle();

      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      _logSupabaseError('joinRoomByCode', e);

      debugPrint('[RoomService][joinRoomByCode] Unexpected error: $e');
      rethrow;
    }
  }

  Future<void> setRoomPhase({
    required String roomId,
    required String phase,
    required DateTime phaseStartedAtUtc,
    required int phaseDurationMs,
    required int turnIndex,
  }) async {
    try {
      await _client
          .from('rooms')
          .update({
            'game_phase': phase,
            'phase_started_at': phaseStartedAtUtc.toIso8601String(),
            'phase_duration_ms': phaseDurationMs,
            'turn_index': turnIndex,
          })
          .eq('id', roomId);
    } catch (e) {
      _logSupabaseError('setRoomPhase', e);
      rethrow;
    }

  }
}


