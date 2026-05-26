import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/doodink_card.dart';
import '../../state/providers/app_providers.dart';
import '../../state/providers/lobby_room_provider.dart';
import '../../theme/doodink_theme.dart';


class LobbyScreen extends ConsumerStatefulWidget {
  final String roomCode;
  const LobbyScreen({super.key, required this.roomCode});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  bool _loading = true;

  List<Map<String, dynamic>> _players = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final roomService = ref.read(roomServiceProvider);
      final room = await roomService.joinRoomByCode(roomCode: widget.roomCode);

      final roomId = room?['id']?.toString();
      if (roomId == null || roomId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _players = [];
          _loading = false;
        });
        return;
      }

      final lobbyRoomService = ref.read(lobbyRoomServiceProvider);
      final players = await lobbyRoomService.fetchRoomPlayers(roomId: roomId);

      if (!mounted) return;
      setState(() {
        _players = players;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: const [
                    Icon(Icons.people_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 10),
                    _LobbyTitle(),
                    Spacer(),
                  ],
                ),
                const SizedBox(height: 14),

                Card(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Join URL',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          'https://doodink.app/join/${widget.roomCode}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _loading ? 'Memuat room...' : 'Room realtime belum diaktifkan (fetch sekali).',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : _players.isEmpty
                          ? const Center(
                              child: Text(
                                'Belum ada player',
                                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _players.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),

                              itemBuilder: (context, index) {
                                final p = _players[index];
                                final username = (p['username'] ?? 'Unknown').toString();
                                final isHost = (p['is_host'] ?? false) == true;
                                final isReady = (p['is_ready'] ?? false) == true;
                                return DoodinkCard(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isHost ? Icons.emoji_events_rounded : Icons.person_rounded,
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                username,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w900,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                isReady ? 'Ready' : 'Not ready',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: Colors.white.withValues(alpha: 0.85),
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isHost)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 8),
                                            child: Icon(Icons.star_rounded, color: Colors.yellow, size: 18),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LobbyTitle extends StatelessWidget {
  const _LobbyTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Lobby',
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: 34,
            fontWeight: FontWeight.w900,
          ),
    );
  }
}


