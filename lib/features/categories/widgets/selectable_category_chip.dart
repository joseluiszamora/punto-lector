import 'package:flutter/material.dart';
import 'package:puntolector/data/models/category.dart';

class SelectableCategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;

  const SelectableCategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color:
            isSelected
                ? _getCategoryColor()
                : _getCategoryColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getCategoryColor(),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(),
            size: 16,
            color: isSelected ? Colors.white : _getCategoryColor(),
          ),
          const SizedBox(width: 6),
          Text(
            category.name,
            style: TextStyle(
              color: isSelected ? Colors.white : _getCategoryColor(),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor() {
    if (category.color?.isNotEmpty == true) {
      try {
        // Convertir color hex a Color
        String colorString = category.color!.replaceAll('#', '');
        if (colorString.length == 6) {
          colorString = 'FF$colorString'; // Agregar alpha
        }
        return Color(int.parse(colorString, radix: 16));
      } catch (_) {
        // Si falla la conversión, usar color por defecto
      }
    }
    // Colores por defecto basados en el índice del nombre
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.red,
      Colors.amber,
    ];
    return colors[category.name.hashCode % colors.length];
  }

  IconData _getCategoryIcon() {
    // Iconos básicos basados en palabras clave comunes en nombres de categorías
    final name = category.name.toLowerCase();
    if (name.contains('historia') || name.contains('históric')) {
      return Icons.history_edu;
    } else if (name.contains('ciencia') || name.contains('científic')) {
      return Icons.science;
    } else if (name.contains('arte') || name.contains('cultura')) {
      return Icons.palette;
    } else if (name.contains('educación') || name.contains('educativ')) {
      return Icons.school;
    } else if (name.contains('ficción') || name.contains('novela')) {
      return Icons.auto_stories;
    } else if (name.contains('biografía') || name.contains('biografic')) {
      return Icons.person;
    } else if (name.contains('cocina') || name.contains('receta')) {
      return Icons.restaurant;
    } else if (name.contains('salud') || name.contains('medicina')) {
      return Icons.favorite;
    } else if (name.contains('tecnología') || name.contains('técnic')) {
      return Icons.computer;
    } else if (name.contains('religion') || name.contains('espiritual')) {
      return Icons.auto_awesome;
    }
    return Icons.category;
  }
}
