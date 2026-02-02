// easier to compartmentalize requirements, might change to pdf view later or just remove this screen (not very complex)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class RequirementSheets extends StatelessWidget {
  const RequirementSheets({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserModel;

    // define requirements for each belt rank (main topics for each card)
    final Map<String, List<String>> requirements = {
      'White Belt': [
        // random, to test
        'Basic stances (front, back, horse)',
        'Basic blocks (high, middle, low)',
        'Basic strikes (punch, knife-hand)',
        'Basic kicks (front, roundhouse)',
        'Self-control and discipline',
      ],
      'Yellow Belt': [
        // fill in later
      ],
      'Green Belt': [
        // fill in later
      ],
      'Blue Belt': [
        // fill in later
      ],
      'Brown Belt': [
        // fill in later
      ],
      'Red Belt': [
        // fill in later
      ],
      'Black Belt': [
        // fill in later
      ],
    };

    final userRank = user?.rank ?? 'White Belt';
    final userRequirements = requirements[userRank] ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // header with rank/program
        Card(
          color: const Color(0xFFFF0000),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(
                  Icons.military_tech,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  'Current Rank: $userRank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Program: ${user?.program ?? "Unknown"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // requirements header
        const Text(
          'Requirements for Next Rank',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // requirements list
        ...userRequirements.asMap().entries.map((entry) {
          return _buildRequirementCard(entry.key + 1, entry.value);
        }),

        const SizedBox(height: 24),

        // info card
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'Testing Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'info about testing...',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementCard(int number, String requirement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFF0000),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                requirement,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}