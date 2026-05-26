import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/doodink_theme.dart';
import '../../shared/widgets/doodink_card.dart';
import '../../shared/widgets/doodink_button.dart';
import '../../state/providers/app_providers.dart';
import '../../state/providers/player_provider.dart';
import '../../state/providers/lobby_room_provider.dart';



class CreateRoomScreen extends ConsumerStatefulWidget {
  final String username;
  const CreateRoomScreen({super.key, required this.username});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  bool _loading = false;

  String _generateRoomCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random();
    return List.generate(4, (_) => alphabet[r.nextInt(alphabet.length)]).join();
  }

  Future<void> _create() async {
    setState(() => _loading = true);

    try {
      final roomService = ref.read(roomServiceProvider);
      final playerId = ref.read(playerIdProvider).asString();


      final roomCode = _generateRoomCode();
      final created = await roomService.createRoom(
        roomCode: roomCode,
        hostPlayerId: playerId,
      );

      if (created == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat room')),
        );
        return;
      }

      // Insert room_players untuk host
      await ref.read(lobbyRoomServiceProvider).upsertRoomPlayer(
        roomId: created['id'] as String,
        playerId: playerId,
        username: widget.username,
        isHost: true,
      );


      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/lobby', arguments: roomCode);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DoodinkTheme.gradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Spacer(),
                    const Hero(tag: 'doodink-logo', child: SizedBox.shrink()),
                  ],
                ),
                const SizedBox(height: 10),
                DoodinkCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Room',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Username: ${widget.username}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Room code akan dibuat otomatis. Kamu jadi host pertama.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DoodinkButton(
                  loading: _loading,
                  text: 'Create',
                  onPressed: _loading ? null : _create,
                  icon: Icons.add_box_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

