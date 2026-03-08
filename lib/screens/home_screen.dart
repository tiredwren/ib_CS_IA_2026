import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'calendar_screen.dart';
import 'requirement_sheets_screen.dart';
import 'proshop_screen.dart';
import 'settings_screen.dart';
import 'admin_roster.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final isAdmin = auth.isAdmin;

    // tab screens differ by role
    final screens = [
      const Calendar(),
      isAdmin ? const _RosterTab() : const RequirementSheets(),
      const Proshop(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo.png',
          height: 40,
          errorBuilder: (_, __, ___) =>
          const Text('TRUE MARTIAL ARTS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 4),
                    Text(isAdmin ? 'Admin' : 'Student', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: screens[_idx],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFCC0000),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(icon: Icons.calendar_today, label: 'Calendar', idx: 0),
                isAdmin
                    ? _navItem(icon: Icons.people_outline, label: 'Roster', idx: 1)
                    : _navItem(icon: Icons.description, label: 'Requirements', idx: 1),
                _navItem(icon: Icons.store_outlined, label: 'Pro Shop', idx: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required int idx}) {
    final sel = _idx == idx;
    return GestureDetector(
      onTap: () => setState(() => _idx = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// wraps AdminRosterView in scaffold so it has its own appbar as a tab
class _RosterTab extends StatelessWidget {
  const _RosterTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        title: const Text('Roster', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
      ),
      body: const AdminRosterView(),
    );
  }
}