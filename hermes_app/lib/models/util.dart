import 'package:cloud_firestore/cloud_firestore.dart';

/// Leitura defensiva de campos vindos do Firestore / das Cloud Functions.
String lerString(dynamic v, [String padrao = '']) => v is String ? v : padrao;
String? lerStringOpc(dynamic v) => v is String && v.isNotEmpty ? v : null;
int lerInt(dynamic v, [int padrao = 0]) => v is num ? v.toInt() : padrao;
bool lerBool(dynamic v, [bool padrao = false]) => v is bool ? v : padrao;
DateTime? lerData(dynamic v) => v is Timestamp ? v.toDate() : null;

Map<String, dynamic> mapa(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> listaDeMapas(dynamic v) =>
    v is List ? v.map((e) => mapa(e)).toList() : <Map<String, dynamic>>[];
