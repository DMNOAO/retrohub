import 'package:flutter/material.dart';

import '../../data/database/app_database.dart';

class FramesPage extends StatelessWidget {
  final Game game;

  const FramesPage({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    final frames = [
      'Clásico oscuro',
      'Game Boy Color',
      'Pokémon Gold',
      'Pokémon Crystal',
      'Minimalista',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marcos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              game.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Personaliza el marco para ${game.console}'),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                itemCount: frames.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
                  final frame = frames[index];

                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Marco seleccionado: $frame'),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.filter_frames,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            frame,
                            textAlign: TextAlign.center,
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
    );
  }
}