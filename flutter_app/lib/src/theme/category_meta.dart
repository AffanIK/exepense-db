import 'package:flutter/material.dart';

class CategoryMeta {
  final String id;
  final String name;
  final Color color;
  final IconData icon;

  const CategoryMeta({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });
}

// Category palette — tuned to sit harmoniously on Slip's cream background
// while keeping the Teal/Butter/Pine brand identity in mind. Warmer hues
// across the row so no single category overpowers the brand colors.
const kCategories = <CategoryMeta>[
  CategoryMeta(
    id: 'food',
    name: 'Food',
    color: Color(0xFFC24B3F), // warm coral
    icon: Icons.local_cafe_outlined,
  ),
  CategoryMeta(
    id: 'shopping',
    name: 'Shopping',
    color: Color(0xFFE0A23A), // butter-amber
    icon: Icons.shopping_bag_outlined,
  ),
  CategoryMeta(
    id: 'transport',
    name: 'Transport',
    color: Color(0xFF3D7E8A), // slate-teal
    icon: Icons.directions_car_outlined,
  ),
  CategoryMeta(
    id: 'bills',
    name: 'Bills',
    color: Color(0xFFB04A6A), // muted rose
    icon: Icons.bolt_outlined,
  ),
  CategoryMeta(
    id: 'leisure',
    name: 'Leisure',
    color: Color(0xFF0F8F87), // teal (Slip primary)
    icon: Icons.music_note_outlined,
  ),
  CategoryMeta(
    id: 'health',
    name: 'Health',
    color: Color(0xFF6E8F3F), // sage / olive
    icon: Icons.favorite_outline,
  ),
  CategoryMeta(
    id: 'other',
    name: 'Other',
    color: Color(0xFF5A6A6E), // ink-slate
    icon: Icons.auto_awesome_outlined,
  ),
];

const _other = CategoryMeta(
  id: 'other',
  name: 'Other',
  color: Color(0xFF5A6A6E),
  icon: Icons.auto_awesome_outlined,
);

final Map<String, CategoryMeta> _byId = {
  for (final c in kCategories) c.id: c,
};

/// Maps any incoming category string (legacy title-case names or new ids)
/// to a canonical [CategoryMeta]. Falls back to "Other".
CategoryMeta metaFor(String raw) {
  final key = raw.trim().toLowerCase();
  if (_byId.containsKey(key)) return _byId[key]!;
  switch (key) {
    case 'housing':
      return _byId['bills']!;
    case 'entertainment':
      return _byId['leisure']!;
    case 'food':
    case 'shopping':
    case 'transport':
    case 'bills':
    case 'leisure':
    case 'health':
      return _byId[key]!;
  }
  return _other;
}

/// Canonical id (e.g. "food") for any legacy or new category string.
String normalizeCategory(String raw) => metaFor(raw).id;
