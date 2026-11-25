import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'config.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_gate.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    if (kUsarEmulador) {
      FirebaseFirestore.instance.useFirestoreEmulator(kEmuladorHost, 8080);
      await FirebaseAuth.instance.useAuthEmulator(kEmuladorHost, 9099);
    }
  } catch (e) {
    // Em vez de tela branca, mostra o que deu errado.
    runApp(_ErroDeInicio(mensagem: '$e'));
    return;
  }

  runApp(const HermesApp());
}

/// Tela mostrada quando o Firebase não consegue iniciar.
class _ErroDeInicio extends StatelessWidget {
  final String mensagem;

  const _ErroDeInicio({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('O Hermes não conseguiu iniciar o Firebase',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  const Text(
                    'Se a mensagem fala de "firebase_options.dart", rode `flutterfire configure` '
                    'dentro da pasta do projeto e abra o app de novo.',
                  ),
                  const SizedBox(height: 16),
                  SelectableText(mensagem, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HermesApp extends StatelessWidget {
  const HermesApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Reconstrói o app inteiro quando o botão de sol/lua troca o tema.
    return ValueListenableBuilder<bool>(
      valueListenable: AppColors.themeIsDark,
      builder: (context, isDark, _) {
        return MaterialApp(
          title: 'Hermes',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.current,
          // Sem `const` de propósito: widget const não reconstrói na troca de tema.
          home: AuthGate(),
        );
      },
    );
  }
}
