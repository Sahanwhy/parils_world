import 'package:flutter/material.dart';

/// Data model for a photo memory in the Photo Dump.
class PhotoMemory {
  const PhotoMemory({
    required this.id,
    required this.assetPath,
    required this.title,
    required this.caption,
    this.isFavorite = false,
    this.favoriteNote,
    required this.tag,
    this.rotationAngle = 0.0,
    this.alignment = Alignment.center,
  });

  final String id;
  final String assetPath;
  final String title;
  final String caption;
  final bool isFavorite;
  final String? favoriteNote;
  final String tag;
  final double rotationAngle;
  final Alignment alignment;

  /// Complete list of Childhood memories using all 14 images provided.
  /// 6(fav).jpeg is marked as the featured favorite loved by Sahan!
  static const List<PhotoMemory> childhoodMemories = [
    PhotoMemory(
      id: 'childhood_6_fav',
      assetPath: 'assets/images/6(fav).jpeg',
      title: 'Baby Paril — Pure Magic ✨',
      caption: 'The most precious smile in the entire universe. Sahan\'s absolute favorite photo in the world.',
      isFavorite: true,
      favoriteNote: 'Sahan loves this one the most 💖 The cutest angel ever!',
      tag: 'Sahan\'s Favorite 👑',
      rotationAngle: 0.0,
    ),
    PhotoMemory(
      id: 'childhood_1',
      assetPath: 'assets/images/1.jpeg',
      title: 'Little Sunshine ☀️',
      caption: 'Curious eyes taking in the big wide world with pure wonder.',
      tag: 'Baby Days',
      rotationAngle: -0.02,
      alignment: Alignment.topCenter,
    ),
    PhotoMemory(
      id: 'childhood_2',
      assetPath: 'assets/images/2.jpeg',
      title: 'Sweet Innocence 🌸',
      caption: 'Quiet gentle moments of baby childhood bliss.',
      tag: 'Memories',
      rotationAngle: 0.02,
    ),
    PhotoMemory(
      id: 'childhood_3',
      assetPath: 'assets/images/3.jpeg',
      title: 'Cute Cheeks 🧸',
      caption: 'Those adorable chubby cheeks that everyone wanted to pinch!',
      tag: 'Chubby Cheeks',
      rotationAngle: -0.015,
    ),
    PhotoMemory(
      id: 'childhood_4',
      assetPath: 'assets/images/5.jpeg',
      title: 'Little Princess 👑',
      caption: 'Royal elegance and charm from the very first day.',
      tag: 'Princess',
      rotationAngle: 0.025,
    ),
    PhotoMemory(
      id: 'childhood_5',
      assetPath: 'assets/images/4.jpeg',
      title: 'Joyful Giggles ✨',
      caption: 'Unfiltered, pure happiness that lights up every single heart.',
      tag: 'Pure Joy',
      rotationAngle: -0.02,
    ),
    PhotoMemory(
      id: 'childhood_7',
      assetPath: 'assets/images/7.jpeg',
      title: 'Sweet Angel 👼',
      caption: 'A little soul full of warmth, gentleness, and grace.',
      tag: 'Angel',
      rotationAngle: 0.015,
      alignment: Alignment.topCenter,
    ),
    PhotoMemory(
      id: 'childhood_8',
      assetPath: 'assets/images/8.jpeg',
      title: 'Playtime Magic 🎨',
      caption: 'Making every single ordinary day an enchanting adventure.',
      tag: 'Playtime',
      rotationAngle: -0.025,
    ),
    PhotoMemory(
      id: 'childhood_9',
      assetPath: 'assets/images/9.jpeg',
      title: 'Heart of Gold 💛',
      caption: 'Always looking out with the kindest, gentlest gaze.',
      tag: 'Gentle Soul',
      rotationAngle: 0.02,
    ),
    PhotoMemory(
      id: 'childhood_10',
      assetPath: 'assets/images/10.jpeg',
      title: 'Little Dreamer 🌙',
      caption: 'Dreaming big dreams under warm starry childhood skies.',
      tag: 'Dreamer',
      rotationAngle: -0.015,
    ),
    PhotoMemory(
      id: 'childhood_11',
      assetPath: 'assets/images/11.jpeg',
      title: 'Irresistible Charm 🥺',
      caption: 'Nobody in the world could ever say no to that cute little face.',
      tag: 'Cuteness 100%',
      rotationAngle: 0.02,
    ),
    PhotoMemory(
      id: 'childhood_12',
      assetPath: 'assets/images/13.jpeg',
      title: 'Candid Perfection 📸',
      caption: 'Caught in a genuine, beautiful, spontaneous childhood instant.',
      tag: 'Candid',
      rotationAngle: -0.02,
    ),
    PhotoMemory(
      id: 'childhood_13',
      assetPath: 'assets/images/12.jpeg',
      title: 'Radiant Smile 💕',
      caption: 'A smile that could brighten even the gloomiest of days.',
      tag: 'Radiant',
      rotationAngle: 0.015,
    ),
    PhotoMemory(
      id: 'childhood_14',
      assetPath: 'assets/images/14.jpeg',
      title: 'Forever Cherished 🎀',
      caption: 'A little piece of heaven on earth, blessed and loved forever.',
      tag: 'Precious',
      rotationAngle: -0.015,
    ),
  ];

  /// Complete list of Teenage memories — 17 images from assets/images/teenage/
  /// 14(fav).jpg is Sahan's absolute favourite teenage photo.
  static const List<PhotoMemory> teenageMemories = [
    PhotoMemory(
      id: 'teenage_14_fav',
      assetPath: 'assets/images/teenage/14(fav).jpg',
      title: 'Glowing Teen ✨',
      caption: 'The photo that stopped Sahan\'s heart — radiant, effortless, and absolutely stunning.',
      isFavorite: true,
      favoriteNote: 'Sahan\'s favourite teenage photo 💖 She looks like a dream here!',
      tag: 'Sahan\'s Favourite 👑',
      rotationAngle: 0.0,
      alignment: Alignment.topCenter,
    ),
    PhotoMemory(
      id: 'teenage_1',
      assetPath: 'assets/images/teenage/1.jpeg',
      title: 'Growing Up 🌱',
      caption: 'The world started making sense when you began blooming into yourself.',
      tag: 'Glow Up',
      rotationAngle: -0.02,
    ),
    PhotoMemory(
      id: 'teenage_2',
      assetPath: 'assets/images/teenage/2.jpeg',
      title: 'That Teen Smile 😊',
      caption: 'Brighter than any hallway light, louder than any school bell.',
      tag: 'Sunshine',
      rotationAngle: 0.025,
    ),
    PhotoMemory(
      id: 'teenage_3',
      assetPath: 'assets/images/teenage/3.jpeg',
      title: 'Fierce & Free 🔥',
      caption: 'Already knowing who she is and not apologising for a second of it.',
      tag: 'Fierce',
      rotationAngle: -0.015,
    ),
    PhotoMemory(
      id: 'teenage_4',
      assetPath: 'assets/images/teenage/4.jpeg',
      title: 'Main Character 🎬',
      caption: 'Every scene you walked into became the best part of the story.',
      tag: 'Main Character',
      rotationAngle: 0.02,
    ),
    PhotoMemory(
      id: 'teenage_5',
      assetPath: 'assets/images/teenage/5.jpeg',
      title: 'Effortless Cool 😎',
      caption: 'Zero effort, maximum impact — that\'s just how she moved through the world.',
      tag: 'Cool Vibes',
      rotationAngle: -0.025,
    ),
    PhotoMemory(
      id: 'teenage_6',
      assetPath: 'assets/images/teenage/6.jpeg',
      title: 'Soft & Strong 🌸',
      caption: 'Delicate on the outside, completely unshakeable on the inside.',
      tag: 'Soft Power',
      rotationAngle: 0.015,
    ),
    PhotoMemory(
      id: 'teenage_7',
      assetPath: 'assets/images/teenage/7.jpeg',
      title: 'Radiant Charm 🌸',
      caption: 'Pure warmth and grace captured in a gentle teenage moment.',
      tag: 'Radiant',
      rotationAngle: 0.015,
    ),
    PhotoMemory(
      id: 'teenage_8',
      assetPath: 'assets/images/teenage/8.jpeg',
      title: 'Pure Joy 🎉',
      caption: 'Laughing so hard the whole room felt it — that\'s her superpower.',
      tag: 'Joy',
      rotationAngle: -0.02,
    ),
    PhotoMemory(
      id: 'teenage_9',
      assetPath: 'assets/images/teenage/9.jpeg',
      title: 'Golden Hour Girl 🌅',
      caption: 'She glows even without the sun — but with it? Absolutely ethereal.',
      tag: 'Golden',
      rotationAngle: 0.02,
    ),
    PhotoMemory(
      id: 'teenage_10',
      assetPath: 'assets/images/teenage/10.jpeg',
      title: 'Quiet Rebel 🎸',
      caption: 'Breaking every rule just by existing so unapologetically.',
      tag: 'Rebel',
      rotationAngle: -0.015,
    ),
    PhotoMemory(
      id: 'teenage_11',
      assetPath: 'assets/images/teenage/11.jpeg',
      title: 'Dream Chaser 🌙',
      caption: 'Eyes already set on a horizon bigger than anyone around her could see.',
      tag: 'Dreamer',
      rotationAngle: 0.025,
    ),
    PhotoMemory(
      id: 'teenage_12',
      assetPath: 'assets/images/teenage/12.jpeg',
      title: 'Unstoppable 💪',
      caption: 'She decided to be the woman she always admired — and then became her.',
      tag: 'Power',
      rotationAngle: -0.02,
    ),
    PhotoMemory(
      id: 'teenage_13',
      assetPath: 'assets/images/teenage/13.jpeg',
      title: 'Forever Young 🎀',
      caption: 'This version of her — free, curious, and electric — lives forever in these frames.',
      tag: 'Forever',
      rotationAngle: 0.015,
    ),
    PhotoMemory(
      id: 'teenage_15',
      assetPath: 'assets/images/teenage/15.jpg',
      title: 'Golden Spark 🌟',
      caption: 'Cherished memories carrying the spark of growing up.',
      tag: 'Cherished',
      rotationAngle: -0.02,
    ),
    PhotoMemory(
      id: 'teenage_16',
      assetPath: 'assets/images/teenage/16.jpg',
      title: 'Timeless Beauty 🕊️',
      caption: 'A quiet, timeless moment of elegance and confidence.',
      tag: 'Timeless',
      rotationAngle: 0.02,
    ),
    PhotoMemory(
      id: 'teenage_17',
      assetPath: 'assets/images/teenage/17.jpg',
      title: 'Electric Spirit 💫',
      caption: 'Every memory adding another unforgettable chapter to the story.',
      tag: 'Electric',
      rotationAngle: -0.015,
    ),
  ];
}
