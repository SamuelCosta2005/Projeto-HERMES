import 'package:flutter/material.dart';
import '../../data/estoque_repository.dart';
import '../../models/item_estoque.dart';
import '../../services/sessao.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/icones.dart';
import '../../widgets/app_card.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/chip_rotulo.dart';
import '../../widgets/estados.dart';
import '../../widgets/hermes_app_bar.dart';
import '../../widgets/icone_quadrado.dart';
import '../../widgets/primary_button.dart';
import 'item_estoque_screen.dart';
import 'item_form_screen.dart';
import 'locais_screen.dart';
import 'movimentacoes_screen.dart';

/// Equipe: estoque em tempo real. Técnico e admin fazem entrada, contagem e baixa;
/// o admin também cadastra itens e vê o histórico de movimentações.
class EstoqueScreen extends StatefulWidget {
  const EstoqueScreen({super.key});

  @override
  State<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> {
  late final Stream<List<ItemEstoque>> _itens;
  final _buscaCtrl = TextEditingController();
  String _busca = '';

  bool get _admin => Sessao.atual?.papel.ehAdmin ?? false;

  @override
  void initState() {
    super.initState();
    _itens = EstoqueRepository().watchItens();
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HermesAppBar(stageBadge: 'Estoque'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
              child: Row(
                children: [
                  Expanded(child: Text('Estoque', style: AppTextStyles.screenTitle)),
                  if (_admin)
                    IconButton(
                      tooltip: 'Locais',
                      icon: Icon(Icons.meeting_room_outlined, color: AppColors.accent),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => LocaisScreen()),
                        );
                      },
                    ),
                  if (_admin)
                    IconButton(
                      tooltip: 'Movimentações',
                      icon: Icon(Icons.history_rounded, color: AppColors.accent),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => MovimentacoesScreen()),
                        );
                      },
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: CampoTexto(
                controller: _buscaCtrl,
                dica: 'Buscar item...',
                icone: Icons.search_rounded,
                onChanged: (v) => setState(() => _busca = v),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ItemEstoque>>(
                stream: _itens,
                builder: (context, snap) {
                  if (snap.hasError) return EstadoErro(erro: snap.error!);
                  if (!snap.hasData) return EstadoCarregando();
                  final busca = _busca.trim().toLowerCase();
                  final lista = snap.data!
                      .where((i) => _admin || i.ativo)
                      .where((i) => busca.isEmpty || i.nome.toLowerCase().contains(busca))
                      .toList();
                  if (lista.isEmpty) {
                    return EstadoVazio(
                      icone: Icons.inventory_2_outlined,
                      titulo: 'Nenhum item encontrado',
                      subtitulo: _admin ? 'Use "Novo Item" para cadastrar.' : null,
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    children: [
                      for (final item in lista)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _CartaoItem(
                            item: item,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ItemEstoqueScreen(itemId: item.id),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            if (_admin)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: PrimaryButton(
                  label: 'Novo Item',
                  icon: Icons.add_rounded,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => ItemFormScreen()),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CartaoItem extends StatelessWidget {
  final ItemEstoque item;
  final VoidCallback onTap;

  const _CartaoItem({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          IconeQuadrado(icone: iconeItem(item.nome)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nome, style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text(
                  'Disponível ${item.disponivel} · Total ${item.estoqueTotal} · Em uso ${item.emUso}',
                  style: AppTextStyles.cardSubtitle,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ChipRotulo(
                      texto: item.retornavel ? 'Retornável' : 'Consumível',
                      cor: AppColors.textSecondary,
                      fundo: AppColors.surfaceAlt,
                    ),
                    if (item.estoqueBaixo)
                      ChipRotulo(
                        texto: 'Estoque baixo',
                        cor: AppColors.warning,
                        fundo: AppColors.warningBackground,
                      ),
                    if (!item.ativo)
                      ChipRotulo(texto: 'Inativo', cor: AppColors.textMuted, fundo: AppColors.surfaceAlt),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
