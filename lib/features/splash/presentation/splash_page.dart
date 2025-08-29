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
    final isLogged = SupabaseInit.client.auth.currentUser != null;
    Navigator.of(
      context,
    ).pushReplacementNamed(isLogged ? r.AppRoutes.home : r.AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
