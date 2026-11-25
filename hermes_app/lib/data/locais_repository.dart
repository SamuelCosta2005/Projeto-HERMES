import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/local.dart';

/// Salas de destino: coleção compartilhada `locais_eventos` do SInergic.
class LocaisRepository {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('locais_eventos');

  /// Lista em tempo real (usada na tela de gestão de locais do admin).
  Stream<List<Local>> watch() {
    return _col.snapshots().map((s) {
      final lista = s.docs.map((d) => Local.deDoc(d.id, d.data())).toList();
      lista.sort((a, b) => a.identificador.toLowerCase().compareTo(b.identificador.toLowerCase()));
      return lista;
    });
  }

  Future<List<Local>> buscar() async {
    final s = await _col.get();
    return s.docs.map((d) => Local.deDoc(d.id, d.data())).toList();
  }
}
