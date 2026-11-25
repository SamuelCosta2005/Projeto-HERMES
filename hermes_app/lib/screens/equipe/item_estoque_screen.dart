import 'package:flutter/material.dart';
import '../../data/estoque_repository.dart';
import '../../models/item_estoque.dart';
import '../../services/hermes_api.dart';
import '../../services/sessao.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/icones.dart';
import '../../widgets/app_card.dart';
import '../../widgets/botao_secundario.dart';
import '../../widgets/chip_rotulo.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/estados.dart';
import '../../widgets/hermes_app_bar.dart';
import '../../widgets/icone_quadrado.dart';
import '../../widgets/section_label.dart';
import 'acao_estoque_sheet.dart';
import 'item_form_screen.dart';
import 'movimentacoes_screen.dart';

/// Detalhe de um item: contadores e ações de estoque (entrada, contagem, baixa).
/// O admin também edita, ativa/desativa e vê o histórico do item.
class ItemEstoqueScreen extends StatefulWidget {
  final String itemId;

  const ItemEstoqueScreen({super.key, required this.itemId});

  @override
  State<ItemEstoqueScreen> createState() => _ItemEstoqueScreenState();
}

class _ItemEstoqueScreenState extends State<ItemEstoqueScreen> {
  late final Stream<ItemEstoque?> _item;
  bool _alterandoAtivo = false;

  bool get _admin => Sessao.atual?.papel.ehAdmin ?? false;

  @override
  void initState() {
    super.initState();
    _item = EstoqueRepository().watchItem(widget.itemId);
  }

  Future<void> _acao(ItemEstoque item, AcaoEstoque acao) async {
    final mensagem = await mostrarAcaoEstoque(context, item, acao);
    if (mensagem != null && mounted) mostrarAviso(context, mensagem);
  }

  Future<void> _alternarAtivo(ItemEstoque item) async {
    final desativar = item.ativo;
    final ok = await confirmar(
      context,
      titulo: desativar ? 'Desativar item?' : 'Reativar item?',
      mensagem: desativar
          ? 'O item some do catálogo de pedidos. O histórico é mantido.'
          : 'O item volta a aparecer no catálogo de pedidos.',
      textoConfirmar: desativar ? 'Desativar' : 'Reativar',
      destrutivo: desativar,
    );
    if (!ok || !mounted) return;
    setState(() => _alterandoAtivo = true);
    try {
      await HermesApi.instance.definirItemAtivo(item.id, !item.ativo);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _alterandoAtivo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HermesAppBar(stageBadge: 'Item'),
      body: SafeArea(
        top: false,
        child: StreamBuilder<ItemEstoque?>(
          stream: _item,
          builder: (context, snap) {
            if (snap.hasError) return EstadoErro(erro: snap.error!);
            if (snap.connectionState == ConnectionState.waiting) return EstadoCarregando();
            final item = snap.data;
            if (item == null) {
              return EstadoVazio(icone: Icons.search_off_rounded, titulo: 'Item não encontrado');
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                AppCard(
                  child: Row(
                    children: [
                      IconeQuadrado(icone: iconeItem(item.nome), tamanho: 44),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.nome, style: AppTextStyles.cardTitle.copyWith(fontSize: 17)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                ChipRotulo(
                                  texto: item.categoria.nome,
                                  cor: AppColors.accent,
                                  fundo: AppColors.accentBackground,
                                ),
                                ChipRotulo(
                                  texto: item.retornavel ? 'Retornável' : 'Consumível',
                                  cor: AppColors.textSecondary,
                                  fundo: AppColors.surfaceAlt,
                                ),
                                if (!item.ativo)
                                  ChipRotulo(
                                    texto: 'Inativo',
                                    cor: AppColors.textMuted,
                                    fundo: AppColors.surfaceAlt,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _Contador(rotulo: 'Total', valor: item.estoqueTotal)),
                    const SizedBox(width: 10),
                    Expanded(child: _Contador(rotulo: 'Em uso', valor: item.emUso)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Contador(rotulo: 'Disponível', valor: item.disponivel, destaque: true),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Estoque mínimo: ${item.estoqueMinimo} ${item.unidade}',
                      style: AppTextStyles.cardSubtitle,
                    ),
                    const SizedBox(width: 8),
                    if (item.estoqueBaixo)
                      ChipRotulo(
                        texto: 'Estoque baixo',
                        cor: AppColors.warning,
                        fundo: AppColors.warningBackground,
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                SectionLabel('Ações de estoque'),
                const SizedBox(height: 10),
                BotaoSecundario(
                  rotulo: 'Entrada (chegou reposição)',
                  icone: Icons.add_box_rounded,
                  onPressed: () => _acao(item, AcaoEstoque.entrada),
                ),
                const SizedBox(height: 10),
                BotaoSecundario(
                  rotulo: 'Contagem física',
                  icone: Icons.fact_check_rounded,
                  onPressed: () => _acao(item, AcaoEstoque.ajuste),
                ),
                const SizedBox(height: 10),
                BotaoSecundario(
                  rotulo: 'Baixa (quebrou, venceu, sumiu)',
                  icone: Icons.remove_circle_rounded,
                  destrutivo: true,
                  onPressed: () => _acao(item, AcaoEstoque.baixa),
                ),
                if (_admin) ...[
                  const SizedBox(height: 22),
                  SectionLabel('Administração do catálogo'),
                  const SizedBox(height: 10),
                  BotaoSecundario(
                    rotulo: 'Editar item',
                    icone: Icons.edit_rounded,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => ItemFormScreen(item: item)),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  BotaoSecundario(
                    rotulo: item.ativo ? 'Desativar item' : 'Reativar item',
                    icone: item.ativo ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    destrutivo: item.ativo,
                    carregando: _alterandoAtivo,
                    onPressed: () => _alternarAtivo(item),
                  ),
                  const SizedBox(height: 10),
                  BotaoSecundario(
                    rotulo: 'Histórico de movimentações',
                    icone: Icons.history_rounded,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => MovimentacoesScreen(itemId: item.id, titulo: item.nome),
                        ),
                      );
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Contador extends StatelessWidget {
  final String rotulo;
  final int valor;
  final bool destaque;

  const _Contador({required this.rotulo, required this.valor, this.destaque = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: destaque ? AppColors.accentBackground : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: destaque ? AppColors.accent : AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            '$valor',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: destaque ? AppColors.accent : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(rotulo, style: AppTextStyles.cardSubtitle),
        ],
      ),
    );
  }
}
