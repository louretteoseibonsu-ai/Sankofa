import 'package:flutter/material.dart';

/// A cultural landmark shown as a point of interest on the world map. Art lands
/// later; the info sheet renders a sculpted placeholder from [accent] until then.
@immutable
class Landmark {
  final String id;
  final String name;
  final String region; // short locator, e.g. "Central Region"
  final Offset coordinates; // normalised 0..1 position on the map canvas
  final String descriptionText;
  final String imageAsset; // art TBD
  final bool isUnlocked;
  final Color accent;

  const Landmark({
    required this.id,
    required this.name,
    required this.region,
    required this.coordinates,
    required this.descriptionText,
    required this.imageAsset,
    required this.accent,
    this.isUnlocked = false,
  });
}

/// Mock repository of iconic Ghanaian landmarks.
const List<Landmark> kLandmarks = [
  Landmark(
    id: 'kakum',
    name: 'Kakum Canopy Walk',
    region: 'Central Region',
    coordinates: Offset(0.50, 0.12),
    imageAsset: 'assets/landmarks/kakum.png',
    accent: Color(0xFF2E9E5B),
    isUnlocked: true,
    descriptionText:
        'Deep in the Central Region rainforest, Kakum National Park’s canopy '
        'walkway sways some 40 metres above the forest floor — seven rope '
        'bridges strung between giant emergent trees, alive with birdsong, '
        'butterflies and the occasional glimpse of forest elephants below.',
  ),
  Landmark(
    id: 'coco',
    name: 'Coco Beach',
    region: 'Nungua, Accra',
    coordinates: Offset(0.72, 0.52),
    imageAsset: 'assets/landmarks/coco.png',
    accent: Color(0xFFD4A373),
    isUnlocked: false,
    descriptionText:
        'A golden stretch of Accra coastline where palm shade meets calm '
        'Atlantic waves — a laid-back spot for grilled tilapia, cold '
        'sobolo and an unhurried sunset over the Gulf of Guinea.',
  ),
  Landmark(
    id: 'elmina',
    name: 'Elmina Castle',
    region: 'Central Region',
    coordinates: Offset(0.60, 0.88),
    imageAsset: 'assets/landmarks/elmina.png',
    accent: Color(0xFFB6BAC0),
    isUnlocked: false,
    descriptionText:
        'Built by the Portuguese in 1482 on the Gulf of Guinea, Elmina Castle '
        'is among the oldest European structures in sub-Saharan Africa. A '
        'UNESCO World Heritage Site, its white walls hold a solemn history as a '
        'hub of the transatlantic slave trade — a place of remembrance, '
        'reflection and return.',
  ),
];
