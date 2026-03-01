import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/requirement_models.dart';
import '../requirement_data.dart';
import 'admin_roster.dart';

class RequirementSheets extends StatefulWidget {
  const RequirementSheets({super.key});

  @override
  State<RequirementSheets> createState() => _RequirementSheetsState();
}

class _RequirementSheetsState extends State<RequirementSheets> {
  String? _viewingRank;
  Set<String> _checkedIds = {};
  bool _isLoading = true;
  String? _uid;
  String _currentRank = 'White Belt';

  @override
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUserModel;

    if (auth.isAdmin) {
      setState(() => _isLoading = false);
      return;
    }

    _uid = user?.uid;
    _currentRank = user?.rank ?? 'White Belt';
    setState(() => _viewingRank = _currentRank);
    await _loadChecked(_currentRank);
  }

  Future<void> _loadChecked(String rank) async {
    setState(() => _isLoading = true);
    if (_uid == null) { setState(() => _isLoading = false); return; }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('userProgress')
          .doc(_uid)
          .collection('checkedRequirements')
          .doc(_rankDocId(rank))
          .get();
      final data = doc.data();
      setState(() {
        _checkedIds = data != null
            ? Set<String>.from((data['checked'] as List<dynamic>? ?? []))
            : {};
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleItem(String id, bool checked) async {
    setState(() {
      checked ? _checkedIds.add(id) : _checkedIds.remove(id);
    });
    if (_uid == null) return;
    await FirebaseFirestore.instance
        .collection('userProgress')
        .doc(_uid)
        .collection('checkedRequirements')
        .doc(_rankDocId(_viewingRank!))
        .set({'checked': _checkedIds.toList()});
  }

  String _rankDocId(String rank) => rank.toLowerCase().replaceAll(' ', '_');

  List<String> _previousRanks(String current) {
    final idx = rankOrder.indexOf(current);
    if (idx <= 0) return [];
    return rankOrder.sublist(0, idx).reversed.toList();
  }

  RankRequirements? _requirementsFor(String rank) {
    try { return allRankRequirements.firstWhere((r) => r.rank == rank); }
    catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUserModel;
    final isAdmin = auth.isAdmin;

    if (isAdmin) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: false,
          title: const Text('Students by Class', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
        ),
        backgroundColor: Colors.white,
        body: const AdminRosterView(),
      );
    }

    final previousRanks = _previousRanks(_currentRank);
    final reqs = _requirementsFor(_viewingRank!);

    int total = 0, done = 0;
    if (reqs != null) {
      for (final cat in reqs.categories) {
        total += cat.items.length;
        done += cat.items.where((i) => _checkedIds.contains(i.id)).length;
      }
    }

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFFCC0000),
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Rank',
                    style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12, letterSpacing: 1.1, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentRank,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.1),
                  ),
                  if (user?.program != null) ...[
                    const SizedBox(height: 4),
                    Text(user!.program, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                  ],
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (previousRanks.isNotEmpty) ...[
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _viewingRank,
                        isExpanded: true,
                        icon: const Icon(Icons.unfold_more, size: 18),
                        style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
                        items: [
                          DropdownMenuItem(value: _currentRank, child: Text('$_currentRank — current')),
                          ...previousRanks.map((r) => DropdownMenuItem(value: r, child: Text(r))),
                        ],
                        onChanged: (rank) async {
                          if (rank == null) return;
                          setState(() => _viewingRank = rank);
                          await _loadChecked(rank);
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                  ],
                  if (reqs != null) ...[
                    Row(
                      children: [
                        Text('$done of $total completed', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        const Spacer(),
                        Text(
                          total == 0 ? '' : '${((done / total) * 100).round()}%',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFCC0000)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: total == 0 ? 0 : done / total,
                      minHeight: 3,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFCC0000)),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),

          if (reqs == null)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'Requirements for $_viewingRank\ncoming soon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 15),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, i) => _buildCategory(reqs.categories[i]),
                childCount: reqs.categories.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildCategory(RequirementCategory cat) {
    final allDone = cat.items.every((i) => _checkedIds.contains(i.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
          child: Row(
            children: [
              Text(
                cat.name.toUpperCase(),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: allDone ? Colors.grey[400] : Colors.grey[500]),
              ),
              if (allDone) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_circle, size: 13, color: Colors.grey[400]),
              ],
            ],
          ),
        ),
        ...cat.items.map((item) => _buildItem(item)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 1, color: Colors.grey[100]),
        ),
      ],
    );
  }

  Widget _buildItem(RequirementItem item) {
    final checked = _checkedIds.contains(item.id);

    return InkWell(
      onTap: () => _toggleItem(item.id, !checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40,
              height: 44,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: checked,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    activeColor: const Color(0xFFCC0000),
                    side: BorderSide(color: Colors.grey[350]!, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (v) => _toggleItem(item.id, v ?? false),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  item.text,
                  style: TextStyle(fontSize: 14, height: 1.4, color: checked ? Colors.grey[400] : Colors.grey[850] ?? Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}