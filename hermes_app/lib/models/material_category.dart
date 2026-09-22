import 'package:flutter/material.dart';

/// Representa uma categoria de estoque, ex: "T.I." ou "Mecânica".
class MaterialCategory {
  final String id;
  final String name;
  final String subtitle;
  final IconData icon;

  const MaterialCategory({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
  });
}
