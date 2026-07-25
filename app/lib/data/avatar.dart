import 'package:flutter/material.dart';

/// How an avatar is earned — structured so the lock state is evaluable, while
/// [Avatar.unlockCriteria] renders the human-readable requirement.
enum AvatarUnlock { free, level, streak, mastery }

/// A playable character avatar (the driver of the tro tro). Art lands later; the
/// UI renders a sculpted placeholder from [accent]/[initials] until then.
@immutable
class Avatar {
  final String id;
  final String name;
  final String assetReference; // e.g. assets/avatars/super_auntie.png (art TBD)
  final String title; // flavour subtitle
  final AvatarUnlock unlockKind;
  final int unlockValue; // threshold for the criterion
  final Color accent; // placeholder tint + selection accent

  const Avatar({
    required this.id,
    required this.name,
    required this.assetReference,
    required this.title,
    required this.accent,
    this.unlockKind = AvatarUnlock.free,
    this.unlockValue = 0,
  });

  /// Human-readable unlock requirement (the `unlockCriteria` field).
  String get unlockCriteria {
    switch (unlockKind) {
      case AvatarUnlock.free:
        return 'Starter';
      case AvatarUnlock.level:
        return 'Reach level $unlockValue';
      case AvatarUnlock.streak:
        return '$unlockValue-day streak';
      case AvatarUnlock.mastery:
        return 'Master $unlockValue lessons';
    }
  }

  /// Two-letter monogram for the placeholder badge (e.g. "SA").
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Whether the player's stats satisfy this avatar's unlock criterion.
  bool unlockedBy({required int level, required int streak, required int mastered}) {
    switch (unlockKind) {
      case AvatarUnlock.free:
        return true;
      case AvatarUnlock.level:
        return level >= unlockValue;
      case AvatarUnlock.streak:
        return streak >= unlockValue;
      case AvatarUnlock.mastery:
        return mastered >= unlockValue;
    }
  }
}

/// The four Super Family characters. Ids persist in cosmeticEquipped['avatar'].
const List<Avatar> kAvatars = [
  Avatar(
    id: 'auntie',
    name: 'Super Auntie',
    title: 'The Trendsetter',
    assetReference: 'assets/avatars/super_auntie.png',
    accent: Color(0xFFE2725B), // terracotta
    unlockKind: AvatarUnlock.free,
  ),
  Avatar(
    id: 'uncle',
    name: 'Super Uncle',
    title: 'The Cool Head',
    assetReference: 'assets/avatars/super_uncle.png',
    accent: Color(0xFF2E86C1), // blue
    unlockKind: AvatarUnlock.level,
    unlockValue: 5,
  ),
  Avatar(
    id: 'grandma',
    name: 'Super Grandma',
    title: 'The Wise One',
    assetReference: 'assets/avatars/super_grandma.png',
    accent: Color(0xFFD4A373), // ochre
    unlockKind: AvatarUnlock.streak,
    unlockValue: 7,
  ),
  Avatar(
    id: 'grandpa',
    name: 'Super Grandpa',
    title: 'The Storyteller',
    assetReference: 'assets/avatars/super_grandpa.png',
    accent: Color(0xFF2E9E5B), // green
    unlockKind: AvatarUnlock.mastery,
    unlockValue: 5,
  ),
];

/// The default avatar id (always unlocked).
const String kDefaultAvatarId = 'auntie';

Avatar avatarById(String? id) =>
    kAvatars.firstWhere((a) => a.id == id, orElse: () => kAvatars.first);
