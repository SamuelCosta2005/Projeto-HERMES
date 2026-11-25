import 'package:flutter/material.dart';
import '../models/perfil.dart';
import '../theme/app_colors.dart';
import 'equipe/emprestimos_screen.dart';
import 'equipe/entregas_screen.dart';
import 'equipe/estoque_screen.dart';
import 'meus_itens_screen.dart';
import 'pedir/materials_screen.dart';

class _Aba {
  final String rotulo;
  final IconData icone;
  final Widget Function() construir;

  _Aba(this.rotulo, this.icone, this.construir);
}

/// Navegação por abas. Todos veem "Pedir" e "Meus itens"; técnico e admin
/// também veem "Entregas", "Empréstimos" e "Estoque" (o admin ganha, dentro de
/// Estoque, as ações de catálogo e o histórico de movimentações).
class HomeShell extends StatefulWidget {
  final Perfil perfil;

  const HomeShell({super.key, required this.perfil});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _indice = 0;
  late final List<_Aba> _abas;

  @override
  void initState() {
    super.initState();
    _abas = [
      _Aba('Pedir', Icons.add_shopping_cart_rounded, () => MaterialsScreen()),
      _Aba('Meus itens', Icons.inventory_2_rounded, () => MeusItensScreen()),
      if (widget.perfil.papel.ehEquipe) ...[
        _Aba('Entregas', Icons.local_shipping_rounded, () => EntregasScreen()),
        _Aba('Empréstimos', Icons.swap_horiz_rounded, () => EmprestimosScreen()),
        _Aba('Estoque', Icons.category_rounded, () => EstoqueScreen()),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    // As páginas são criadas de novo a cada build (sem reaproveitar a mesma
    // instância): widget reaproveitado "congela" na troca de tema claro/escuro.
    final paginas = _abas.map((a) => a.construir()).toList();

    return Scaffold(
      body: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: IndexedStack(index: _indice, children: paginas),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                for (var i = 0; i < _abas.length; i++)
                  _ItemNav(
                    icone: _abas[i].icone,
                    rotulo: _abas[i].rotulo,
                    selecionado: i == _indice,
                    onTap: () => setState(() => _indice = i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemNav extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final bool selecionado;
  final VoidCallback onTap;

  const _ItemNav({
    required this.icone,
    required this.rotulo,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cor = selecionado ? AppColors.accent : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: cor, size: 22),
            const SizedBox(height: 3),
            Text(
              rotulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cor, fontSize: 10.5, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
