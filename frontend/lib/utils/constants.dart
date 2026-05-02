// lib/utils/constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  static const String baseUrl = 'http://192.168.1.4:5000';

  static const Map<String, CharacterInfo> characters = {
    'king': CharacterInfo(
      id: 'king',
      // FIX: correct king name
      name: 'Sri Vikrama Rajasinha',
      title: 'Last King of Kandy (1798–1815)',
      emoji: '👑',
      color: Color(0xFFFFB300),    // amber gold
      accentColor: Color(0xFFFFF9C4), // light yellow
    ),
    'citizen': CharacterInfo(
      id: 'citizen',
      name: 'Citizen',
      title: 'Local Resident',
      emoji: '👤',
      color: Color(0xFF1565C0),    // deep blue
      accentColor: Color(0xFFE3F2FD), // light blue
    ),
    'dutch': CharacterInfo(
      id: 'dutch',
      name: 'Dutch Merchant',
      title: 'Colonial Era Trader',
      emoji: '⚓',
      color: Color(0xFF0288D1),    // light blue
      accentColor: Color(0xFFB3E5FC),
    ),
    'nilame': CharacterInfo(
      id: 'nilame',
      name: 'Kandyan Nilame',
      title: 'Royal Court Official',
      emoji: '🦚',
      color: Color(0xFF6A1B9A),    // purple
      accentColor: Color(0xFFE1BEE7),
    ),
  };

  static const List<String> expertiseLevels = [
    'child',
    'student',
    'tourist',
    'researcher',
  ];

  static const Map<String, String> expertiseDescriptions = {
    'child':      'Simple words, short sentences (Age 6–12)',
    'student':    'Educational, cause-effect (Age 13–22)',
    'tourist':    'Vivid, sensory & practical tips',
    'researcher': 'Academic precision & full detail',
  };

  static const Map<String, String> expertiseIcons = {
    'child':      '🧒',
    'student':    '🎓',
    'tourist':    '🧳',
    'researcher': '🔬',
  };
}

class CharacterInfo {
  final String id;
  final String name;
  final String title;
  final String emoji;
  final Color color;
  final Color accentColor;

  const CharacterInfo({
    required this.id,
    required this.name,
    required this.title,
    required this.emoji,
    required this.color,
    required this.accentColor,
  });
}