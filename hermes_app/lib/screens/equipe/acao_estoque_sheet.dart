import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/item_estoque.dart';
import '../../services/hermes_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/erros.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/primary_button.dart';

enum AcaoEstoque { entrada, ajuste, baixa }

/// Abre a folha da ação. Devolve a mensagem de sucesso (para o chamador mostrar)
/// ou null se o usuário fechou sem concluir.
Future<String?> mostrarAcaoEstoque(BuildContext context, ItemEstoque item, AcaoEstoque acao) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AcaoSheet(item: item, acao: acao),
  );
}

class _AcaoSheet extends StatefulWidget {
  final ItemEstoque item;
  final AcaoEstoque acao;

  const _AcaoSheet({required this.item, required this.acao});

  @override
  State<_AcaoSheet> createState() => _AcaoSheetState();
}

class _AcaoSheetState extends State<_AcaoSheet> {
  final _quantidade = TextEditingController();
  final _motivo = TextEditingController();
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _quantidade.dispose();
    _motivo.dispose();
    super.dispose();
  }

  AcaoEstoque get _acao => widget.acao;
  bool get _motivoObrigatorio => _acao != AcaoEstoque.entrada;

  String get _titulo {
    switch (_acao) {
      case AcaoEstoque.entrada:
        return 'Entrada de estoque';
      case AcaoEstoque.ajuste:
        return 'Contagem física';
      case AcaoEstoque.baixa:
        return 'Baixa de estoque';
    }
  }

  String get _ajuda {
    switch (_acao) {
      case AcaoEstoque.entrada:
        return 'Some ao estoque as unidades que acabaram de chegar.';
      case AcaoEstoque.ajuste:
        return 'Conte as unidades que estão no depósito agora. As que estão emprestadas '
            'não entram na conta. O sistema corrige a diferença e registra o motivo.';
      case AcaoEstoque.baixa:
        return 'Só dá para dar baixa no que está disponível (${widget.item.disponivel} agora). '
            'Itens reservados ou emprestados seguem outro caminho.';
    }
  }

  String get _rotuloQuantidade {
    switch (_acao) {
      case AcaoEstoque.entrada:
        return 'Quantidade que chegou';
      case AcaoEstoque.ajuste:
        return 'Unidades encontradas no depósito';
      case AcaoEstoque.baixa:
        return 'Quantidade a baixar';
    }
  }

  String get _rotuloBotao {
    switch (_acao) {
      case AcaoEstoque.entrada:
        return 'Registrar entrada';
      case AcaoEstoque.ajuste:
        return 'Aplicar contagem';
      case AcaoEstoque.baixa:
        return 'Registrar baixa';
    }
  }

  Future<void> _enviar() async {
    final valor = int.tryParse(_quantidade.text.trim());
    final motivo = _motivo.text.trim();

    if (valor == null) {
      setState(() => _erro = 'Informe uma quantidade.');
      return;
    }
    if (_acao != AcaoEstoque.ajuste && valor < 1) {
      setState(() => _erro = 'A quantidade precisa ser maior que zero.');
      return;
    }
    if (_motivoObrigatorio && motivo.isEmpty) {
      setState(() => _erro = 'Informe o motivo.');
      return;
    }

    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      String mensagem;
      switch (_acao) {
        case AcaoEstoque.entrada:
          await HermesApi.instance.entradaEstoque(
            itemId: widget.item.id,
            quantidade: valor,
            motivo: motivo,
          );
          mensagem = 'Entrada de $valor registrada.';
          break;
        case AcaoEstoque.ajuste:
          final r = await HermesApi.instance.ajusteEstoque(
            itemId: widget.item.id,
            contagemFisica: valor,
            motivo: motivo,
          );
          mensagem = r.semDiferenca
              ? 'Contagem confere: nenhuma diferença.'
              : 'Estoque ajustado (${r.delta > 0 ? '+' : ''}${r.delta}). Total agora: ${r.estoqueTotal}.';
          break;
        case AcaoEstoque.baixa:
          await HermesApi.instance.baixaEstoque(
            itemId: widget.item.id,
            quantidade: valor,
            motivo: motivo,
          );
          mensagem = 'Baixa de $valor registrada.';
          break;
      }
      if (!mounted) return;
      Navigator.of(context).pop(mensagem);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _erro = mensagemDeErro(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.border),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_titulo, style: AppTextStyles.cardTitle.copyWith(fontSize: 16)),
              const SizedBox(height: 4),
              Text(widget.item.nome, style: AppTextStyles.cardSubtitle),
              const SizedBox(height: 10),
              Text(_ajuda, style: AppTextStyles.cardSubtitle),
              const SizedBox(height: 16),
              CampoTexto(
                controller: _quantidade,
                rotulo: _rotuloQuantidade,
                teclado: TextInputType.number,
                formatadores: [FilteringTextInputFormatter.digitsOnly],
                autofoco: true,
              ),
              const SizedBox(height: 12),
              CampoTexto(
                controller: _motivo,
                rotulo: _motivoObrigatorio ? 'Motivo' : 'Motivo / nota fiscal (opcional)',
                dica: _acao == AcaoEstoque.entrada ? 'Ex.: compra NF 123' : 'Ex.: inventário mensal',
              ),
              if (_erro != null) ...[
                const SizedBox(height: 10),
                Text(_erro!, style: AppTextStyles.cardSubtitle.copyWith(color: AppColors.warning)),
              ],
              const SizedBox(height: 18),
              PrimaryButton(
                label: _rotuloBotao,
                icon: Icons.check_rounded,
                isLoading: _enviando,
                color: _acao == AcaoEstoque.baixa ? AppColors.warning : null,
                onPressed: _enviar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
