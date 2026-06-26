export interface VocabularyItem {
  twi: string;
  english: string;
  phonetic: string;
  usageContext?: string;
}

export interface VocabularyCategory {
  id: string;
  name: string;
  description: string;
  icon: string;
  items: VocabularyItem[];
}

export interface AkanDayName {
  dayIndex: number; // 0 = Sunday, 1 = Monday, etc.
  dayTwi: string;
  maleName: string;
  femaleName: string;
  attribute: string;
  meaning: string;
}

export interface QuizQuestion {
  id: string;
  category: string;
  question: string;
  options: string[];
  answer: string;
  explanation: string;
}

export interface AdinkraSymbol {
  id: string;
  name: string;
  literalTranslation: string;
  coreValue: string;
  symbolDescription: string;
  emojiCode?: string; // a close symbolic character
}

export const ACAN_DAY_NAMES: AkanDayName[] = [
  {
    dayIndex: 0,
    dayTwi: "Kwasiada",
    maleName: "Kwasi",
    femaleName: "Akosua",
    attribute: "Bodua / Asiama",
    meaning: "Spiritual, agile, natural leaders. Associated with the Universe and pure beginnings."
  },
  {
    dayIndex: 1,
    dayTwi: "Dwowda",
    maleName: "Kwadwo",
    femaleName: "Adwoa",
    attribute: "Okoto / Koto",
    meaning: "Peaceful, calm, reflective, and diplomatic. Natural peacemakers."
  },
  {
    dayIndex: 2,
    dayTwi: "Benada",
    maleName: "Kwabena",
    femaleName: "Abena",
    attribute: "Ogyam / Obrempong",
    meaning: "Warm-hearted, friendly, passionate, and protective. Full of active energy."
  },
  {
    dayIndex: 3,
    dayTwi: "Wukuada",
    maleName: "Kwaku",
    femaleName: "Akua",
    attribute: "Ntonni / Dausi",
    meaning: "Intellectual, creative, communicative, and witty. Natural problem-solvers."
  },
  {
    dayIndex: 4,
    dayTwi: "Yawoada",
    maleName: "Yaw",
    femaleName: "Yaa",
    attribute: "Preko / Barko",
    meaning: "Courageous, highly determined, assertive, and resilient under pressure."
  },
  {
    dayIndex: 5,
    dayTwi: "Fiada",
    maleName: "Kofi",
    femaleName: "Afia",
    attribute: "Okyere / Kyere",
    meaning: "Generous, highly observant, creative, and very community-minded."
  },
  {
    dayIndex: 6,
    dayTwi: "Memeneda",
    maleName: "Kwame",
    femaleName: "Ama",
    attribute: "Atoapem / Oteanankannuro",
    meaning: "Responsible, highly organized, deep-thinking, and historically minded. Wise advisors."
  }
];

export const VOCABULARY_CATEGORIES: VocabularyCategory[] = [
  {
    id: "greetings",
    name: "Greetings & Etiquette",
    description: "Learn how to say hello, show respect, and address people politely.",
    icon: "MessageSquareHeart",
    items: [
      {
        twi: "Akwaaba",
        english: "Welcome",
        phonetic: "Ah-kwaa-bah",
        usageContext: "Warm welcome given to visitors or anyone arriving."
      },
      {
        twi: "Mema wo akye",
        english: "Good morning",
        phonetic: "Me-mah wo ah-chay",
        usageContext: "A respectful morning greeting. Often shortened to 'Akye'."
      },
      {
        twi: "Mema wo aha",
        english: "Good afternoon",
        phonetic: "Me-mah wo ah-hah",
        usageContext: "Middle of the day greeting (between 12 PM and 4 PM)."
      },
      {
        twi: "Mema wo adwo",
        english: "Good evening",
        phonetic: "Me-mah wo ah-joh",
        usageContext: "Evening greeting. Shows high warmth."
      },
      {
        twi: "Ete sen?",
        english: "How are you?",
        phonetic: "Eh-teh sen?",
        usageContext: "The most common conversational greeting. Literally 'how is it standing?'"
      },
      {
        twi: "Eye",
        english: "It is fine / good",
        phonetic: "Eh-yeh",
        usageContext: "Standard optimistic response to 'Ete sen?'"
      },
      {
        twi: "Medaase",
        english: "Thank you",
        phonetic: "Meh-daah-say",
        usageContext: "Expressing gratitude. High cultural significance."
      },
      {
        twi: "Me paakyew",
        english: "Please",
        phonetic: "Meh paa-chih-oh",
        usageContext: "Always used to make requests polite and demonstrate good breeding."
      },
      {
        twi: "Kose",
        english: "Sorry",
        phonetic: "Koh-say",
        usageContext: "Expressing regret, condolence, or empathy."
      },
      {
        twi: "Nante yiye",
        english: "Walk well / Goodbye",
        phonetic: "Nah-teh yee-yay",
        usageContext: "A beautiful way to bid farewell. Literally 'walk well'."
      }
    ]
  },
  {
    id: "conversational",
    name: "Conversational Basics",
    description: "Simple phrases to build your first interactions.",
    icon: "Users",
    items: [
      {
        twi: "Yoo",
        english: "Okay / Agreed",
        phonetic: "Yoo",
        usageContext: "Used constantly to confirm, agree, or say okay."
      },
      {
        twi: "Aane",
        english: "Yes",
        phonetic: "Ah-nay",
        usageContext: "Affirmative answer."
      },
      {
        twi: "Dabi",
        english: "No",
        phonetic: "Dah-bee",
        usageContext: "Negative answer."
      },
      {
        twi: "Wo din de sen?",
        english: "What is your name?",
        phonetic: "Wo deen day sen?",
        usageContext: "Asking for someone's name."
      },
      {
        twi: "Me din de...",
        english: "My name is...",
        phonetic: "Meh deen day...",
        usageContext: "Introducing yourself."
      },
      {
        twi: "Wofiri he?",
        english: "Where are you from?",
        phonetic: "Wo-fih-ree hay?",
        usageContext: "Inquiring about origins."
      },
      {
        twi: "Mofiri...",
        english: "I am from...",
        phonetic: "Meh-fih-ree...",
        usageContext: "Stating your country or hometown."
      },
      {
        twi: "Mente Twi yiye",
        english: "I don't hear (speak) Twi well",
        phonetic: "Men-tay Twee yee-yay",
        usageContext: "Polite warning that you are still a learner."
      }
    ]
  },
  {
    id: "family",
    name: "Family & Relations",
    description: "Words for relatives, which form the cornerstone of Akan communal life.",
    icon: "Heart",
    items: [
      {
        twi: "Agya / Papa",
        english: "Father",
        phonetic: "Ah-jah / Pah-pah",
        usageContext: "Biological father or father figure."
      },
      {
        twi: "Ena / Maame",
        english: "Mother",
        phonetic: "Eh-nah / Maa-may",
        usageContext: "Biological mother or maternal figure."
      },
      {
        twi: "Onuabarima",
        english: "Brother",
        phonetic: "Oh-nwah-bah-ree-mah",
        usageContext: "Literally 'male sibling'."
      },
      {
        twi: "Onuabaa",
        english: "Sister",
        phonetic: "Oh-nwah-baa",
        usageContext: "Literally 'female sibling'."
      },
      {
        twi: "Nana",
        english: "Grandparent / Elder / Chief",
        phonetic: "Nah-nah",
        usageContext: "A term of high honor used for elders, chiefs, or grandparents."
      },
      {
        twi: "Oba",
        english: "Child",
        phonetic: "Oh-bah",
        usageContext: "Child or offspring."
      },
      {
        twi: "Okunu",
        english: "Husband",
        phonetic: "Oh-koo-noo",
        usageContext: "Spouse (male)."
      },
      {
        twi: "Oyere",
        english: "Wife",
        phonetic: "Oh-yeh-ray",
        usageContext: "Spouse (female)."
      }
    ]
  },
  {
    id: "numbers",
    name: "Numbers & Counting",
    description: "Learn how to count from 1 to 10 and beyond.",
    icon: "Binary",
    items: [
      { twi: "Baako", english: "One", phonetic: "Baah-koh" },
      { twi: "Mmienu", english: "Two", phonetic: "Mmee-eh-noo" },
      { twi: "Mmiensa", english: "Three", phonetic: "Mmee-ehn-sah" },
      { twi: "Enan", english: "Four", phonetic: "Eh-nahn" },
      { twi: "Enum", english: "Five", phonetic: "Eh-noom" },
      { twi: "Ensia", english: "Six", phonetic: "En-see-ah" },
      { twi: "Eson", english: "Seven", phonetic: "Eh-sohn" },
      { twi: "Enwotwe", english: "Eight", phonetic: "En-woh-chway" },
      { twi: "Enkron", english: "Nine", phonetic: "En-krohn" },
      { twi: "Edu", english: "Ten", phonetic: "Eh-doo" }
    ]
  },
  {
    id: "food",
    name: "Food & Dining",
    description: "Traditional dishes and dining table expressions.",
    icon: "Utensils",
    items: [
      {
        twi: "Aduane",
        english: "Food",
        phonetic: "Ah-dwah-nay"
      },
      {
        twi: "Fufuo",
        english: "Fufu",
        phonetic: "Foo-foo-oh",
        usageContext: "Ghanaian staple made by pounding cassava and plantain."
      },
      {
        twi: "Nsuo",
        english: "Water",
        phonetic: "N-soo-oh",
        usageContext: "Vital request: 'Mepaakyew ma me nsuo' - Please give me water."
      },
      {
        twi: "Enam",
        english: "Meat / Fish",
        phonetic: "Eh-nahm"
      },
      {
        twi: "Kom de me",
        english: "I am hungry",
        phonetic: "Kohm day mee",
        usageContext: "Literally 'hunger holds/afflicts me'."
      },
      {
        twi: "Sukom de me",
        english: "I am thirsty",
        phonetic: "Soo-kohm day mee",
        usageContext: "Literally 'water-hunger holds me'."
      },
      {
        twi: "Adidi",
        english: "To eat",
        phonetic: "Ah-dee-dee"
      }
    ]
  }
];

export const ADINKRA_SYMBOLS: AdinkraSymbol[] = [
  {
    id: "sankofa",
    name: "Sankofa",
    literalTranslation: "Go back and get it",
    coreValue: "Learning from the past / Cultural Heritage",
    symbolDescription: "Depicted either as a bird with its head turned backwards taking an egg from its back, or a stylized heart shape. It teaches that gathering wisdom and values from our ancestors is critical to building a prosperous future.",
    emojiCode: "𓅃"
  },
  {
    id: "gyenyame",
    name: "Gye Nyame",
    literalTranslation: "Except God",
    coreValue: "Supremacy of God / Spiritual Faith",
    symbolDescription: "One of the most famous Adinkra symbols. It represents the omnipotence and supremacy of God over all creation, expressing that nothing can happen without divine authorization.",
    emojiCode: "𓋹"
  },
  {
    id: "dwennimmen",
    name: "Dwennimmen",
    literalTranslation: "Ram's horns",
    coreValue: "Humility combined with Strength",
    symbolDescription: "Represents the horns of a ram. It symbolizes that even when you are strong, powerful, and accomplished, you should maintain a humble spirit, learning from others and serving the community.",
    emojiCode: "🐏"
  },
  {
    id: "mate_masie",
    name: "Mate Masie",
    literalTranslation: "I have heard and kept it",
    coreValue: "Wisdom, Knowledge & Prudence",
    symbolDescription: "A symbol of four interconnected circles. It signifies listening deeply, reflecting, and storing wisdom. It is the hallmark of a wise scholar or chief.",
    emojiCode: "🔘"
  }
];

export const QUIZ_QUESTIONS: QuizQuestion[] = [
  {
    id: "q1",
    category: "Greetings & Basics",
    question: "What is the primary meaning of the word 'Akwaaba'?",
    options: ["Goodbye", "Thank you", "Welcome", "Good morning"],
    answer: "Welcome",
    explanation: "Akwaaba is the legendary Ghanaian word for 'Welcome', showered upon guests to show hospitality."
  },
  {
    id: "q2",
    category: "Greetings & Basics",
    question: "How do you say 'Thank you' in Asante Twi?",
    options: ["Akwaaba", "Medaase", "Kose", "Ete sen?"],
    answer: "Medaase",
    explanation: "'Medaase' means thank you. It represents giving thanks to someone's kindness."
  },
  {
    id: "q3",
    category: "Day Names",
    question: "If a girl is born on Saturday (Memeneda), what is her traditional Akan day name?",
    options: ["Akua", "Ama", "Adwoa", "Yaa"],
    answer: "Ama",
    explanation: "Ama is the traditional name for a girl born on Saturday. A boy born on Saturday is named Kwame."
  },
  {
    id: "q4",
    category: "Numbers & Counting",
    question: "Which of the following is the Twi word for the number Five (5)?",
    options: ["Mmienu", "Enum", "Edu", "Ensia"],
    answer: "Enum",
    explanation: "Enum is 5. Baako (1), Mmienu (2), Mmiensa (3), Enan (4), Enum (5)."
  },
  {
    id: "q5",
    category: "Cultural Wisdom",
    question: "What is the literal translation of the symbol and word 'Sankofa'?",
    options: ["Except God", "Go back and get it", "Ram's horns", "Humility and Strength"],
    answer: "Go back and get it",
    explanation: "Sankofa means 'to return and fetch it' (san - to return; ko - to go; fa - to look/take). It represents learning from our history."
  },
  {
    id: "q6",
    category: "Conversational Basics",
    question: "What does 'Kom de me' translate to?",
    options: ["I am happy", "I am tired", "I am hungry", "I am going home"],
    answer: "I am hungry",
    explanation: "'Kom de me' literally translates to 'hunger holds/afflicts me', meaning 'I am hungry'."
  }
];
