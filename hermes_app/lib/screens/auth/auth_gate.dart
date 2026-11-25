import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/perfil.dart';
import '../../services/auth_service.dart';
import '../../services/hermes_api.dart';
import '../../services/sessao.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../home_shell.dart';
import '../robo/robo_screen.dart';
import 'login_screen.dart';
import 'sem_acesso_screen.dart';

/// Porteiro do app: sem login -> tela de login; com login -> carrega o papel
/// do usuário no servidor e abre o app.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<User?> _estado;

  @override
  void initState() {
    super.initState();
    _estado = AuthService.estado;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _estado,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _TelaCarregando();
        }
        final usuario = snap.data;
        if (usuario == null) return LoginScreen();
        // A chave por uid garante que trocar de conta recarrega o perfil.
        return _CarregadorPerfil(key: ValueKey<String>(usuario.uid));
      },
    );
  }
}

class _CarregadorPerfil extends StatefulWidget {
  const _CarregadorPerfil({super.key});

  @override
  State<_CarregadorPerfil> createState() => _CarregadorPerfilState();
}

class _CarregadorPerfilState extends State<_CarregadorPerfil> {
  Perfil? _perfil;
  Object? _erro;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    if (!_carregando) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }
    try {
      // Se o usuário acabou de apertar "Entrar", espera o servidor registrar
      // o papel. Se a entrada falhou (ex.: senha errada), o login já foi
      // desfeito e esta tela some; não mostra erro nenhum.
      final pendente = AuthService.entradaEmAndamento;
      if (pendente != null) {
        try {
          await pendente;
        } catch (_) {
          return;
        }
      }
      final perfil = await HermesApi.instance.meuPerfil();
      Sessao.perfil.value = perfil;
      if (!mounted) return;
      setState(() {
        _perfil = perfil;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e;
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return _TelaCarregando();
    final erro = _erro;
    if (erro != null) return SemAcessoScreen(erro: erro, onTentarNovamente: _carregar);
    if (_perfil!.papel.ehRobo) return RoboScreen();
    return HomeShell(perfil: _perfil!);
  }
}

class _TelaCarregando extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('HERMES', style: AppTextStyles.screenTitle),
            const SizedBox(height: 18),
            CircularProgressIndicator(color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}
