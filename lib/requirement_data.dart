// used ai to read requirement sheet pdfs and give them to me in text/categorical format
// easier to translate to firebase later (less hardcoding, more extensibility/modifiable by client)

import 'models/requirement_models.dart';

const List<RankReqs> allRankRequirements = [
  RankReqs(
    rank: 'White Belt',
    categories: [
      ReqCategory(name: 'Core Values', items: [
        ReqItem(id: 'white_cv_0', text: 'Be respectful to yourself, your family, the school, and all students'),
        ReqItem(id: 'white_cv_1', text: 'Listen and follow instructions'),
      ]),
      ReqCategory(name: 'Fitness', items: [
        ReqItem(id: 'white_fit_0', text: '1 correct push-up (hands under shoulders, body straight, chest touches focus mitt)'),
        ReqItem(id: 'white_fit_1', text: '1 correct sit-up (hands on opposite shoulders, touch elbows to knees)'),
      ]),
      ReqCategory(name: 'Stances', items: [
        ReqItem(id: 'white_st_0', text: 'Front Stance'),
        ReqItem(id: 'white_st_1', text: 'Side Stance'),
        ReqItem(id: 'white_st_2', text: 'Horse Stance'),
        ReqItem(id: 'white_st_3', text: 'Angle Stance'),
      ]),
      ReqCategory(name: 'Basic Kicks', items: [
        ReqItem(id: 'white_kick_0', text: 'Front Rising Kick – front stance'),
        ReqItem(id: 'white_kick_1', text: 'Side Rising Kick – side stance'),
        ReqItem(id: 'white_kick_2', text: '#1 Front Kick (Ap Cha Ki) – moving forward, weapon: Ball, front stance'),
        ReqItem(id: 'white_kick_3', text: '#2 Side Kick (Yup Cha Ki) – moving forward, weapon: Edge of Heel, side stance'),
      ]),
      ReqCategory(name: 'Form Basics', items: [
        ReqItem(id: 'white_fb_0', text: 'Introduction to 1st Stage Motion: step first, then punch or block; no hip rotation; no up and down motion'),
        ReqItem(id: 'white_fb_1', text: '#1 Middle Punch – front stance'),
        ReqItem(id: 'white_fb_2', text: '#2 Low Block – front stance'),
      ]),
      ReqCategory(name: 'Form', items: [
        ReqItem(id: 'white_form_0', text: 'Ki Bon Hana (8 moves) – Basic Form One'),
      ]),
      ReqCategory(name: 'Self Defense', items: [
        ReqItem(id: 'white_sd_0', text: 'Distancing: hands up, step back, say "Stop!"'),
        ReqItem(id: 'white_sd_1', text: 'Pushing Hands: push opponent\'s hands away without getting touched'),
        ReqItem(id: 'white_sd_2', text: 'Defense Combination: 1) Distancing  2) Pushing Hands  3) Escape'),
        ReqItem(id: 'white_sd_3', text: 'Release & Escape from same-side wrist grab'),
      ]),
      ReqCategory(name: 'Sparring', items: [
        ReqItem(id: 'white_spar_0', text: 'Sparring Stance: one leg back, weight on balls of feet, knees slightly bent, fists up with Ki-hop'),
        ReqItem(id: 'white_spar_1', text: 'Slide Step: moving forward and backward without feet crossing'),
        ReqItem(id: 'white_spar_2', text: 'Free Sparring using Slide Step'),
      ]),
    ],
  ),

  RankReqs(
    rank: 'Advanced White Belt',
    categories: [
      ReqCategory(name: 'Prerequisites', items: [
        ReqItem(id: 'awhite_pre_0', text: 'Test fee due day before test: \$40'),
        ReqItem(id: 'awhite_pre_1', text: 'Minimum of 8 classes'),
        ReqItem(id: 'awhite_pre_2', text: 'All requirements marked off by Senior Instructor 1 week before testing'),
      ]),
      ReqCategory(name: 'Core Values', items: [
        ReqItem(id: 'awhite_cv_0', text: 'Be respectful to yourself, your family, the school, and all students'),
        ReqItem(id: 'awhite_cv_1', text: 'Listen and follow instructions'),
        ReqItem(id: 'awhite_cv_2', text: 'Fact: The name of our school is True Martial Arts'),
      ]),
      ReqCategory(name: 'Fitness', items: [
        ReqItem(id: 'awhite_fit_0', text: '1 correct push-up'),
        ReqItem(id: 'awhite_fit_1', text: '1 correct sit-up'),
      ]),
      ReqCategory(name: 'Basic Kicks', items: [
        ReqItem(id: 'awhite_kick_0', text: 'Front Rising Kick – front stance'),
        ReqItem(id: 'awhite_kick_1', text: 'Side Rising Kick – side stance'),
        ReqItem(id: 'awhite_kick_2', text: 'Front Kick – back foot kicks, kick out, pull back – front stance'),
        ReqItem(id: 'awhite_kick_3', text: 'Side Kick – front foot kicks, chamber, kick out, chamber back – side stance'),
      ]),
      ReqCategory(name: 'Form Basics', items: [
        ReqItem(id: 'awhite_fb_0', text: 'Introduction to 1st Stage Motion'),
        ReqItem(id: 'awhite_fb_1', text: '#1 Middle Punch – front stance'),
        ReqItem(id: 'awhite_fb_2', text: '#2 Low Block – front stance'),
      ]),
      ReqCategory(name: 'Form', items: [
        ReqItem(id: 'awhite_form_0', text: 'Ki Bon Hana (8 moves) – Basic Form One'),
      ]),
      ReqCategory(name: 'Self Defense', items: [
        ReqItem(id: 'awhite_sd_0', text: 'Distancing'),
        ReqItem(id: 'awhite_sd_1', text: 'Pushing Hands'),
        ReqItem(id: 'awhite_sd_2', text: 'Defense Combination: 1) Distancing  2) Pushing Hands  3) Escape'),
        ReqItem(id: 'awhite_sd_3', text: 'Release & Escape from same-side wrist grab'),
      ]),
      ReqCategory(name: 'Sparring', items: [
        ReqItem(id: 'awhite_spar_0', text: 'Sparring Stance'),
        ReqItem(id: 'awhite_spar_1', text: 'Slide Step (forward and backward)'),
        ReqItem(id: 'awhite_spar_2', text: 'Free Sparring using Slide Step'),
      ]),
    ],
  ),

  RankReqs(
    rank: 'Yellow Belt',
    categories: [
      ReqCategory(name: 'Prerequisites', items: [
        ReqItem(id: 'yellow_pre_0', text: 'Test fee due day before test: \$45'),
        ReqItem(id: 'yellow_pre_1', text: 'Minimum of 8 classes'),
        ReqItem(id: 'yellow_pre_2', text: 'Learning period of 2 weeks – no pre-testing'),
        ReqItem(id: 'yellow_pre_3', text: 'All requirements marked off by Senior Instructor 1 week before testing'),
      ]),
      ReqCategory(name: 'Core Values', items: [
        ReqItem(id: 'yellow_cv_0', text: 'Be respectful to yourself, your family, the school, and all students'),
        ReqItem(id: 'yellow_cv_1', text: 'Listen and follow instructions'),
        ReqItem(id: 'yellow_cv_2', text: 'Only talk when asking or answering a question'),
        ReqItem(id: 'yellow_cv_3', text: 'Do not fool around'),
        ReqItem(id: 'yellow_cv_4', text: 'Fact: The name of our school is True Martial Arts. We study Tae Kwon Do, Arnis, and Self Defense.'),
      ]),
      ReqCategory(name: 'Fitness', items: [
        ReqItem(id: 'yellow_fit_0', text: '2 correct push-ups'),
        ReqItem(id: 'yellow_fit_1', text: '2 correct sit-ups'),
      ]),
      ReqCategory(name: 'Basic Kicks', items: [
        ReqItem(id: 'yellow_kick_0', text: '#1 Front Kick (Ap Cha Ki) – moving forward, weapon: Ball, front stance'),
        ReqItem(id: 'yellow_kick_1', text: '#2 Side Kick (Yup Cha Ki) – moving forward, weapon: Edge of Heel, side stance'),
        ReqItem(id: 'yellow_kick_2', text: '#3 Roundhouse Kick (Dolyu Cha Ki) – weapon: Top, side stance'),
        ReqItem(id: 'yellow_kick_3', text: 'Jump Front Kick – weapon: Ball'),
      ]),
      ReqCategory(name: 'Form Basics', items: [
        ReqItem(id: 'yellow_fb_0', text: '#1 Middle Punch – front stance'),
        ReqItem(id: 'yellow_fb_1', text: '#2 Low Block – front stance'),
        ReqItem(id: 'yellow_fb_2', text: '#3 High Block – front stance'),
        ReqItem(id: 'yellow_fb_3', text: '#4 Side Middle Punch – side stance'),
      ]),
      ReqCategory(name: 'Form', items: [
        ReqItem(id: 'yellow_form_0', text: 'Ki Bon Hana – Basic Form One (complete)'),
      ]),
      ReqCategory(name: 'Self Defense', items: [
        ReqItem(id: 'yellow_sd_0', text: 'Distancing'),
        ReqItem(id: 'yellow_sd_1', text: 'Pushing Hands'),
        ReqItem(id: 'yellow_sd_2', text: 'Defense Combination: 1) Distancing  2) Pushing Hands  3) Escape'),
        ReqItem(id: 'yellow_sd_3', text: 'Release & Escape from same-side wrist grab'),
        ReqItem(id: 'yellow_sd_4', text: 'Release & Defend against same-side wrist grab: Release-grab + Palm-heel Strike to nose, push away, escape'),
      ]),
      ReqCategory(name: 'Sparring', items: [
        ReqItem(id: 'yellow_spar_0', text: 'Sparring Combination: Slide Step Forward + Front Punch + Reverse Punch with Ki-hop + Slide Step Backwards'),
        ReqItem(id: 'yellow_spar_1', text: 'Slide Step (forward and backward, feet never cross)'),
        ReqItem(id: 'yellow_spar_2', text: 'Free Sparring using Slide Step'),
      ]),
    ],
  ),

  RankReqs(
    rank: 'Advanced Yellow Belt',
    categories: [
      ReqCategory(name: 'Prerequisites', items: [
        ReqItem(id: 'ayellow_pre_0', text: 'Test fee due day before test: \$55'),
        ReqItem(id: 'ayellow_pre_1', text: 'Learning period of 2 weeks – no pre-testing'),
        ReqItem(id: 'ayellow_pre_2', text: 'All requirements marked off by Senior Instructor 1 week before testing'),
      ]),
      ReqCategory(name: 'Core Values', items: [
        ReqItem(id: 'ayellow_cv_0', text: 'Be respectful to yourself, your family, the school, and all students'),
        ReqItem(id: 'ayellow_cv_1', text: 'Try your best'),
        ReqItem(id: 'ayellow_cv_2', text: 'Have a positive attitude'),
        ReqItem(id: 'ayellow_cv_3', text: 'Do not be negative about the school or other students'),
        ReqItem(id: 'ayellow_cv_4', text: 'Fact: Tae Kwon Do comes from Korea.'),
      ]),
      ReqCategory(name: 'Fitness', items: [
        ReqItem(id: 'ayellow_fit_0', text: '5 correct push-ups without stopping'),
        ReqItem(id: 'ayellow_fit_1', text: '10 correct sit-ups without stopping'),
      ]),
      ReqCategory(name: 'Stances', items: [
        ReqItem(id: 'ayellow_st_0', text: 'Back Stance: back foot points to side, front foot forward, 60/40 weight, back leg deeply bent'),
        ReqItem(id: 'ayellow_st_1', text: 'Knows turning for each stance (Dwi Do Dra)'),
      ]),
      ReqCategory(name: 'Basic Kicks', items: [
        ReqItem(id: 'ayellow_kick_0', text: '#4 Stepping Side Kick (Yup Cha Na Ka Ki) – weapon: Edge of Heel, side stance'),
        ReqItem(id: 'ayellow_kick_1', text: '#5 Stepping Back-heel Kick (Dwi Do Cha Na Ka Ki) – weapon: Back of Heel, side stance'),
        ReqItem(id: 'ayellow_kick_2', text: '#6 Jump Side Kick (I Dan Yup Cha Ki) – weapon: Edge of Heel, side stance'),
        ReqItem(id: 'ayellow_kick_3', text: 'Jump Roundhouse Kick – weapon: Top, parallel stance'),
      ]),
      ReqCategory(name: 'Form Basics', items: [
        ReqItem(id: 'ayellow_fb_0', text: '#5 Inner-forearm Block – back stance'),
        ReqItem(id: 'ayellow_fb_1', text: '#6 Side Knife-hand Strike – side stance'),
        ReqItem(id: 'ayellow_fb_2', text: '#7 Side Back-fist Strike – side stance'),
        ReqItem(id: 'ayellow_fb_3', text: '#8 Inner-forearm Guard – back stance'),
      ]),
      ReqCategory(name: 'Form', items: [
        ReqItem(id: 'ayellow_form_0', text: 'Ki Bon Dul – Basic Form Two'),
      ]),
      ReqCategory(name: 'Self Defense', items: [
        ReqItem(id: 'ayellow_sd_0', text: 'Defense Combination: 1) Distancing  2) Turtle or Rhino Guard with Slide Step retreat  3) Escape'),
        ReqItem(id: 'ayellow_sd_1', text: 'Release & Escape from opposite-side or two-hands wrist grab'),
        ReqItem(id: 'ayellow_sd_2', text: 'Release & Defend: Release-grab + Reverse Punch to temple, push away, escape'),
      ]),
      ReqCategory(name: 'Sparring', items: [
        ReqItem(id: 'ayellow_spar_0', text: 'Sparring Combination: Front Kick + Front Punch + Reverse Punch with Ki-hop'),
        ReqItem(id: 'ayellow_spar_1', text: 'Sparring Fundamental: Guards 1) Rhino  2) Turtle'),
        ReqItem(id: 'ayellow_spar_2', text: 'Free Sparring using Guards'),
      ]),
    ],
  ),

  RankReqs(
    rank: 'Green Belt',
    categories: [
      ReqCategory(name: 'Prerequisites', items: [
        ReqItem(id: 'green_pre_0', text: 'Test fee due day before test: \$80'),
        ReqItem(id: 'green_pre_1', text: 'Has received Yellow Belt in Arnis (includes red t-shirt)'),
        ReqItem(id: 'green_pre_2', text: 'Learning period of 2 weeks – no pre-testing'),
        ReqItem(id: 'green_pre_3', text: 'All requirements marked off by Senior Instructor 1 week before testing'),
      ]),
      ReqCategory(name: 'Core Values', items: [
        ReqItem(id: 'green_cv_0', text: 'Be respectful to yourself, your family, the school, and all students'),
        ReqItem(id: 'green_cv_1', text: 'Set short-term and long-term goals'),
        ReqItem(id: 'green_cv_2', text: 'Good concentration, do not get distracted'),
        ReqItem(id: 'green_cv_3', text: 'Meet challenges head on'),
        ReqItem(id: 'green_cv_4', text: 'Fact: Arnis comes from the Philippines.'),
      ]),
      ReqCategory(name: 'Fitness', items: [
        ReqItem(id: 'green_fit_0', text: '7 correct push-ups without stopping'),
        ReqItem(id: 'green_fit_1', text: '15 correct sit-ups without stopping'),
      ]),
      ReqCategory(name: 'Basic Kicks', items: [
        ReqItem(id: 'green_kick_0', text: '#7 Back-heel Kick (Dwi Do Cha Ki) – weapon: Back of Heel, side stance'),
        ReqItem(id: 'green_kick_1', text: '#8 Reverse Side Kick (Bande Yup Cha Ki) – weapon: Edge of Heel, side stance'),
        ReqItem(id: 'green_kick_2', text: '#9 Stepping Roundhouse Kick (Dolyu Cha Na Ka Ki) – weapon: Top, side stance'),
        ReqItem(id: 'green_kick_3', text: 'Jump Side Kick – weapon: Edge of Heel, parallel stance'),
      ]),
      ReqCategory(name: 'Form Basics', items: [
        ReqItem(id: 'green_fb_0', text: '#9 Side Outer-forearm Block (with Ki-hop) – side stance'),
        ReqItem(id: 'green_fb_1', text: '#10 Reinforced Block – front stance'),
        ReqItem(id: 'green_fb_2', text: '#11 Hammer-fist Punch – side stance'),
        ReqItem(id: 'green_fb_3', text: '#12 Front Kick Attack (front kick + reverse punch + reverse inner-forearm block) – front stance'),
      ]),
      ReqCategory(name: 'Form', items: [
        ReqItem(id: 'green_form_0', text: 'Tae Kyuk Hyung – Foot Kicking Form'),
      ]),
      ReqCategory(name: 'Self Defense', items: [
        ReqItem(id: 'green_sd_0', text: 'Defense Combination: 1) Distancing  2) Forearm or Hand Check Blocks with Slide Step retreat  3) Escape'),
        ReqItem(id: 'green_sd_1', text: 'Release & Escape from both-hands wrist grab'),
        ReqItem(id: 'green_sd_2', text: 'Release & Defend against both-hands wrist grab: Release-grab both hands + Knee to groin, push away, escape'),
        ReqItem(id: 'green_sd_3', text: '3-Step Spar #1: (Defender) Hand Check blocks with high counter-attacks / (Attacker) Punch to solar plexus'),
        ReqItem(id: 'green_sd_4', text: '3-Step Spar #2: (Defender) Forearm blocks with low counter-attacks / (Attacker) Punch to face'),
      ]),
      ReqCategory(name: 'Sparring', items: [
        ReqItem(id: 'green_spar_0', text: 'Sparring Combination: Side Kick + Back-fist + Ridge-hand (same hand) with Ki-hop'),
        ReqItem(id: 'green_spar_1', text: 'Sparring Fundamental: Blocks 1) Forearm  2) Hand Check'),
        ReqItem(id: 'green_spar_2', text: 'Free Sparring using Blocks'),
      ]),
    ],
  ),

  RankReqs(
    rank: 'Advanced Green Belt',
    categories: [
      ReqCategory(name: 'Prerequisites', items: [
        ReqItem(id: 'agreen_pre_0', text: 'Test fee due day before test: \$70'),
        ReqItem(id: 'agreen_pre_1', text: 'Learning period of 1 month – no pre-testing'),
        ReqItem(id: 'agreen_pre_2', text: 'All requirements marked off by Senior Instructor 1 week before testing'),
      ]),
      ReqCategory(name: 'Core Values', items: [
        ReqItem(id: 'agreen_cv_0', text: 'Be respectful to yourself, your family, the school, and all students'),
        ReqItem(id: 'agreen_cv_1', text: 'Desire to be good at martial arts'),
        ReqItem(id: 'agreen_cv_2', text: 'Focused eyes while training'),
        ReqItem(id: 'agreen_cv_3', text: 'Make healthy habits and choices'),
        ReqItem(id: 'agreen_cv_4', text: 'Fact: Self Defense comes from different Martial Arts styles from around the world.'),
      ]),
      ReqCategory(name: 'Fitness', items: [
        ReqItem(id: 'agreen_fit_0', text: '10 correct push-ups without stopping'),
        ReqItem(id: 'agreen_fit_1', text: '17 correct sit-ups without stopping'),
      ]),
      ReqCategory(name: 'Basic Kicks', items: [
        ReqItem(id: 'agreen_kick_0', text: '#10 Jump Front Kick (I Dan Ap Cha Ki) – weapon: Ball, front stance'),
        ReqItem(id: 'agreen_kick_1', text: '#11 Reverse Back-heel Kick (Bande Dwi Do Cha Ki) – weapon: Back of Heel, side stance'),
        ReqItem(id: 'agreen_kick_2', text: '#12 Front-Turning Jump Side Kick (Dit O I Dan Yup Cha Ki) – weapon: Edge of Heel, side stance'),
        ReqItem(id: 'agreen_kick_3', text: 'Flying Front Kick: raise & kick same leg / raise & kick opposite leg / left & right leg – weapon: Ball'),
      ]),
      ReqCategory(name: 'Form Basics', items: [
        ReqItem(id: 'agreen_fb_0', text: 'Introduction to 2nd Stage Motion: step and technique finish at same time, hip rotation, head level'),
        ReqItem(id: 'agreen_fb_1', text: '#13 Release Attack (middle & high outer-forearm block + release + tension side middle punch) – back stance, side stance'),
        ReqItem(id: 'agreen_fb_2', text: '#14 Exploding Back-fist Attack (side middle punch + exploding back-fist with side kick backwards + knife-hand guard forward with Ki-hop) – side stance, back stance'),
        ReqItem(id: 'agreen_fb_3', text: '#15 Stomping Back-fist Attack (foot stomp + shoulder block + back-fist) – side stance'),
        ReqItem(id: 'agreen_fb_4', text: '#16 Out-In Block (inner-forearm block + double high low blocks, hip hand goes out then in) – back stance, feet together'),
      ]),
      ReqCategory(name: 'Form', items: [
        ReqItem(id: 'agreen_form_0', text: 'Pung An Hana – Intermediate Form One'),
      ]),
      ReqCategory(name: 'Self Defense', items: [
        ReqItem(id: 'agreen_sd_0', text: 'Release & Escape from an arm lock: Release, Escape, yell "No!", run to safe person or place'),
        ReqItem(id: 'agreen_sd_1', text: 'Release & Defend against arm lock: Reverse Elbow to temple, push away, escape or escalate as needed'),
        ReqItem(id: 'agreen_sd_2', text: 'One Step Spars using one efficient attack to: Top of the foot / Knee'),
      ]),
      ReqCategory(name: 'Sparring', items: [
        ReqItem(id: 'agreen_spar_0', text: 'Sparring Combination: Roundhouse Kick + Front Punch + Hook Punch (same hand) with Ki-hop'),
        ReqItem(id: 'agreen_spar_1', text: 'Sparring Fundamental: Crossover step (forward and backward)'),
        ReqItem(id: 'agreen_spar_2', text: 'Free Sparring using Crossover step'),
      ]),
    ],
  ),
  RankReqs(rank: 'Blue Belt',
    categories: [
      ReqCategory(name: 'Prerequisites', items: [
        ReqItem(id: 'blue_pre_0', text: 'Test fee due day before test: \$80'),
        ReqItem(id: 'blue_pre_1', text: 'Has received Green Belt in Arnis'),
        ReqItem(id: 'blue_pre_2', text: 'Learning period of 1 month — no pre-testing'),
        ReqItem(id: 'blue_pre_3', text: 'All requirements marked off by Senior Instructor 1 week before testing'),
      ]),
      ReqCategory(name: 'Core Values', items: [
        ReqItem(id: 'blue_cv_0', text: 'Be respectful to yourself, your family, the school, and all the students'),
        ReqItem(id: 'blue_cv_1', text: 'Indomitable Spirit, never give up'),
        ReqItem(id: 'blue_cv_2', text: 'Consistent at completing tasks'),
        ReqItem(id: 'blue_cv_3', text: 'Practice outside of class'),
        ReqItem(id: 'blue_cv_4', text: 'Fact: Tae Kwon Do means "The art of the hand and foot"'),
      ]),
      ReqCategory(name: 'Fitness', items: [
        ReqItem(id: 'blue_fit_0', text: '12 correct push-ups without stopping'),
        ReqItem(id: 'blue_fit_1', text: '20 correct sit-ups without stopping'),
      ]),
      ReqCategory(name: 'Stances', items: [
        ReqItem(id: 'blue_st_0', text: 'Front Leg Stance: front leg slightly bent, back leg bent, only ball of foot & toes of back foot touching ground, 90/10 weight front'),
        ReqItem(id: 'blue_st_1', text: 'Short Back Stance: only ball of foot and toes of front foot touch ground, 90/10 weight back, feet form an "L" shape shoulder distance apart'),
        ReqItem(id: 'blue_st_2', text: 'In-line Stance: similar to backwards front stance but feet are in-line, toes point backwards, look forward over front shoulder'),
      ]),
      ReqCategory(name: 'Basic Kicks', items: [
        ReqItem(id: 'blue_kick_0', text: '#13 Push Front Kick (Mi Lyu Ap Cha Ki) — weapon: Whole Bottom of Foot, front stance'),
        ReqItem(id: 'blue_kick_1', text: '#14 Back Kick (Dit Cha Ki) — weapon: Bottom of Heel, side stance'),
        ReqItem(id: 'blue_kick_2', text: '#15 Crescent Kick (Hu Lyu Cha Ki) — weapon: Side of Foot, side stance'),
        ReqItem(id: 'blue_kick_3', text: 'Flying Side Kick: raise & kick same leg / raise & kick opposite leg / left & right leg — weapon: Edge of Heel'),
      ]),
      ReqCategory(name: 'Form Basics', items: [
        ReqItem(id: 'blue_fb_0', text: '#17 Reverse Elbow Strike — front stance'),
        ReqItem(id: 'blue_fb_1', text: '#18 Angle Neck Attack (reverse neck strike / high block + front kick + hopping back-knuckle strike with Ki-hop) — front stance, front leg stance'),
        ReqItem(id: 'blue_fb_2', text: '#19 "X" Block Attack (low "X" block reverse hand on top + high "X" block in + reverse hand pass to side + side middle punch + side middle punch with Ki-hop) — front stance, short back stance, side stance, side stance'),
        ReqItem(id: 'blue_fb_3', text: '#20 Bow and Arrow Strike — short back stance, modified front stance, in-line stance'),
      ]),
      ReqCategory(name: 'Form', items: [
        ReqItem(id: 'blue_form_0', text: 'Pung An Dul — Intermediate Form Two'),
      ]),
      ReqCategory(name: 'Self Defense', items: [
        ReqItem(id: 'blue_sd_0', text: 'Release & Escape from a bear hug (grab from behind): 1) Release 2) Escape — yell "No!", run away to a safe person or place'),
        ReqItem(id: 'blue_sd_1', text: 'Release & Defend against a bear hug (grab from behind): same side hand on hand for release + foot stomps until you release, then push away or escape, escalate if needed'),
        ReqItem(id: 'blue_sd_2', text: 'One Step Spars using one efficient attack to: Groin, Solar Plexus'),
      ]),
      ReqCategory(name: 'Sparring', items: [
        ReqItem(id: 'blue_spar_0', text: 'Sparring Combination: Shoulder Feint + Front Foot Roundhouse Kick + Superman Punch with Ki-hop'),
        ReqItem(id: 'blue_spar_1', text: 'Sparring Fundamental: 9 Sparring Angles — 1) Forward 2) Diagonal forward right 3) Diagonal forward left 4) Right 5) Left 6) Backwards 7) Diagonal backward right 8) Diagonal backward left 9) Up high'),
        ReqItem(id: 'blue_spar_2', text: 'Free Sparring using 9 Sparring Angles'),
      ]),
    ],
  ),

  RankReqs(
    rank: 'Advanced Blue Belt',
    categories: [
      ReqCategory(name: 'Prerequisites', items: [
        ReqItem(id: 'ablue_pre_0', text: 'Test fee due day before test: \$90'),
        ReqItem(id: 'ablue_pre_1', text: 'Has received Blue Belt in Arnis'),
        ReqItem(id: 'ablue_pre_2', text: 'Minimum age: 8 years old (or almost)'),
        ReqItem(id: 'ablue_pre_3', text: 'Has attended a Board Breaking Seminar at this rank'),
        ReqItem(id: 'ablue_pre_4', text: 'Learning period of 6 weeks — no pre-testing'),
        ReqItem(id: 'ablue_pre_5', text: 'All requirements marked off by Senior Instructor 1 week before testing'),
      ]),
      ReqCategory(name: 'Core Values', items: [
        ReqItem(id: 'ablue_cv_0', text: 'Be respectful to yourself, your family, the school, and all the students'),
        ReqItem(id: 'ablue_cv_1', text: 'Self-motivated, work hard without being told'),
        ReqItem(id: 'ablue_cv_2', text: 'Be accountable, do not justify mistakes'),
        ReqItem(id: 'ablue_cv_3', text: 'Able to handle new or awkward situations'),
        ReqItem(id: 'ablue_cv_4', text: 'Fact: Arnis means "To harness"'),
      ]),
      ReqCategory(name: 'Fitness', items: [
        ReqItem(id: 'ablue_fit_0', text: '15 correct push-ups without stopping'),
        ReqItem(id: 'ablue_fit_1', text: '25 correct sit-ups without stopping'),
      ]),
      ReqCategory(name: 'Stances', items: [
        ReqItem(id: 'ablue_st_0', text: 'Side Parallel Stance: same as parallel stance except head turned sideways looking over the shoulder'),
      ]),
      ReqCategory(name: 'Basic Kicks', items: [
        ReqItem(id: 'ablue_kick_0', text: '#16 Front-Turning Jump Roundhouse Kick (Dit O I Dan Dolyu Cha Ki) — weapon: Top, side stance'),
        ReqItem(id: 'ablue_kick_1', text: '#17 Hook Back-heel Kick (Ki Ban Dwi Do Chi) — weapon: Back of Heel, side stance'),
        ReqItem(id: 'ablue_kick_2', text: '#18 Front, Roundhouse Kick (Ap Dolyu Cha Ki) — weapon: Ball then Top, side stance'),
        ReqItem(id: 'ablue_kick_3', text: 'Jump Reverse Side Kick — weapon: Edge of Heel, side parallel stance'),
      ]),
      ReqCategory(name: 'Form Basics', items: [
        ReqItem(id: 'ablue_fb_0', text: 'Introduction to 3rd Stage Motion: step and technique finish at same time, move forward using hip rotation, head moves with body to create ultimate power'),
        ReqItem(id: 'ablue_fb_1', text: 'Understands lagging and leading hip in stage motion'),
        ReqItem(id: 'ablue_fb_2', text: '#21 Front Reverse Punch Attack (guard with Ki-hop + front punch + reverse punch + low knife-hand block) — back stance'),
        ReqItem(id: 'ablue_fb_3', text: '#22 Step Back-heel Kick Attack (step back heel + front foot roundhouse + reverse side kick jump optional with Ki-hop + high block) — back stance'),
        ReqItem(id: 'ablue_fb_4', text: '#23 Upward Punch Attack (high block + grab + upward punch + tension side middle punch) — back stance, side stance'),
        ReqItem(id: 'ablue_fb_5', text: '#24 Double Knife-hand Guard (low knife-hand guard + middle knife-hand guard with Ki-hop) — back stance'),
      ]),
      ReqCategory(name: 'Form', items: [
        ReqItem(id: 'ablue_form_0', text: 'Tae Seung Nom Book Hyung — Foot Fighting North South Form'),
      ]),
      ReqCategory(name: 'Self Defense', items: [
        ReqItem(id: 'ablue_sd_0', text: 'Release & Escape from an arm choke from behind: 1) Release 2) Escape — yell "No!", run away to a safe person or place'),
        ReqItem(id: 'ablue_sd_1', text: 'Release & Defend against arm choke from behind: move to side head lock position, outside knee or punch to thigh + grab hair or face and pull opponent to ground, then escape or escalate'),
        ReqItem(id: 'ablue_sd_2', text: 'One Step Spars using one efficient counter attack to: Floating Rib, Jaw'),
      ]),
      ReqCategory(name: 'Sparring', items: [
        ReqItem(id: 'ablue_spar_0', text: 'Sparring Combination: Foot Feint + Crescent Kick + Side Kick with Ki-hop — do not put foot down between kicks'),
        ReqItem(id: 'ablue_spar_1', text: 'Sparring Fundamental: Sparring Style #1 — Initiator — be explosive and first to act'),
        ReqItem(id: 'ablue_spar_2', text: 'Free Sparring using Sparring Style #1 — Initiator'),
      ]),
      ReqCategory(name: 'MMA', items: [
        ReqItem(id: 'ablue_mma_0', text: 'Takedowns: 1) Tripping 2) Leg Throw — start from control, stay in control'),
      ]),
    ],
  ),

  RankReqs(
    rank: 'Brown Belt',
    categories: [
      ReqCategory(name: 'Prerequisites', items: [
        ReqItem(id: 'brown_pre_0', text: 'Test fee due day before test: \$225 (includes gray t-shirt and red uniform)'),
        ReqItem(id: 'brown_pre_1', text: 'Minimum age: 9 years old (or almost)'),
        ReqItem(id: 'brown_pre_2', text: 'Has attended a Board Breaking Seminar at this rank'),
        ReqItem(id: 'brown_pre_3', text: 'Learning period of 6 weeks — no pre-testing'),
        ReqItem(id: 'brown_pre_4', text: 'All requirements marked off by Senior Instructor 1 week before testing'),
      ]),
      ReqCategory(name: 'Core Values', items: [
        ReqItem(id: 'brown_cv_0', text: 'Be respectful to yourself, your family, the school, and all the students'),
        ReqItem(id: 'brown_cv_1', text: 'Self-confident on and off the training floor'),
        ReqItem(id: 'brown_cv_2', text: 'Rarely misses class'),
        ReqItem(id: 'brown_cv_3', text: 'Be humble, do not brag about personal accomplishments'),
        ReqItem(id: 'brown_cv_4', text: 'Fact: The style of Tae Kwon Do we study is American Chang Moo Kwon. Chang Moo Kwon means "The clear way"'),
      ]),
      ReqCategory(name: 'Fitness', items: [
        ReqItem(id: 'brown_fit_0', text: '17 correct push-ups without stopping'),
        ReqItem(id: 'brown_fit_1', text: '30 correct sit-ups without stopping'),
      ]),
      ReqCategory(name: 'Basic Kicks', items: [
        ReqItem(id: 'brown_kick_0', text: '#19 Reverse Front Kick (Bande Ap Cha Ki) — weapon: Ball, front stance'),
        ReqItem(id: 'brown_kick_1', text: '#20 Reverse Jump Side Kick (Bande I Dan Yup Cha Ki) — weapon: Edge of Heel, side stance'),
        ReqItem(id: 'brown_kick_2', text: '#21 Reverse Groin Kick (Bande Sabu Cha Ki) — weapon: Back of Heel, side stance'),
        ReqItem(id: 'brown_kick_3', text: 'Jump Reverse Hook Back-heel Kick — weapon: Back of Heel, side parallel stance'),
      ]),
      ReqCategory(name: 'Form Basics', items: [
        ReqItem(id: 'brown_fb_0', text: '#25 Opposite Attack (tension high knife-hand block + short reverse punch) — back stance'),
        ReqItem(id: 'brown_fb_1', text: '#26 Two Hands Attack ("X" block + double short punch + front/reverse punch with Ki-hop) — front stance, short back stance, front stance'),
        ReqItem(id: 'brown_fb_2', text: '#27 Snap Punch Attack (hook back-heel kick + side snap punch) — side stance'),
        ReqItem(id: 'brown_fb_3', text: '#28 Double Front Kick Attack (tension high knife-hand block + double front kick + front/reverse punch) — back stance, lunge'),
      ]),
      ReqCategory(name: 'Form', items: [
        ReqItem(id: 'brown_form_0', text: 'Kang Han Yoja — Strong Woman Form'),
      ]),
      ReqCategory(name: 'Self Defense', items: [
        ReqItem(id: 'brown_sd_0', text: 'Release & Escape from a two-hands choke in front or from behind: 1) Release 2) Escape — yell "No!", run away to a safe person or place'),
        ReqItem(id: 'brown_sd_1', text: 'Release & Defend against two-hands choke on the ground: Opposite Grab Center Lock + Arm Bar and explode hip up, push opponent away, escape or escalate'),
        ReqItem(id: 'brown_sd_2', text: 'One Step Spars using one efficient attack to: Ears, Eyes'),
      ]),
      ReqCategory(name: 'Sparring', items: [
        ReqItem(id: 'brown_spar_0', text: 'Sparring Combination: Fake Front Punch + Reverse Side Kick + Knife Hand with Ki-hop'),
        ReqItem(id: 'brown_spar_1', text: 'Sparring Fundamental: Sparring Style #2 — Counter Attacker — keep your distance, defend, see the open area and react'),
        ReqItem(id: 'brown_spar_2', text: 'Free Sparring using Sparring Style #2 — Counter Attacker'),
      ]),
      ReqCategory(name: 'MMA', items: [
        ReqItem(id: 'brown_mma_0', text: 'Takedowns: 3) Choke-down 4) Outside Leg — start from control, stay in control'),
        ReqItem(id: 'brown_mma_1', text: 'Leg Kick: shin kick to the thigh, knee slightly bent, no pull back'),
        ReqItem(id: 'brown_mma_2', text: 'Leg Kick Defense: slightly lift the leg being attacked off the ground, turn to go with the kicking momentum'),
      ]),
    ],
  ),

  RankReqs(
    rank: 'Advanced Brown Belt',
    categories: [
      ReqCategory(name: 'Prerequisites', items: [
        ReqItem(id: 'abrown_pre_0', text: 'Test fee due day before test: \$125'),
        ReqItem(id: 'abrown_pre_1', text: 'Minimum age: 10 years old (or almost)'),
        ReqItem(id: 'abrown_pre_2', text: 'Has attended a Board Breaking Seminar at this rank'),
        ReqItem(id: 'abrown_pre_3', text: 'Has MMA head gear and fingerless sparring gloves before your first class'),
        ReqItem(id: 'abrown_pre_4', text: 'Has received Brown Belt in Arnis'),
        ReqItem(id: 'abrown_pre_5', text: 'Learning period of 2 months — no pre-testing'),
        ReqItem(id: 'abrown_pre_6', text: 'All requirements marked off by Senior Instructor 1 week before testing'),
      ]),
      ReqCategory(name: 'Core Values', items: [
        ReqItem(id: 'abrown_cv_0', text: 'Be respectful to yourself, your family, the school, and all the students'),
        ReqItem(id: 'abrown_cv_1', text: 'Desire to be above the standard'),
        ReqItem(id: 'abrown_cv_2', text: 'Self-control over negative thoughts, emotions, and attitudes'),
        ReqItem(id: 'abrown_cv_3', text: 'Participate in school activities'),
        ReqItem(id: 'abrown_cv_4', text: 'Fact: We study Modern Arnis, which was founded by Grandmaster Remy Presas'),
      ]),
      ReqCategory(name: 'Fitness', items: [
        ReqItem(id: 'abrown_fit_0', text: '20 correct push-ups without stopping'),
        ReqItem(id: 'abrown_fit_1', text: '40 correct sit-ups without stopping'),
      ]),
      ReqCategory(name: 'Stances', items: [
        ReqItem(id: 'abrown_st_0', text: 'Crouching Stance: similar to front leg stance except front leg is deeply bent'),
      ]),
      ReqCategory(name: 'Advanced Kicks', items: [
        ReqItem(id: 'abrown_kick_0', text: '#A1 Jump Double Front Kick — weapon: Ball, front stance'),
        ReqItem(id: 'abrown_kick_1', text: '#A2 Double Roundhouse Kick — weapon: Top, side stance'),
        ReqItem(id: 'abrown_kick_2', text: '#A3 Sweep, Back-heel Kick — weapon: Side of Foot then Back of Heel, side stance'),
        ReqItem(id: 'abrown_kick_3', text: 'Jump Reverse Back-heel Kick — weapon: Back of Heel, side parallel stance'),
      ]),
      ReqCategory(name: 'Form Basics', items: [
        ReqItem(id: 'abrown_fb_0', text: '#29 Temple Guard Attack (guard + short reverse punch) — back stance, side stance'),
        ReqItem(id: 'abrown_fb_1', text: '#30 Double Low Punch Attack (step back while circling arms + double low punch + cross block + double knife hand block) — feet together, crouching stance, front stance, front stance'),
        ReqItem(id: 'abrown_fb_2', text: '#31 Double High Hammer-fist Attack (both hands grab + inner high hammer-fist + outer high hammer-fist with Ki-hop) — front stance'),
        ReqItem(id: 'abrown_fb_3', text: '#32 Temple Punch (wind up + wrap foot + high hammer-fist) — side stance'),
      ]),
      ReqCategory(name: 'Form', items: [
        ReqItem(id: 'abrown_form_0', text: 'Ji-On Hyung — Temple Form'),
      ]),
      ReqCategory(name: 'Self Defense', items: [
        ReqItem(id: 'abrown_sd_0', text: 'Release & Escape from a one-hand shirt grab: 1) Release 2) Escape — yell "No!", run away to a safe person or place'),
        ReqItem(id: 'abrown_sd_1', text: 'Release & Defend against a one-hand shirt grab: place opposite hand on opponent\'s hand + step back twisting into reverse wrist lock, step forward pushing away, escape or escalate'),
        ReqItem(id: 'abrown_sd_2', text: 'One Step Spars using one efficient attack to: Throat, Nose'),
        ReqItem(id: 'abrown_sd_3', text: 'Ground Defense against standing opponent: Guard, Circling, Side-to-side, Get up'),
      ]),
      ReqCategory(name: 'Sparring', items: [
        ReqItem(id: 'abrown_spar_0', text: 'Sparring Fundamental: Sparring Style #3 — Jammer — stay in close, cover up, look for open area and attack'),
        ReqItem(id: 'abrown_spar_1', text: 'Free Sparring using Sparring Style #3 — Jammer'),
      ]),
      ReqCategory(name: 'MMA', items: [
        ReqItem(id: 'abrown_mma_0', text: 'Takedowns: 5) Arm Drag — start from control; 6) Catch Kicking Leg and Trip — start from distance, stay in control'),
        ReqItem(id: 'abrown_mma_1', text: 'Street Fighting Fundamentals: Clinch (hand on back of neck, temple to temple), Pushing (get them away), Grabbing (pull them close)'),
        ReqItem(id: 'abrown_mma_2', text: '15 Strikes: 1) Jab 2) Cross 3) Front hand hook 4) Back hand hook to body 5) Front hand uppercut 6) Back hand uppercut 7) Downward hammer-fist with back hand 8) Front elbow 9) Back elbow 10) Front knee 11) Back knee 12) Front foot push front kick 13) Back foot front kick 14) Front foot leg kick 15) Back foot leg kick spin around into guard'),
        ReqItem(id: 'abrown_mma_3', text: 'Street Fighting using: Clinch, Pushing, Grabbing, 15 Strikes — survival technique, all weapons of body, any target area, no takedowns'),
        ReqItem(id: 'abrown_mma_4', text: 'Mount Positions: 1) Full Mount; Guard Positions: 1) Closed Guard'),
        ReqItem(id: 'abrown_mma_5', text: 'Ground Sparring using: Clinch, Body Control'),
      ]),
    ],
  ),

  RankReqs(
    rank: 'Red Belt',
    categories: [
      ReqCategory(name: 'Prerequisites', items: [
        ReqItem(id: 'red_pre_0', text: 'Test fee due day before test: \$150'),
        ReqItem(id: 'red_pre_1', text: 'Minimum age: 11 years old (or almost)'),
        ReqItem(id: 'red_pre_2', text: 'Has attended a Board Breaking Seminar at this rank'),
        ReqItem(id: 'red_pre_3', text: 'Learning period of 2 months — no pre-testing'),
        ReqItem(id: 'red_pre_4', text: 'All requirements marked off by Senior Instructor 1 week before testing'),
        ReqItem(id: 'red_pre_5', text: 'Write an essay about True Way of the Warrior — describe the five aspects with examples: Respect, Integrity, Responsibility, Honor, Courage. Email to info@truemartialarts.com'),
      ]),
      ReqCategory(name: 'Core Values', items: [
        ReqItem(id: 'red_cv_0', text: 'Be respectful to yourself, your family, the school, and all the students'),
        ReqItem(id: 'red_cv_1', text: 'Self-discipline, take action regardless of distractions'),
        ReqItem(id: 'red_cv_2', text: 'Do the right thing even when nobody is looking'),
        ReqItem(id: 'red_cv_3', text: 'Exhibits strong leadership qualities'),
        ReqItem(id: 'red_cv_4', text: 'Fact: True Martial Arts was founded in 1982 by the late Sa Bum Nim Thomas Zoppi in Bellevue, Washington. TMA opened its Sammamish location in 1995'),
      ]),
      ReqCategory(name: 'Fitness', items: [
        ReqItem(id: 'red_fit_0', text: '25 correct push-ups without stopping'),
        ReqItem(id: 'red_fit_1', text: '50 correct sit-ups without stopping'),
      ]),
      ReqCategory(name: 'Advanced Kicks', items: [
        ReqItem(id: 'red_kick_0', text: '#A4 Reverse Crescent Kick — weapon: Reverse Side of Foot, front stance'),
        ReqItem(id: 'red_kick_1', text: '#A5 Front, Jump Roundhouse Kick — weapon: Ball then Top, side stance'),
        ReqItem(id: 'red_kick_2', text: '#A6 Ax Kick — weapon: Back of Heel, front stance'),
        ReqItem(id: 'red_kick_3', text: 'Jump Crescent Kick — weapon: Side of Foot, side parallel stance'),
      ]),
      ReqCategory(name: 'Form Basics', items: [
        ReqItem(id: 'red_fb_0', text: '#33 Reverse Punch Attack (side middle punch + high reverse punch with Ki-hop) — side stance, front stance'),
        ReqItem(id: 'red_fb_1', text: '#34 Double Knife-hand Block (block behind look behind + block front look front) — side stance'),
        ReqItem(id: 'red_fb_2', text: '#35 Double Knife-hand Attack (guard + side kick + reverse side kick + knife-hand behind + knife-hand in front with Ki-hop) — side stance'),
        ReqItem(id: 'red_fb_3', text: '#36 Reverse Low Knife-hand Guard (low knife-hand guard + reverse low knife-hand guard) — back stance, back stance'),
      ]),
      ReqCategory(name: 'Form', items: [
        ReqItem(id: 'red_form_0', text: 'Ja Yu Hyung — Free Fighting Form'),
      ]),
      ReqCategory(name: 'Self Defense', items: [
        ReqItem(id: 'red_sd_0', text: 'Release & Escape from a two-hands shirt grab: 1) Release 2) Escape — yell "No!", run away to a safe person or place'),
        ReqItem(id: 'red_sd_1', text: 'Release & Defend against a two-hands shirt grab: reverse hammer-fist to groin + under circle + elbow to temple, push away, escape or escalate'),
        ReqItem(id: 'red_sd_2', text: 'One Step Spars using one efficient attack to: Temple, Side of the neck'),
      ]),
      ReqCategory(name: 'Sparring', items: [
        ReqItem(id: 'red_spar_0', text: 'Sparring Fundamental: Sparring Style #4 — Runner — stay out of harm\'s way, get in and attack then get out quickly'),
        ReqItem(id: 'red_spar_1', text: 'Free Sparring using Sparring Style #4 — Runner'),
      ]),
      ReqCategory(name: 'MMA', items: [
        ReqItem(id: 'red_mma_0', text: 'Takedowns: 7) Circle Neck Throw 8) Back Knee Push — start from control, stay in control'),
        ReqItem(id: 'red_mma_1', text: 'Street Fighting Fundamental: 8 Elbow Strikes — 1) Front 2) Back 3) Reverse 4) Upward 5) Thrust 6) Angle Downward 7) Chop Down 8) Spin Reverse'),
        ReqItem(id: 'red_mma_2', text: 'Street Fighting using: Takedowns, 8 Elbow Strikes — if takedown occurs stand up immediately and restart'),
        ReqItem(id: 'red_mma_3', text: 'Mount Positions: 2) Side Mount 3) Back Mount; Guard Positions: 2) Open Guard 3) Half Guard'),
        ReqItem(id: 'red_mma_4', text: 'Submissions: 1) Standing Guillotine Choke 2) Rear Naked Choke'),
        ReqItem(id: 'red_mma_5', text: 'Submission Defenses: 1) Push Hip and Look Up 2) Pull Down'),
        ReqItem(id: 'red_mma_6', text: 'Ground Sparring using Mount Positions'),
      ]),
    ],
  ),

  RankReqs(
    rank: 'Advanced Red Belt',
    categories: [
      ReqCategory(name: 'Prerequisites', items: [
        ReqItem(id: 'ared_pre_0', text: 'Test fee due day before test: \$250, retry fee: \$125'),
        ReqItem(id: 'ared_pre_1', text: 'Has received Red Belt in Arnis'),
        ReqItem(id: 'ared_pre_2', text: 'Minimum age: 12 years old (or almost)'),
        ReqItem(id: 'ared_pre_3', text: 'Minimum of 80 classes training as a Red Belt'),
        ReqItem(id: 'ared_pre_4', text: 'Has attended 2 Board Breaking Seminars at this rank — 1 should be done within 3 months before the test date'),
        ReqItem(id: 'ared_pre_5', text: 'Learning period of 10 weeks — no pre-testing'),
        ReqItem(id: 'ared_pre_6', text: 'All deadlines for Essay, Training Plan, Fitness and Old Forms must be met'),
        ReqItem(id: 'ared_pre_7', text: 'Write an essay on "The Black Belt Mindset" — describe the three principles with examples: 100% effort, positive attitude, indomitable spirit. Email to info@truemartialarts.com'),
        ReqItem(id: 'ared_pre_8', text: 'Develop a Training Plan approved by the Student Development Director — email to sballata@msn.com before the deadline. Plan covers 3+ months: TMA class frequency, outside martial arts training, additional cardio/fitness'),
      ]),
      ReqCategory(name: 'Core Values', items: [
        ReqItem(id: 'ared_cv_0', text: 'Be respectful to yourself, your family, the school, and all the students'),
        ReqItem(id: 'ared_cv_1', text: 'Relax while going hard'),
        ReqItem(id: 'ared_cv_2', text: 'Reaching for Black Belt'),
        ReqItem(id: 'ared_cv_3', text: 'Demonstrate "The Black Belt Mindset": 100% effort, positive attitude, and indomitable spirit'),
        ReqItem(id: 'ared_cv_4', text: 'Fact: GJN Skyler Zoppi\'s teacher was SBN Thomas Zoppi in Bellevue, WA. SBN Thomas Zoppi\'s teacher was SBN Dan Di Vito in Los Angeles, CA. SBN Dan Di Vito\'s teacher was Grandmaster Chang Hae Choi in Chicago, IL'),
      ]),
      ReqCategory(name: 'Fitness', items: [
        ReqItem(id: 'ared_fit_0', text: '30 correct push-ups without stopping'),
        ReqItem(id: 'ared_fit_1', text: '60 correct sit-ups without stopping'),
      ]),
      ReqCategory(name: 'Advanced Kicks', items: [
        ReqItem(id: 'ared_kick_0', text: '#A7 Low Side Kick with Double Punch — weapon: Edge of Heel, side stance'),
        ReqItem(id: 'ared_kick_1', text: '#A8 Hook Back-heel, Roundhouse Kick — weapon: Back of Heel then Top, side stance'),
        ReqItem(id: 'ared_kick_2', text: '#A9 Front, Roundhouse, Front-Turning Reverse Side Kick — weapon: Ball then Top then Reverse Side of Foot, side stance'),
        ReqItem(id: 'ared_kick_3', text: 'Flying Reverse Side Kick — weapon: Edge of Heel'),
      ]),
      ReqCategory(name: 'Form Basics', items: [
        ReqItem(id: 'ared_fb_0', text: '#37 Triple Forearm Block (inner-forearm block + reverse inner-forearm block + outer-forearm block) — front stance'),
        ReqItem(id: 'ared_fb_1', text: '#38 Penetrating the Fortress Attack (standing double punch + double inner-forearm block + hopping double punch + lunge punch with Ki-hop) — feet together, feet together, front stance'),
        ReqItem(id: 'ared_fb_2', text: '#39 Double High Low Punch Attack (chamber in front + pivot + double high/low punch) — modified inline stance'),
        ReqItem(id: 'ared_fb_3', text: '#40 Hopping Knife-hand Guard (reverse low inner-forearm block + hop to high knife-hand guard) — angle stance, back stance'),
      ]),
      ReqCategory(name: 'Form', items: [
        ReqItem(id: 'ared_form_0', text: 'Bal She I — Penetrating the Fortress'),
      ]),
      ReqCategory(name: 'Self Defense', items: [
        ReqItem(id: 'ared_sd_0', text: 'Release, Defend & Escape against two opponents: Two-hands Choke from in front and Bear Hug'),
        ReqItem(id: 'ared_sd_1', text: 'One Step Spars: counterattack 2 to 4 strikes to target and vital areas with a finishing blow — demonstrate reality'),
      ]),
      ReqCategory(name: 'Sparring', items: [
        ReqItem(id: 'ared_spar_0', text: 'Sparring Fundamental: Shielding (block one opponent using another), Funneling (line up multiple opponents to attack one at a time), Disappearing (shoulder roll or leap away from the crowd)'),
        ReqItem(id: 'ared_spar_1', text: 'Free Sparring against two opponents hands only using: Shielding, Funneling, Disappearing'),
      ]),
      ReqCategory(name: 'MMA', items: [
        ReqItem(id: 'ared_mma_0', text: 'Takedowns: 9) Slide By 10) Single Leg Drive — start from clinch, stay in control'),
        ReqItem(id: 'ared_mma_1', text: 'Street Fighting using: Takedowns — if takedown occurs end in mounted position then stand up and restart. Survival Technique, all weapons of body, any target area'),
        ReqItem(id: 'ared_mma_2', text: 'Mount Escapes: 1) Full Mount — push on knee, end in Closed Guard; 2) Side Mount — hook ankle, end in Half Guard'),
        ReqItem(id: 'ared_mma_3', text: 'Submissions: 3) Forearm Choke 4) Key Lock'),
        ReqItem(id: 'ared_mma_4', text: 'Submission Defenses: 3) Push Across 4) Break Grip'),
        ReqItem(id: 'ared_mma_5', text: 'Ground Sparring using Submissions'),
      ]),
    ],
  ),

  RankReqs(
    rank: 'Black Belt',
    categories: [
      ReqCategory(name: 'Prerequisites', items: [
        ReqItem(id: 'black_pre_0', text: 'Test fee due day before test: \$500, retry fee: \$250 (includes black belt, black trim white top, black t-shirt and black uniform)'),
        ReqItem(id: 'black_pre_1', text: 'Minimum age: 13 years old'),
        ReqItem(id: 'black_pre_2', text: 'Has received Black Belt in Arnis'),
        ReqItem(id: 'black_pre_3', text: 'Minimum of 92 classes training as an Advanced Red Belt'),
        ReqItem(id: 'black_pre_4', text: 'Learning period of 3 months — no pre-testing, focus on learning new requirements'),
        ReqItem(id: 'black_pre_5', text: 'Has attended 2 Board Breaking Seminars at this rank — 1 should be done within 3 months before the test date'),
        ReqItem(id: 'black_pre_6', text: 'Knows Korean terminology for Basic Kicks #1 through #21'),
        ReqItem(id: 'black_pre_7', text: 'All deadlines for Internship, Essay, Training Plan, Fitness, Old Forms and Created Form must be met'),
        ReqItem(id: 'black_pre_8', text: 'Has consistently trained with the Tae Kwon Do Director'),
        ReqItem(id: 'black_pre_9', text: 'Has consistent 100% effort throughout the entirety of every class'),
        ReqItem(id: 'black_pre_10', text: 'Has started or completed an Assistant Instructor Internship before the deadline for your targeted test date'),
        ReqItem(id: 'black_pre_11', text: 'Has knowledge of 10 various martial arts styles and 10 martial arts Masters (outside of TMA) of your choice'),
        ReqItem(id: 'black_pre_12', text: 'Write an essay on Black Belt: What it is and what it takes — describe your own thoughts, experiences, and journey. Email to info@truemartialarts.com before the deadline'),
        ReqItem(id: 'black_pre_13', text: 'Develop a Training Plan approved by the Student Development Director — email to sballata@msn.com. Plan covers 3+ months: TMA class frequency, outside martial arts training, additional cardio/fitness'),
      ]),
      ReqCategory(name: 'Core Values', items: [
        ReqItem(id: 'black_cv_0', text: 'Be respectful to yourself, your family, the school, all the students, and all other people'),
        ReqItem(id: 'black_cv_1', text: 'Increased ability to confront force'),
        ReqItem(id: 'black_cv_2', text: 'Strong Intent, having the belief and desire necessary to achieve your goal'),
        ReqItem(id: 'black_cv_3', text: 'Integrity, do what you say you will do'),
        ReqItem(id: 'black_cv_4', text: 'Explain: Ability to Create Motion, Intention without Reservation'),
      ]),
      ReqCategory(name: 'Fitness', items: [
        ReqItem(id: 'black_fit_0', text: '35 correct push-ups without stopping'),
        ReqItem(id: 'black_fit_1', text: '70 correct sit-ups within 2 minutes'),
      ]),
      ReqCategory(name: 'Advanced Kicks', items: [
        ReqItem(id: 'black_kick_0', text: '#A10 Reverse Hook Back-heel, Back-leg Roundhouse Kick — side stance'),
        ReqItem(id: 'black_kick_1', text: '#A11 Jump Side, Reverse Side Kick — side stance'),
        ReqItem(id: 'black_kick_2', text: '#A12 Spinning Reverse Crescent Kick — side stance'),
        ReqItem(id: 'black_kick_3', text: 'Jump Reverse Crescent Kick — side parallel stance'),
      ]),
      ReqCategory(name: 'Form Basics', items: [
        ReqItem(id: 'black_fb_0', text: '#41 Diagonal Punch Attack (back hand punch across up + hammer-fist down + punch up + hammer-fist across down) — side stance'),
        ReqItem(id: 'black_fb_1', text: '#42 Forearm Attack (tension forearm strike + two hands punch forward with Ki-hop) — side stance'),
        ReqItem(id: 'black_fb_2', text: '#43 Out-In Attack (high/low knife-hand guard + out-in block with ridge-hands then fists + defensive attack + punch) — back stance, mod front stance, back stance'),
        ReqItem(id: 'black_fb_3', text: '#44 Chest Breaking Attack (chest breaking strike + circle into knife hand guard) — front stance, short back stance'),
      ]),
      ReqCategory(name: 'Forms', items: [
        ReqItem(id: 'black_form_0', text: 'Chul Ki Bongo Sa Dan Cha Ki Hyung — Alley Blocking High Kick Form'),
        ReqItem(id: 'black_form_1', text: 'Created Form: must be about 30 moves, end where it begins, have symmetrical movements, and have a Korean name'),
      ]),
      ReqCategory(name: 'Self Defense', items: [
        ReqItem(id: 'black_sd_0', text: 'Release and Defend against any situation: single opponent'),
        ReqItem(id: 'black_sd_1', text: 'No Step Spars: efficient counter attacks to target and vital areas with finishing blow — demonstrate reality in counterattack'),
      ]),
      ReqCategory(name: 'Sparring', items: [
        ReqItem(id: 'black_spar_0', text: 'Free Sparring against two opponents hands and feet using: Shielding, Funneling, Disappearing — move around'),
      ]),
      ReqCategory(name: 'MMA', items: [
        ReqItem(id: 'black_mma_0', text: 'Takedowns: 11) Head Bump Single Leg Throw 12) Double Leg Throw — start from control, stay in control'),
        ReqItem(id: 'black_mma_1', text: 'Street Fighting Fundamental: Defense Sprawl'),
        ReqItem(id: 'black_mma_2', text: 'Street Fighting using: all MMA techniques'),
        ReqItem(id: 'black_mma_3', text: 'Guard Escapes: 1) Pass Closed Guard — sit on heals, neck out, elbow to knee, weight on chest, slide to Side Mount'),
        ReqItem(id: 'black_mma_4', text: 'Mount Escapes: 3) Back Mount — elbow in thigh, lift foot, twist, end in Side Mount'),
        ReqItem(id: 'black_mma_5', text: 'Submissions: 5) Arm Bar from Guard 6) Ezekiel Choke — while being mounted'),
        ReqItem(id: 'black_mma_6', text: 'Submission Defenses: 5) Thinking Man 6) Hero Grip'),
        ReqItem(id: 'black_mma_7', text: 'Guard Sweeps: 1) Underhook'),
      ]),
      ReqCategory(name: 'Board Breaks', items: [
        ReqItem(id: 'black_bb_0', text: 'Combination Break of your choice — must be impressive to the audience and black belt panel'),
        ReqItem(id: 'black_bb_1', text: 'Chi OR Speed Break of your choice — must be impressive to the audience and black belt panel'),
      ]),
    ],
  ),
];

// hand-defined hierarchy
// integers used as sort keys
const List<String> rankOrder = [
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