import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../auth/state/auth_bloc.dart';
import '../../../core/routing/app_router.dart' as r;
import '../../../data/models/user_role.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _firstName;
  String? _lastName;
  String? _nationalityName;
  String? _nationalityFlag;
  String? _nationalityId;
  bool _loading = true;
  bool _editing = false;

  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _nationalities = [];

  @override
  void initState() {
    super.initState();
    _loadProfileExtras();
  }

  Future<void> _loadProfileExtras() async {
    final state = context.read<AuthBloc>().state;
    if (state is! Authenticated) {
      setState(() => _loading = false);
      return;
    }
    try {
      final client = sb.Supabase.instance.client;
      final prof =
          await client
              .from('user_profiles')
              .select('first_name, last_name, nationality_id')
              .eq('id', state.user.id)
              .maybeSingle();
      if (prof != null) {
        _firstName = (prof['first_name'] as String?)?.trim();
        _lastName = (prof['last_name'] as String?)?.trim();
        _firstCtrl.text = _firstName ?? '';
        _lastCtrl.text = _lastName ?? '';
        final natId = prof['nationality_id'] as String?;
        _nationalityId = natId;
        if (natId != null && natId.isNotEmpty) {
          final nat =
              await client
                  .from('nationalities')
                  .select('id, name, flag_url')
                  .eq('id', natId)
                  .maybeSingle();
          if (nat != null) {
            _nationalityName = nat['name'] as String?;
            _nationalityFlag = nat['flag_url'] as String?;
          }
        }
      }
      // Cargar opciones de nacionalidades
      final list = await client
          .from('nationalities')
          .select('id, name, flag_url')
          .order('name', ascending: true);
      _nationalities =
          (list as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final first = _firstCtrl.text.trim();
    final last = _lastCtrl.text.trim();
    final nat = _nationalityId;
    context.read<AuthBloc>().add(
      UpdateProfileRequested(first, last, nat ?? ''),
    );
    setState(() => _editing = false);
    await _loadProfileExtras();
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => curr is Unauthenticated,
      listener: (ctx, state) {
        Navigator.of(
          ctx,
        ).pushNamedAndRemoveUntil(r.AppRoutes.login, (route) => false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Perfil'),
          actions: [
            if (!_loading)
              IconButton(
                icon: Icon(_editing ? Icons.close : Icons.edit),
                tooltip: _editing ? 'Cancelar' : 'Editar',
                onPressed: () => setState(() => _editing = !_editing),
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is! Authenticated) {
                return const Text('No has iniciado sesión');
              }
              final user = authState.user;
              if (_loading)
                return const Center(child: CircularProgressIndicator());

              if (_editing) {
                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _firstCtrl,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Requerido'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _lastCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Apellido',
                        ),
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Requerido'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _nationalityId,
                        isExpanded: true,
                        items:
                            _nationalities
                                .map(
                                  (n) => DropdownMenuItem<String>(
                                    value: n['id'] as String,
                                    child: Row(
                                      children: [
                                        if ((n['flag_url'] as String?)
                                                ?.isNotEmpty ==
                                            true)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8.0,
                                            ),
                                            child: Image.network(
                                              n['flag_url'] as String,
                                              width: 24,
                                              height: 18,
                                            ),
                                          ),
                                        Flexible(
                                          child: Text(n['name'] as String),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _nationalityId = v),
                        decoration: const InputDecoration(
                          labelText: 'Nacionalidad',
                        ),
                        validator:
                            (v) =>
                                (v == null || v.isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _save,
                            child: const Text('Guardar'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => setState(() => _editing = false),
                            child: const Text('Cancelar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage:
                            user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                        child:
                            (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                                ? const Icon(Icons.person_outline)
                                : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.email,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (_firstName != null || _lastName != null)
                              Text(
                                [
                                  if (_firstName != null &&
                                      _firstName!.isNotEmpty)
                                    _firstName!,
                                  if (_lastName != null &&
                                      _lastName!.isNotEmpty)
                                    _lastName!,
                                ].join(' '),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_nationalityName != null)
                    Row(
                      children: [
                        if (_nationalityFlag != null &&
                            _nationalityFlag!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Image.network(
                              _nationalityFlag!,
                              width: 24,
                              height: 18,
                            ),
                          ),
                        Text('Nacionalidad: $_nationalityName'),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Text('Rol de usuario: ${user.role.asString}'),
                  const Spacer(),
                  ElevatedButton(
                    onPressed:
                        () => context.read<AuthBloc>().add(
                          const SignOutRequested(),
                        ),
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
