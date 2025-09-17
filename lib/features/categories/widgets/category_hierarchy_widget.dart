import 'package:flutter/material.dart';
import '../../../data/models/category.dart';

class CategoryHierarchyWidget extends StatefulWidget {
  final List<Category> categories;
  final Function(Category)? onCategorySelected;
  final bool showChildrenCount;
  final bool showBookCount;
  final bool expandable;

  const CategoryHierarchyWidget({
    super.key,
    required this.categories,
    this.onCategorySelected,
    this.showChildrenCount = true,
    this.showBookCount = true,
    this.expandable = true,
  });

  @override
  State<CategoryHierarchyWidget> createState() =>
      _CategoryHierarchyWidgetState();
}

class _CategoryHierarchyWidgetState extends State<CategoryHierarchyWidget> {
  final Set<String> _expandedCategories = {};

  @override
  Widget build(BuildContext context) {
    // Group categories by parent
    final mainCategories =
        widget.categories.where((c) => c.isMainCategory).toList();
    final subcategoriesMap = <String, List<Category>>{};

    for (final cat in widget.categories.where((c) => c.isSubcategory)) {
      if (cat.parentId != null) {
        subcategoriesMap.putIfAbsent(cat.parentId!, () => []).add(cat);
      }
    }

    return ListView.builder(
      itemCount: mainCategories.length,
      itemBuilder: (context, index) {
        final category = mainCategories[index];
        final subcategories = subcategoriesMap[category.id] ?? [];

        return _buildCategoryItem(category, subcategories, level: 0);
      },
    );
  }

  Widget _buildCategoryItem(
    Category category,
    List<Category> subcategories, {
    int level = 0,
  }) {
    final isExpanded = _expandedCategories.contains(category.id);
    final hasSubcategories = subcategories.isNotEmpty || category.hasChildren;

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(
            left: 16.0 + (level * 24.0),
            right: 16.0,
          ),
          leading:
              hasSubcategories && widget.expandable
                  ? IconButton(
                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedCategories.remove(category.id);
                        } else {
                          _expandedCategories.add(category.id);
                        }
                      });
                    },
                  )
                  : level > 0
                  ? Icon(
                    Icons.subdirectory_arrow_right,
                    color: Colors.grey[500],
                    size: 20,
                  )
                  : null,
          title: Row(
            children: [
              if (category.color != null)
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: _parseColor(category.color!),
                    shape: BoxShape.circle,
                  ),
                ),
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontWeight: level == 0 ? FontWeight.w600 : FontWeight.w500,
                    fontSize: level == 0 ? 16 : 14,
                  ),
                ),
              ),
            ],
          ),
          subtitle: _buildSubtitle(category),
          trailing: _buildTrailing(category),
          onTap:
              widget.onCategorySelected != null
                  ? () => widget.onCategorySelected!(category)
                  : null,
        ),
        if (isExpanded && hasSubcategories)
          ...subcategories.map(
            (subcat) => _buildCategoryItem(
              subcat,
              [], // For now, we only show 2 levels
              level: level + 1,
            ),
          ),
      ],
    );
  }

  Widget? _buildSubtitle(Category category) {
    if (category.description != null || category.fullPath != null) {
      return Text(
        category.fullPath ?? category.description ?? '',
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return null;
  }

  Widget? _buildTrailing(Category category) {
    final List<Widget> badges = [];

    if (widget.showBookCount && category.bookCount > 0) {
      badges.add(
        _buildBadge(category.bookCount.toString(), Colors.blue, 'Libros'),
      );
    }

    if (widget.showChildrenCount && category.childrenCount > 0) {
      badges.add(
        _buildBadge(
          category.childrenCount.toString(),
          Colors.green,
          'Subcategorías',
        ),
      );
    }

    if (badges.isEmpty) return null;

    return Row(mainAxisSize: MainAxisSize.min, children: badges);
  }

  Widget _buildBadge(String text, Color color, String tooltip) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(
          int.parse(colorString.substring(1), radix: 16) + 0xFF000000,
        );
      }
      return Colors.grey;
    } catch (e) {
      return Colors.grey;
    }
  }
}

// Breadcrumb widget for category navigation
class CategoryBreadcrumb extends StatelessWidget {
  final List<Category> path;
  final Function(Category)? onCategoryTap;

  const CategoryBreadcrumb({super.key, required this.path, this.onCategoryTap});

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.home_outlined, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    path.asMap().entries.map((entry) {
                      final index = entry.key;
                      final category = entry.value;
                      final isLast = index == path.length - 1;

                      return Row(
                        children: [
                          if (index > 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                            ),
                          GestureDetector(
                            onTap:
                                onCategoryTap != null && !isLast
                                    ? () => onCategoryTap!(category)
                                    : null,
                            child: Text(
                              category.name,
                              style: TextStyle(
                                color: isLast ? Colors.black87 : Colors.blue,
                                fontSize: 14,
                                fontWeight:
                                    isLast
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                decoration:
                                    !isLast && onCategoryTap != null
                                        ? TextDecoration.underline
                                        : null,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Category selector dialog
class CategorySelectorDialog extends StatefulWidget {
  final List<Category> categories;
  final Category? selectedCategory;
  final bool allowSubcategories;

  const CategorySelectorDialog({
    super.key,
    required this.categories,
    this.selectedCategory,
    this.allowSubcategories = true,
  });

  @override
  State<CategorySelectorDialog> createState() => _CategorySelectorDialogState();
}

class _CategorySelectorDialogState extends State<CategorySelectorDialog> {
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar categoría'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: CategoryHierarchyWidget(
          categories: widget.categories,
          expandable: true,
          onCategorySelected: (category) {
            if (!widget.allowSubcategories && category.isSubcategory) {
              return;
            }
            setState(() {
              _selectedCategory = category;
            });
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed:
              _selectedCategory != null
                  ? () => Navigator.of(context).pop(_selectedCategory)
                  : null,
          child: const Text('Seleccionar'),
        ),
      ],
    );
  }
}
