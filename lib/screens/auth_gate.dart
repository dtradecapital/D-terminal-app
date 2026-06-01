import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'home_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  static final ValueNotifier<bool> devBypassNotifier = ValueNotifier<bool>(false);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AuthGate.devBypassNotifier,
      builder: (context, bypass, child) {
        if (bypass) {
          return const HomePage();
        }
        return StreamBuilder<sb.AuthState>(
          stream: sb.Supabase.instance.client.auth.onAuthStateChange,
          builder: (context, snapshot) {
            final session = sb.Supabase.instance.client.auth.currentSession;

            if (session != null) {
              return const HomePage();
            }

            return const LoginPage();
          },
        );
      },
    );
  }
}
