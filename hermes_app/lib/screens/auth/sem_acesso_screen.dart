import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/erros.dart';
import '../../widgets/botao_secundario.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/theme_toggle_button.dart';

/// Mostrada quando o login deu certo mas o usuário não tem acesso ao módulo
/// (ou quando não foi possível carregar o perfil).
class SemAcessoScreen extends StatelessWidget {
  final Object erro;
  final VoidCallback onTentarNovamente;

  const SemAcessoScreen({super.key, required this.erro, required this.onTentarNovamente});

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
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline_rounded, color: AppColors.warning, size: 46),
                      const SizedBox(height: 16),
                      Text('Não foi possível entrar', style: AppTextStyles.screenTitle.copyWith(fontSize: 20)),
                      const SizedBox(height: 8),
                      Text(
                        mensagemDeErro(erro),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.screenSubtitle,
                      ),
                      const SizedBox(height: 26),
                      PrimaryButton(
                        label: 'Tentar de novo',
                        icon: Icons.refresh_rounded,
                        onPressed: onTentarNovamente,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: BotaoSecundario(
                          rotulo: 'Sair da conta',
                          icone: Icons.logout_rounded,
                          onPressed: AuthService.sair,
                        ),
                      ),
                    ],
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
