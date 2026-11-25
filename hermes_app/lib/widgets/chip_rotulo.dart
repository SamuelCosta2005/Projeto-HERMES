import 'package:flutter/material.dart';

/// Etiqueta pequena e colorida (status, "Retornável", "Estoque baixo"...).
class ChipRotulo extends StatelessWidget {
  final String texto;
  final Color cor;
  final Color fundo;

  const ChipRotulo({super.key, required this.texto, required this.cor, required this.fundo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(7)),
      child: Text(
        texto.toUpperCase(),
        style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.3),
      ),
    );
  }
}
