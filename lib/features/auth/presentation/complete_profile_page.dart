import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/routing/app_router.dart' as r;
import '../state/auth_bloc.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  String? _natId;

  late final sb.SupabaseClient _sb;
  List<Map<String, dynamic>> _nationalities = [];
  bool _loadingNats = false;

  @override
  void initState() {
    super.initState();
    _sb = sb.Supabase.instance.client;
    _loadNationalities();
  }

  Future<void> _loadNationalities() async {
    setState(() => _loadingNats = true);
    try {
      final data = await _sb
          .from('nationalities')
          .select('id, name, country_code, flag_url')
          .order('name', ascending: true);
      _nationalities =
          (data as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
    } catch (_) {
      _nationalities = [];
    } finally {
      if (mounted) setState(() => _loadingNats = false);
    }
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_natId == null || _natId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona tu nacionalidad')),
      );
      return;
    }
    context.read<AuthBloc>().add(
      UpdateProfileRequested(
        _firstCtrl.text.trim(),
        _lastCtrl.text.trim(),
        _natId!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Completa tu perfil')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, r.AppRoutes.home);
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Nacionalidad',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            onPressed: _loadingNats ? null : _loadNationalities,
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Recargar',
                          ),
                        ],
                      ),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _natId,
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
                                                      const SizedBox(
                                                        width: 24,
                                                        height: 18,
                                                      ),
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
                        onChanged: (v) => setState(() => _natId = v),
                        validator:
                            (v) =>
                                (v == null || v.isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: loading ? null : _save,
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
