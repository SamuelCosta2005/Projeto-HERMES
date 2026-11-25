import 'package:flutter/material.dart';

/// Categorias aceitas pelo backend ('ti' e 'mecanica').
enum Categoria {
  ti('ti', 'T.I.', 'Hardware e Acessórios', 'Tecnologia da Informação', Icons.computer_rounded),
  mecanica('mecanica', 'Mecânica', 'Ferramentas e Peças', 'Mecânica', Icons.build_rounded);

  const Categoria(this.id, this.nome, this.subtitulo, this.nomeCompleto, this.icone);

  final String id;
  final String nome;
  final String subtitulo;
  final String nomeCompleto;
  final IconData icone;

  static Categoria deId(String? id) {
    for (final c in Categoria.values) {
      if (c.id == id) return c;
    }
    return Categoria.ti;
  }
}
