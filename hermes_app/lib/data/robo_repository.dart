import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/util.dart';

/// Última posição enviada pelo celular do robô.
class RoboPosicao {
  final double latitude;
  final double longitude;
  final double precisaoM;
  final bool ativo;

  /// true quando a leitura veio só do cache do aparelho (pode estar velha).
  final bool doCache;

  const RoboPosicao({
    required this.latitude,
    required this.longitude,
    required this.precisaoM,
    required this.ativo,
    required this.doCache,
  });
}

/// Documento único `hermes_config/robo`: o celular do robô escreve, os apps dos
/// clientes leem.
class RoboRepository {
  final DocumentReference<Map<String, dynamic>> _doc =
      FirebaseFirestore.instance.doc('hermes_config/robo');

  Stream<RoboPosicao?> watch() {
    return _doc.snapshots().map((s) {
      final d = s.data();
      if (d == null) return null;
      final lat = d['lat'];
      final lng = d['lng'];
      if (lat is! num || lng is! num) return null;
      final prec = d['precisao'];
      return RoboPosicao(
        latitude: lat.toDouble(),
        longitude: lng.toDouble(),
        precisaoM: prec is num ? prec.toDouble() : 0,
        ativo: lerBool(d['ativo']),
        doCache: s.metadata.isFromCache,
      );
    });
  }

  Future<void> publicar({
    required double latitude,
    required double longitude,
    required double precisaoM,
  }) {
    return _doc.set(<String, dynamic>{
      'lat': latitude,
      'lng': longitude,
      'precisao': precisaoM,
      'ativo': true,
      'atualizadoEm': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> desativar() {
    return _doc.set(<String, dynamic>{
      'ativo': false,
      'atualizadoEm': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
