import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/routing/app_router.dart' as r;
import '../../auth/state/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isRegister = false;
  final _nameCtrl = TextEditingController();

  String? _selectedNationalityId;
  late final sb.SupabaseClient _sb;
  List<Map<String, dynamic>> _nationalities = [];
  bool _loadingNats = false;

  @override
  void initState() {
    super.initState();
    _sb = sb.Supabase.instance.client;
    _maybeLoadNationalities();
  }

  Future<void> _maybeLoadNationalities() async {
    if (!_isRegister) return;
    setState(() => _loadingNats = true);
    try {
      final data = await _sb
          .from('nationalities')
          .select('id, name, country_code, flag_url')
          .order('name');
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
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (_isRegister) {
      context.read<AuthBloc>().add(
        SignUpWithEmailPassword(
          email,
          pass,
          name: _nameCtrl.text.trim(),
          nationalityId: _selectedNationalityId,
        ),
      );
    } else {
      context.read<AuthBloc>().add(SignInWithEmailPassword(email, pass));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingresar')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            Navigator.pushReplacementNamed(context, r.AppRoutes.home);
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (_isRegister) ...[
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nombre (opcional)',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Nacionalidad',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Recargar',
                                  onPressed:
                                      _loadingNats
                                          ? null
                                          : _maybeLoadNationalities,
                                  icon: const Icon(Icons.refresh),
                                ),
                              ],
                            ),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _selectedNationalityId,
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
                                                  padding:
                                                      const EdgeInsets.only(
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
                                                child: Text(
                                                  n['name'] as String,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (v) => setState(
                                    () => _selectedNationalityId = v,
                                  ),
                              decoration: const InputDecoration(
                                hintText:
                                    'Selecciona tu nacionalidad (opcional)',
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Ingresa tu email';
                              if (!v.contains('@')) return 'Email inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                            ),
                            obscureText: true,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Ingresa tu contraseña';
                              if (v.length < 6) return 'Mínimo 6 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: loading ? null : _submit,
                              child: Text(
                                _isRegister ? 'Crear cuenta' : 'Ingresar',
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed:
                                loading
                                    ? null
                                    : () async {
                                      setState(
                                        () => _isRegister = !_isRegister,
                                      );
                                      if (_isRegister &&
                                          _nationalities.isEmpty) {
                                        await _maybeLoadNationalities();
                                      }
                                    },
                            child: Text(
                              _isRegister
                                  ? '¿Ya tienes cuenta? Inicia sesión'
                                  : '¿No tienes cuenta? Regístrate',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed:
                          loading
                              ? null
                              : () => context.read<AuthBloc>().add(
                                const SignInWithGoogle(),
                              ),
                      icon: const Icon(Icons.login),
                      label: const Text('Continuar con Google'),
                    ),
                    if (state is AuthError) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.message,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
