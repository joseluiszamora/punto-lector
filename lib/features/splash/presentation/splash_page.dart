import 'package:flutter/material.dart';
import '../../../core/routing/app_router.dart' as r;
import '../../../core/supabase/supabase_client_provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _tilt;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.96,
      end: 1.06,
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_ctrl);
    _tilt = Tween<double>(
      begin: -0.02,
      end: 0.02,
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_ctrl);
    _redirect();
  }

  Future<void> _redirect() async {
    // Dar tiempo a mostrar el splash de forma agradable
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final u = SupabaseInit.client.auth.currentUser;
    if (u == null) {
      Navigator.of(context).pushReplacementNamed(r.AppRoutes.login);
      return;
    }
    // Comprobar perfil
    try {
      final data =
          await SupabaseInit.client
              .from('user_profiles')
              .select('first_name, last_name, nationality_id')
              .eq('id', u.id)
              .maybeSingle();
      final first = (data?['first_name'] as String?)?.trim();
      final last = (data?['last_name'] as String?)?.trim();
      final nat = data?['nationality_id'] as String?;
      final complete =
          (first != null && first.isNotEmpty) &&
          (last != null && last.isNotEmpty) &&
          (nat != null && nat.isNotEmpty);
      Navigator.of(context).pushReplacementNamed(
        complete ? r.AppRoutes.home : r.AppRoutes.completeProfile,
      );
    } catch (_) {
      Navigator.of(context).pushReplacementNamed(r.AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.surface, cs.surfaceContainerHigh],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _tilt.value,
                    child: Transform.scale(scale: _scale.value, child: child),
                  );
                },
                child: Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.25),
                        blurRadius: 22,
                        spreadRadius: 2,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 56,
                    color: cs.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'punto lector',
                style: tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
