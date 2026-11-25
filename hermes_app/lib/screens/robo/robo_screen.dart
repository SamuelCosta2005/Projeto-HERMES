import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../data/robo_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/erros.dart';
import '../../utils/localizacao.dart';
import '../../widgets/app_card.dart';
import '../../widgets/botao_secundario.dart';
import '../../widgets/hermes_app_bar.dart';
import '../../widgets/primary_button.dart';

/// Tela do celular que faz o papel do robô: lê o GPS e manda a posição para o
/// Firestore a cada poucos segundos. Mantenha o app aberto e a tela ligada.
class RoboScreen extends StatefulWidget {
  const RoboScreen({super.key});

  @override
  State<RoboScreen> createState() => _RoboScreenState();
}

class _RoboScreenState extends State<RoboScreen> {
  final RoboRepository _repo = RoboRepository();
  StreamSubscription<Position>? _sub;
  Timer? _timer;
  Position? _ultima;
  DateTime? _ultimoEnvio;
  bool _rodando = false;
  bool _iniciando = false;
  int _envios = 0;
  String? _erro;

  LocationSettings _config() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 3),
      );
    }
    return const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 0);
  }

  Future<void> _iniciar() async {
    setState(() {
      _iniciando = true;
      _erro = null;
    });
    final problema = await garantirPermissaoLocalizacao();
    if (problema != null) {
      if (mounted) {
        setState(() {
          _erro = problema;
          _iniciando = false;
        });
      }
      return;
    }
    try {
      _sub = Geolocator.getPositionStream(locationSettings: _config()).listen(
        (p) {
          _ultima = p;
          if (mounted) setState(() {});
        },
        onError: (Object e) {
          if (mounted) setState(() => _erro = 'Erro no GPS: $e');
        },
      );
      // A posição é enviada de tempos em tempos (mesmo parado), para o app do
      // cliente saber que o robô continua "vivo".
      _timer = Timer.periodic(const Duration(seconds: 4), (_) => _enviar());
      await WakelockPlus.enable();
      if (!mounted) return;
      setState(() {
        _rodando = true;
        _iniciando = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = 'Não foi possível iniciar o rastreio ($e).';
          _iniciando = false;
        });
      }
    }
  }

  Future<void> _enviar() async {
    final p = _ultima;
    if (p == null) return;
    try {
      await _repo.publicar(latitude: p.latitude, longitude: p.longitude, precisaoM: p.accuracy);
      if (!mounted) return;
      setState(() {
        _ultimoEnvio = DateTime.now();
        _envios++;
        _erro = null;
      });
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    }
  }

  Future<void> _parar() async {
    await _sub?.cancel();
    _timer?.cancel();
    _sub = null;
    _timer = null;
    try {
      await WakelockPlus.disable();
      await _repo.desativar();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _rodando = false;
      _ultima = null;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    if (_rodando) {
      WakelockPlus.disable();
      _repo.desativar();
    }
    super.dispose();
  }

  String _hora(DateTime? d) {
    if (d == null) return '—';
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.hour)}:${dois(d.minute)}:${dois(d.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = _ultima;
    return Scaffold(
      appBar: HermesAppBar(stageBadge: 'Robô'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text('Modo robô', style: AppTextStyles.screenTitle),
            const SizedBox(height: 4),
            Text(
              'Este celular representa o Hermes. Enquanto o rastreio estiver ligado, '
              'os clientes com entrega "a caminho" veem esta posição no mapa.',
              style: AppTextStyles.screenSubtitle,
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _rodando ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                        color: _rodando ? AppColors.success : AppColors.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _rodando ? 'Rastreio ligado' : 'Rastreio desligado',
                        style: AppTextStyles.cardTitle,
                      ),
                    ],
                  ),
                  if (_rodando) ...[
                    const SizedBox(height: 12),
                    _Linha('Posição', p == null ? 'Procurando sinal de GPS...' : '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}'),
                    _Linha('Precisão', p == null ? '—' : '± ${p.accuracy.round()} m'),
                    _Linha('Último envio', _hora(_ultimoEnvio)),
                    _Linha('Envios', '$_envios'),
                  ],
                ],
              ),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 12),
              Text(_erro!, style: AppTextStyles.cardSubtitle.copyWith(color: AppColors.warning)),
            ],
            const SizedBox(height: 16),
            if (!_rodando)
              PrimaryButton(
                label: 'Iniciar rastreio',
                icon: Icons.play_arrow_rounded,
                isLoading: _iniciando,
                onPressed: _iniciar,
              )
            else
              BotaoSecundario(
                rotulo: 'Parar rastreio',
                icone: Icons.stop_rounded,
                destrutivo: true,
                onPressed: _parar,
              ),
            const SizedBox(height: 16),
            Text(
              'Dicas: deixe o app aberto e a tela ligada (a tela não apaga sozinha enquanto o '
              'rastreio estiver ligado). Funciona bem ao ar livre; dentro de prédio o GPS falha.',
              style: AppTextStyles.cardSubtitle.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  final String rotulo;
  final String valor;

  const _Linha(this.rotulo, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, child: Text(rotulo, style: AppTextStyles.cardSubtitle)),
          Expanded(
            child: Text(valor, style: AppTextStyles.cardSubtitle.copyWith(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
