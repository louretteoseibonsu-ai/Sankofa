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
  id: string; // also the key used to render the authentic SVG glyph in App.tsx
  name: string;
  literalTranslation: string;
  coreValue: string;
  symbolDescription: string;
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

// Symbols and meanings sourced from adinkrasymbols.org.
// Each `id` maps to an authentic monochrome SVG glyph rendered by <AdinkraGlyph /> in App.tsx.
export const ADINKRA_SYMBOLS: AdinkraSymbol[] = [
  {
    id: "gyenyame",
    name: "Gye Nyame",
    literalTranslation: "Except God",
    coreValue: "Omnipotence & Supremacy of God",
    symbolDescription: "Probably the most popular Adinkra symbol, expressing the omnipotence and supremacy of God over all creation. It conveys that nothing happens without divine authorization. It is featured on Ghana's largest-denomination banknote, the 200 cedi note."
  },
  {
    id: "sankofa",
    name: "Sankofa",
    literalTranslation: "Go back and get it",
    coreValue: "Learning from the past to build the future",
    symbolDescription: "Depicted as a bird turning its head backward to retrieve an egg from its back. A symbol of the wisdom of learning from the past to build for the future. From the Akan proverb, 'Se wo were fi na wosan kofa a yenkyiri,' meaning 'It is not taboo to go back for what you forgot (or left behind).'"
  },
  {
    id: "dwennimmen",
    name: "Dwennimmen",
    literalTranslation: "Ram's horns",
    coreValue: "Strength tempered with Humility",
    symbolDescription: "Represents a ram's horns. A symbol of strength (in mind, body, and soul), humility, wisdom, and learning. It teaches that even the strong should remain humble. It features prominently in the logo of the University of Ghana."
  },
  {
    id: "akoma",
    name: "Akoma",
    literalTranslation: "The heart",
    coreValue: "Love, Patience & Endurance",
    symbolDescription: "A symbol of love, goodwill, patience, faithfulness, fondness, endurance, and consistency. The heart reminds one to 'take heart' and be tolerant and patient with others."
  },
  {
    id: "nkyinkyim",
    name: "Nkyinkyim",
    literalTranslation: "Twisting",
    coreValue: "Adaptability & Resourcefulness",
    symbolDescription: "A symbol representing the tortuous, twisting nature of life's journey. It speaks to the dynamism, adaptability, and resourcefulness required to navigate life's many turns."
  },
  {
    id: "adinkrahene",
    name: "Adinkrahene",
    literalTranslation: "King of the Adinkra symbols",
    coreValue: "Authority, Leadership & Charisma",
    symbolDescription: "Three concentric circles forming a symbol of authority, leadership, and charisma, and the qualities associated with kings. Adinkrahene is reportedly the inspiration for the design of the other Adinkra symbols."
  },
  {
    id: "mate_masie",
    name: "Mate Masie",
    literalTranslation: "I have heard and kept it",
    coreValue: "Wisdom, Knowledge & Prudence",
    symbolDescription: "Also known as Ntesie. A symbol of wisdom, knowledge, and prudence. It signifies listening deeply, reflecting, and storing wisdom — the hallmark of a wise and discerning person."
  },
  {
    id: "fihankra",
    name: "Fihankra",
    literalTranslation: "Enclosed, secured compound",
    coreValue: "Brotherhood, Safety & Solidarity",
    symbolDescription: "An enclosed or secured compound house. A symbol of brotherhood, safety, security, completeness, and solidarity — representing the ideal of a unified, protected community."
  },
  {
    id: "aya",
    name: "Aya",
    literalTranslation: "Fern",
    coreValue: "Endurance & Defiance Against Difficulties",
    symbolDescription: "The fern, a hardy plant that can grow in difficult places. A symbol of endurance, independence, defiance against difficulties, hardiness, perseverance, and resourcefulness."
  },
  {
    id: "funtumfunefu",
    name: "Funtumfunefu Denkyemfunefu",
    literalTranslation: "Conjoined crocodiles",
    coreValue: "Unity in Diversity",
    symbolDescription: "Two crocodiles sharing a single stomach. A symbol of unity in diversity and a common destiny — reminding us that though individuals may compete, the community shares one fate and thrives through cooperation."
  },
  {
    id: "nyame_dua",
    name: "Nyame Dua",
    literalTranslation: "God's tree (altar)",
    coreValue: "God's Presence & Protection",
    symbolDescription: "A sacred altar or 'tree of God,' traditionally a three- or four-pronged stump. A symbol of God's presence and protection, marking a place of worship and spiritual purification."
  },
  {
    id: "epa",
    name: "Epa",
    literalTranslation: "Handcuffs",
    coreValue: "Law, Justice & Accountability",
    symbolDescription: "The handcuff or shackle. A symbol of law, justice, slavery, and captivity. It carries the proverb that whatever binds another also binds the one who holds the chain — a reminder of mutual accountability."
  },
  {
    id: "akofena",
    name: "Akofena",
    literalTranslation: "Sword of war",
    coreValue: "Courage, Valor & State Authority",
    symbolDescription: "Crossed ceremonial swords. A symbol of courage, valor, and heroism, and of the legitimized authority of a ruler. A pair of these state swords appears in Ghana's coat of arms."
  },
  {
    id: "akoben",
    name: "Akoben",
    literalTranslation: "War horn",
    coreValue: "Vigilance & Readiness",
    symbolDescription: "A war horn sounded to call warriors to battle. A symbol of vigilance, wariness, and readiness — a call to action and a readiness to serve voluntarily."
  },
  {
    id: "osram_ne_nsoromma",
    name: "Osram ne Nsoromma",
    literalTranslation: "The moon and the star",
    coreValue: "Love, Faithfulness & Harmony",
    symbolDescription: "The moon and the evening star. A symbol of love, faithfulness, fondness, harmony, and benevolence — depicting the bond between two devoted souls, as the star awaits the rising of the moon."
  },
  {
    id: "nkonsonkonson",
    name: "Nkonsonkonson",
    literalTranslation: "Chain link",
    coreValue: "Unity & Human Relations",
    symbolDescription: "A chain of links. A symbol of unity, brotherhood, and cooperation, reminding us that we are linked in both life and death. 'We are linked together like a chain; in unity lies our strength.'"
  },
  {
    id: "hye_wo_nhye",
    name: "Hye Wo Nhye",
    literalTranslation: "That which does not burn",
    coreValue: "Imperishability & Endurance",
    symbolDescription: "Literally 'burn you do not burn.' A symbol of imperishability, endurance, and permanence — inspired by priests who walked on fire unharmed. It encourages steadfastness in the face of hardship."
  },
  {
    id: "mpatapo",
    name: "Mpatapo",
    literalTranslation: "Knot of reconciliation",
    coreValue: "Peace & Reconciliation",
    symbolDescription: "The 'pacification' or reconciliation knot. A symbol of peacemaking after strife, binding parties together in renewed bonds of harmony, forgiveness, and reconciliation."
  },
  {
    id: "owuo_atwedee",
    name: "Owuo Atwedee",
    literalTranslation: "The ladder of death",
    coreValue: "Mortality & The Human Condition",
    symbolDescription: "The ladder of death, which all must climb. A symbol of mortality, reminding everyone that death is the common destiny of all: 'Owuo atwedee baako mforo,' meaning all people will climb the ladder of death."
  },
  {
    id: "aban",
    name: "Aban",
    literalTranslation: "Fortress / castle",
    coreValue: "Strength, Authority & Security",
    symbolDescription: "A fortress or castle. A symbol of strength, safety, and the seat of power, authority, and magnificence. It represents the security and permanence of a well-protected society."
  },
  {
    id: "mframadan",
    name: "Mframadan",
    literalTranslation: "Wind-resistant house",
    coreValue: "Resilience & Preparedness",
    symbolDescription: "A well-ventilated, sturdily built house. A symbol of resilience and readiness to withstand the storms and vicissitudes of life — preparedness against forces one cannot control."
  },
  {
    id: "duafe",
    name: "Duafe",
    literalTranslation: "Wooden comb",
    coreValue: "Feminine Virtue & Care",
    symbolDescription: "A wooden comb used to groom and beautify the hair. A symbol of good feminine qualities such as patience, prudence, fondness, love, and care, and of feminine consideration and tenderness."
  },
  {
    id: "denkyem",
    name: "Denkyem",
    literalTranslation: "Crocodile",
    coreValue: "Adaptability & Cleverness",
    symbolDescription: "The crocodile, which lives in water yet breathes air. A symbol of adaptability and cleverness — the wisdom to thrive in changing and challenging environments by adjusting one's approach."
  },
  {
    id: "akoma_ntoaso",
    name: "Akoma Ntoaso",
    literalTranslation: "Linked hearts",
    coreValue: "Agreement, Unity & Charter",
    symbolDescription: "Joined or linked hearts, an extension of the Akoma symbol. A symbol of understanding, agreement, togetherness, and unity — a charter binding people to a common purpose and shared commitment."
  },
  {
    id: "odo_nnyew_fie_kwan",
    name: "Odo Nnyew Fie Kwan",
    literalTranslation: "Love never loses its way home",
    coreValue: "Power of Love",
    symbolDescription: "Love does not lose its way home. A symbol of the enduring power of love and devotion — those led by love always find their way to the right place."
  },
  {
    id: "nea_onnim",
    name: "Nea Onnim",
    literalTranslation: "He who does not know can know",
    coreValue: "Knowledge & Lifelong Learning",
    symbolDescription: "From the proverb, 'He who does not know can come to know from learning.' A symbol of knowledge, lifelong education, and the continued quest for understanding."
  },
  {
    id: "nsoromma",
    name: "Nsoromma",
    literalTranslation: "Star, child of the heavens",
    coreValue: "Faith & Reliance on God",
    symbolDescription: "The star, literally 'child of the heavens.' A symbol of faith and the belief in the patronage, guardianship, and benevolence of a supreme being."
  },
  {
    id: "abe_dua",
    name: "Abe Dua",
    literalTranslation: "Palm tree",
    coreValue: "Wealth & Self-Sufficiency",
    symbolDescription: "The palm tree, which provides many resources. A symbol of wealth, resourcefulness, self-sufficiency, and vitality."
  },
  {
    id: "adwo",
    name: "Adwo",
    literalTranslation: "Calmness",
    coreValue: "Peace & Tranquility",
    symbolDescription: "A symbol for calmness, peace, tranquility, and quiet — the serenity that comes from a settled and harmonious spirit."
  },
  {
    id: "agyin_dawuru",
    name: "Agyin Dawuru",
    literalTranslation: "Agyin's gong",
    coreValue: "Faithfulness & Dutifulness",
    symbolDescription: "Agyin's gong. A symbol of faithfulness, alertness, and dutifulness, designed to commemorate the loyalty of Agyin, a dutiful servant and gong-beater of the Asantehene."
  },
  {
    id: "akoko_nan",
    name: "Akoko Nan",
    literalTranslation: "The foot of a hen",
    coreValue: "Discipline with Mercy",
    symbolDescription: "The foot of a hen. A symbol of discipline coupled with care and nurturing, from the proverb 'the hen treads on her chicks but does not kill them' — firm yet loving guidance."
  },
  {
    id: "ananse_ntentan",
    name: "Ananse Ntentan",
    literalTranslation: "Spider's web",
    coreValue: "Wisdom & Creativity",
    symbolDescription: "The web of Ananse, the crafty spider of African folklore. A symbol of wisdom, craftiness, creativity, and the complexities of life."
  },
  {
    id: "ani_bere_a_enso_gya",
    name: "Ani Bere A Enso Gya",
    literalTranslation: "Serious eyes do not spark fire",
    coreValue: "Patience & Self-Control",
    symbolDescription: "No matter how serious (red-eyed) one becomes, the eyes do not spark flames. A symbol of patience, self-containment, self-discipline, and self-control."
  },
  {
    id: "asase_ye_duru",
    name: "Asase Ye Duru",
    literalTranslation: "The earth has weight",
    coreValue: "Providence & Divinity of Earth",
    symbolDescription: "The earth has weight. A symbol of providence and the divinity of Mother Earth, honoring the importance of the land in sustaining life."
  },
  {
    id: "bese_saka",
    name: "Bese Saka",
    literalTranslation: "Bunch of cola nuts",
    coreValue: "Affluence, Abundance & Unity",
    symbolDescription: "A bunch of cola nuts, an important cash crop. A symbol of affluence, power, abundance, plenty, and togetherness."
  },
  {
    id: "bi_nka_bi",
    name: "Bi Nka Bi",
    literalTranslation: "Bite not one another",
    coreValue: "Peace & Harmony",
    symbolDescription: "No one should bite another. A symbol of peace, harmony, and the avoidance of strife, conflict, and provocation within the community."
  },
  {
    id: "dame_dame",
    name: "Dame Dame",
    literalTranslation: "Checkers / draughts",
    coreValue: "Intelligence & Strategy",
    symbolDescription: "The board game of checkers (draughts). A symbol of craftiness, intelligence, and strategy."
  },
  {
    id: "dono_ntoaso",
    name: "Dono Ntoaso",
    literalTranslation: "Double talking drum",
    coreValue: "United Action & Goodwill",
    symbolDescription: "The joined double dono (talking drum). A symbol of united action, alertness, goodwill, praise, and rejoicing."
  },
  {
    id: "dono",
    name: "Dono",
    literalTranslation: "Talking drum",
    coreValue: "Praise, Goodwill & Rhythm",
    symbolDescription: "The tension talking drum used to send messages and praise. A symbol of appellation, praise, goodwill, and rhythm."
  },
  {
    id: "eban",
    name: "Eban",
    literalTranslation: "Fence",
    coreValue: "Safety, Security & Love",
    symbolDescription: "A fence. A symbol of safety, security, and love — the protective enclosure of a loving home that shields and nurtures those within."
  },
  {
    id: "ese_ne_tekrema",
    name: "Ese ne Tekrema",
    literalTranslation: "Teeth and tongue",
    coreValue: "Friendship & Interdependence",
    symbolDescription: "The teeth and the tongue, which play interdependent roles in the mouth. A symbol of friendship, interdependence, growth, and the need to resolve conflict."
  },
  {
    id: "fafanto",
    name: "Fafanto",
    literalTranslation: "Butterfly",
    coreValue: "Tenderness & Gentleness",
    symbolDescription: "The butterfly. A symbol of tenderness, gentleness, honesty, and fragility — and of transformation and new life."
  },
  {
    id: "fofo",
    name: "Fofo",
    literalTranslation: "Yellow-flowered plant",
    coreValue: "Warning Against Jealousy",
    symbolDescription: "The fofo, a plant whose seeds scatter in the wind. A symbol of warning against jealousy, envy, and covetousness."
  },
  {
    id: "gyawu_atiko",
    name: "Gyawu Atiko",
    literalTranslation: "Back of Gyawu's head",
    coreValue: "Valor & Bravery",
    symbolDescription: "The shaved hairstyle worn at the back of war-captain Gyawu's head. A symbol of valor and bravery."
  },
  {
    id: "hwehwemudua",
    name: "Hwehwemudua",
    literalTranslation: "Measuring rod",
    coreValue: "Excellence & Quality Control",
    symbolDescription: "The measuring rod or rule. A symbol of excellence, superior quality, perfection, knowledge, and critical examination."
  },
  {
    id: "kramo_bone",
    name: "Kramo Bone",
    literalTranslation: "The bad makes the good unseen",
    coreValue: "Warning Against Hypocrisy",
    symbolDescription: "The bad one makes it hard to recognize the good. A symbol warning against deception and hypocrisy, since the dishonest obscure the honest."
  },
  {
    id: "kuronti_ne_akwamu",
    name: "Kuronti ne Akwamu",
    literalTranslation: "Two state councils",
    coreValue: "Democracy & Shared Counsel",
    symbolDescription: "The Kuronti and Akwamu chiefs who share governance. A symbol of democracy, the sharing of ideas, and taking counsel together."
  },
  {
    id: "kwatakye_atiko",
    name: "Kwatakye Atiko",
    literalTranslation: "Back of Kwatakye's head",
    coreValue: "Valor & Bravery",
    symbolDescription: "The hairstyle of Kwatakye, a war captain of old Asante. A symbol of valor, bravery, and fearlessness."
  },
  {
    id: "mako",
    name: "Mako",
    literalTranslation: "Peppers",
    coreValue: "Equality & Patience",
    symbolDescription: "From the proverb 'all peppers on the same plant do not ripen at once.' A symbol of inequality, uneven development, and the patience that uneven progress requires."
  },
  {
    id: "menso_wo_kenten",
    name: "Menso Wo Kenten",
    literalTranslation: "I carry not your basket",
    coreValue: "Self-Reliance",
    symbolDescription: "I am not carrying your basket. A symbol of industry, self-reliance, and economic self-determination."
  },
  {
    id: "mmere_dane",
    name: "Mmere Dane",
    literalTranslation: "Time changes",
    coreValue: "Change & Impermanence",
    symbolDescription: "Times change. A symbol of the dynamism of life and the temporariness of good (and bad) times — fortunes turn, so remain humble and hopeful."
  },
  {
    id: "mpuannum",
    name: "Mpuannum",
    literalTranslation: "Five tufts of hair",
    coreValue: "Loyalty & Priestly Office",
    symbolDescription: "Five tufts of hair, a traditional hairstyle. A symbol of loyalty, adroitness, and priestly office."
  },
  {
    id: "nsaa",
    name: "Nsaa",
    literalTranslation: "Hand-woven blanket",
    coreValue: "Excellence & Authenticity",
    symbolDescription: "A type of finely woven cloth renowned for its quality. A symbol of excellence, genuineness, and authenticity — discerning the real from the counterfeit."
  },
  {
    id: "nteasee",
    name: "Nteasee",
    literalTranslation: "Understanding",
    coreValue: "Understanding & Cooperation",
    symbolDescription: "Understanding. A symbol of understanding, agreement, and cooperation between people who reach common ground."
  },
  {
    id: "nyame_biribi_wo_soro",
    name: "Nyame Biribi Wo Soro",
    literalTranslation: "God is in the heavens",
    coreValue: "Hope & Inspiration",
    symbolDescription: "From the saying 'God, there is something in the heavens; let it reach me.' A symbol of hope, aspiration, and inspiration."
  },
  {
    id: "nyame_nwu_na_mawu",
    name: "Nyame Nwu Na Mawu",
    literalTranslation: "God never dies",
    coreValue: "Immortality of the Soul",
    symbolDescription: "God will not die for me to die. A symbol expressing the immortality of the human soul and the eternal nature of God."
  },
  {
    id: "okuafo_pa",
    name: "Okuafo Pa",
    literalTranslation: "The good farmer",
    coreValue: "Diligence & Hard Work",
    symbolDescription: "The good farmer. A symbol of diligence, hard work, and entrepreneurship — the industrious cultivator who reaps a bountiful harvest."
  },
  {
    id: "sepow",
    name: "Sepow",
    literalTranslation: "Executioner's knife",
    coreValue: "Justice",
    symbolDescription: "The knife once used by the executioner. A symbol of justice and the gravity of judicial authority."
  },
  {
    id: "tamfo_bebre",
    name: "Tamfo Bebre",
    literalTranslation: "The enemy will stew",
    coreValue: "Resilience Against Envy",
    symbolDescription: "The enemy will stew in his own juice. A symbol concerning ill-will, jealousy, and envy — and the resilience to rise above the spite of others."
  },
  {
    id: "uac_nkanea",
    name: "UAC Nkanea",
    literalTranslation: "UAC lights",
    coreValue: "Technological Advancement",
    symbolDescription: "The street lights once installed by the United Africa Company. A symbol of technological advancement, modernity, and progress."
  },
  {
    id: "wawa_aba",
    name: "Wawa Aba",
    literalTranslation: "Seed of the wawa tree",
    coreValue: "Hardiness & Perseverance",
    symbolDescription: "The seed of the wawa tree, which is extremely hard. A symbol of hardiness, toughness, perseverance, and resilience in the face of adversity."
  },
  {
    id: "woforo_dua_pa",
    name: "Woforo Dua Pa A",
    literalTranslation: "When you climb a good tree",
    coreValue: "Support for Good Causes",
    symbolDescription: "When you climb a good tree, you are given a push. A symbol of support, cooperation, and encouragement for those who pursue worthy goals."
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
