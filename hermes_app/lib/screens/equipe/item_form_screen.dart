import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/categoria.dart';
import '../../models/item_estoque.dart';
import '../../services/hermes_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_card.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/hermes_app_bar.dart';
import '../../widgets/icone_quadrado.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_label.dart';

/// Admin: cadastrar um item novo ou editar um existente.
/// Quantidades não se editam aqui (estoque só muda por entrada, contagem, baixa
/// ou pelo fluxo de pedidos), para o livro de movimentações sempre bater.
class ItemFormScreen extends StatefulWidget {
  final ItemEstoque? item;

  const ItemFormScreen({super.key, this.item});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  late final TextEditingController _nome;
  late final TextEditingController _unidade;
  late final TextEditingController _minimo;
  late final TextEditingController _inicial;
  late Categoria _categoria;
  late bool _retornavel;
  bool _salvando = false;

  bool get _edicao => widget.item != null;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _nome = TextEditingController(text: i?.nome ?? '');
    _unidade = TextEditingController(text: i?.unidade ?? 'un');
    _minimo = TextEditingController(text: '${i?.estoqueMinimo ?? 0}');
    _inicial = TextEditingController(text: '0');
    _categoria = i?.categoria ?? Categoria.ti;
    _retornavel = i?.retornavel ?? true;
  }

  @override
  void dispose() {
    _nome.dispose();
    _unidade.dispose();
    _minimo.dispose();
    _inicial.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final nome = _nome.text.trim();
    final unidade = _unidade.text.trim().isEmpty ? 'un' : _unidade.text.trim();
    final minimo = int.tryParse(_minimo.text.trim());
    final inicial = int.tryParse(_inicial.text.trim());

    if (nome.isEmpty) {
      mostrarAviso(context, 'Informe o nome do item.');
      return;
    }
    if (minimo == null) {
      mostrarAviso(context, 'Informe o estoque mínimo (pode ser 0).');
      return;
    }
    if (!_edicao && inicial == null) {
      mostrarAviso(context, 'Informe o estoque inicial (pode ser 0).');
      return;
    }

    final atual = widget.item;
    if (atual != null &&
        nome == atual.nome &&
        unidade == atual.unidade &&
        minimo == atual.estoqueMinimo &&
        _categoria == atual.categoria &&
        _retornavel == atual.retornavel) {
      mostrarAviso(context, 'Nada para salvar.');
      return;
    }

    setState(() => _salvando = true);
    try {
      if (atual == null) {
        await HermesApi.instance.criarItem(
          nome: nome,
          categoria: _categoria,
          retornavel: _retornavel,
          estoqueInicial: inicial ?? 0,
          estoqueMinimo: minimo,
          unidade: unidade,
        );
      } else {
        await HermesApi.instance.editarItem(
          atual.id,
          nome: nome == atual.nome ? null : nome,
          categoria: _categoria == atual.categoria ? null : _categoria,
          retornavel: _retornavel == atual.retornavel ? null : _retornavel,
          estoqueMinimo: minimo == atual.estoqueMinimo ? null : minimo,
          unidade: unidade == atual.unidade ? null : unidade,
        );
      }
      if (!mounted) return;
      mostrarAviso(context, _edicao ? 'Item atualizado.' : 'Item cadastrado.');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      mostrarErro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final emUso = widget.item?.emUso ?? 0;
    final bloqueiaRetornavel = _edicao && emUso > 0;

    return Scaffold(
      appBar: HermesAppBar(stageBadge: _edicao ? 'Editar item' : 'Novo item'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  CampoTexto(controller: _nome, rotulo: 'Nome do item', dica: 'Ex.: Cabo Ethernet Cat6 5m'),
                  const SizedBox(height: 18),
                  SectionLabel('Categoria'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final c in Categoria.values) ...[
                        Expanded(
                          child: AppCard(
                            onTap: () => setState(() => _categoria = c),
                            borderColor: c == _categoria ? AppColors.accent : AppColors.border,
                            backgroundColor: c == _categoria ? AppColors.accentBackground : AppColors.surface,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Row(
                              children: [
                                IconeQuadrado(icone: c.icone, destaque: c == _categoria, tamanho: 30),
                                const SizedBox(width: 10),
                                Expanded(child: Text(c.nome, style: AppTextStyles.cardTitle)),
                              ],
                            ),
                          ),
                        ),
                        if (c != Categoria.values.last) const SizedBox(width: 10),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('Item retornável', style: AppTextStyles.cardTitle)),
                            Switch(
                              value: _retornavel,
                              activeTrackColor: AppColors.accent,
                              onChanged: bloqueiaRetornavel ? null : (v) => setState(() => _retornavel = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _retornavel
                              ? 'Vira empréstimo e precisa ser devolvido ao suporte técnico.'
                              : 'Consumível: a baixa no estoque é definitiva na entrega.',
                          style: AppTextStyles.cardSubtitle,
                        ),
                        if (bloqueiaRetornavel) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Há $emUso unidade(s) em uso (reservadas ou emprestadas): não dá para mudar isto agora.',
                            style: AppTextStyles.cardSubtitle.copyWith(color: AppColors.warning),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (!_edicao) ...[
                    CampoTexto(
                      controller: _inicial,
                      rotulo: 'Estoque inicial',
                      teclado: TextInputType.number,
                      formatadores: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CampoTexto(
                          controller: _minimo,
                          rotulo: 'Estoque mínimo',
                          teclado: TextInputType.number,
                          formatadores: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CampoTexto(controller: _unidade, rotulo: 'Unidade', dica: 'un, cx, m...'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _edicao
                        ? 'Para mudar quantidades use as ações de estoque (entrada, contagem física ou baixa).'
                        : 'O estoque inicial entra no histórico como "Carga inicial".',
                    style: AppTextStyles.cardSubtitle,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: PrimaryButton(
                label: _edicao ? 'Salvar alterações' : 'Cadastrar item',
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
