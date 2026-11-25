import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../data/robo_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/localizacao.dart';

/// Mapa em tempo real: posição do robô (vinda do Firestore) e a do próprio
/// cliente (GPS do aparelho). Mapa de fundo: OpenStreetMap.
class MapaEntrega extends StatefulWidget {
  const MapaEntrega({super.key});

  @override
  State<MapaEntrega> createState() => _MapaEntregaState();
}

class _MapaEntregaState extends State<MapaEntrega> {
  static const Duration _tempoSemSinal = Duration(seconds: 30);

  final MapController _mapa = MapController();
  bool _mapaPronto = false;
  StreamSubscription<RoboPosicao?>? _subRobo;
  StreamSubscription<Position>? _subEu;
  Timer? _vigia;

  RoboPosicao? _robo;
  DateTime? _roboVisto; // quando este aparelho recebeu a última posição "fresca"
  LatLng? _eu;
  String? _avisoGps;

  @override
  void initState() {
    super.initState();
    _subRobo = RoboRepository().watch().listen((r) {
      if (!mounted) return;
      setState(() {
        _robo = r;
        if (r != null && r.ativo && !r.doCache) _roboVisto = DateTime.now();
      });
      _reenquadrar();
    }, onError: (Object _) {});
    // Reavalia a cada 5 s se o robô ficou sem sinal.
    _vigia = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
    _iniciarGps();
  }

  Future<void> _iniciarGps() async {
    final problema = await garantirPermissaoLocalizacao();
    if (problema != null) {
      if (mounted) setState(() => _avisoGps = problema);
      return;
    }
    _subEu = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 3),
    ).listen((p) {
      if (!mounted) return;
      setState(() => _eu = LatLng(p.latitude, p.longitude));
      _reenquadrar();
    }, onError: (Object e) {
      if (mounted) setState(() => _avisoGps = 'Erro no GPS: $e');
    });
  }

  @override
  void dispose() {
    _subRobo?.cancel();
    _subEu?.cancel();
    _vigia?.cancel();
    _mapa.dispose();
    super.dispose();
  }

  bool get _roboComSinal {
    final r = _robo;
    final visto = _roboVisto;
    if (r == null || !r.ativo || visto == null) return false;
    return DateTime.now().difference(visto) < _tempoSemSinal;
  }

  LatLng? get _pontoRobo => _roboComSinal ? LatLng(_robo!.latitude, _robo!.longitude) : null;

  void _reenquadrar() {
    if (!_mapaPronto) return;
    final pontos = <LatLng>[
      if (_pontoRobo != null) _pontoRobo!,
      if (_eu != null) _eu!,
    ];
    if (pontos.isEmpty) return;
    if (pontos.length == 1) {
      _mapa.move(pontos.first, 17);
    } else {
      _mapa.fitCamera(CameraFit.coordinates(
        coordinates: pontos,
        padding: const EdgeInsets.all(56),
        maxZoom: 18,
      ));
    }
  }

  String _textoStatus() {
    final robo = _pontoRobo;
    if (robo == null) {
      return _eu == null ? 'Procurando sinal do robô...' : 'Sem sinal do robô no momento';
    }
    if (_eu == null) return _avisoGps ?? 'Procurando a sua localização...';
    final m = Geolocator.distanceBetween(robo.latitude, robo.longitude, _eu!.latitude, _eu!.longitude);
    return 'Robô a ${formatarDistancia(m)} de você';
  }

  @override
  Widget build(BuildContext context) {
    final inicio = _pontoRobo ?? _eu;
    final altura = 260.0;
    return Container(
      height: altura,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: inicio == null
          ? _Aguardando(texto: _avisoGps ?? _textoStatus())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapa,
                  options: MapOptions(
                    initialCenter: inicio,
                    initialZoom: 17,
                    onMapReady: () {
                      _mapaPronto = true;
                      _reenquadrar();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.hermes_app',
                    ),
                    MarkerLayer(
                      markers: [
                        if (_eu != null)
                          Marker(
                            point: _eu!,
                            width: 36,
                            height: 36,
                            child: _Pino(icone: Icons.person_rounded, fundo: AppColors.textPrimary, cor: AppColors.surface),
                          ),
                        if (_pontoRobo != null)
                          Marker(
                            point: _pontoRobo!,
                            width: 44,
                            height: 44,
                            child: const _Pino(icone: Icons.smart_toy_rounded, fundo: null, cor: Colors.white, robo: true),
                          ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(_textoStatus(), style: AppTextStyles.cardSubtitle.copyWith(color: AppColors.textPrimary)),
                  ),
                ),
                Positioned(
                  right: 6,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: Colors.white70,
                    child: const Text('© OpenStreetMap', style: TextStyle(fontSize: 9, color: Colors.black87)),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Aguardando extends StatelessWidget {
  final String texto;

  const _Aguardando({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.accent),
            ),
            const SizedBox(height: 12),
            Text(texto, textAlign: TextAlign.center, style: AppTextStyles.cardSubtitle),
          ],
        ),
      ),
    );
  }
}

class _Pino extends StatelessWidget {
  final IconData icone;
  final Color? fundo;
  final Color cor;
  final bool robo;

  const _Pino({required this.icone, required this.fundo, required this.cor, this.robo = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: robo ? AppColors.accent : fundo,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
      ),
      child: Icon(icone, color: cor, size: robo ? 24 : 20),
    );
  }
}
