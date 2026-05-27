import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/supabase/supabase_client_factory.dart';
import '../../data/supabase/services/lobby_realtime_service.dart';

import '../../shared/widgets/doodink_card.dart';
import '../../state/providers/app_providers.dart';
import '../../state/providers/lobby_room_provider.dart';
import '../../state/providers/player_provider.dart';
import '../../theme/doodink_theme.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  final String roomCode;
  const LobbyScreen({super.key, required this.roomCode});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  bool _loading = true;
  bool _roomStarting = false;

  String? _roomId;
  List<Map<String, dynamic>> _players = [];

  LobbyRealtimeService? _realtime;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _realtime?.unsubscribeAll();
    super.dispose();
  }

  bool get _allReady {
    if (_players.isEmpty) return false;
    return _players.every((p) => (p['is_ready'] ?? false) == true);
  }

  Future<void> _setReady(bool isReady) async {
    final roomId = _roomId;
    if (roomId == null || roomId.isEmpty) return;

    final lobbyRoomService = ref.read(lobbyRoomServiceProvider);
    final playerId = ref.read(playerIdProvider).asString();

    await lobbyRoomService.setPlayerReady(
      roomId: roomId,
      playerId: playerId,
      isReady: isReady,
    );
  }

  Future<void> _startGame() async {
    final roomId = _roomId;
    if (roomId == null || roomId.isEmpty) return;

    if (_roomStarting) return;
    if (!_allReady) return;

    setState(() => _roomStarting = true);
    try {
      final roomService = ref.read(roomServiceProvider);

      // 30 detik untuk fase prompting tema
      await roomService.setRoomPhase(
        roomId: roomId,
        phase: 'writing',
        phaseStartedAtUtc: DateTime.now().toUtc(),
        phaseDurationMs: 30000,
        turnIndex: 0,
      );

      if (!mounted) return;
      setState(() => _roomStarting = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _roomStarting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildReadyButtonForPlayer(Map<String, dynamic> p) {
    final isHost = (p['is_host'] ?? false) == true;
    final isReady = (p['is_ready'] ?? false) == true;

    final currentPlayerId = ref.read(playerIdProvider).asString();
    final playerId = p['player_id']?.toString();
    final isMe = playerId != null && playerId == currentPlayerId;

    if (isHost) {
      return ElevatedButton.icon(
        onPressed: _roomId == null
            ? null
            : (_allReady && !_roomStarting)
                ? _startGame
                : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          backgroundColor: Colors.white.withValues(alpha: 0.12),
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.06),
        ),
        icon: const Icon(Icons.play_arrow_rounded, size: 18),
        label: Text(
          _roomStarting ? 'Starting...' : 'Mulai',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      );
    }

    if (!isMe) return const SizedBox.shrink();

    return ElevatedButton.icon(
      onPressed: _loading || _roomId == null
          ? null
          : () async {
              await _setReady(!isReady);
            },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        backgroundColor: Colors.white.withValues(alpha: 0.12),
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.06),
      ),
      icon: Icon(isReady ? Icons.check_rounded : Icons.done_outline_rounded, size: 18),
      label: Text(
        isReady ? 'Ready' : 'Belum ready',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
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
          _roomId = null;
          _loading = false;
        });
        return;
      }

      _roomId = roomId;

      final lobbyRoomService = ref.read(lobbyRoomServiceProvider);
      final players = await lobbyRoomService.fetchRoomPlayers(roomId: roomId);

      _realtime = LobbyRealtimeService(client: SupabaseClientFactory.client);
      _realtime!.subscribeRoomPlayers(
        roomId: roomId,
        onPlayersChanged: (players) {
          if (!mounted) return;
          setState(() => _players = players);
        },
      );

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
                          _loading
                              ? 'Memuat room...'
                              : 'Semua player harus Ready dulu',
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
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w700,
                                ),
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
                                          isHost
                                              ? Icons.emoji_events_rounded
                                              : Icons.person_rounded,
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
                                            child: Icon(
                                              Icons.star_rounded,
                                              color: Colors.yellow,
                                              size: 18,
                                            ),
                                          ),
                                        const SizedBox(width: 10),
                                        _buildReadyButtonForPlayer(p),
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

