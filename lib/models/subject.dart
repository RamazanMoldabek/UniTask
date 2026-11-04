import 'package:flutter/material.dart';

class Subject {
  final int? id;
  final String title;
  final String colorHex;

  const Subject({
    this.id,
    required this.title,
    this.colorHex = '#4F46E5',
  });

  Color get color {
    final hexCode = colorHex.replaceAll('#', '');
    if (hexCode.length == 6) {
      return Color(int.parse('FF$hexCode', radix: 16));
    } else if (hexCode.length == 8) {
      return Color(int.parse(hexCode, radix: 16));
    }
    return const Color(0xFF4F46E5);
  }

  Subject copyWith({
    int? id,
    String? title,
    String? colorHex,
  }) {
    return Subject(
      id: id ?? this.id,
      title: title ?? this.title,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'color_hex': colorHex,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      colorHex: map['color_hex'] as String? ?? '#4F46E5',
    );
  }
}
