import 'landmark.dart';

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
