import 'package:flutter/material.dart';
import '../../data/locais_repository.dart';
import '../../models/categoria.dart';
import '../../models/linha_selecionada.dart';
import '../../models/local.dart';
import '../../services/hermes_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/andares.dart';
import '../../utils/icones.dart';
import '../../widgets/app_card.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/estados.dart';
import '../../widgets/hermes_app_bar.dart';
import '../../widgets/icone_quadrado.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_label.dart';
import 'order_approved_screen.dart';

/// Tela 2 do fluxo: escolher a sala de destino e criar o pedido.
class SelectRoomScreen extends StatefulWidget {
  final Categoria categoria;
  final List<LinhaSelecionada> linhas;

  const SelectRoomScreen({super.key, required this.categoria, required this.linhas});

  @override
  State<SelectRoomScreen> createState() => _SelectRoomScreenState();
}

class _SelectRoomScreenState extends State<SelectRoomScreen> {
  final _buscaCtrl = TextEditingController();
  List<Local> _locais = [];
  Local? _selecionado;
  Object? _erro;
  bool _carregando = true;
  bool _enviando = false;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final locais = await LocaisRepository().buscar();
      locais.sort((a, b) {
        final porAndar = ordemAndar(a.andar).compareTo(ordemAndar(b.andar));
        return porAndar != 0 ? porAndar : a.identificador.compareTo(b.identificador);
      });
      if (!mounted) return;
      setState(() {
        _locais = locais;
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

  Future<void> _confirmar() async {
    final local = _selecionado;
    if (local == null || _enviando) return;
    setState(() => _enviando = true);
    try {
      final criado = await HermesApi.instance.criarPedido(
        categoria: widget.categoria,
        linhas: widget.linhas,
        localId: local.id,
      );
      if (!mounted) return;
      // Troca esta tela pela de aprovação; o `true` avisa a tela de materiais
      // que o pedido foi criado (ela limpa a seleção).
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => OrderApprovedScreen(pedidoId: criado.pedidoId)),
        result: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      mostrarErro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busca = _busca.trim().toLowerCase();
    final filtrados = _locais
        .where((l) =>
            busca.isEmpty ||
            l.identificador.toLowerCase().contains(busca) ||
            l.predio.toLowerCase().contains(busca))
        .toList();

    final grupos = <String, List<Local>>{};
    for (final l in filtrados) {
      grupos.putIfAbsent(l.andar, () => <Local>[]).add(l);
    }

    return Scaffold(
      appBar: HermesAppBar(stageBadge: 'Destino'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: _carregando
                  ? EstadoCarregando()
                  : _erro != null
                      ? EstadoErro(erro: _erro!, onTentarNovamente: _carregar)
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                          children: [
                            Text('Selecione a Sala', style: AppTextStyles.screenTitle),
                            const SizedBox(height: 6),
                            Text(
                              'Escolha o local de destino para a entrega dos materiais.',
                              style: AppTextStyles.screenSubtitle,
                            ),
                            const SizedBox(height: 20),
                            SectionLabel('Buscar no terminal'),
                            const SizedBox(height: 8),
                            CampoTexto(
                              controller: _buscaCtrl,
                              dica: 'Ex: Sala 101, Almoxarifado...',
                              icone: Icons.search_rounded,
                              onChanged: (v) => setState(() => _busca = v),
                            ),
                            const SizedBox(height: 20),
                            if (filtrados.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text('Nenhuma sala encontrada.', style: AppTextStyles.cardSubtitle),
                                ),
                              ),
                            for (final andar in grupos.keys) ...[
                              SectionLabel(rotuloAndar(andar)),
                              const SizedBox(height: 10),
                              for (final local in grupos[andar]!)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _LocalTile(
                                    local: local,
                                    selecionado: local.id == _selecionado?.id,
                                    onTap: () => setState(() => _selecionado = local),
                                  ),
                                ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: PrimaryButton(
                label: 'Confirmar Destino',
                icon: Icons.check_rounded,
                isLoading: _enviando,
                onPressed: _selecionado == null ? null : _confirmar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalTile extends StatelessWidget {
  final Local local;
  final bool selecionado;
  final VoidCallback onTap;

  const _LocalTile({required this.local, required this.selecionado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      borderColor: selecionado ? AppColors.accent : AppColors.border,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          IconeQuadrado(icone: iconeLocal(local.identificador), destaque: selecionado),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(local.identificador, style: AppTextStyles.cardTitle),
                if (local.detalhe.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(local.detalhe, style: AppTextStyles.cardSubtitle),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _Radio(selecionado: selecionado),
        ],
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final bool selecionado;

  const _Radio({required this.selecionado});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selecionado ? AppColors.accent : AppColors.border, width: 1.6),
      ),
      child: selecionado
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
              ),
            )
          : null,
    );
  }
}
