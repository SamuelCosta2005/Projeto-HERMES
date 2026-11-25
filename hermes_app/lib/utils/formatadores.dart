String _d2(int n) => n.toString().padLeft(2, '0');

String horaCurta(DateTime d) => '${_d2(d.hour)}:${_d2(d.minute)}';
String dataCurta(DateTime d) => '${_d2(d.day)}/${_d2(d.month)}';

/// "12/10 09:41" (ou "—" se não houver data).
String dataHora(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  return '${dataCurta(l)} ${horaCurta(l)}';
}

/// "Hoje, 09:41", "Ontem, 18:20" ou "12/10, 09:41".
String horaRelativa(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  final agora = DateTime.now();
  final hoje = DateTime(agora.year, agora.month, agora.day);
  final dia = DateTime(l.year, l.month, l.day);
  final dias = hoje.difference(dia).inDays;
  if (dias == 0) return 'Hoje, ${horaCurta(l)}';
  if (dias == 1) return 'Ontem, ${horaCurta(l)}';
  return '${dataCurta(l)}, ${horaCurta(l)}';
}

/// "agora", "há 5 min", "há 3 h", "há 2 dias".
String haQuanto(DateTime? d) {
  if (d == null) return '—';
  final dif = DateTime.now().difference(d);
  if (dif.inMinutes < 1) return 'agora';
  if (dif.inMinutes < 60) return 'há ${dif.inMinutes} min';
  if (dif.inHours < 24) return 'há ${dif.inHours} h';
  final dias = dif.inDays;
  return dias == 1 ? 'há 1 dia' : 'há $dias dias';
}

/// Texto da previsão de entrega: "~ 12 min", "Em instantes" ou "—".
String textoEta(DateTime? previsao) {
  if (previsao == null) return '—';
  final min = previsao.difference(DateTime.now()).inMinutes;
  if (min <= 0) return 'Em instantes';
  return '~ $min min';
}

/// Limita [v] ao intervalo [minimo, maximo] (sempre devolve int).
int limitar(int v, int minimo, int maximo) {
  if (v < minimo) return minimo;
  if (v > maximo) return maximo;
  return v;
}

/// "01 unidade", "03 unidades" (formato da tela de pedido aprovado).
String quantidadeEmTexto(int n) =>
    '${n.toString().padLeft(2, '0')} ${n == 1 ? 'unidade' : 'unidades'}';
