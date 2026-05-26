import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class PlayerId {
  final String value;
  const PlayerId(this.value);

  String asString() => value;
}

final playerIdProvider = Provider<PlayerId>((ref) => PlayerId(const Uuid().v4()));


