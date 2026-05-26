import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/doodink_theme.dart';
import '../../shared/widgets/doodink_card.dart';
import '../../shared/widgets/doodink_button.dart';
import '../../state/providers/app_providers.dart';
import '../../shared/widgets/rounded_input.dart';

class JoinRoomScreen extends ConsumerStatefulWidget {
  final String username;
  const JoinRoomScreen({super.key, required this.username});

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final codeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final raw = codeController.text.trim().toUpperCase();
    if (raw.length != 4) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room code harus 4 karakter')),
      );
      return;
    }

    if (!mounted) return;

    setState(() => _loading = true);
    try {

      final roomService = ref.read(roomServiceProvider);
      final room = await roomService.joinRoomByCode(roomCode: raw);
      if (room == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room tidak ditemukan')),
        );
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/lobby', arguments: raw);

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
                  ],
                ),
                const SizedBox(height: 10),
                DoodinkCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join Room',
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
                        'Masukkan room code (contoh: ABCD)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),

                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                RoundedInput(
                  controller: codeController,
                  label: 'Room code',
                  hint: 'ABCD',
                ),

                const SizedBox(height: 16),

                DoodinkButton(
                  loading: _loading,
                  text: 'Join',
                  onPressed: _loading ? null : _join,
                  icon: Icons.login_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

