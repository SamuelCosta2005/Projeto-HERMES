import 'package:flutter/material.dart';

bool _tem(String texto, List<String> palavras) {
  final t = texto.toLowerCase();
  for (final p in palavras) {
    if (t.contains(p)) return true;
  }
  return false;
}

/// Ícone do item, escolhido pelo nome (o banco não guarda ícone).
IconData iconeItem(String nome) {
  if (_tem(nome, ['hdmi', 'vga', 'adaptador'])) return Icons.settings_input_hdmi_rounded;
  if (_tem(nome, ['cabo', 'ethernet', 'rede'])) return Icons.cable_rounded;
  if (_tem(nome, ['mouse'])) return Icons.mouse_rounded;
  if (_tem(nome, ['teclado'])) return Icons.keyboard_rounded;
  if (_tem(nome, ['monitor', 'tela'])) return Icons.desktop_windows_rounded;
  if (_tem(nome, ['notebook', 'laptop'])) return Icons.laptop_rounded;
  if (_tem(nome, ['furadeira'])) return Icons.handyman_rounded;
  if (_tem(nome, ['chave', 'alicate', 'martelo'])) return Icons.build_rounded;
  if (_tem(nome, ['parafuso', 'porca', 'arruela'])) return Icons.settings_rounded;
  return Icons.inventory_2_rounded;
}

/// Ícone do local, escolhido pelo identificador.
IconData iconeLocal(String identificador) {
  if (_tem(identificador, ['t.i', 'informática', 'informatica', 'hardware'])) return Icons.dvr_rounded;
  if (_tem(identificador, ['almoxarifado', 'depósito', 'deposito'])) return Icons.inventory_2_rounded;
  if (_tem(identificador, ['mecânica', 'mecanica', 'oficina'])) return Icons.build_rounded;
  if (_tem(identificador, ['robótica', 'robotica'])) return Icons.smart_toy_rounded;
  if (_tem(identificador, ['laborat', 'maker'])) return Icons.science_rounded;
  if (_tem(identificador, ['engenharia'])) return Icons.architecture_rounded;
  if (_tem(identificador, ['auditório', 'auditorio'])) return Icons.theater_comedy_rounded;
  return Icons.meeting_room_rounded;
}
