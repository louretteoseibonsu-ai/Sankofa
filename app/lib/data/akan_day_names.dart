class AkanDayName {
  final int dayIndex; // 0 = Sunday ... 6 = Saturday
  final String dayTwi;
  final String maleName;
  final String femaleName;
  final String attribute;
  final String meaning;
  const AkanDayName({
    required this.dayIndex,
    required this.dayTwi,
    required this.maleName,
    required this.femaleName,
    required this.attribute,
    required this.meaning,
  });
}

/// English weekday names indexed by [AkanDayName.dayIndex] (0 = Sunday).
const List<String> kEnglishDays = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

const List<AkanDayName> kAkanDayNames = [
  AkanDayName(
    dayIndex: 0,
    dayTwi: 'Kwasiada',
    maleName: 'Kwasi',
    femaleName: 'Akosua',
    attribute: 'Bodua / Asiama',
    meaning: 'Spiritual, agile, natural leaders. Associated with the Universe and pure beginnings.',
  ),
  AkanDayName(
    dayIndex: 1,
    dayTwi: 'Dwowda',
    maleName: 'Kwadwo',
    femaleName: 'Adwoa',
    attribute: 'Okoto / Koto',
    meaning: 'Peaceful, calm, reflective, and diplomatic. Natural peacemakers.',
  ),
  AkanDayName(
    dayIndex: 2,
    dayTwi: 'Benada',
    maleName: 'Kwabena',
    femaleName: 'Abena',
    attribute: 'Ogyam / Obrempong',
    meaning: 'Warm-hearted, friendly, passionate, and protective. Full of active energy.',
  ),
  AkanDayName(
    dayIndex: 3,
    dayTwi: 'Wukuada',
    maleName: 'Kwaku',
    femaleName: 'Akua',
    attribute: 'Ntonni / Dausi',
    meaning: 'Intellectual, creative, communicative, and witty. Natural problem-solvers.',
  ),
  AkanDayName(
    dayIndex: 4,
    dayTwi: 'Yawoada',
    maleName: 'Yaw',
    femaleName: 'Yaa',
    attribute: 'Preko / Barko',
    meaning: 'Courageous, highly determined, assertive, and resilient under pressure.',
  ),
  AkanDayName(
    dayIndex: 5,
    dayTwi: 'Fiada',
    maleName: 'Kofi',
    femaleName: 'Afia',
    attribute: 'Okyere / Kyere',
    meaning: 'Generous, highly observant, creative, and very community-minded.',
  ),
  AkanDayName(
    dayIndex: 6,
    dayTwi: 'Memeneda',
    maleName: 'Kwame',
    femaleName: 'Ama',
    attribute: 'Atoapem / Oteanankannuro',
    meaning: 'Responsible, highly organized, deep-thinking, and historically minded. Wise advisors.',
  ),
];
