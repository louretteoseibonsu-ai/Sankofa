import 'landmark.dart';
import 'lesson_catalog.dart';

/// Region/Act → landmark mapping (by order). If [lesson] is the final milestone
/// (boss) of its Act, returns the landmark that Act unlocks — otherwise null.
/// Clearing an Act's boss triggers the checkpoint-travel cinematic to it.
Landmark? landmarkForActBoss(Lesson lesson) {
  for (var i = 0; i < kCategories.length; i++) {
    final c = kCategories[i];
    if (c.lessons.isNotEmpty && c.lessons.last.id == lesson.id) {
      return kLandmarks[i.clamp(0, kLandmarks.length - 1)];
    }
  }
  return null;
}

/// Journey progression state — the Flutter equivalent of the requested
/// JourneyState / ViewModel flag. Held by the map screen; when
/// [currentLandmarkIndex] advances, the map plays the checkpoint-travel
/// cinematic and flips [isTraveling] for its duration.
class JourneyState {
  final int currentLandmarkIndex;
  final bool isTraveling;

  const JourneyState({
    this.currentLandmarkIndex = 0,
    this.isTraveling = false,
  });

  Landmark get currentLandmark =>
      kLandmarks[currentLandmarkIndex.clamp(0, kLandmarks.length - 1)];

  bool get hasNext => currentLandmarkIndex < kLandmarks.length - 1;

  Landmark? get nextLandmark =>
      hasNext ? kLandmarks[currentLandmarkIndex + 1] : null;

  JourneyState copyWith({int? currentLandmarkIndex, bool? isTraveling}) =>
      JourneyState(
        currentLandmarkIndex: currentLandmarkIndex ?? this.currentLandmarkIndex,
        isTraveling: isTraveling ?? this.isTraveling,
      );
}
