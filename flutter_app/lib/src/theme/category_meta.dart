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

const kCategories = <CategoryMeta>[
  CategoryMeta(
    id: 'food',
    name: 'Food',
    color: Color(0xFF7C3AED),
    icon: Icons.local_cafe_outlined,
  ),
  CategoryMeta(
    id: 'shopping',
    name: 'Shopping',
    color: Color(0xFFF59E0B),
    icon: Icons.shopping_bag_outlined,
  ),
  CategoryMeta(
    id: 'transport',
    name: 'Transport',
    color: Color(0xFF06B6D4),
    icon: Icons.directions_car_outlined,
  ),
  CategoryMeta(
    id: 'bills',
    name: 'Bills',
    color: Color(0xFFEC4899),
    icon: Icons.bolt_outlined,
  ),
  CategoryMeta(
    id: 'leisure',
    name: 'Leisure',
    color: Color(0xFF10E0A0),
    icon: Icons.music_note_outlined,
  ),
  CategoryMeta(
    id: 'health',
    name: 'Health',
    color: Color(0xFFF43F5E),
    icon: Icons.favorite_outline,
  ),
  CategoryMeta(
    id: 'other',
    name: 'Other',
    color: Color(0xFFA78BFA),
    icon: Icons.auto_awesome_outlined,
  ),
];

const _other = CategoryMeta(
  id: 'other',
  name: 'Other',
  color: Color(0xFFA78BFA),
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
