import 'package:flutter_riverpod/flutter_riverpod.dart';

class CurrentRoom {

  final String roomId;
  final String roomCode;

  const CurrentRoom({
    required this.roomId,
    required this.roomCode,
  });
}

/// Store the currently joined/created room.
///
/// We keep it simple for campus demo: roomId is fetched from Supabase by joining room.
final currentRoomProvider = Provider<CurrentRoom?>(
  (ref) => null,
);




