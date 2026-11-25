import 'pedido.dart';
import 'util.dart';

/// Uma etapa da fila, SEM identificar de quem é (só o próprio usuário se reconhece).
class EtapaFila {
  final int ordem;
  final StatusPedido status;
  final bool ehMeu;

  const EtapaFila({required this.ordem, required this.status, required this.ehMeu});
}

/// Resposta anônima de hermesConsultarFila.
class FilaInfo {
  final bool naFila;
  final StatusPedido status;
  final int posicao;
  final int pedidosAFrente;
  final int esperaEstimadaMin;
  final List<EtapaFila> etapas;

  const FilaInfo({
    required this.naFila,
    required this.status,
    required this.posicao,
    required this.pedidosAFrente,
    required this.esperaEstimadaMin,
    required this.etapas,
  });

  factory FilaInfo.deMapa(Map<String, dynamic> m) {
    return FilaInfo(
      naFila: lerBool(m['naFila']),
      status: StatusPedido.deId(lerStringOpc(m['status'])),
      posicao: lerInt(m['posicao']),
      pedidosAFrente: lerInt(m['pedidosAFrente']),
      esperaEstimadaMin: lerInt(m['esperaEstimadaMin']),
      etapas: listaDeMapas(m['etapas'])
          .map((e) => EtapaFila(
                ordem: lerInt(e['ordem']),
                status: StatusPedido.deId(lerStringOpc(e['status'])),
                ehMeu: lerBool(e['ehMeu']),
              ))
          .toList(),
    );
  }
}
