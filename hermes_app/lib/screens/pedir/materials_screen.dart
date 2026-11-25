import 'package:flutter/material.dart';
import '../../data/estoque_repository.dart';
import '../../models/categoria.dart';
import '../../models/item_estoque.dart';
import '../../models/linha_selecionada.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatadores.dart';
import '../../utils/icones.dart';
import '../../widgets/app_card.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/chip_rotulo.dart';
import '../../widgets/estados.dart';
import '../../widgets/hermes_app_bar.dart';
import '../../widgets/icone_quadrado.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_label.dart';
import '../../widgets/stepper_quantidade.dart';
import 'select_room_screen.dart';

/// Tela 1 do fluxo: escolher categoria, itens e quantidades (estoque em tempo real).
class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  late final Stream<List<ItemEstoque>> _itens;
  final _buscaCtrl = TextEditingController();
  final Map<String, int> _qtd = {};
  Categoria _categoria = Categoria.ti;
  String _busca = '';

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

  int _quantidadeDe(ItemEstoque i) => limitar(_qtd[i.id] ?? 0, 0, i.disponivel);

  List<LinhaSelecionada> _selecionadas(List<ItemEstoque> todos) {
    final linhas = <LinhaSelecionada>[];
    for (final i in todos) {
      if (!i.ativo || i.categoria != _categoria) continue;
      final q = _quantidadeDe(i);
      if (q > 0) linhas.add(LinhaSelecionada(item: i, quantidade: q));
    }
    return linhas;
  }

  int _contarSelecionados(List<ItemEstoque> todos, Categoria c) {
    var n = 0;
    for (final i in todos) {
      if (i.ativo && i.categoria == c && _quantidadeDe(i) > 0) n++;
    }
    return n;
  }

  void _mudar(ItemEstoque item, int delta) {
    setState(() => _qtd[item.id] = limitar(_quantidadeDe(item) + delta, 0, item.disponivel));
  }

  Future<void> _solicitar(List<ItemEstoque> todos) async {
    final linhas = _selecionadas(todos);
    if (linhas.isEmpty) return;
    final criou = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SelectRoomScreen(categoria: _categoria, linhas: linhas),
      ),
    );
    // Pedido criado: limpa a seleção para o próximo.
    if (criou == true && mounted) setState(() => _qtd.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HermesAppBar(stageBadge: 'Selecionar'),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<ItemEstoque>>(
          stream: _itens,
          builder: (context, snap) {
            if (snap.hasError) return EstadoErro(erro: snap.error!);
            if (!snap.hasData) return EstadoCarregando();

            final todos = snap.data!;
            final busca = _busca.trim().toLowerCase();
            final visiveis = todos
                .where((i) => i.ativo && i.categoria == _categoria)
                .where((i) => busca.isEmpty || i.nome.toLowerCase().contains(busca))
                .toList();
            final selecionadas = _selecionadas(todos);

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    children: [
                      Row(
                        children: [
                          for (final c in Categoria.values) ...[
                            Expanded(
                              child: _CategoriaCard(
                                categoria: c,
                                selecionada: c == _categoria,
                                selecionados: _contarSelecionados(todos, c),
                                onTap: () => setState(() => _categoria = c),
                              ),
                            ),
                            if (c != Categoria.values.last) const SizedBox(width: 12),
                          ],
                        ],
                      ),
                      const SizedBox(height: 22),
                      SectionLabel('Buscar no estoque'),
                      const SizedBox(height: 8),
                      CampoTexto(
                        controller: _buscaCtrl,
                        dica: 'Ex: Cabo HDMI, Teclado, Parafuso M8...',
                        icone: Icons.search_rounded,
                        onChanged: (v) => setState(() => _busca = v),
                      ),
                      const SizedBox(height: 22),
                      SectionLabel('Itens disponíveis'),
                      const SizedBox(height: 10),
                      if (visiveis.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text('Nenhum item encontrado.', style: AppTextStyles.cardSubtitle),
                          ),
                        )
                      else
                        for (final item in visiveis)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _LinhaItem(
                              item: item,
                              quantidade: _quantidadeDe(item),
                              onMenos: () => _mudar(item, -1),
                              onMais: () => _mudar(item, 1),
                            ),
                          ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: PrimaryButton(
                    label: selecionadas.isEmpty
                        ? 'Solicitar Entrega'
                        : 'Solicitar Entrega (${selecionadas.length})',
                    icon: Icons.local_shipping_rounded,
                    onPressed: selecionadas.isEmpty ? null : () => _solicitar(todos),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoriaCard extends StatelessWidget {
  final Categoria categoria;
  final bool selecionada;
  final int selecionados;
  final VoidCallback onTap;

  const _CategoriaCard({
    required this.categoria,
    required this.selecionada,
    required this.selecionados,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      borderColor: selecionada ? AppColors.accent : AppColors.border,
      backgroundColor: selecionada ? AppColors.accentBackground : AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconeQuadrado(icone: categoria.icone, destaque: selecionada),
              const Spacer(),
              if (selecionados > 0)
                ChipRotulo(
                  texto: '$selecionados',
                  cor: AppColors.background,
                  fundo: AppColors.accent,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(categoria.nome, style: AppTextStyles.cardTitle),
          const SizedBox(height: 2),
          Text(
            categoria.subtitulo,
            style: AppTextStyles.cardSubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LinhaItem extends StatelessWidget {
  final ItemEstoque item;
  final int quantidade;
  final VoidCallback onMenos;
  final VoidCallback onMais;

  const _LinhaItem({
    required this.item,
    required this.quantidade,
    required this.onMenos,
    required this.onMais,
  });

  @override
  Widget build(BuildContext context) {
    final indisponivel = item.disponivel <= 0;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          IconeQuadrado(icone: iconeItem(item.nome)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nome, style: AppTextStyles.cardTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      indisponivel ? 'Indisponível' : 'Estoque: ${item.disponivel} ${item.unidade}',
                      style: AppTextStyles.cardSubtitle.copyWith(
                        color: indisponivel ? AppColors.warning : AppColors.textSecondary,
                      ),
                    ),
                    if (item.retornavel)
                      ChipRotulo(
                        texto: 'Retornável',
                        cor: AppColors.accent,
                        fundo: AppColors.accentBackground,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!indisponivel)
            StepperQuantidade(
              valor: quantidade,
              onMenos: quantidade > 0 ? onMenos : null,
              onMais: quantidade < item.disponivel ? onMais : null,
            ),
        ],
      ),
    );
  }
}
