/// Estado de localização/entrega do robô em tempo real (tela "Mapa").
class TrackingStatus {
  final String buildingLabel; // "MAPA DA FILIAL (PRÉDIO INDUSTRIAL 4)"
  final String robotLabel; // "HERMES V2 NO CORREDOR 3"
  final String originLabel; // "DEPÓSITO (A)"
  final String destinationLabel; // "VOCÊ (SETOR B)"
  final String statusText; // "A caminho do Setor B"
  final String etaText; // "4 Minutos"
  final double progress; // 0.0 - 1.0

  const TrackingStatus({
    required this.buildingLabel,
    required this.robotLabel,
    required this.originLabel,
    required this.destinationLabel,
    required this.statusText,
    required this.etaText,
    required this.progress,
  });

  String get progressLabel => '${(progress * 100).round()}% concluído';
}
