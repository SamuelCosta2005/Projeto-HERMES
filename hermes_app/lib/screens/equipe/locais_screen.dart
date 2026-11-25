import 'package:flutter/material.dart';
import '../../data/locais_repository.dart';
import '../../models/local.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_card.dart';
import '../../widgets/estados.dart';
import '../../widgets/hermes_app_bar.dart';
import '../../widgets/icone_quadrado.dart';
import '../../widgets/primary_button.dart';
import 'local_form_screen.dart';

/// Admin: lista dos locais de entrega (salas) e acesso ao cadastro.
class LocaisScreen extends StatefulWidget {
  const LocaisScreen({super.key});

  @override
  State<LocaisScreen> createState() => _LocaisScreenState();
}

class _LocaisScreenState extends State<LocaisScreen> {
  late final Stream<List<Local>> _locais;

  @override
  void initState() {
    super.initState();
    _locais = LocaisRepository().watch();
  }

  void _abrir([Local? local]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LocalFormScreen(local: local)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HermesAppBar(stageBadge: 'Locais'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Locais de entrega', style: AppTextStyles.screenTitle),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Local>>(
                stream: _locais,
                builder: (context, snap) {
                  if (snap.hasError) return EstadoErro(erro: snap.error!);
                  if (!snap.hasData) return EstadoCarregando();
                  final lista = snap.data!;
                  if (lista.isEmpty) {
                    return EstadoVazio(
                      icone: Icons.meeting_room_outlined,
                      titulo: 'Nenhum local cadastrado',
                      subtitulo: 'Use "Novo local" para cadastrar a primeira sala.',
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    children: [
                      for (final l in lista)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            onTap: () => _abrir(l),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                IconeQuadrado(icone: Icons.meeting_room_outlined),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(l.identificador, style: AppTextStyles.cardTitle),
                                      const SizedBox(height: 2),
                                      Text(
                                        [
                                          if (l.detalhe.isNotEmpty) l.detalhe,
                                          if (l.andar.isNotEmpty) l.andar,
                                        ].join(' · '),
                                        style: AppTextStyles.cardSubtitle,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: PrimaryButton(
                label: 'Novo local',
                icon: Icons.add_rounded,
                onPressed: () => _abrir(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
