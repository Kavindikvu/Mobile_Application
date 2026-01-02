import 'package:flutter/material.dart';

/// Identifiers used for pre-built avatar references, stored as `avatar://{id}`.
const String kAvatarScheme = 'avatar://';

/// A catalog entry describing a colourful, icon-based avatar.
class AvatarOption {
  const AvatarOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.gradient,
    required this.iconColor,
    this.accentColor,
  });

  final String id;
  final String label;
  final IconData icon;
  final Gradient gradient;
  final Color iconColor;
  final Color? accentColor;
}

/// Centralised avatar catalog used across the kid profile experience.
class AvatarCatalog {
  static final List<AvatarOption> studentAvatars = [
    AvatarOption(
      id: 'stellar-otter',
      label: 'Stellar Otter',
      icon: Icons.water_rounded,
      gradient: const LinearGradient(
        colors: [
          Color(0xFF4F9CFF),
          Color(0xFF4364F7),
        ],
      ),
      iconColor: Colors.white,
    ),
    AvatarOption(
      id: 'rocket-fox',
      label: 'Rocket Fox',
      icon: Icons.rocket_launch_outlined,
      gradient: const LinearGradient(
        colors: [
          Color(0xFFFF7A7A),
          Color(0xFFFF3D68),
        ],
      ),
      iconColor: Colors.white,
    ),
    AvatarOption(
      id: 'joyful-koala',
      label: 'Joyful Koala',
      icon: Icons.emoji_nature_outlined,
      gradient: const LinearGradient(
        colors: [
          Color(0xFF6FE3A6),
          Color(0xFF2BC0E4),
        ],
      ),
      iconColor: Colors.white,
    ),
    AvatarOption(
      id: 'curious-owl',
      label: 'Curious Owl',
      icon: Icons.visibility_outlined,
      gradient: const LinearGradient(
        colors: [
          Color(0xFFFFC371),
          Color(0xFFFF5F6D),
        ],
      ),
      iconColor: Colors.white,
    ),
    AvatarOption(
      id: 'brave-lion',
      label: 'Brave Lion',
      icon: Icons.emoji_events_outlined,
      gradient: const LinearGradient(
        colors: [
          Color(0xFFFFA751),
          Color(0xFFFFD452),
        ],
      ),
      iconColor: Colors.white,
    ),
    AvatarOption(
      id: 'cosmic-whale',
      label: 'Cosmic Whale',
      icon: Icons.auto_awesome,
      gradient: const LinearGradient(
        colors: [
          Color(0xFF8360C3),
          Color(0xFF2EBF91),
        ],
      ),
      iconColor: Colors.white,
    ),
    AvatarOption(
      id: 'playful-panda',
      label: 'Playful Panda',
      icon: Icons.sports_martial_arts_outlined,
      gradient: const LinearGradient(
        colors: [
          Color(0xFFB24592),
          Color(0xFFF15F79),
        ],
      ),
      iconColor: Colors.white,
    ),
    AvatarOption(
      id: 'sky-dolphin',
      label: 'Sky Dolphin',
      icon: Icons.waves_outlined,
      gradient: const LinearGradient(
        colors: [
          Color(0xFF43C6AC),
          Color(0xFFF8FFAE),
        ],
      ),
      iconColor: Colors.white,
    ),
  ];

  static AvatarOption? resolveStudentAvatar(String? imageReference) {
    final id = _extractId(imageReference);
    if (id == null) return null;
    for (final option in studentAvatars) {
      if (option.id == id) {
        return option;
      }
    }
    return null;
  }

  static String? _extractId(String? imageReference) {
    if (imageReference == null) return null;
    if (!imageReference.startsWith(kAvatarScheme)) return null;
    return imageReference.replaceFirst(kAvatarScheme, '').trim();
  }
}

