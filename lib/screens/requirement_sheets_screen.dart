import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class RequirementItem {
  final String id;
  final String text;
  const RequirementItem({required this.id, required this.text});
}

class RequirementCategory {
  final String name;
  final List<RequirementItem> items;
  const RequirementCategory({required this.name, required this.items});
}

class RankRequirements {
  final String rank;
  final List<RequirementCategory> categories;
  const RankRequirements({required this.rank, required this.categories});
}


// used ai to read requirement sheet pdfs and give them to me in text/categorical format
// easier to translate to firebase later (less hardcoding, more extensibility/modifiable by client)
const List<RankRequirements> _allRankRequirements = [
  RankRequirements(
    rank: 'White Belt',
    categories: [
      RequirementCategory(name: 'Core Values', items: [
        RequirementItem(id: 'white_cv_0', text: 'Be respectful to yourself, your family, the school, and all students'),
        RequirementItem(id: 'white_cv_1', text: 'Listen and follow instructions'),
      ]),
      RequirementCategory(name: 'Fitness', items: [
        RequirementItem(id: 'white_fit_0', text: '1 correct push-up (hands under shoulders, body straight, chest touches focus mitt)'),
        RequirementItem(id: 'white_fit_1', text: '1 correct sit-up (hands on opposite shoulders, touch elbows to knees)'),
      ]),
      RequirementCategory(name: 'Stances', items: [
        RequirementItem(id: 'white_st_0', text: 'Front Stance'),
        RequirementItem(id: 'white_st_1', text: 'Side Stance'),
        RequirementItem(id: 'white_st_2', text: 'Horse Stance'),
        RequirementItem(id: 'white_st_3', text: 'Angle Stance'),
      ]),
      RequirementCategory(name: 'Basic Kicks', items: [
        RequirementItem(id: 'white_kick_0', text: 'Front Rising Kick – front stance'),
        RequirementItem(id: 'white_kick_1', text: 'Side Rising Kick – side stance'),
        RequirementItem(id: 'white_kick_2', text: '#1 Front Kick (Ap Cha Ki) – moving forward, weapon: Ball, front stance'),
        RequirementItem(id: 'white_kick_3', text: '#2 Side Kick (Yup Cha Ki) – moving forward, weapon: Edge of Heel, side stance'),
      ]),
      RequirementCategory(name: 'Form Basics', items: [
        RequirementItem(id: 'white_fb_0', text: 'Introduction to 1st Stage Motion: step first, then punch or block; no hip rotation; no up and down motion'),
        RequirementItem(id: 'white_fb_1', text: '#1 Middle Punch – front stance'),
        RequirementItem(id: 'white_fb_2', text: '#2 Low Block – front stance'),
      ]),
      RequirementCategory(name: 'Form', items: [
        RequirementItem(id: 'white_form_0', text: 'Ki Bon Hana (8 moves) – Basic Form One'),
      ]),
      RequirementCategory(name: 'Self Defense', items: [
        RequirementItem(id: 'white_sd_0', text: 'Distancing: hands up, step back, say "Stop!"'),
        RequirementItem(id: 'white_sd_1', text: 'Pushing Hands: push opponent\'s hands away without getting touched'),
        RequirementItem(id: 'white_sd_2', text: 'Defense Combination: 1) Distancing  2) Pushing Hands  3) Escape'),
        RequirementItem(id: 'white_sd_3', text: 'Release & Escape from same-side wrist grab'),
      ]),
      RequirementCategory(name: 'Sparring', items: [
        RequirementItem(id: 'white_spar_0', text: 'Sparring Stance: one leg back, weight on balls of feet, knees slightly bent, fists up with Ki-hop'),
        RequirementItem(id: 'white_spar_1', text: 'Slide Step: moving forward and backward without feet crossing'),
        RequirementItem(id: 'white_spar_2', text: 'Free Sparring using Slide Step'),
      ]),
    ],
  ),

  RankRequirements(
    rank: 'Advanced White Belt',
    categories: [
      RequirementCategory(name: 'Prerequisites', items: [
        RequirementItem(id: 'awhite_pre_0', text: 'Test fee due day before test: \$40'),
        RequirementItem(id: 'awhite_pre_1', text: 'Minimum of 8 classes'),
        RequirementItem(id: 'awhite_pre_2', text: 'All requirements marked off by Senior Instructor 1 week before testing'),
      ]),
      RequirementCategory(name: 'Core Values', items: [
        RequirementItem(id: 'awhite_cv_0', text: 'Be respectful to yourself, your family, the school, and all students'),
        RequirementItem(id: 'awhite_cv_1', text: 'Listen and follow instructions'),
        RequirementItem(id: 'awhite_cv_2', text: 'Fact: The name of our school is True Martial Arts'),
      ]),
      RequirementCategory(name: 'Fitness', items: [
        RequirementItem(id: 'awhite_fit_0', text: '1 correct push-up'),
        RequirementItem(id: 'awhite_fit_1', text: '1 correct sit-up'),
      ]),
      RequirementCategory(name: 'Basic Kicks', items: [
        RequirementItem(id: 'awhite_kick_0', text: 'Front Rising Kick – front stance'),
        RequirementItem(id: 'awhite_kick_1', text: 'Side Rising Kick – side stance'),
        RequirementItem(id: 'awhite_kick_2', text: 'Front Kick – back foot kicks, kick out, pull back – front stance'),
        RequirementItem(id: 'awhite_kick_3', text: 'Side Kick – front foot kicks, chamber, kick out, chamber back – side stance'),
      ]),
      RequirementCategory(name: 'Form Basics', items: [
        RequirementItem(id: 'awhite_fb_0', text: 'Introduction to 1st Stage Motion'),
        RequirementItem(id: 'awhite_fb_1', text: '#1 Middle Punch – front stance'),
        RequirementItem(id: 'awhite_fb_2', text: '#2 Low Block – front stance'),
      ]),
      RequirementCategory(name: 'Form', items: [
        RequirementItem(id: 'awhite_form_0', text: 'Ki Bon Hana (8 moves) – Basic Form One'),
      ]),
      RequirementCategory(name: 'Self Defense', items: [
        RequirementItem(id: 'awhite_sd_0', text: 'Distancing'),
        RequirementItem(id: 'awhite_sd_1', text: 'Pushing Hands'),
        RequirementItem(id: 'awhite_sd_2', text: 'Defense Combination: 1) Distancing  2) Pushing Hands  3) Escape'),
        RequirementItem(id: 'awhite_sd_3', text: 'Release & Escape from same-side wrist grab'),
      ]),
      RequirementCategory(name: 'Sparring', items: [
        RequirementItem(id: 'awhite_spar_0', text: 'Sparring Stance'),
        RequirementItem(id: 'awhite_spar_1', text: 'Slide Step (forward and backward)'),
        RequirementItem(id: 'awhite_spar_2', text: 'Free Sparring using Slide Step'),
      ]),
    ],
  ),

  RankRequirements(
    rank: 'Yellow Belt',
    categories: [
      RequirementCategory(name: 'Prerequisites', items: [
        RequirementItem(id: 'yellow_pre_0', text: 'Test fee due day before test: \$45'),
        RequirementItem(id: 'yellow_pre_1', text: 'Minimum of 8 classes'),
        RequirementItem(id: 'yellow_pre_2', text: 'Learning period of 2 weeks – no pre-testing'),
        RequirementItem(id: 'yellow_pre_3', text: 'All requirements marked off by Senior Instructor 1 week before testing'),
      ]),
      RequirementCategory(name: 'Core Values', items: [
        RequirementItem(id: 'yellow_cv_0', text: 'Be respectful to yourself, your family, the school, and all students'),
        RequirementItem(id: 'yellow_cv_1', text: 'Listen and follow instructions'),
        RequirementItem(id: 'yellow_cv_2', text: 'Only talk when asking or answering a question'),
        RequirementItem(id: 'yellow_cv_3', text: 'Do not fool around'),
        RequirementItem(id: 'yellow_cv_4', text: 'Fact: The name of our school is True Martial Arts. We study Tae Kwon Do, Arnis, and Self Defense.'),
      ]),
      RequirementCategory(name: 'Fitness', items: [
        RequirementItem(id: 'yellow_fit_0', text: '2 correct push-ups'),
        RequirementItem(id: 'yellow_fit_1', text: '2 correct sit-ups'),
      ]),
      RequirementCategory(name: 'Basic Kicks', items: [
        RequirementItem(id: 'yellow_kick_0', text: '#1 Front Kick (Ap Cha Ki) – moving forward, weapon: Ball, front stance'),
        RequirementItem(id: 'yellow_kick_1', text: '#2 Side Kick (Yup Cha Ki) – moving forward, weapon: Edge of Heel, side stance'),
        RequirementItem(id: 'yellow_kick_2', text: '#3 Roundhouse Kick (Dolyu Cha Ki) – weapon: Top, side stance'),
        RequirementItem(id: 'yellow_kick_3', text: 'Jump Front Kick – weapon: Ball'),
      ]),
      RequirementCategory(name: 'Form Basics', items: [
        RequirementItem(id: 'yellow_fb_0', text: '#1 Middle Punch – front stance'),
        RequirementItem(id: 'yellow_fb_1', text: '#2 Low Block – front stance'),
        RequirementItem(id: 'yellow_fb_2', text: '#3 High Block – front stance'),
        RequirementItem(id: 'yellow_fb_3', text: '#4 Side Middle Punch – side stance'),
      ]),
      RequirementCategory(name: 'Form', items: [
        RequirementItem(id: 'yellow_form_0', text: 'Ki Bon Hana – Basic Form One (complete)'),
      ]),
      RequirementCategory(name: 'Self Defense', items: [
        RequirementItem(id: 'yellow_sd_0', text: 'Distancing'),
        RequirementItem(id: 'yellow_sd_1', text: 'Pushing Hands'),
        RequirementItem(id: 'yellow_sd_2', text: 'Defense Combination: 1) Distancing  2) Pushing Hands  3) Escape'),
        RequirementItem(id: 'yellow_sd_3', text: 'Release & Escape from same-side wrist grab'),
        RequirementItem(id: 'yellow_sd_4', text: 'Release & Defend against same-side wrist grab: Release-grab + Palm-heel Strike to nose, push away, escape'),
      ]),
      RequirementCategory(name: 'Sparring', items: [
        RequirementItem(id: 'yellow_spar_0', text: 'Sparring Combination: Slide Step Forward + Front Punch + Reverse Punch with Ki-hop + Slide Step Backwards'),
        RequirementItem(id: 'yellow_spar_1', text: 'Slide Step (forward and backward, feet never cross)'),
        RequirementItem(id: 'yellow_spar_2', text: 'Free Sparring using Slide Step'),
      ]),
    ],
  ),

  RankRequirements(
    rank: 'Advanced Yellow Belt',
    categories: [
      RequirementCategory(name: 'Prerequisites', items: [
        RequirementItem(id: 'ayellow_pre_0', text: 'Test fee due day before test: \$55'),
        RequirementItem(id: 'ayellow_pre_1', text: 'Learning period of 2 weeks – no pre-testing'),
        RequirementItem(id: 'ayellow_pre_2', text: 'All requirements marked off by Senior Instructor 1 week before testing'),
      ]),
      RequirementCategory(name: 'Core Values', items: [
        RequirementItem(id: 'ayellow_cv_0', text: 'Be respectful to yourself, your family, the school, and all students'),
        RequirementItem(id: 'ayellow_cv_1', text: 'Try your best'),
        RequirementItem(id: 'ayellow_cv_2', text: 'Have a positive attitude'),
        RequirementItem(id: 'ayellow_cv_3', text: 'Do not be negative about the school or other students'),
        RequirementItem(id: 'ayellow_cv_4', text: 'Fact: Tae Kwon Do comes from Korea.'),
      ]),
      RequirementCategory(name: 'Fitness', items: [
        RequirementItem(id: 'ayellow_fit_0', text: '5 correct push-ups without stopping'),
        RequirementItem(id: 'ayellow_fit_1', text: '10 correct sit-ups without stopping'),
      ]),
      RequirementCategory(name: 'Stances', items: [
        RequirementItem(id: 'ayellow_st_0', text: 'Back Stance: back foot points to side, front foot forward, 60/40 weight, back leg deeply bent'),
        RequirementItem(id: 'ayellow_st_1', text: 'Knows turning for each stance (Dwi Do Dra)'),
      ]),
      RequirementCategory(name: 'Basic Kicks', items: [
        RequirementItem(id: 'ayellow_kick_0', text: '#4 Stepping Side Kick (Yup Cha Na Ka Ki) – weapon: Edge of Heel, side stance'),
        RequirementItem(id: 'ayellow_kick_1', text: '#5 Stepping Back-heel Kick (Dwi Do Cha Na Ka Ki) – weapon: Back of Heel, side stance'),
        RequirementItem(id: 'ayellow_kick_2', text: '#6 Jump Side Kick (I Dan Yup Cha Ki) – weapon: Edge of Heel, side stance'),
        RequirementItem(id: 'ayellow_kick_3', text: 'Jump Roundhouse Kick – weapon: Top, parallel stance'),
      ]),
      RequirementCategory(name: 'Form Basics', items: [
        RequirementItem(id: 'ayellow_fb_0', text: '#5 Inner-forearm Block – back stance'),
        RequirementItem(id: 'ayellow_fb_1', text: '#6 Side Knife-hand Strike – side stance'),
        RequirementItem(id: 'ayellow_fb_2', text: '#7 Side Back-fist Strike – side stance'),
        RequirementItem(id: 'ayellow_fb_3', text: '#8 Inner-forearm Guard – back stance'),
      ]),
      RequirementCategory(name: 'Form', items: [
        RequirementItem(id: 'ayellow_form_0', text: 'Ki Bon Dul – Basic Form Two'),
      ]),
      RequirementCategory(name: 'Self Defense', items: [
        RequirementItem(id: 'ayellow_sd_0', text: 'Defense Combination: 1) Distancing  2) Turtle or Rhino Guard with Slide Step retreat  3) Escape'),
        RequirementItem(id: 'ayellow_sd_1', text: 'Release & Escape from opposite-side or two-hands wrist grab'),
        RequirementItem(id: 'ayellow_sd_2', text: 'Release & Defend: Release-grab + Reverse Punch to temple, push away, escape'),
      ]),
      RequirementCategory(name: 'Sparring', items: [
        RequirementItem(id: 'ayellow_spar_0', text: 'Sparring Combination: Front Kick + Front Punch + Reverse Punch with Ki-hop'),
        RequirementItem(id: 'ayellow_spar_1', text: 'Sparring Fundamental: Guards 1) Rhino  2) Turtle'),
        RequirementItem(id: 'ayellow_spar_2', text: 'Free Sparring using Guards'),
      ]),
    ],
  ),

  RankRequirements(
    rank: 'Green Belt',
    categories: [
      RequirementCategory(name: 'Prerequisites', items: [
        RequirementItem(id: 'green_pre_0', text: 'Test fee due day before test: \$80'),
        RequirementItem(id: 'green_pre_1', text: 'Has received Yellow Belt in Arnis (includes red t-shirt)'),
        RequirementItem(id: 'green_pre_2', text: 'Learning period of 2 weeks – no pre-testing'),
        RequirementItem(id: 'green_pre_3', text: 'All requirements marked off by Senior Instructor 1 week before testing'),
      ]),
      RequirementCategory(name: 'Core Values', items: [
        RequirementItem(id: 'green_cv_0', text: 'Be respectful to yourself, your family, the school, and all students'),
        RequirementItem(id: 'green_cv_1', text: 'Set short-term and long-term goals'),
        RequirementItem(id: 'green_cv_2', text: 'Good concentration, do not get distracted'),
        RequirementItem(id: 'green_cv_3', text: 'Meet challenges head on'),
        RequirementItem(id: 'green_cv_4', text: 'Fact: Arnis comes from the Philippines.'),
      ]),
      RequirementCategory(name: 'Fitness', items: [
        RequirementItem(id: 'green_fit_0', text: '7 correct push-ups without stopping'),
        RequirementItem(id: 'green_fit_1', text: '15 correct sit-ups without stopping'),
      ]),
      RequirementCategory(name: 'Basic Kicks', items: [
        RequirementItem(id: 'green_kick_0', text: '#7 Back-heel Kick (Dwi Do Cha Ki) – weapon: Back of Heel, side stance'),
        RequirementItem(id: 'green_kick_1', text: '#8 Reverse Side Kick (Bande Yup Cha Ki) – weapon: Edge of Heel, side stance'),
        RequirementItem(id: 'green_kick_2', text: '#9 Stepping Roundhouse Kick (Dolyu Cha Na Ka Ki) – weapon: Top, side stance'),
        RequirementItem(id: 'green_kick_3', text: 'Jump Side Kick – weapon: Edge of Heel, parallel stance'),
      ]),
      RequirementCategory(name: 'Form Basics', items: [
        RequirementItem(id: 'green_fb_0', text: '#9 Side Outer-forearm Block (with Ki-hop) – side stance'),
        RequirementItem(id: 'green_fb_1', text: '#10 Reinforced Block – front stance'),
        RequirementItem(id: 'green_fb_2', text: '#11 Hammer-fist Punch – side stance'),
        RequirementItem(id: 'green_fb_3', text: '#12 Front Kick Attack (front kick + reverse punch + reverse inner-forearm block) – front stance'),
      ]),
      RequirementCategory(name: 'Form', items: [
        RequirementItem(id: 'green_form_0', text: 'Tae Kyuk Hyung – Foot Kicking Form'),
      ]),
      RequirementCategory(name: 'Self Defense', items: [
        RequirementItem(id: 'green_sd_0', text: 'Defense Combination: 1) Distancing  2) Forearm or Hand Check Blocks with Slide Step retreat  3) Escape'),
        RequirementItem(id: 'green_sd_1', text: 'Release & Escape from both-hands wrist grab'),
        RequirementItem(id: 'green_sd_2', text: 'Release & Defend against both-hands wrist grab: Release-grab both hands + Knee to groin, push away, escape'),
        RequirementItem(id: 'green_sd_3', text: '3-Step Spar #1: (Defender) Hand Check blocks with high counter-attacks / (Attacker) Punch to solar plexus'),
        RequirementItem(id: 'green_sd_4', text: '3-Step Spar #2: (Defender) Forearm blocks with low counter-attacks / (Attacker) Punch to face'),
      ]),
      RequirementCategory(name: 'Sparring', items: [
        RequirementItem(id: 'green_spar_0', text: 'Sparring Combination: Side Kick + Back-fist + Ridge-hand (same hand) with Ki-hop'),
        RequirementItem(id: 'green_spar_1', text: 'Sparring Fundamental: Blocks 1) Forearm  2) Hand Check'),
        RequirementItem(id: 'green_spar_2', text: 'Free Sparring using Blocks'),
      ]),
    ],
  ),

  RankRequirements(
    rank: 'Advanced Green Belt',
    categories: [
      RequirementCategory(name: 'Prerequisites', items: [
        RequirementItem(id: 'agreen_pre_0', text: 'Test fee due day before test: \$70'),
        RequirementItem(id: 'agreen_pre_1', text: 'Learning period of 1 month – no pre-testing'),
        RequirementItem(id: 'agreen_pre_2', text: 'All requirements marked off by Senior Instructor 1 week before testing'),
      ]),
      RequirementCategory(name: 'Core Values', items: [
        RequirementItem(id: 'agreen_cv_0', text: 'Be respectful to yourself, your family, the school, and all students'),
        RequirementItem(id: 'agreen_cv_1', text: 'Desire to be good at martial arts'),
        RequirementItem(id: 'agreen_cv_2', text: 'Focused eyes while training'),
        RequirementItem(id: 'agreen_cv_3', text: 'Make healthy habits and choices'),
        RequirementItem(id: 'agreen_cv_4', text: 'Fact: Self Defense comes from different Martial Arts styles from around the world.'),
      ]),
      RequirementCategory(name: 'Fitness', items: [
        RequirementItem(id: 'agreen_fit_0', text: '10 correct push-ups without stopping'),
        RequirementItem(id: 'agreen_fit_1', text: '17 correct sit-ups without stopping'),
      ]),
      RequirementCategory(name: 'Basic Kicks', items: [
        RequirementItem(id: 'agreen_kick_0', text: '#10 Jump Front Kick (I Dan Ap Cha Ki) – weapon: Ball, front stance'),
        RequirementItem(id: 'agreen_kick_1', text: '#11 Reverse Back-heel Kick (Bande Dwi Do Cha Ki) – weapon: Back of Heel, side stance'),
        RequirementItem(id: 'agreen_kick_2', text: '#12 Front-Turning Jump Side Kick (Dit O I Dan Yup Cha Ki) – weapon: Edge of Heel, side stance'),
        RequirementItem(id: 'agreen_kick_3', text: 'Flying Front Kick: raise & kick same leg / raise & kick opposite leg / left & right leg – weapon: Ball'),
      ]),
      RequirementCategory(name: 'Form Basics', items: [
        RequirementItem(id: 'agreen_fb_0', text: 'Introduction to 2nd Stage Motion: step and technique finish at same time, hip rotation, head level'),
        RequirementItem(id: 'agreen_fb_1', text: '#13 Release Attack (middle & high outer-forearm block + release + tension side middle punch) – back stance, side stance'),
        RequirementItem(id: 'agreen_fb_2', text: '#14 Exploding Back-fist Attack (side middle punch + exploding back-fist with side kick backwards + knife-hand guard forward with Ki-hop) – side stance, back stance'),
        RequirementItem(id: 'agreen_fb_3', text: '#15 Stomping Back-fist Attack (foot stomp + shoulder block + back-fist) – side stance'),
        RequirementItem(id: 'agreen_fb_4', text: '#16 Out-In Block (inner-forearm block + double high low blocks, hip hand goes out then in) – back stance, feet together'),
      ]),
      RequirementCategory(name: 'Form', items: [
        RequirementItem(id: 'agreen_form_0', text: 'Pung An Hana – Intermediate Form One'),
      ]),
      RequirementCategory(name: 'Self Defense', items: [
        RequirementItem(id: 'agreen_sd_0', text: 'Release & Escape from an arm lock: Release, Escape, yell "No!", run to safe person or place'),
        RequirementItem(id: 'agreen_sd_1', text: 'Release & Defend against arm lock: Reverse Elbow to temple, push away, escape or escalate as needed'),
        RequirementItem(id: 'agreen_sd_2', text: 'One Step Spars using one efficient attack to: Top of the foot / Knee'),
      ]),
      RequirementCategory(name: 'Sparring', items: [
        RequirementItem(id: 'agreen_spar_0', text: 'Sparring Combination: Roundhouse Kick + Front Punch + Hook Punch (same hand) with Ki-hop'),
        RequirementItem(id: 'agreen_spar_1', text: 'Sparring Fundamental: Crossover step (forward and backward)'),
        RequirementItem(id: 'agreen_spar_2', text: 'Free Sparring using Crossover step'),
      ]),
    ],
  ),
];

const List<String> _rankOrder = [
  'White Belt',
  'Advanced White Belt',
  'Yellow Belt',
  'Advanced Yellow Belt',
  'Green Belt',
  'Advanced Green Belt',
  'Blue Belt',
  'Advanced Blue Belt',
  'Brown Belt',
  'Advanced Brown Belt',
  'Red Belt',
  'Advanced Red Belt',
  'Black Belt',
];

class RequirementSheets extends StatefulWidget {
  const RequirementSheets({super.key});

  @override
  State<RequirementSheets> createState() => _RequirementSheetsState();
}

class _RequirementSheetsState extends State<RequirementSheets> {
  late String _viewingRank;
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
        .doc(_rankDocId(_viewingRank))
        .set({'checked': _checkedIds.toList()});
  }

  String _rankDocId(String rank) => rank.toLowerCase().replaceAll(' ', '_');

  List<String> _previousRanks(String current) {
    final idx = _rankOrder.indexOf(current);
    if (idx <= 0) return [];
    return _rankOrder.sublist(0, idx).reversed.toList();
  }

  RankRequirements? _requirementsFor(String rank) {
    try { return _allRankRequirements.firstWhere((r) => r.rank == rank); }
    catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUserModel;
    final previousRanks = _previousRanks(_currentRank);
    final reqs = _requirementsFor(_viewingRank);

    // total progress
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
          // hero
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFFCC0000),
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Rank',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentRank,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  if (user?.program != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      user!.program,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // rank dropdown
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
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: _currentRank,
                            child: Text('$_currentRank — current'),
                          ),
                          ...previousRanks.map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r),
                          )),
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

                  // progress bar
                  if (reqs != null) ...[
                    Row(
                      children: [
                        Text(
                          '$done of $total completed',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          total == 0 ? '' : '${((done / total) * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFCC0000),
                          ),
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

          // requirement list
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
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: allDone ? Colors.grey[400] : Colors.grey[500],
                ),
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
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: checked ? Colors.grey[400] : Colors.grey[850] ?? Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}