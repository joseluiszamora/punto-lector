import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../auth/state/auth_bloc.dart';
import '../../../core/routing/app_router.dart' as r;
import '../../../data/models/app_user.dart';

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

  Widget _buildEditForm(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => setState(() => _editing = false),
        ),
        title: const Text(
          'Editar Perfil',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _firstCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Requerido'
                                    : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _lastCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Apellido',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Requerido'
                                    : null,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _nationalityId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Nacionalidad',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
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
                                              errorBuilder:
                                                  (_, __, ___) =>
                                                      const SizedBox(),
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
                        validator:
                            (v) =>
                                (v == null || v.isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D3E50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Guardar',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileView(BuildContext context, AppUser user) {
    return CustomScrollView(
      slivers: [
        // Header colorido
        SliverAppBar(
          expandedHeight: 200,
          pinned: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF6B6B), // Rojo
                    Color(0xFF4ECDC4), // Cyan
                    Color(0xFFFFD93D), // Amarillo
                    Color(0xFF6BCF7F), // Verde
                  ],
                  stops: [0.0, 0.33, 0.66, 1.0],
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.1)],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Contenido principal
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -60),
            child: Column(
              children: [
                // Avatar centrado con badge de edición
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 46,
                          backgroundImage:
                              user.avatarUrl != null &&
                                      user.avatarUrl!.isNotEmpty
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                          backgroundColor: Colors.grey[200],
                          child:
                              (user.avatarUrl == null ||
                                      user.avatarUrl!.isEmpty)
                                  ? Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.grey[600],
                                  )
                                  : null,
                        ),
                      ),
                    ),
                    // Badge de edición
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () => setState(() => _editing = true),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2D3E50),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Tarjeta principal
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildProfileField(
                            'First Name',
                            _firstName?.isNotEmpty == true
                                ? _firstName!
                                : 'No disponible',
                            null,
                          ),
                          const SizedBox(height: 16),
                          _buildProfileField(
                            'Last Name',
                            _lastName?.isNotEmpty == true
                                ? _lastName!
                                : 'No disponible',
                            null,
                          ),
                          const SizedBox(height: 16),
                          _buildProfileField('Email', user.email, null),
                          const SizedBox(height: 16),
                          _buildProfileField(
                            'Nacionalidad',
                            _nationalityName ?? 'No especificada',
                            null,
                            flagUrl: _nationalityFlag,
                          ),
                          const SizedBox(height: 16),
                          _buildProfileField(
                            'Birth',
                            'No especificado',
                            Icons.arrow_forward_ios,
                          ),
                          const SizedBox(height: 16),
                          _buildProfileField(
                            'Gender',
                            'No especificado',
                            Icons.arrow_forward_ios,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Botones de acción
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implementar cambio de contraseña
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Función no implementada'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.lock),
                          label: const Text('Change Password'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D3E50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed:
                              () => context.read<AuthBloc>().add(
                                const SignOutRequested(),
                              ),
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileField(
    String label,
    String value,
    IconData? trailing, {
    String? flagUrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (flagUrl != null && flagUrl.isNotEmpty) ...[
              Image.network(
                flagUrl,
                width: 24,
                height: 18,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            if (trailing != null)
              Icon(trailing, size: 16, color: Colors.grey[400]),
          ],
        ),
      ],
    );
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
        backgroundColor: Colors.grey[50],
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            if (authState is! Authenticated) {
              return const Center(child: Text('No has iniciado sesión'));
            }
            final user = authState.user;
            if (_loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_editing) {
              return _buildEditForm(context);
            }

            return _buildProfileView(context, user);
          },
        ),
      ),
    );
  }
}
