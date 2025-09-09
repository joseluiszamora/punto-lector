import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/routing/app_router.dart' as r;
import '../../../core/theme/app_theme.dart';
import '../../auth/state/auth_bloc.dart';
import '../../../data/repositories/auth_repository.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is Authenticated) {
            final repo = context.read<IAuthRepository>();
            final complete = await repo.isCurrentUserProfileComplete();
            if (complete) {
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, r.AppRoutes.home);
            } else {
              if (!mounted) return;
              Navigator.pushReplacementNamed(
                context,
                r.AppRoutes.completeProfile,
              );
            }
          } else if (state is RequireProfileCompletionState) {
            Navigator.pushReplacementNamed(
              context,
              r.AppRoutes.completeProfile,
            );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(theme),
                  const SizedBox(height: 40),
                  _buildLoginCard(theme, loading, state),
                  const SizedBox(height: 24),
                  _buildSocialLogin(theme, loading),
                  const SizedBox(height: 24),
                  _buildToggleButton(theme, loading),
                  if (state is AuthError)
                    _buildErrorMessage(theme, state.message),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Text(
          _isRegister ? 'Crear Cuenta' : 'Bienvenido',
          style: AppTheme.headingStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _isRegister
              ? 'Completa tu información para registrarte'
              : 'Ingresa a tu cuenta para continuar',
          style: AppTheme.subheadingStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginCard(ThemeData theme, bool loading, AuthState state) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isRegister) ...[
              _buildNameField(),
              const SizedBox(height: 20),
              _buildNationalityField(),
              const SizedBox(height: 20),
            ],
            _buildEmailField(),
            const SizedBox(height: 20),
            _buildPasswordField(),
            const SizedBox(height: 28),
            _buildSubmitButton(loading),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameCtrl,
      decoration: const InputDecoration(
        labelText: 'Nombre completo',
        prefixIcon: Icon(Icons.person_outline),
      ),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildNationalityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Nacionalidad',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            if (_loadingNats)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                onPressed: _maybeLoadNationalities,
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Recargar nacionalidades',
              ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _selectedNationalityId,
          decoration: const InputDecoration(
            hintText: 'Selecciona tu nacionalidad (opcional)',
            prefixIcon: Icon(Icons.flag_outlined),
          ),
          items:
              _nationalities.map((n) {
                return DropdownMenuItem<String>(
                  value: n['id'] as String,
                  child: Row(
                    children: [
                      if ((n['flag_url'] as String?)?.isNotEmpty == true)
                        Container(
                          width: 28,
                          height: 20,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Image.network(
                              n['flag_url'] as String,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.flag, size: 12),
                                  ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          n['name'] as String,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          onChanged: (v) => setState(() => _selectedNationalityId = v),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailCtrl,
      decoration: const InputDecoration(
        labelText: 'Correo electrónico',
        prefixIcon: Icon(Icons.email_outlined),
      ),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Ingresa tu correo electrónico';
        if (!v.contains('@') || !v.contains('.')) return 'Correo inválido';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passCtrl,
      decoration: const InputDecoration(
        labelText: 'Contraseña',
        prefixIcon: Icon(Icons.lock_outline),
      ),
      obscureText: true,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submit(),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
        if (v.length < 6) return 'Mínimo 6 caracteres';
        return null;
      },
    );
  }

  Widget _buildSubmitButton(bool loading) {
    return ElevatedButton(
      onPressed: loading ? null : _submit,
      child:
          loading
              ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
              : Text(_isRegister ? 'Crear Cuenta' : 'Iniciar Sesión'),
    );
  }

  Widget _buildSocialLogin(ThemeData theme, bool loading) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: theme.colorScheme.outline)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'O continúa con',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: Divider(color: theme.colorScheme.outline)),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          decoration: AppTheme.socialButtonDecoration,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap:
                  loading
                      ? null
                      : () => context.read<AuthBloc>().add(
                        const SignInWithGoogle(),
                      ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'G',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Google',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(ThemeData theme, bool loading) {
    return TextButton(
      onPressed:
          loading
              ? null
              : () async {
                setState(() => _isRegister = !_isRegister);
                if (_isRegister && _nationalities.isEmpty) {
                  await _maybeLoadNationalities();
                }
              },
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: theme.textTheme.bodyMedium,
          children: [
            TextSpan(
              text:
                  _isRegister
                      ? '¿Ya tienes una cuenta? '
                      : '¿No tienes cuenta? ',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            TextSpan(
              text: _isRegister ? 'Inicia Sesión' : 'Regístrate',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(ThemeData theme, String message) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
