import '../../config.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/erros.dart';
import '../../widgets/botao_secundario.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/theme_toggle_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _entrando = false;
  String? _erro;

  Future<void> _entrar({String? senha}) async {
    setState(() {
      _entrando = true;
      _erro = null;
    });
    try {
      await AuthService.entrar(senha: senha);
      // Sucesso: o AuthGate troca de tela sozinho.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = mensagemDeErro(e);
        _entrando = false;
      });
      return;
    }
    if (mounted) setState(() => _entrando = false);
  }

  Future<void> _entrarComSenha(String titulo) async {
    final senha = await showDialog<String>(
      context: context,
      builder: (ctx) => _DialogSenha(titulo: titulo),
    );
    if (senha == null || senha.isEmpty) return;
    await _entrar(senha: senha);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
              child: Row(children: [const Spacer(), ThemeToggleButton()]),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.accent, width: 1.6),
                              color: AppColors.accentBackground,
                            ),
                            child: Icon(Icons.inventory_2_outlined, color: AppColors.accent, size: 32),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text('HERMES', textAlign: TextAlign.center, style: AppTextStyles.screenTitle),
                        const SizedBox(height: 6),
                        Text(
                          'Peça e acompanhe materiais entregues pelo robô.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.screenSubtitle,
                        ),
                        const SizedBox(height: 32),
                        PrimaryButton(
                          label: 'Entrar',
                          icon: Icons.login_rounded,
                          isLoading: _entrando,
                          onPressed: _entrando ? null : () => _entrar(),
                        ),
                        if (_erro != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _erro!,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.cardSubtitle.copyWith(color: AppColors.warning),
                          ),
                        ],
                        const SizedBox(height: 14),
                        BotaoSecundario(
                          rotulo: 'Sou do suporte técnico',
                          icone: Icons.lock_outline_rounded,
                          onPressed: _entrando ? null : () => _entrar(senha: kSenhaAdmin),
                        ),
                        const SizedBox(height: 10),
                        BotaoSecundario(
                          rotulo: 'Sou o robô',
                          icone: Icons.smart_toy_outlined,
                          onPressed: _entrando ? null : () => _entrar(senha: kSenhaRobo),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pede a senha do admin. Devolve o texto digitado (ou null se cancelar).
class _DialogSenha extends StatefulWidget {
  final String titulo;

  const _DialogSenha({required this.titulo});

  @override
  State<_DialogSenha> createState() => _DialogSenhaState();
}

class _DialogSenhaState extends State<_DialogSenha> {
  final _senha = TextEditingController();

  @override
  void dispose() {
    _senha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.titulo, style: AppTextStyles.cardTitle.copyWith(fontSize: 16)),
      content: CampoTexto(
        controller: _senha,
        rotulo: 'Senha',
        icone: Icons.lock_outline_rounded,
        obscuro: true,
        autofoco: true,
        teclado: TextInputType.number,
        acao: TextInputAction.done,
        onEnviar: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: AppTextStyles.body),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_senha.text),
          child: Text(
            'Entrar',
            style: AppTextStyles.body.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
