import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/movimentacao.dart';

/// Livro de movimentações de estoque. Só o admin consegue ler.
class MovimentacoesRepository {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('movimentacoes_estoque');

  Stream<List<Movimentacao>> watchRecentes({String? itemId, int limite = 100}) {
    Query<Map<String, dynamic>> q = _col;
    if (itemId != null) {
      q = q.where('itemId', isEqualTo: itemId);
    }
    // Sem filtro de item: o próprio Firestore ordena (índice automático).
    // Com filtro de item: ordena aqui no app, para não exigir índice composto.
    if (itemId == null) {
      q = q.orderBy('criadoEm', descending: true).limit(limite);
    }
    return q.snapshots().map((s) {
      final lista = s.docs.map((d) => Movimentacao.deDoc(d.id, d.data())).toList();
      if (itemId != null) {
        final agora = DateTime.now();
        lista.sort((a, b) => (b.criadoEm ?? agora).compareTo(a.criadoEm ?? agora));
        return lista.length > limite ? lista.sublist(0, limite) : lista;
      }
      return lista;
    });
  }
}
