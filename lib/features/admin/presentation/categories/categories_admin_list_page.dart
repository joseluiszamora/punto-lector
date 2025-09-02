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
      final items = await repo.listAll();
      _itemsCache = items;
      emit(_CategoriesState.loaded(items));
    } catch (e) {
      emit(_CategoriesState.error(e.toString()));
    }
  }

  Future<void> create(String name, {String? color}) async {
    emit(const _CategoriesState.operating());
    try {
      await repo.create(name: name, color: color);
      // Notificar éxito primero y luego recargar para que el último estado sea Loaded
      emit(const _CategoriesState.operationSuccess());
      await load();
    } catch (e) {
      emit(_CategoriesState.error(e.toString()));
    }
  }

  Future<void> update(String id, String name, {String? color}) async {
    emit(const _CategoriesState.operating());
    try {
      await repo.update(id, name: name, color: color);
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

class _CategoriesView extends StatelessWidget {
  const _CategoriesView();
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
          // Helper para construir la lista con items (desde estado o cache)
          Widget buildList(List<Category> items) {
            if (items.isEmpty)
              return const Center(child: Text('Sin categorías'));
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final c = items[i];
                return ListTile(
                  leading: _ColorDot(hex: c.color),
                  title: Text(c.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openForm(ctx, category: c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(ctx, c),
                      ),
                    ],
                  ),
                );
              },
            );
          }

          if (state is _Loaded) {
            return buildList(state.items);
          }
          if (state is _Loading) {
            return const Center(child: CircularProgressIndicator());
          }
          // En Operating u OperationSuccess mostramos la lista desde cache para evitar parpadeo
          if (state is _Operating || state is _OperationSuccess) {
            final cached = context.read<_CategoriesCubit>().items;
            return buildList(cached);
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

  Future<void> _openForm(BuildContext context, {Category? category}) async {
    final result = await showDialog<_CategoryFormResult>(
      context: context,
      builder:
          (ctx) => _CategoryDialog(
            initialName: category?.name,
            initialColor: category?.color,
          ),
    );
    if (result == null) return;
    final cubit = context.read<_CategoriesCubit>();
    if (category == null) {
      await cubit.create(result.name, color: result.color);
    } else {
      await cubit.update(category.id, result.name, color: result.color);
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
  _CategoryFormResult(this.name, this.color);
}

class _CategoryDialog extends StatefulWidget {
  final String? initialName;
  final String? initialColor;
  const _CategoryDialog({this.initialName, this.initialColor});
  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  String? _colorHex;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName ?? '');
    _colorHex = widget.initialColor;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
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
      title: Text(
        widget.initialName == null ? 'Nueva categoría' : 'Editar categoría',
      ),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator:
                  (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 8),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop(
              context,
              _CategoryFormResult(_name.text.trim(), _colorHex),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
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
