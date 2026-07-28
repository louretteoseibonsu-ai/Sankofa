import 'lesson_content.dart' show Challenge;

/// A short reading passage: Twi lines (each matches a bundled audio clip so
/// pronunciation plays free), an English translation, and comprehension
/// questions. Built from vocabulary the app already teaches, so the Twi is
/// accurate and speakable.
class ReadingPassage {
  final String id;
  final String title;
  final String level; // Beginner / Elementary / …
  final List<String> lines;
  final String english;
  /// Per-line English, aligned 1:1 with [lines]. When present (and the level is
  /// Beginner/Elementary), the reader shows an interlinear layout — each Twi
  /// line with its English directly beneath. Empty ⇒ flowing-paragraph reader.
  final List<String> lineGloss;
  final List<Challenge> questions;

  /// Folklore framework extras (optional): a short "why this matters" note and
  /// the key words to pre-teach. Empty for the plain everyday passages.
  final String culturalContext;
  final List<MapEntry<String, String>> vocab; // twi → English gloss

  const ReadingPassage({
    required this.id,
    required this.title,
    required this.level,
    required this.lines,
    required this.english,
    required this.questions,
    this.lineGloss = const [],
    this.culturalContext = '',
    this.vocab = const [],
  });

  /// Correct answers needed to pass (60%, rounded up).
  int get passMark => (questions.length * 0.6).ceil();
}

const List<ReadingPassage> kReadingPassages = [
  ReadingPassage(
    id: 'read_greetings_family',
    title: 'Akwaaba — Meeting Ama',
    level: 'Beginner',
    lines: [
      'Akwaaba! Yɛma wo akwaaba.',
      'Wo ho te sɛn?',
      'Me ho yɛ',
      'Medaase',
      "Me na ne m'agya wɔ fie.",
      'Onua baa baako wɔ me.',
      'Me abusua mu nnipa dɔɔso.',
    ],
    lineGloss: [
      'Welcome! We welcome you.',
      'How are you?',
      'I am fine.',
      'Thank you.',
      'My mother and my father are at home.',
      'I have one sister.',
      'There are many people in my family.',
    ],
    english: 'Welcome! We welcome you. How are you? I am fine. Thank you. '
        'My mother and my father are at home. I have one sister. '
        'There are many people in my family.',
    questions: [
      Challenge(
        'How does the speaker say they are feeling?',
        ['I am fine (Me ho yɛ)', 'I am tired', 'I am hungry', 'I am busy'],
        0,
      ),
      Challenge(
        'Who is at home (fie)?',
        ['Mother and father', 'Brother and sister', 'Grandparents', 'Friends'],
        0,
      ),
      Challenge(
        'How many sisters does the speaker have?',
        ['One', 'Two', 'Three', 'None'],
        0,
      ),
      Challenge(
        'What does “Medaase” mean?',
        ['Thank you', 'Welcome', 'Sorry', 'Please'],
        0,
      ),
    ],
  ),
  ReadingPassage(
    id: 'read_numbers',
    title: 'Yɛkan — Let’s Count',
    level: 'Beginner',
    lines: [
      'Baako, mmienu, mmiɛnsa.',
      'ɛnan',
      'enum',
      'Me wɔ nnipa baako.',
    ],
    lineGloss: [
      'One, two, three.',
      'Four.',
      'Five.',
      'I have one person.',
    ],
    english: 'One, two, three. Four. Five. I have one person.',
    questions: [
      Challenge(
        'What number is “mmienu”?',
        ['Two', 'One', 'Three', 'Five'],
        0,
      ),
      Challenge(
        'What number is “enum”?',
        ['Five', 'Four', 'Six', 'Ten'],
        0,
      ),
      Challenge(
        '“Baako” means…',
        ['One', 'Two', 'Zero', 'Many'],
        0,
      ),
      Challenge(
        '“Mmiɛnsa” is which number?',
        ['Three', 'Two', 'Four', 'Six'],
        0,
      ),
    ],
  ),
  ReadingPassage(
    id: 'read_time_of_day',
    title: 'Nkyea — Greetings Through the Day',
    level: 'Elementary',
    lines: [
      'Maakye',
      'Maaha',
      'Maadwo',
    ],
    lineGloss: [
      'Good morning.',
      'Good afternoon.',
      'Good evening.',
    ],
    english: 'Good morning. Good afternoon. Good evening. '
        '(At every time of day, we greet one another.)',
    questions: [
      Challenge(
        'Which greeting is used in the morning (anɔpa)?',
        ['Maakye', 'Maaha', 'Maadwo', 'Medaase'],
        0,
      ),
      Challenge(
        '“Maadwo” is used in the…',
        ['Evening', 'Morning', 'Afternoon', 'Midnight'],
        0,
      ),
      Challenge(
        '“Maaha” greets someone in the…',
        ['Afternoon', 'Morning', 'Evening', 'Night'],
        0,
      ),
    ],
  ),
  ReadingPassage(
    id: 'read_at_the_door',
    title: 'Bra Mu — At the Door',
    level: 'Elementary',
    lines: [
      'Akwaaba, bra mu.',
      'Mepa wo kyɛw',
      'Wo ho te sɛn?',
      'Me ho yɛ',
      'Medaase',
      'Aane',
    ],
    lineGloss: [
      'Welcome, come in.',
      'Please. / Excuse me.',
      'How are you?',
      'I am fine.',
      'Thank you.',
      'Yes.',
    ],
    english: 'Welcome, come in. Please. How are you? I am fine. Thank you. Yes.',
    questions: [
      Challenge(
        '“Bra mu” invites you to…',
        ['Come in', 'Sit down', 'Eat', 'Leave'],
        0,
      ),
      Challenge(
        '“Mepa wo kyɛw” means…',
        ['Please / excuse me', 'Thank you', 'Welcome', 'Goodbye'],
        0,
      ),
      Challenge(
        'The reply “Me ho yɛ” means…',
        ['I am fine', 'I am here', 'I am coming', 'I am hungry'],
        0,
      ),
      Challenge(
        '“Aane” means…',
        ['Yes', 'No', 'Maybe', 'Please'],
        0,
      ),
    ],
  ),
  // ── Folklore Reading Module — Anansesɛm ─────────────────────────────────
  ReadingPassage(
    id: 'read_ananse_wisdom_pot',
    title: 'Ananse ne Nyansa Kuku',
    level: 'Folklore',
    lines: [
      'Ananse pɛ sɛ ɔfa nyansa nyinaa.',
      'Ɔde nyansa no guu kuku mu.',
      'Ɔpɛ sɛ ɔforo dua no de sie.',
      'Ne ba Ntikuma kyerɛɛ no ɔkwan pa.',
      'Ananse bo fuiɛ, na kuku no bɔeɛ.',
      'Nyansa petee wiase nyinaa mu.',
    ],
    english:
        'Long ago, Kwaku Ananse the spider decided to gather all the wisdom in '
        'the world and keep it for himself. He collected it into a clay pot and '
        'set out to hide it at the top of a tall tree. He tied the pot to his '
        'front and tried to climb — but the pot kept getting in the way, and he '
        'slipped again and again. His small son, Ntikuma, watching from below, '
        'said, “Father, tie the pot on your back — then you can climb.” Ananse '
        'was astonished that a child knew something he, the keeper of all '
        'wisdom, did not. In his frustration he let the pot fall. It smashed, '
        'and the wisdom scattered on the wind to every corner of the world. '
        'That is why no one person holds all wisdom — a little belongs to '
        'everyone.',
    culturalContext:
        'Kwaku Ananse the spider is the trickster hero of Akan folktales — so '
        'central that all folktales are called Anansesɛm, “Spider tales.” '
        'Elders tell them in the evening to pass on wisdom through humour. This '
        'story explains a proverb Ghanaians still say: nyansa nyinaa nni onipa '
        'baako tirim — “all wisdom is not in one person’s head.”',
    vocab: [
      MapEntry('Ananse', 'the spider — trickster hero of the tales'),
      MapEntry('nyansa', 'wisdom'),
      MapEntry('kuku', 'a clay pot'),
      MapEntry('Ntikuma', "Ananse's son"),
      MapEntry('Anansesɛm', 'folktales (“spider tales”)'),
    ],
    questions: [
      Challenge(
        'What did Ananse want to do with all the wisdom?',
        [
          'Keep it for himself',
          'Share it with everyone',
          'Sell it at the market',
          'Give it to Nyame'
        ],
        0,
      ),
      Challenge(
        'Where did he put the wisdom?',
        [
          'In a clay pot (kuku)',
          'In a golden box',
          'In a basket',
          'Under a tree'
        ],
        0,
      ),
      Challenge(
        'Who gave Ananse the clever advice?',
        ['His son Ntikuma', 'Nyame the Sky God', 'His wife', 'A leopard'],
        0,
      ),
      Challenge(
        'What does the story teach?',
        [
          'No one person holds all wisdom',
          'Spiders can climb trees',
          'Always obey your elders',
          'Pots break easily'
        ],
        0,
      ),
    ],
  ),
  ReadingPassage(
    id: 'read_ananse_thin_waist',
    title: 'Ananse ne Aponto Mmienu',
    level: 'Folklore',
    lines: [
      'Nkuraa mmienu yɛɛ aponto da koro.',
      'Ananse mpɛ sɛ ne werɛ fi biara.',
      'Ɔde ahoma kyekyeree ne sisi.',
      'Ne mma no twee ahoma no denneennen.',
      'Ahoma no mia Ananse sisi ma ɛyɛɛ ketewa.',
      'Ɛno nti na ananse asisi yɛ ketewa.',
    ],
    english:
        'On the very same day, two villages were preparing a great feast. '
        'Greedy Kwaku Ananse could not bear to miss either one. So he tied a '
        'long rope around his waist and gave one end to his children in the '
        'first village and the other to his children in the second, telling '
        'each, “Pull the rope when the food is ready, and I will come running.” '
        'But both feasts were ready at exactly the same moment. His children '
        'pulled hard from both sides at once. The rope drew tight around '
        'Ananse’s middle and held him fast — he could reach neither feast and '
        'got nothing to eat at all. By the time they found him, the rope had '
        'squeezed his waist thin and small. And that, they say, is why the '
        'spider has a thin waist to this day.',
    culturalContext:
        'Many Anansesɛm are “pourquoi” tales — they explain why the world is '
        'the way it is (why the spider’s waist is thin, why stories are told at '
        'night). Ananse’s greed is the running joke, but the lesson lands '
        'gently: wanting everything at once can leave you with nothing. Elders '
        'tell it to warn against greed — anibere nkɔ, “greed leads nowhere.”',
    vocab: [
      MapEntry('aponto', 'a feast / celebration'),
      MapEntry('ahoma', 'rope'),
      MapEntry('sisi', 'waist'),
      MapEntry('aduane', 'food'),
      MapEntry('ketewa', 'small / thin'),
    ],
    questions: [
      Challenge(
        'Why did Ananse tie a rope around his waist?',
        [
          'To be pulled to whichever feast was ready',
          'To climb a tree',
          'To catch fish',
          'To carry the food home'
        ],
        0,
      ),
      Challenge(
        'What happened when both feasts were ready at once?',
        [
          'Both sides pulled and the rope squeezed him',
          'He ate at both',
          'He chose the nearer village',
          'The rope snapped'
        ],
        0,
      ),
      Challenge(
        'How much did Ananse get to eat?',
        ['Nothing at all', 'A full meal', 'Half a meal', 'Only dessert'],
        0,
      ),
      Challenge(
        'What does this story explain?',
        [
          'Why the spider has a thin waist',
          'Why spiders spin webs',
          'Why feasts are held at night',
          'Why ropes are strong'
        ],
        0,
      ),
    ],
  ),
  ReadingPassage(
    id: 'read_ananse_stories',
    title: 'Sɛdeɛ Anansesɛm Baa Wiase',
    level: 'Folklore',
    lines: [
      'Kane no, Nyame na ɔwɔ anansesɛm nyinaa.',
      'Ananse pɛ sɛ ɔtɔ bi.',
      'Nyame kaa boɔ a ɛyɛ den.',
      'Ananse de nyansa kyeree Onini ne Osebo.',
      'Ɔde wɔn nyinaa kɔmaa Nyame.',
      'Ɛfiri saa bɛr no, yɛfrɛ atetesɛm Anansesɛm.',
    ],
    english:
        'Long ago, all the world’s stories belonged to Nyame, the Sky God, who '
        'kept them locked in a box. Kwaku Ananse the spider longed to own them. '
        'Nyame set a price no one had ever paid: “Bring me Onini the python, '
        'the Mmoboro hornets, and Osebo the leopard.” With cunning instead of '
        'strength, Ananse won all three. He tricked the python into being '
        'measured against a pole — and tied it fast. He fooled the hornets into '
        'a gourd by pretending it was raining, so they flew inside to shelter. '
        'He trapped the fierce leopard in a hidden pit. He carried all three up '
        'to the sky, and Nyame, astonished, handed over the stories. Ever '
        'since, all folktales are called Anansesɛm — “Spider tales” — and '
        'wisdom, Ananse teaches, achieves what force cannot.',
    culturalContext:
        'This is the origin tale that gives the whole tradition its name: '
        'Anansesɛm, “Spider tales.” It sets out Ananse’s defining trait — he '
        'wins not by strength but by cleverness (nyansa), outwitting creatures '
        'far bigger than himself. Carried across the Atlantic, he lives on in '
        'the Caribbean and the Americas as “Anansi.” The lesson: nyansa sen '
        'ahoɔden — “wisdom is greater than strength.”',
    vocab: [
      MapEntry('Nyame', 'God (the Sky God)'),
      MapEntry('anansesɛm', 'folktales (“spider tales”)'),
      MapEntry('Onini', 'the python'),
      MapEntry('Osebo', 'the leopard'),
      MapEntry('nyansa', 'wisdom / cunning'),
    ],
    questions: [
      Challenge(
        'Who owned all the stories at first?',
        ['Nyame the Sky God', 'Ananse', 'Osebo the leopard', 'The chief'],
        0,
      ),
      Challenge(
        'What price did Nyame set?',
        [
          'Capture the python, hornets, and leopard',
          'Ten bags of gold',
          'Climb the tallest tree',
          'Tell a hundred stories'
        ],
        0,
      ),
      Challenge(
        'How did Ananse win the stories?',
        [
          'With cunning, not strength',
          'By fighting the animals',
          'By paying with gold',
          'By asking politely'
        ],
        0,
      ),
      Challenge(
        'Why are folktales called Anansesɛm?',
        [
          'Because Ananse won the stories',
          'Because spiders tell them',
          'Because they are told at night',
          'Because Nyame wrote them'
        ],
        0,
      ),
    ],
  ),
];
