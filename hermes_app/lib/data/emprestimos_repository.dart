import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emprestimo.dart';

class EmprestimosRepository {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('emprestimos_hermes');

  /// Meus empréstimos (abertos e devolvidos), mais recentes primeiro.
  /// Ordenado aqui no app para não exigir índice extra.
  Stream<List<Emprestimo>> watchMeus(String uid) {
    return _col.where('solicitanteId', isEqualTo: uid).snapshots().map((s) {
      final lista = s.docs.map((d) => Emprestimo.deDoc(d.id, d.data())).toList();
      lista.sort((a, b) => (b.entregueEm ?? DateTime(0)).compareTo(a.entregueEm ?? DateTime(0)));
      return lista;
    });
  }

  /// Todos os empréstimos em aberto (com o usuário ou com recolhimento pedido).
  /// Só técnico/admin conseguem ler.
  Stream<List<Emprestimo>> watchAbertos() {
    // Ordena aqui no app (mais antigos primeiro) para não exigir índice no Firestore.
    return _col.where('status', whereIn: ['emPosse', 'devolucaoSolicitada']).snapshots().map((s) {
      final lista = s.docs.map((d) => Emprestimo.deDoc(d.id, d.data())).toList();
      final agora = DateTime.now();
      lista.sort((a, b) => (a.entregueEm ?? agora).compareTo(b.entregueEm ?? agora));
      return lista;
    });
  }
}
