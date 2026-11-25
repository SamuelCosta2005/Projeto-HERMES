import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/local.dart';
import '../../services/hermes_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/botao_secundario.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/hermes_app_bar.dart';
import '../../widgets/primary_button.dart';

/// Admin: cadastrar ou editar um local de entrega (sala).
class LocalFormScreen extends StatefulWidget {
  final Local? local;

  const LocalFormScreen({super.key, this.local});

  @override
  State<LocalFormScreen> createState() => _LocalFormScreenState();
}

class _LocalFormScreenState extends State<LocalFormScreen> {
  late final TextEditingController _identificador;
  late final TextEditingController _unidade;
  late final TextEditingController _predio;
  late final TextEditingController _andar;
  late final TextEditingController _capacidade;
  bool _salvando = false;

  bool get _edicao => widget.local != null;

  @override
  void initState() {
    super.initState();
    final l = widget.local;
    _identificador = TextEditingController(text: l?.identificador ?? '');
    _unidade = TextEditingController(text: l?.unidade ?? '');
    _predio = TextEditingController(text: l?.predio ?? '');
    _andar = TextEditingController(text: l?.andar ?? '');
    _capacidade = TextEditingController(text: '${l?.capacidadeMaxima ?? 0}');
  }

  @override
  void dispose() {
    _identificador.dispose();
    _unidade.dispose();
    _predio.dispose();
    _andar.dispose();
    _capacidade.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final nome = _identificador.text.trim();
    final capacidade = int.tryParse(_capacidade.text.trim());
    if (nome.isEmpty) {
      mostrarAviso(context, 'Informe o nome do local.');
      return;
    }
    if (capacidade == null) {
      mostrarAviso(context, 'Informe a capacidade (pode ser 0).');
      return;
    }
    setState(() => _salvando = true);
    try {
      final atual = widget.local;
      if (atual == null) {
        await HermesApi.instance.criarLocal(
          unidade: _unidade.text,
          predio: _predio.text,
          andar: _andar.text,
          identificador: nome,
          capacidadeMaxima: capacidade,
        );
      } else {
        await HermesApi.instance.editarLocal(
          atual.id,
          unidade: _unidade.text,
          predio: _predio.text,
          andar: _andar.text,
          identificador: nome,
          capacidadeMaxima: capacidade,
        );
      }
      if (!mounted) return;
      mostrarAviso(context, _edicao ? 'Local atualizado.' : 'Local cadastrado.');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      mostrarErro(context, e);
    }
  }

  Future<void> _excluir() async {
    final atual = widget.local;
    if (atual == null) return;
    final sim = await confirmar(
      context,
      titulo: 'Excluir local?',
      mensagem: 'O local "${atual.identificador}" deixa de aparecer na escolha de sala. '
          'Pedidos antigos continuam mostrando o nome.',
      textoConfirmar: 'Excluir',
      destrutivo: true,
    );
    if (!sim || !mounted) return;
    setState(() => _salvando = true);
    try {
      await HermesApi.instance.excluirLocal(atual.id);
      if (!mounted) return;
      mostrarAviso(context, 'Local excluído.');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      mostrarErro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HermesAppBar(stageBadge: _edicao ? 'Editar local' : 'Novo local'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  CampoTexto(controller: _identificador, rotulo: 'Nome do local', dica: 'Ex.: Sala 101'),
                  const SizedBox(height: 12),
                  CampoTexto(controller: _unidade, rotulo: 'Unidade', dica: 'Ex.: São Gabriel'),
                  const SizedBox(height: 12),
                  CampoTexto(controller: _predio, rotulo: 'Prédio', dica: 'Ex.: Hub São Gabriel'),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: CampoTexto(controller: _andar, rotulo: 'Andar', dica: 'Térreo, 1º...')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CampoTexto(
                          controller: _capacidade,
                          rotulo: 'Capacidade',
                          teclado: TextInputType.number,
                          formatadores: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Atenção: esta lista é a mesma coleção de salas usada pelo SInergic. '
                    'Editar ou excluir aqui altera lá também.',
                    style: AppTextStyles.cardSubtitle.copyWith(color: AppColors.textMuted),
                  ),
                  if (_edicao) ...[
                    const SizedBox(height: 18),
                    BotaoSecundario(
                      rotulo: 'Excluir local',
                      icone: Icons.delete_outline_rounded,
                      destrutivo: true,
                      onPressed: _salvando ? null : _excluir,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: PrimaryButton(
                label: _edicao ? 'Salvar alterações' : 'Cadastrar local',
                icon: Icons.check_rounded,
                isLoading: _salvando,
                onPressed: _salvar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
