import 'package:flutter/material.dart';

import '../../theme/doodink_theme.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});


  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final usernameController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: DoodinkTheme.gradientBackground(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'DoodInk',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'party drawing • guess • reveal',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 22),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Username',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: usernameController,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                hintText: 'e.g. Nanda',
                                filled: true,
fillColor: Colors.white.withValues(alpha: 0.08),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    ElevatedButton.icon(
                      onPressed: () {
                        final username = usernameController.text.trim();
                        if (username.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Username wajib diisi')),
                          );
                          return;
                        }
                        Navigator.of(context).pushNamed(
                          '/createRoom',
                          arguments: {'username': username},
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Room'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        final username = usernameController.text.trim();
                        if (username.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Username wajib diisi')),
                          );
                          return;
                        }
                        Navigator.of(context).pushNamed(
                          '/joinRoom',
                          arguments: {'username': username},
                        );
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Join Room'),

                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      'Tip: start dulu dengan 2 device untuk lihat realtime.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w700,
                          ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

