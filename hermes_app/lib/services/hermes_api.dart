import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config.dart';
import '../models/categoria.dart';
import '../models/fila_info.dart';
import '../models/linha_selecionada.dart';
import '../models/pedido.dart';
import '../models/perfil.dart';
import '../models/util.dart';
import 'hermes_exception.dart';
import 'sessao.dart';

class PedidoCriado {
  final String pedidoId;
  final String codigo;
  final DateTime previsaoEntrega;
  final int posicao;

  const PedidoCriado({
    required this.pedidoId,
    required this.codigo,
    required this.previsaoEntrega,
    required this.posicao,
  });
}

class ResultadoRecebimento {
  final bool jaConfirmado;
  final int emprestimosCriados;

  const ResultadoRecebimento({required this.jaConfirmado, required this.emprestimosCriados});
}

class ResultadoDevolucao {
  final String status;
  final int restante;

  const ResultadoDevolucao({required this.status, required this.restante});
}

class ResultadoAjuste {
  final int delta;
  final int estoqueTotal;
  final bool semDiferenca;

  const ResultadoAjuste({required this.delta, required this.estoqueTotal, required this.semDiferenca});
}

// ---------------------------------------------------------------------------
// Nomes das coleções
// ---------------------------------------------------------------------------
const String _colItens = 'estoque_itens';
const String _colPedidos = 'pedidos_hermes';
const String _colEmprestimos = 'emprestimos_hermes';
const String _colMovimentacoes = 'movimentacoes_estoque';
const String _colLocais = 'locais_eventos';
const String _colUsuarios = 'hermes_usuarios';
const String _docContadores = 'hermes_config/contadores';
const String _docParametros = 'hermes_config/parametros';

const int _tempoMedioPadraoMin = 4;
const int _maxLinhasPorPedido = 25;
const List<String> _statusFilaAtiva = ['queued', 'inTransit', 'arrived'];

/// Lança o erro no mesmo formato que o servidor usava (código + identificador).
Never _erro(String codigo, String id, [Map<String, dynamic> detalhes = const <String, dynamic>{}]) {
  throw HermesException(codigo: codigo, identificador: id, detalhes: detalhes);
}

/// Contadores de um item. disponível = total − emUso.
class _Cont {
  final int total;
  final int emUso;
  const _Cont(this.total, this.emUso);
  int get disponivel => total - emUso;
}

/// Aplica a variação e garante 0 ≤ emUso ≤ total (único lugar que calcula contador novo).
_Cont _aplicar(_Cont c, int dTotal, int dUso) {
  final t = c.total + dTotal;
  final u = c.emUso + dUso;
  if (t < 0 || u < 0 || u > t) {
    _erro('failed-precondition', 'estoque-inconsistente', {'estoqueTotal': t, 'emUso': u});
  }
  return _Cont(t, u);
}

class _Item {
  final String id;
  final String nome;
  final String categoria;
  final bool retornavel;
  final bool ativo;
  final int estoqueMinimo;
  final _Cont cont;

  const _Item({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.retornavel,
    required this.ativo,
    required this.estoqueMinimo,
    required this.cont,
  });
}

_Item _lerItem(DocumentSnapshot<Map<String, dynamic>> s) {
  final d = s.data();
  if (!s.exists || d == null) _erro('not-found', 'item-inexistente', {'itemId': s.id});
  return _Item(
    id: s.id,
    nome: lerString(d['nome']),
    categoria: lerString(d['categoria']),
    retornavel: lerBool(d['retornavel']),
    ativo: d['ativo'] != false,
    estoqueMinimo: lerInt(d['estoqueMinimo']),
    cont: _Cont(lerInt(d['estoqueTotal']), lerInt(d['emUso'])),
  );
}

/// Quanto do empréstimo ainda está com o usuário.
int _restante(Map<String, dynamic> e) =>
    lerInt(e['quantidade']) -
    lerInt(e['quantidadeDevolvida']) -
    lerInt(e['quantidadeDanificada']) -
    lerInt(e['quantidadePerdida']);

/// Toda a regra de negócio do Hermes, rodando DENTRO do app com transações do
/// Firestore (versão sem Cloud Functions, para o plano gratuito).
///
/// Atenção: sem servidor, as regras de papel (cliente x admin) são só do app;
/// o Firestore fica aberto para qualquer usuário logado. Serve para teste.
class HermesApi {
  HermesApi._();
  static final HermesApi instance = HermesApi._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> _doc(String col, String id) => _db.collection(col).doc(id);
  CollectionReference<Map<String, dynamic>> _col(String col) => _db.collection(col);

  Perfil _ator() {
    final p = Sessao.atual;
    if (p == null) _erro('unauthenticated', 'login-obrigatorio');
    return p;
  }

  Perfil _equipe() {
    final p = _ator();
    if (!p.papel.ehEquipe) _erro('permission-denied', 'papel-insuficiente');
    return p;
  }

  Perfil _admin() {
    final p = _ator();
    if (!p.papel.ehAdmin) _erro('permission-denied', 'papel-insuficiente');
    return p;
  }

  /// Executa [fn] e traduz erros do Firestore para o formato do app.
  Future<T> _rodar<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        _erro('unavailable', '');
      }
      if (e.code == 'permission-denied') _erro('permission-denied', '');
      rethrow;
    }
  }

  // ---- perfil ----------------------------------------------------------
  /// Login simplificado (testes): sem [senha] vira cliente; com a senha certa
  /// vira admin (suporte técnico). Exige que o app já esteja logado (anônimo).
  Future<Perfil> entrar({String? senha}) => _rodar(() async {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) _erro('unauthenticated', 'login-obrigatorio');
        var papel = Papel.solicitante;
        if (senha != null && senha.isNotEmpty) {
          if (senha == kSenhaAdmin) {
            papel = Papel.admin;
          } else if (senha == kSenhaRobo) {
            papel = Papel.robo;
          } else {
            _erro('permission-denied', 'senha-incorreta');
          }
        }
        final nome = papel == Papel.admin
            ? 'Suporte técnico'
            : papel == Papel.robo
                ? 'Robô Hermes'
                : 'Cliente';
        await _doc(_colUsuarios, uid).set(<String, dynamic>{
          'nome': nome,
          'papel': papel.id,
          'atualizadoEm': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return Perfil(uid: uid, nome: nome, papel: papel);
      });

  Future<Perfil> meuPerfil() => _rodar(() async {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) _erro('unauthenticated', 'login-obrigatorio');
        final s = await _doc(_colUsuarios, uid).get();
        final d = s.data();
        if (!s.exists || d == null) _erro('permission-denied', 'usuario-nao-cadastrado');
        return Perfil(
          uid: uid,
          nome: lerString(d['nome'], 'Sem nome'),
          papel: Papel.deId(lerStringOpc(d['papel'])),
        );
      });

  // ---- movimentação (livro) -------------------------------------------
  void _mov(
    Transaction tx, {
    required Perfil ator,
    required String itemId,
    required String itemNome,
    required String tipo,
    required int quantidade,
    required int dTotal,
    required int dUso,
    String? pedidoId,
    String? emprestimoId,
    String? motivo,
  }) {
    tx.set(_col(_colMovimentacoes).doc(), <String, dynamic>{
      'itemId': itemId,
      'itemNome': itemNome,
      'tipo': tipo,
      'quantidade': quantidade,
      'efeitoEstoqueTotal': dTotal,
      'efeitoEmUso': dUso,
      'pedidoId': pedidoId,
      'emprestimoId': emprestimoId,
      'motivo': motivo,
      'realizadoPorId': ator.uid,
      'realizadoPorNome': ator.nome,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  void _gravarCont(Transaction tx, String itemId, _Cont n) {
    tx.update(_doc(_colItens, itemId), <String, dynamic>{
      'estoqueTotal': n.total,
      'emUso': n.emUso,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<int> _tempoMedioMin() async {
    final s = await _db.doc(_docParametros).get();
    final v = s.data()?['tempoMedioEntregaMin'];
    return v is num && v > 0 ? v.toInt() : _tempoMedioPadraoMin;
  }

  // ---- pedidos ---------------------------------------------------------
  Future<PedidoCriado> criarPedido({
    required Categoria categoria,
    required List<LinhaSelecionada> linhas,
    required String localId,
    String? setor,
  }) =>
      _rodar(() async {
        final ator = _ator();
        // Soma linhas repetidas do mesmo item.
        final somadas = <String, int>{};
        for (final l in linhas) {
          if (l.quantidade < 1) _erro('invalid-argument', 'quantidade-invalida', {'itemId': l.item.id});
          somadas[l.item.id] = (somadas[l.item.id] ?? 0) + l.quantidade;
        }
        if (somadas.isEmpty) _erro('invalid-argument', 'pedido-sem-itens');
        if (somadas.length > _maxLinhasPorPedido) {
          _erro('invalid-argument', 'itens-demais', {'max': _maxLinhasPorPedido});
        }
        if (localId.trim().isEmpty) _erro('invalid-argument', 'campo-obrigatorio', {'campo': 'localId'});

        final localSnap = await _doc(_colLocais, localId).get();
        final local = localSnap.data();
        if (!localSnap.exists || local == null) _erro('not-found', 'local-inexistente', {'localId': localId});
        final ident = lerString(local['identificador']).trim();
        final localNome = ident.isNotEmpty ? ident : localId;
        final localDetalhe = [local['unidade'], local['predio'], local['andar']]
            .whereType<String>()
            .where((v) => v.trim().isNotEmpty)
            .join(' · ');

        final tempoMedio = await _tempoMedioMin();
        final ativosAgg = await _col(_colPedidos).where('status', whereIn: _statusFilaAtiva).count().get();
        final ativos = ativosAgg.count ?? 0;
        final setorLimpo = (setor ?? '').trim();

        return _db.runTransaction<PedidoCriado>((tx) async {
          final contadorRef = _db.doc(_docContadores);
          final contadorSnap = await tx.get(contadorRef);
          final ids = somadas.keys.toList();
          final itens = <_Item>[];
          for (final id in ids) {
            itens.add(_lerItem(await tx.get(_doc(_colItens, id))));
          }

          final linhasPedido = <Map<String, dynamic>>[];
          final novos = <String, _Cont>{};
          for (final item in itens) {
            final qtd = somadas[item.id]!;
            if (!item.ativo) _erro('failed-precondition', 'item-inativo', {'item': item.nome});
            if (item.categoria != categoria.id) {
              _erro('invalid-argument', 'item-de-outra-categoria', {'item': item.nome});
            }
            if (qtd > item.cont.disponivel) {
              _erro('failed-precondition', 'estoque-insuficiente', {
                'item': item.nome,
                'disponivel': item.cont.disponivel,
                'solicitado': qtd,
              });
            }
            novos[item.id] = _aplicar(item.cont, 0, qtd);
            linhasPedido.add(<String, dynamic>{
              'itemId': item.id,
              'nome': item.nome,
              'quantidade': qtd,
              'retornavel': item.retornavel,
            });
          }

          final ultimo = contadorSnap.data()?['pedido'];
          final sequencia = (ultimo is num ? ultimo.toInt() : 0) + 1;
          final codigo = '#HR-${1000 + sequencia}';
          final pedidoRef = _col(_colPedidos).doc();
          final previsaoMs = DateTime.now().millisecondsSinceEpoch + (ativos + 1) * tempoMedio * 60000;

          // --- escritas (todas as leituras já foram feitas) ---
          tx.set(contadorRef, <String, dynamic>{'pedido': sequencia}, SetOptions(merge: true));
          for (final item in itens) {
            _gravarCont(tx, item.id, novos[item.id]!);
            _mov(tx,
                ator: ator,
                itemId: item.id,
                itemNome: item.nome,
                tipo: 'reserva',
                quantidade: somadas[item.id]!,
                dTotal: 0,
                dUso: somadas[item.id]!,
                pedidoId: pedidoRef.id);
          }
          tx.set(pedidoRef, <String, dynamic>{
            'codigo': codigo,
            'categoria': categoria.id,
            'itens': linhasPedido,
            'localId': localId,
            'localNome': localNome,
            'localDetalhe': localDetalhe,
            'solicitanteId': ator.uid,
            'solicitanteNome': ator.nome,
            'solicitanteSetor': setorLimpo.isEmpty ? null : setorLimpo,
            'status': 'queued',
            'previsaoEntrega': Timestamp.fromMillisecondsSinceEpoch(previsaoMs),
            'entregueEm': null,
            'canceladoEm': null,
            'criadoEm': FieldValue.serverTimestamp(),
            'atualizadoEm': FieldValue.serverTimestamp(),
          });
          return PedidoCriado(
            pedidoId: pedidoRef.id,
            codigo: codigo,
            previsaoEntrega: DateTime.fromMillisecondsSinceEpoch(previsaoMs),
            posicao: ativos + 1,
          );
        });
      });

  /// O próprio cliente cancela o pedido dele (só enquanto está "na fila").
  Future<void> cancelarPedido(String pedidoId) => _rodar(() async {
        final ator = _ator();
        await _db.runTransaction<void>((tx) => _cancelarTx(tx, ator, pedidoId, comoEquipe: false));
      });

  /// Suporte técnico cancela qualquer pedido ativo (na fila, a caminho ou que
  /// chegou e ninguém confirmou). Libera o estoque reservado.
  Future<void> cancelarPedidoEquipe(String pedidoId) => _rodar(() async {
        final ator = _equipe();
        await _db.runTransaction<void>((tx) => _cancelarTx(tx, ator, pedidoId, comoEquipe: true));
      });

  /// Cancela TODOS os pedidos ativos de uma vez (reinicia a fila).
  /// Devolve quantos foram cancelados.
  Future<int> zerarFila() => _rodar(() async {
        final ator = _admin();
        final ativos = await _col(_colPedidos).where('status', whereIn: _statusFilaAtiva).get();
        var feitos = 0;
        for (final d in ativos.docs) {
          await _db.runTransaction<void>((tx) => _cancelarTx(tx, ator, d.id, comoEquipe: true));
          feitos++;
        }
        return feitos;
      });

  Future<void> _cancelarTx(Transaction tx, Perfil ator, String pedidoId, {required bool comoEquipe}) async {
    final ref = _doc(_colPedidos, pedidoId);
    final snap = await tx.get(ref);
    final p = snap.data();
    if (!snap.exists || p == null) _erro('not-found', 'pedido-inexistente');
    if (!comoEquipe && p['solicitanteId'] != ator.uid) _erro('permission-denied', 'pedido-de-outro-usuario');
    final status = lerString(p['status']);
    if (status == 'cancelled') return; // duplo toque: não faz nada
    final cancelavel = comoEquipe ? _statusFilaAtiva.contains(status) : status == 'queued';
    if (!cancelavel) _erro('failed-precondition', 'pedido-nao-cancelavel', {'status': status});

    final linhas = listaDeMapas(p['itens']);
    final itens = <_Item>[];
    for (final l in linhas) {
      itens.add(_lerItem(await tx.get(_doc(_colItens, lerString(l['itemId'])))));
    }
    final novos = <_Cont>[];
    for (var i = 0; i < linhas.length; i++) {
      novos.add(_aplicar(itens[i].cont, 0, -lerInt(linhas[i]['quantidade'])));
    }
    for (var i = 0; i < linhas.length; i++) {
      final q = lerInt(linhas[i]['quantidade']);
      _gravarCont(tx, itens[i].id, novos[i]);
      _mov(tx,
          ator: ator,
          itemId: itens[i].id,
          itemNome: itens[i].nome,
          tipo: 'liberacao',
          quantidade: q,
          dTotal: 0,
          dUso: -q,
          pedidoId: pedidoId,
          motivo: comoEquipe ? 'Pedido cancelado pelo suporte técnico' : 'Pedido cancelado pelo solicitante');
    }
    tx.update(ref, <String, dynamic>{
      'status': 'cancelled',
      'canceladoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// [novoStatus]: "inTransit" ou "arrived". Só técnico/admin.
  Future<void> atualizarStatusEntrega(String pedidoId, String novoStatus) => _rodar(() async {
        _equipe();
        if (novoStatus != 'inTransit' && novoStatus != 'arrived') {
          _erro('invalid-argument', 'status-invalido');
        }
        if (novoStatus == 'inTransit') {
          // O robô atende um pedido por vez, na ordem da fila: só sai o primeiro
          // da fila, e só se nenhum outro estiver a caminho ou esperando confirmação.
          final ativos = await _col(_colPedidos).where('status', whereIn: _statusFilaAtiva).get();
          final agora = DateTime.now().millisecondsSinceEpoch;
          final lista = ativos.docs.map((d) {
            final t = d.data()['criadoEm'];
            return (
              id: d.id,
              status: lerString(d.data()['status']),
              ms: t is Timestamp ? t.millisecondsSinceEpoch : agora,
            );
          }).toList()
            ..sort((a, b) {
              final c = a.ms.compareTo(b.ms);
              return c != 0 ? c : a.id.compareTo(b.id);
            });
          final ocupado = lista.any((a) => a.id != pedidoId && a.status != 'queued');
          final primeiro = lista.where((a) => a.status == 'queued').toList();
          if (ocupado || primeiro.isEmpty || primeiro.first.id != pedidoId) {
            _erro('failed-precondition', 'fora-da-vez');
          }
        }
        await _db.runTransaction<void>((tx) async {
          final ref = _doc(_colPedidos, pedidoId);
          final snap = await tx.get(ref);
          final p = snap.data();
          if (!snap.exists || p == null) _erro('not-found', 'pedido-inexistente');
          final atual = lerString(p['status']);
          if (atual == novoStatus) return;
          final ok = (atual == 'queued' && novoStatus == 'inTransit') ||
              (atual == 'inTransit' && novoStatus == 'arrived');
          if (!ok) _erro('failed-precondition', 'transicao-invalida', {'atual': atual, 'novo': novoStatus});
          tx.update(ref, <String, dynamic>{
            'status': novoStatus,
            'atualizadoEm': FieldValue.serverTimestamp(),
          });
        });
      });

  /// O cliente confirma que recebeu.
  Future<ResultadoRecebimento> confirmarRecebimento(String pedidoId) => _rodar(() async {
        final ator = _ator();
        return _db.runTransaction<ResultadoRecebimento>(
          (tx) => _confirmarTx(tx, ator, pedidoId, comoEquipe: false),
        );
      });

  /// Suporte técnico dá o pedido como entregue quando o cliente não confirma
  /// (destrava a fila). Só vale para pedido que já chegou.
  Future<ResultadoRecebimento> entregarPedidoEquipe(String pedidoId) => _rodar(() async {
        final ator = _equipe();
        return _db.runTransaction<ResultadoRecebimento>(
          (tx) => _confirmarTx(tx, ator, pedidoId, comoEquipe: true),
        );
      });

  Future<ResultadoRecebimento> _confirmarTx(
    Transaction tx,
    Perfil ator,
    String pedidoId, {
    required bool comoEquipe,
  }) async {
    final ref = _doc(_colPedidos, pedidoId);
    final snap = await tx.get(ref);
    final p = snap.data();
    if (!snap.exists || p == null) _erro('not-found', 'pedido-inexistente');
    if (!comoEquipe && p['solicitanteId'] != ator.uid) _erro('permission-denied', 'pedido-de-outro-usuario');
    if (p['status'] == 'delivered') {
      return const ResultadoRecebimento(jaConfirmado: true, emprestimosCriados: 0);
    }
    if (p['status'] != 'arrived') {
      _erro('failed-precondition', 'pedido-nao-chegou', {'status': p['status']});
    }
    final linhas = listaDeMapas(p['itens']);
    final consumiveis = linhas.where((l) => !lerBool(l['retornavel'])).toList();
    final retornaveis = linhas.where((l) => lerBool(l['retornavel'])).toList();

    final itens = <_Item>[];
    for (final l in consumiveis) {
      itens.add(_lerItem(await tx.get(_doc(_colItens, lerString(l['itemId'])))));
    }
    final novos = <_Cont>[];
    for (var i = 0; i < consumiveis.length; i++) {
      final q = lerInt(consumiveis[i]['quantidade']);
      novos.add(_aplicar(itens[i].cont, -q, -q));
    }

    // --- escritas ---
    for (var i = 0; i < consumiveis.length; i++) {
      final q = lerInt(consumiveis[i]['quantidade']);
      _gravarCont(tx, itens[i].id, novos[i]);
      _mov(tx,
          ator: ator,
          itemId: itens[i].id,
          itemNome: itens[i].nome,
          tipo: 'consumo',
          quantidade: q,
          dTotal: -q,
          dUso: -q,
          pedidoId: pedidoId,
          motivo: comoEquipe ? 'Entrega confirmada pelo suporte técnico' : null);
    }
    for (final l in retornaveis) {
      tx.set(_col(_colEmprestimos).doc(), <String, dynamic>{
        'pedidoId': pedidoId,
        'pedidoCodigo': p['codigo'],
        'itemId': l['itemId'],
        'itemNome': l['nome'],
        'quantidade': lerInt(l['quantidade']),
        'quantidadeDevolvida': 0,
        'quantidadeDanificada': 0,
        'quantidadePerdida': 0,
        'solicitanteId': p['solicitanteId'],
        'solicitanteNome': p['solicitanteNome'] ?? ator.nome,
        'solicitanteSetor': p['solicitanteSetor'],
        'localId': p['localId'],
        'localNome': p['localNome'],
        'localDetalhe': p['localDetalhe'],
        'status': 'emPosse',
        'devolucaoSolicitadaEm': null,
        'recebidoPorId': null,
        'recebidoPorNome': null,
        'observacoes': null,
        'entregueEm': FieldValue.serverTimestamp(),
        'devolvidoEm': null,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    }
    tx.update(ref, <String, dynamic>{
      'status': 'delivered',
      'entregueEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
    return ResultadoRecebimento(jaConfirmado: false, emprestimosCriados: retornaveis.length);
  }

  /// Posição na fila, SEM expor código, destino ou itens de outros pedidos.
  Future<FilaInfo> consultarFila(String pedidoId) => _rodar(() async {
        final ator = _ator();
        final snap = await _doc(_colPedidos, pedidoId).get();
        final p = snap.data();
        if (!snap.exists || p == null) _erro('not-found', 'pedido-inexistente');
        if (p['solicitanteId'] != ator.uid) _erro('permission-denied', 'pedido-de-outro-usuario');
        final status = lerString(p['status']);
        FilaInfo fora() => FilaInfo(
              naFila: false,
              status: StatusPedido.deId(status),
              posicao: 0,
              pedidosAFrente: 0,
              esperaEstimadaMin: 0,
              etapas: const <EtapaFila>[],
            );
        if (!_statusFilaAtiva.contains(status)) return fora();

        final tempoMedio = await _tempoMedioMin();
        // Sem orderBy no servidor (evita índice composto); ordena aqui.
        final consulta = await _col(_colPedidos).where('status', whereIn: _statusFilaAtiva).get();
        final agora = DateTime.now().millisecondsSinceEpoch;
        final ativos = consulta.docs.map((d) {
          final t = d.data()['criadoEm'];
          return (
            id: d.id,
            status: lerString(d.data()['status']),
            ms: t is Timestamp ? t.millisecondsSinceEpoch : agora,
          );
        }).toList()
          ..sort((a, b) {
            final c = a.ms.compareTo(b.ms);
            return c != 0 ? c : a.id.compareTo(b.id);
          });

        final indice = ativos.indexWhere((a) => a.id == pedidoId);
        if (indice == -1) return fora();
        final etapas = <EtapaFila>[];
        for (var i = 0; i <= indice; i++) {
          etapas.add(EtapaFila(
            ordem: i + 1,
            status: StatusPedido.deId(ativos[i].status),
            ehMeu: ativos[i].id == pedidoId,
          ));
        }
        return FilaInfo(
          naFila: true,
          status: StatusPedido.deId(status),
          posicao: indice + 1,
          pedidosAFrente: indice,
          esperaEstimadaMin: indice * tempoMedio,
          etapas: etapas,
        );
      });

  // ---- empréstimos / devolução ----------------------------------------
  Future<void> solicitarDevolucao(String emprestimoId) => _rodar(() async {
        final ator = _ator();
        await _db.runTransaction<void>((tx) async {
          final ref = _doc(_colEmprestimos, emprestimoId);
          final snap = await tx.get(ref);
          final e = snap.data();
          if (!snap.exists || e == null) _erro('not-found', 'emprestimo-inexistente');
          if (e['solicitanteId'] != ator.uid) _erro('permission-denied', 'emprestimo-de-outro-usuario');
          if (e['status'] == 'devolucaoSolicitada') return;
          if (e['status'] != 'emPosse') {
            _erro('failed-precondition', 'emprestimo-nao-esta-em-posse', {'status': e['status']});
          }
          tx.update(ref, <String, dynamic>{
            'status': 'devolucaoSolicitada',
            'devolucaoSolicitadaEm': FieldValue.serverTimestamp(),
            'atualizadoEm': FieldValue.serverTimestamp(),
          });
        });
      });

  Future<ResultadoDevolucao> registrarDevolucao({
    required String emprestimoId,
    required int ok,
    required int danificadas,
    required int perdidas,
    String? observacoes,
  }) =>
      _rodar(() async {
        final ator = _equipe();
        if (ok < 0 || danificadas < 0 || perdidas < 0) {
          _erro('invalid-argument', 'inteiro-nao-negativo-obrigatorio');
        }
        final total = ok + danificadas + perdidas;
        if (total < 1) _erro('invalid-argument', 'devolucao-vazia');
        final obs = (observacoes ?? '').trim();

        return _db.runTransaction<ResultadoDevolucao>((tx) async {
          final empRef = _doc(_colEmprestimos, emprestimoId);
          final empSnap = await tx.get(empRef);
          final e = empSnap.data();
          if (!empSnap.exists || e == null) _erro('not-found', 'emprestimo-inexistente');
          final status = lerString(e['status']);
          if (status == 'devolvido') _erro('failed-precondition', 'emprestimo-ja-devolvido');
          final aceitos = kPermitirDevolucaoSemPedido ? ['devolucaoSolicitada', 'emPosse'] : ['devolucaoSolicitada'];
          if (!aceitos.contains(status)) {
            _erro('failed-precondition', 'devolucao-nao-solicitada', {'status': status});
          }
          final falta = _restante(e);
          if (total > falta) {
            _erro('failed-precondition', 'devolucao-maior-que-pendente', {'pendente': falta, 'informado': total});
          }
          final restanteDepois = falta - total;
          final item = _lerItem(await tx.get(_doc(_colItens, lerString(e['itemId']))));
          final baixas = danificadas + perdidas;
          final novos = _aplicar(item.cont, -baixas, -ok - baixas);

          // --- escritas ---
          _gravarCont(tx, item.id, novos);
          final cod = lerString(e['pedidoCodigo']);
          final complemento = obs.isEmpty ? '' : ' — $obs';
          final pedidoId = lerStringOpc(e['pedidoId']);
          if (ok > 0) {
            _mov(tx,
                ator: ator,
                itemId: item.id,
                itemNome: item.nome,
                tipo: 'devolucao',
                quantidade: ok,
                dTotal: 0,
                dUso: -ok,
                pedidoId: pedidoId,
                emprestimoId: emprestimoId);
          }
          if (danificadas > 0) {
            _mov(tx,
                ator: ator,
                itemId: item.id,
                itemNome: item.nome,
                tipo: 'baixa',
                quantidade: danificadas,
                dTotal: -danificadas,
                dUso: -danificadas,
                pedidoId: pedidoId,
                emprestimoId: emprestimoId,
                motivo: 'Danificado na devolução do pedido $cod$complemento'.trim());
          }
          if (perdidas > 0) {
            _mov(tx,
                ator: ator,
                itemId: item.id,
                itemNome: item.nome,
                tipo: 'baixa',
                quantidade: perdidas,
                dTotal: -perdidas,
                dUso: -perdidas,
                pedidoId: pedidoId,
                emprestimoId: emprestimoId,
                motivo: 'Perdido na devolução do pedido $cod$complemento'.trim());
          }
          final fechou = restanteDepois == 0;
          tx.update(empRef, <String, dynamic>{
            'quantidadeDevolvida': lerInt(e['quantidadeDevolvida']) + ok,
            'quantidadeDanificada': lerInt(e['quantidadeDanificada']) + danificadas,
            'quantidadePerdida': lerInt(e['quantidadePerdida']) + perdidas,
            'status': fechou ? 'devolvido' : 'emPosse',
            'devolucaoSolicitadaEm': fechou ? e['devolucaoSolicitadaEm'] : null,
            'devolvidoEm': fechou ? FieldValue.serverTimestamp() : null,
            'recebidoPorId': ator.uid,
            'recebidoPorNome': ator.nome,
            if (obs.isNotEmpty) 'observacoes': obs,
            'atualizadoEm': FieldValue.serverTimestamp(),
          });
          return ResultadoDevolucao(status: fechou ? 'devolvido' : 'emPosse', restante: restanteDepois);
        });
      });

  // ---- estoque ---------------------------------------------------------
  Future<void> entradaEstoque({required String itemId, required int quantidade, String? motivo}) =>
      _rodar(() async {
        final ator = _equipe();
        if (quantidade < 1) _erro('invalid-argument', 'inteiro-positivo-obrigatorio', {'campo': 'quantidade'});
        final mot = (motivo ?? '').trim();
        await _db.runTransaction<void>((tx) async {
          final item = _lerItem(await tx.get(_doc(_colItens, itemId)));
          final novos = _aplicar(item.cont, quantidade, 0);
          _gravarCont(tx, itemId, novos);
          _mov(tx,
              ator: ator,
              itemId: itemId,
              itemNome: item.nome,
              tipo: 'entrada',
              quantidade: quantidade,
              dTotal: quantidade,
              dUso: 0,
              motivo: mot.isEmpty ? null : mot);
        });
      });

  Future<ResultadoAjuste> ajusteEstoque({
    required String itemId,
    required int contagemFisica,
    required String motivo,
  }) =>
      _rodar(() async {
        final ator = _equipe();
        if (contagemFisica < 0) _erro('invalid-argument', 'inteiro-nao-negativo-obrigatorio', {'campo': 'contagemFisica'});
        final mot = motivo.trim();
        if (mot.isEmpty) _erro('invalid-argument', 'campo-obrigatorio', {'campo': 'motivo'});

        // Empréstimos em aberto deste item (filtra o status aqui para não exigir índice).
        final abertos = await _col(_colEmprestimos).where('itemId', isEqualTo: itemId).get();
        final idsAbertos = abertos.docs
            .where((d) => const ['emPosse', 'devolucaoSolicitada'].contains(d.data()['status']))
            .map((d) => d.id)
            .toList();

        return _db.runTransaction<ResultadoAjuste>((tx) async {
          final item = _lerItem(await tx.get(_doc(_colItens, itemId)));
          var emMaos = 0;
          for (final id in idsAbertos) {
            final s = await tx.get(_doc(_colEmprestimos, id));
            final d = s.data();
            if (d != null && const ['emPosse', 'devolucaoSolicitada'].contains(d['status'])) {
              emMaos += _restante(d);
            }
          }
          final reservadas = item.cont.emUso - emMaos;
          if (reservadas < 0) {
            _erro('failed-precondition', 'estoque-inconsistente', {'emUso': item.cont.emUso, 'emMaos': emMaos});
          }
          if (contagemFisica < reservadas) {
            _erro('failed-precondition', 'contagem-menor-que-reservas',
                {'reservadas': reservadas, 'contagem': contagemFisica});
          }
          final novoTotal = emMaos + contagemFisica;
          final delta = novoTotal - item.cont.total;
          if (delta == 0) {
            return ResultadoAjuste(delta: 0, estoqueTotal: item.cont.total, semDiferenca: true);
          }
          final novos = _aplicar(item.cont, delta, 0);
          _gravarCont(tx, itemId, novos);
          _mov(tx,
              ator: ator,
              itemId: itemId,
              itemNome: item.nome,
              tipo: 'ajuste',
              quantidade: delta.abs(),
              dTotal: delta,
              dUso: 0,
              motivo: '$mot [contagem física: $contagemFisica; esperado no depósito: ${contagemFisica - delta}]');
          return ResultadoAjuste(delta: delta, estoqueTotal: novoTotal, semDiferenca: false);
        });
      });

  Future<void> baixaEstoque({required String itemId, required int quantidade, required String motivo}) =>
      _rodar(() async {
        final ator = _equipe();
        if (quantidade < 1) _erro('invalid-argument', 'inteiro-positivo-obrigatorio', {'campo': 'quantidade'});
        final mot = motivo.trim();
        if (mot.isEmpty) _erro('invalid-argument', 'campo-obrigatorio', {'campo': 'motivo'});
        await _db.runTransaction<void>((tx) async {
          final item = _lerItem(await tx.get(_doc(_colItens, itemId)));
          if (quantidade > item.cont.disponivel) {
            _erro('failed-precondition', 'baixa-maior-que-disponivel', {
              'item': item.nome,
              'disponivel': item.cont.disponivel,
              'solicitado': quantidade,
            });
          }
          final novos = _aplicar(item.cont, -quantidade, 0);
          _gravarCont(tx, itemId, novos);
          _mov(tx,
              ator: ator,
              itemId: itemId,
              itemNome: item.nome,
              tipo: 'baixa',
              quantidade: quantidade,
              dTotal: -quantidade,
              dUso: 0,
              motivo: mot);
        });
      });

  // ---- catálogo (admin) -----------------------------------------------
  Future<void> criarItem({
    required String nome,
    required Categoria categoria,
    required bool retornavel,
    required int estoqueInicial,
    required int estoqueMinimo,
    required String unidade,
  }) =>
      _rodar(() async {
        final ator = _admin();
        final n = nome.trim();
        if (n.isEmpty) _erro('invalid-argument', 'campo-obrigatorio', {'campo': 'nome'});
        if (estoqueInicial < 0 || estoqueMinimo < 0) {
          _erro('invalid-argument', 'inteiro-nao-negativo-obrigatorio');
        }
        final un = unidade.trim().isEmpty ? 'un' : unidade.trim();
        final ref = _col(_colItens).doc();
        await _db.runTransaction<void>((tx) async {
          tx.set(ref, <String, dynamic>{
            'nome': n,
            'categoria': categoria.id,
            'retornavel': retornavel,
            'estoqueTotal': estoqueInicial,
            'emUso': 0,
            'estoqueMinimo': estoqueMinimo,
            'unidade': un,
            'ativo': true,
            'criadoEm': FieldValue.serverTimestamp(),
            'atualizadoEm': FieldValue.serverTimestamp(),
          });
          if (estoqueInicial > 0) {
            _mov(tx,
                ator: ator,
                itemId: ref.id,
                itemNome: n,
                tipo: 'entrada',
                quantidade: estoqueInicial,
                dTotal: estoqueInicial,
                dUso: 0,
                motivo: 'Carga inicial');
          }
        });
      });

  /// Só os campos informados são alterados.
  Future<void> editarItem(
    String itemId, {
    String? nome,
    Categoria? categoria,
    bool? retornavel,
    int? estoqueMinimo,
    String? unidade,
  }) =>
      _rodar(() async {
        _admin();
        final mudancas = <String, dynamic>{};
        if (nome != null) {
          if (nome.trim().isEmpty) _erro('invalid-argument', 'campo-obrigatorio', {'campo': 'nome'});
          mudancas['nome'] = nome.trim();
        }
        if (categoria != null) mudancas['categoria'] = categoria.id;
        if (retornavel != null) mudancas['retornavel'] = retornavel;
        if (estoqueMinimo != null) {
          if (estoqueMinimo < 0) _erro('invalid-argument', 'inteiro-nao-negativo-obrigatorio');
          mudancas['estoqueMinimo'] = estoqueMinimo;
        }
        if (unidade != null) {
          if (unidade.trim().isEmpty) _erro('invalid-argument', 'campo-obrigatorio', {'campo': 'unidade'});
          mudancas['unidade'] = unidade.trim();
        }
        if (mudancas.isEmpty) _erro('invalid-argument', 'nada-para-alterar');
        await _db.runTransaction<void>((tx) async {
          final ref = _doc(_colItens, itemId);
          final item = _lerItem(await tx.get(ref));
          if (retornavel != null && retornavel != item.retornavel && item.cont.emUso > 0) {
            _erro('failed-precondition', 'item-em-uso', {'item': item.nome, 'emUso': item.cont.emUso});
          }
          tx.update(ref, <String, dynamic>{...mudancas, 'atualizadoEm': FieldValue.serverTimestamp()});
        });
      });

  // ---- locais (admin) -------------------------------------------------
  Map<String, dynamic> _dadosLocal(String unidade, String predio, String andar, String identificador, int capacidade) {
    if (identificador.trim().isEmpty) _erro('invalid-argument', 'campo-obrigatorio', {'campo': 'identificador'});
    if (capacidade < 0) _erro('invalid-argument', 'inteiro-nao-negativo-obrigatorio');
    return <String, dynamic>{
      'unidade': unidade.trim(),
      'predio': predio.trim(),
      'andar': andar.trim(),
      'identificador': identificador.trim(),
      'capacidadeMaxima': capacidade,
    };
  }

  Future<void> criarLocal({
    required String unidade,
    required String predio,
    required String andar,
    required String identificador,
    required int capacidadeMaxima,
  }) =>
      _rodar(() async {
        _admin();
        final dados = _dadosLocal(unidade, predio, andar, identificador, capacidadeMaxima);
        await _col(_colLocais).add(<String, dynamic>{...dados, 'criadoEm': FieldValue.serverTimestamp()});
      });

  Future<void> editarLocal(
    String localId, {
    required String unidade,
    required String predio,
    required String andar,
    required String identificador,
    required int capacidadeMaxima,
  }) =>
      _rodar(() async {
        _admin();
        final dados = _dadosLocal(unidade, predio, andar, identificador, capacidadeMaxima);
        await _doc(_colLocais, localId).update(dados);
      });

  /// Pedidos antigos guardam o nome da sala, então continuam legíveis.
  Future<void> excluirLocal(String localId) => _rodar(() async {
        _admin();
        await _doc(_colLocais, localId).delete();
      });

  Future<void> definirItemAtivo(String itemId, bool ativo) => _rodar(() async {
        _admin();
        await _db.runTransaction<void>((tx) async {
          final ref = _doc(_colItens, itemId);
          _lerItem(await tx.get(ref));
          tx.update(ref, <String, dynamic>{'ativo': ativo, 'atualizadoEm': FieldValue.serverTimestamp()});
        });
      });
}
