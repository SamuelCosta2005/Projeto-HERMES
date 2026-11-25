/// Ordem de exibição dos andares: Subsolo, Térreo, 1º, 2º, ... e o resto no fim.
int ordemAndar(String andar) {
  final a = andar.toLowerCase().trim();
  if (a.isEmpty) return 1000;
  if (a.contains('subsolo')) return -1;
  if (a.contains('térreo') || a.contains('terreo')) return 0;
  final m = RegExp(r'\d+').firstMatch(a);
  if (m != null) return int.parse(m.group(0)!);
  return 500;
}

/// "Térreo" -> "TÉRREO"; "1º" -> "1º ANDAR"; "" -> "SEM ANDAR".
String rotuloAndar(String andar) {
  final a = andar.trim();
  if (a.isEmpty) return 'SEM ANDAR';
  final maiusculo = a.toUpperCase();
  if (RegExp(r'^\d').hasMatch(a) && !a.toLowerCase().contains('andar')) {
    return '$maiusculo ANDAR';
  }
  return maiusculo;
}
