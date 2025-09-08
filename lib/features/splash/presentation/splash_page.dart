import 'package:flutter/material.dart';
import '../../../core/routing/app_router.dart' as r;
import '../../../core/supabase/supabase_client_provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(milliseconds: 200));
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
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
