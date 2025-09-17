import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart' show Colors;
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../data/models/category.dart';
import '../../../../data/repositories/categories_repository.dart';

class CategoriesAdminListPage extends StatelessWidget {
  const CategoriesAdminListPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
              _CategoriesCubit(CategoriesRepository(SupabaseInit.client))
                ..load(),
      child: const _CategoriesView(),
    );
  }
}

class _CategoriesCubit extends Cubit<_CategoriesState> {
  final ICategoriesRepository repo;
  // Cache local para mantener la lista visible durante operaciones
  List<Category> _itemsCache = [];
  List<Category> get items => _itemsCache;

  _CategoriesCubit(this.repo) : super(const _CategoriesState.loading());

  Future<void> load() async {
    emit(const _CategoriesState.loading());
    try {
      final items = await repo.getCategoriesTree();
      _itemsCache = items;
      emit(_CategoriesState.loaded(items));
    } catch (e) {
      emit(_CategoriesState.error(e.toString()));
    }
  }

  Future<void> create(
    String name, {
    String? description,
    String? color,
    String? parentId,
    int level = 0,
    int sortOrder = 0,
  }) async {
    emit(const _CategoriesState.operating());
    try {
      await repo.create(
        name: name,
        description: description,
        color: color,
        parentId: parentId,
        level: level,
        sortOrder: sortOrder,
      );
      emit(const _CategoriesState.operationSuccess());
      await load();
    } catch (e) {
      emit(_CategoriesState.error(e.toString()));
    }
  }

  Future<void> update(
    String id,
    String name, {
    String? description,
    String? color,
    String? parentId,
    int? level,
    int? sortOrder,
  }) async {
    emit(const _CategoriesState.operating());
    try {
      await repo.update(
        id,
        name: name,
        description: description,
        color: color,
        parentId: parentId,
        level: level,
        sortOrder: sortOrder,
      );
      emit(const _CategoriesState.operationSuccess());
      await load();
    } catch (e) {
      emit(_CategoriesState.error(e.toString()));
    }
  }

  Future<void> remove(String id) async {
    emit(const _CategoriesState.operating());
    try {
      await repo.delete(id);
      emit(const _CategoriesState.operationSuccess());
      await load();
    } catch (e) {
      emit(_CategoriesState.error(e.toString()));
    }
  }
}

sealed class _CategoriesState {
  const _CategoriesState();
  const factory _CategoriesState.loading() = _Loading;
  const factory _CategoriesState.loaded(List<Category> items) = _Loaded;
  const factory _CategoriesState.error(String message) = _Error;
  const factory _CategoriesState.operating() = _Operating;
  const factory _CategoriesState.operationSuccess() = _OperationSuccess;
}

class _Loading extends _CategoriesState {
  const _Loading();
}

class _Operating extends _CategoriesState {
  const _Operating();
}

class _OperationSuccess extends _CategoriesState {
  const _OperationSuccess();
}

class _Error extends _CategoriesState {
  final String message;
  const _Error(this.message);
}

class _Loaded extends _CategoriesState {
  final List<Category> items;
  const _Loaded(this.items);
}

class _CategoriesView extends StatefulWidget {
  const _CategoriesView();

  @override
  State<_CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<_CategoriesView> {
  final Set<String> _expandedCategories = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Categorías'),
        actions: [
          IconButton(
            onPressed: () => context.read<_CategoriesCubit>().load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: BlocConsumer<_CategoriesCubit, _CategoriesState>(
        listener: (context, state) {
          if (state is _Error) {
            final msg = state.message.replaceFirst('Exception: ', '');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $msg')));
          } else if (state is _OperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Operación exitosa')));
          }
        },
        builder: (context, state) {
          // Helper para construir la lista jerárquica
          Widget buildHierarchicalList(List<Category> categories) {
            if (categories.isEmpty) {
              return const Center(child: Text('Sin categorías'));
            }

            // Agrupar categorías por padre
            final mainCategories =
                categories.where((c) => c.isMainCategory).toList();
            final subcategoriesMap = <String, List<Category>>{};

            for (final cat in categories.where((c) => c.isSubcategory)) {
              if (cat.parentId != null) {
                subcategoriesMap.putIfAbsent(cat.parentId!, () => []).add(cat);
              }
            }

            // Ordenar categorías
            mainCategories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
            for (final subcats in subcategoriesMap.values) {
              subcats.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
            }

            return ListView.builder(
              itemCount: _calculateTotalItems(mainCategories, subcategoriesMap),
              itemBuilder: (context, index) {
                return _buildHierarchicalItem(
                  mainCategories,
                  subcategoriesMap,
                  index,
                );
              },
            );
          }

          if (state is _Loaded) {
            return buildHierarchicalList(state.items);
          }
          if (state is _Loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is _Operating || state is _OperationSuccess) {
            final cached = context.read<_CategoriesCubit>().items;
            return buildHierarchicalList(cached);
          }
          if (state is _Error) {
            final msg = state.message.replaceFirst('Exception: ', '');
            return Center(
              child: Text(msg, style: const TextStyle(color: Colors.red)),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  int _calculateTotalItems(
    List<Category> mainCategories,
    Map<String, List<Category>> subcategoriesMap,
  ) {
    int total = mainCategories.length;
    for (final mainCat in mainCategories) {
      if (_expandedCategories.contains(mainCat.id)) {
        total += subcategoriesMap[mainCat.id]?.length ?? 0;
      }
    }
    return total;
  }

  Widget _buildHierarchicalItem(
    List<Category> mainCategories,
    Map<String, List<Category>> subcategoriesMap,
    int flatIndex,
  ) {
    int currentIndex = 0;

    for (final mainCat in mainCategories) {
      if (currentIndex == flatIndex) {
        return _buildCategoryTile(mainCat, level: 0);
      }
      currentIndex++;

      if (_expandedCategories.contains(mainCat.id)) {
        final subcats = subcategoriesMap[mainCat.id] ?? [];
        for (final subcat in subcats) {
          if (currentIndex == flatIndex) {
            return _buildCategoryTile(subcat, level: 1);
          }
          currentIndex++;
        }
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildCategoryTile(Category category, {required int level}) {
    final hasSubcategories = category.hasChildren;
    final isExpanded = _expandedCategories.contains(category.id);

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: 8.0 + (level * 16.0),
        vertical: 2.0,
      ),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasSubcategories && level == 0)
              IconButton(
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
            else if (level > 0)
              Icon(
                Icons.subdirectory_arrow_right,
                color: Colors.grey[500],
                size: 20,
              ),
            _ColorDot(hex: category.color),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: TextStyle(
                  fontWeight: level == 0 ? FontWeight.w600 : FontWeight.w500,
                  fontSize: level == 0 ? 16 : 14,
                ),
              ),
            ),
            if (category.hasChildren)
              _Badge(
                text: category.childrenCount.toString(),
                color: Colors.green,
                tooltip: 'Subcategorías',
              ),
            if (category.hasBooks)
              _Badge(
                text: category.bookCount.toString(),
                color: Colors.blue,
                tooltip: 'Libros',
              ),
          ],
        ),
        subtitle:
            category.description != null
                ? Text(
                  category.description!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
                : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (level == 0)
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => _openForm(context, parentCategory: category),
                tooltip: 'Agregar subcategoría',
              ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _openForm(context, category: category),
              tooltip: 'Editar',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _confirmDelete(context, category),
              tooltip: 'Eliminar',
            ),
          ],
        ),
      ),
    );
  }

  void _openForm(
    BuildContext context, {
    Category? category,
    Category? parentCategory,
  }) async {
    final cubit = context.read<_CategoriesCubit>();
    final result = await showDialog<_CategoryFormResult?>(
      context: context,
      builder:
          (_) => _CategoryDialog(
            category: category,
            parentCategory: parentCategory,
            availableParents:
                cubit.items
                    .where(
                      (c) => c.isMainCategory && c.id != category?.id,
                    ) // No permitir auto-referencia
                    .toList(),
          ),
    );

    if (result != null && context.mounted) {
      if (category == null) {
        // Crear nueva categoría
        await cubit.create(
          result.name,
          description: result.description,
          color: result.color,
          parentId: result.parentId,
          level: result.level,
          sortOrder: result.sortOrder,
        );
      } else {
        // Actualizar categoría existente
        await cubit.update(
          category.id,
          result.name,
          description: result.description,
          color: result.color,
          parentId: result.parentId,
          level: result.level,
          sortOrder: result.sortOrder,
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, Category c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar categoría'),
            content: Text('¿Deseas eliminar "${c.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
    if (ok == true) {
      await context.read<_CategoriesCubit>().remove(c.id);
    }
  }
}

class _CategoryFormResult {
  final String name;
  final String? color;
  final String? description;
  final String? parentId;
  final int level;
  final int sortOrder;

  _CategoryFormResult({
    required this.name,
    this.color,
    this.description,
    this.parentId,
    required this.level,
    required this.sortOrder,
  });
}

class _CategoryDialog extends StatefulWidget {
  final Category? category; // Para editar
  final Category? parentCategory; // Para crear subcategoría
  final List<Category> availableParents; // Categorías principales disponibles

  const _CategoryDialog({
    this.category,
    this.parentCategory,
    required this.availableParents,
  });

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _sortOrder;
  String? _colorHex;
  String? _selectedParentId;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category?.name ?? '');
    _description = TextEditingController(
      text: widget.category?.description ?? '',
    );
    _sortOrder = TextEditingController(
      text: widget.category?.sortOrder.toString() ?? '0',
    );
    _colorHex = widget.category?.color;
    _selectedParentId = widget.category?.parentId ?? widget.parentCategory?.id;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.category != null) {
      return 'Editar Categoría';
    } else if (widget.parentCategory != null) {
      return 'Nueva Subcategoría';
    } else {
      return 'Nueva Categoría';
    }
  }

  List<Category> get _availableParents {
    return widget.availableParents;
  }

  // Color utilidades
  String _toHex(Color color) {
    final r = color.red.toRadixString(16).padLeft(2, '0');
    final g = color.green.toRadixString(16).padLeft(2, '0');
    final b = color.blue.toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  Future<void> _pickColor() async {
    final palette = <Color>[
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.blueGrey,
      Colors.grey,
    ];
    final chosen = await showModalBottomSheet<Color?>(
      context: context,
      builder:
          (_) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final c in palette)
                    GestureDetector(
                      onTap: () => Navigator.pop(context, c),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12),
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Sin color'),
                  ),
                ],
              ),
            ),
          ),
    );
    if (chosen != null) {
      setState(() => _colorHex = _toHex(chosen));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_title),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campo Nombre
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    hintText: 'Historia, Ficción, etc.',
                  ),
                  validator:
                      (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Campo Descripción
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Descripción opcional de la categoría',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Selector de Padre (solo si hay categorías principales disponibles)
                if (_availableParents.isNotEmpty &&
                    widget.category?.isMainCategory != true) ...[
                  const Text(
                    'Categoría Padre',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: _selectedParentId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    hint: const Text('Seleccionar padre (opcional)'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Sin padre (categoría principal)'),
                      ),
                      ..._availableParents.map(
                        (parent) => DropdownMenuItem<String?>(
                          value: parent.id,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ColorDot(hex: parent.color),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  parent.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedParentId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Campo Orden
                TextFormField(
                  controller: _sortOrder,
                  decoration: const InputDecoration(
                    labelText: 'Orden',
                    hintText: '0, 1, 2...',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = int.tryParse(v.trim());
                    return n == null ? 'Debe ser un número' : null;
                  },
                ),
                const SizedBox(height: 16),

                // Selector de Color
                Row(
                  children: [
                    _ColorDot(hex: _colorHex),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _pickColor,
                      icon: const Icon(Icons.color_lens_outlined),
                      label: const Text('Color'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;

            final name = _name.text.trim();
            final description =
                _description.text.trim().isNotEmpty
                    ? _description.text.trim()
                    : null;
            final sortOrder = int.tryParse(_sortOrder.text.trim()) ?? 0;
            final level = _selectedParentId != null ? 1 : 0;

            Navigator.pop(
              context,
              _CategoryFormResult(
                name: name,
                color: _colorHex,
                description: description,
                parentId: _selectedParentId,
                level: level,
                sortOrder: sortOrder,
              ),
            );
          },
          child: Text(widget.category == null ? 'Crear' : 'Guardar'),
        ),
      ],
    );
  }
}

// Widget auxiliar para mostrar contadores en badges
class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final String tooltip;

  const _Badge({
    required this.text,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final String? hex;
  const _ColorDot({this.hex});
  @override
  Widget build(BuildContext context) {
    final color = _parse(hex) ?? Colors.black26;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12),
      ),
    );
  }

  Color? _parse(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final h = hex.replaceAll('#', '');
    if (h.length != 6) return null;
    final val = int.tryParse(h, radix: 16);
    if (val == null) return null;
    return Color(0xFF000000 | val);
  }
}
