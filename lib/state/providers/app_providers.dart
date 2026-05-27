import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/supabase/services/room_service.dart';

final roomServiceProvider = Provider<RoomService>((ref) {
  return RoomService();
});

