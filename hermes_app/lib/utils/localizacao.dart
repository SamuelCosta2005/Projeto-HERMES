import 'package:geolocator/geolocator.dart';

/// Garante que o GPS está ligado e que o app tem permissão.
/// Devolve null se está tudo certo, ou o texto do problema.
Future<String?> garantirPermissaoLocalizacao() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return 'Ligue a localização (GPS) do aparelho.';
    }
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.denied) {
      return 'Permissão de localização negada.';
    }
    if (p == LocationPermission.deniedForever) {
      return 'Permissão de localização bloqueada. Libere nas configurações do aparelho.';
    }
    return null;
  } catch (e) {
    return 'Não foi possível usar a localização ($e).';
  }
}

/// "850 m" ou "1,2 km".
String formatarDistancia(double metros) {
  if (metros < 1000) return '${metros.round()} m';
  return '${(metros / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
}
