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

    // _viewingRank is set async in _init, guard until it's ready
    if (_viewingRank == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final previousRanks = _previousRanks(_currentRank);
    final reqs = _requirementsFor(_viewingRank!);

    int total = 0, done = 0;
    if (reqs != null) {
      for (final cat in reqs.categories) {
        total += cat.items.length;
        done += cat.items.where((i) => _checkedIds.contains(i.id)).length;
      }
    }

    final progress = total == 0 ? 0.0 : done / total;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          // rank info card at the top
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // rank info
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCC0000),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Rank',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 11,
                                      letterSpacing: 0.8,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _currentRank,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                                  ),
                                  if (user?.program != null && user!.program.isNotEmpty)
                                    Text(
                                      user.program,
                                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                                    ),
                                ],
                              ),
                            ),
                            // big % on the right so progress is immediately visible
                            Text(
                              '${(progress * 100).round()}%',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              '$done of $total completed',
                              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: Colors.white.withOpacity(0.25),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // only show if student has previous ranks to view
                  if (previousRanks.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _viewingRank,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      items: [
                        DropdownMenuItem(value: _currentRank, child: Text('$_currentRank (current)')),
                        ...previousRanks.map((r) => DropdownMenuItem(value: r, child: Text(r))),
                      ],
                      onChanged: (rank) async {
                        if (rank == null) return;
                        setState(() => _viewingRank = rank);
                        await _loadChecked(rank);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (reqs == null)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'Requirements for $_viewingRank\ncoming soon',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 15),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildCategory(reqs.categories[i]),
                  ),
                  childCount: reqs.categories.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategory(RequirementCategory cat) {
    final items = cat.items;
    final allDone = items.every((i) => _checkedIds.contains(i.id));
    final doneCnt = items.where((i) => _checkedIds.contains(i.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // category header row with done count
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                cat.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: allDone ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
              const Spacer(),
              if (allDone)
                Icon(Icons.check_circle, size: 13, color: Colors.grey[400])
              else
                Text(
                  '$doneCnt/${items.length}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final last = idx == items.length - 1;
              return _buildItem(item, idx, last);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(RequirementItem item, int idx, bool last) {
    final checked = _checkedIds.contains(item.id);

    return Column(
      children: [
        InkWell(
          onTap: () => _toggleItem(item.id, !checked),
          borderRadius: BorderRadius.vertical(
            top: idx == 0 ? const Radius.circular(4) : Radius.zero,
            bottom: last ? const Radius.circular(4) : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: checked ? Colors.grey[400] : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
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
              ],
            ),
          ),
        ),
        if (!last)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Divider(height: 1, color: Colors.grey.shade100),
          ),
      ],
    );
  }
}