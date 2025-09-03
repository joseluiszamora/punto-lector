import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../data/models/app_user.dart';
import '../../../../data/models/user_role.dart';
import '../../../../data/repositories/users_repository.dart';

class UsersAdminListPage extends StatelessWidget {
  const UsersAdminListPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _UsersCubit(UsersRepository(SupabaseInit.client))..load(),
      child: const _UsersView(),
    );
  }
}

class _UsersCubit extends Cubit<_UsersState> {
  final IUsersRepository repo;
  List<AppUser> _itemsCache = [];
  List<AppUser> get items => _itemsCache;

  _UsersCubit(this.repo) : super(const _UsersState.loading());

  Future<void> load() async {
    emit(const _UsersState.loading());
    try {
      final items = await repo.listAll();
      _itemsCache = items;
      emit(_UsersState.loaded(items));
    } catch (e) {
      emit(_UsersState.error(e.toString()));
    }
  }

  Future<void> updateRole(String id, UserRole role) async {
    emit(const _UsersState.operating());
    try {
      final updated = await repo.updateRole(id, role);
      _itemsCache =
          _itemsCache.map((u) => u.id == updated.id ? updated : u).toList();
      emit(const _UsersState.operationSuccess());
      emit(_UsersState.loaded(_itemsCache));
    } catch (e) {
      emit(_UsersState.error(e.toString()));
    }
  }
}

sealed class _UsersState {
  const _UsersState();
  const factory _UsersState.loading() = _Loading;
  const factory _UsersState.loaded(List<AppUser> items) = _Loaded;
  const factory _UsersState.error(String message) = _Error;
  const factory _UsersState.operating() = _Operating;
  const factory _UsersState.operationSuccess() = _OperationSuccess;
}

class _Loading extends _UsersState {
  const _Loading();
}

class _Operating extends _UsersState {
  const _Operating();
}

class _OperationSuccess extends _UsersState {
  const _OperationSuccess();
}

class _Error extends _UsersState {
  final String message;
  const _Error(this.message);
}

class _Loaded extends _UsersState {
  final List<AppUser> items;
  const _Loaded(this.items);
}

class _UsersView extends StatelessWidget {
  const _UsersView();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Usuarios'),
        actions: [
          IconButton(
            onPressed: () => context.read<_UsersCubit>().load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<_UsersCubit, _UsersState>(
        listener: (context, state) {
          if (state is _Error) {
            final msg = state.message.replaceFirst('Exception: ', '');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $msg')));
          } else if (state is _OperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Rol actualizado')));
          }
        },
        builder: (context, state) {
          if (state is _Loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is _Loaded) {
            final items = state.items;
            if (items.isEmpty) return const Center(child: Text('Sin usuarios'));
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final u = items[i];
                final hasAvatar =
                    (u.avatarUrl != null && u.avatarUrl!.isNotEmpty);
                final title =
                    (u.name != null && u.name!.isNotEmpty) ? u.name! : u.email;
                final subtitle =
                    (u.name != null && u.name!.isNotEmpty) ? u.email : null;
                return ListTile(
                  leading:
                      hasAvatar
                          ? CircleAvatar(
                            backgroundImage: NetworkImage(u.avatarUrl!),
                            radius: 22,
                          )
                          : const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                  title: Text(title),
                  subtitle:
                      subtitle == null
                          ? Text('Rol: ${u.role.asString}')
                          : Text('$subtitle\nRol: ${u.role.asString}'),
                  isThreeLine: subtitle != null,
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Editar rol',
                    onPressed: () async {
                      final picked = await showDialog<UserRole>(
                        context: context,
                        builder: (_) => _RoleDialog(initial: u.role),
                      );
                      if (picked != null &&
                          picked != u.role &&
                          context.mounted) {
                        await context.read<_UsersCubit>().updateRole(
                          u.id,
                          picked,
                        );
                      }
                    },
                  ),
                );
              },
            );
          }
          if (state is _Operating || state is _OperationSuccess) {
            final cached = context.read<_UsersCubit>().items;
            return ListView.separated(
              itemCount: cached.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final u = cached[i];
                final hasAvatar =
                    (u.avatarUrl != null && u.avatarUrl!.isNotEmpty);
                final title =
                    (u.name != null && u.name!.isNotEmpty) ? u.name! : u.email;
                final subtitle =
                    (u.name != null && u.name!.isNotEmpty) ? u.email : null;
                return ListTile(
                  leading:
                      hasAvatar
                          ? CircleAvatar(
                            backgroundImage: NetworkImage(u.avatarUrl!),
                            radius: 22,
                          )
                          : const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                  title: Text(title),
                  subtitle:
                      subtitle == null
                          ? Text('Rol: ${u.role.asString}')
                          : Text('$subtitle\nRol: ${u.role.asString}'),
                  isThreeLine: subtitle != null,
                );
              },
            );
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
}

class _RoleDialog extends StatefulWidget {
  final UserRole initial;
  const _RoleDialog({required this.initial});
  @override
  State<_RoleDialog> createState() => _RoleDialogState();
}

class _RoleDialogState extends State<_RoleDialog> {
  late UserRole _role;
  @override
  void initState() {
    super.initState();
    _role = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar rol'),
      content: DropdownButtonFormField<UserRole>(
        value: _role,
        decoration: const InputDecoration(labelText: 'Rol'),
        items: const [
          DropdownMenuItem(value: UserRole.user, child: Text('user')),
          DropdownMenuItem(
            value: UserRole.storeManager,
            child: Text('store_manager'),
          ),
          DropdownMenuItem(value: UserRole.admin, child: Text('admin')),
          DropdownMenuItem(
            value: UserRole.superAdmin,
            child: Text('super_admin'),
          ),
        ],
        onChanged: (v) => setState(() => _role = v ?? _role),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _role),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
