import 'package:flutter/material.dart';
import '../models/emprestimo.dart';
import '../models/pedido.dart';
import '../theme/app_colors.dart';
import 'chip_rotulo.dart';

/// Etiqueta colorida do status de um pedido.
Widget chipStatusPedido(StatusPedido s) {
  switch (s) {
    case StatusPedido.queued:
      return ChipRotulo(texto: s.rotulo, cor: AppColors.textSecondary, fundo: AppColors.surfaceAlt);
    case StatusPedido.inTransit:
      return ChipRotulo(texto: s.rotulo, cor: AppColors.accent, fundo: AppColors.accentBackground);
    case StatusPedido.arrived:
    case StatusPedido.delivered:
      return ChipRotulo(texto: s.rotulo, cor: AppColors.success, fundo: AppColors.successBackground);
    case StatusPedido.cancelled:
      return ChipRotulo(texto: s.rotulo, cor: AppColors.warning, fundo: AppColors.warningBackground);
  }
}

/// Etiqueta colorida do status de um empréstimo.
Widget chipStatusEmprestimo(StatusEmprestimo s) {
  switch (s) {
    case StatusEmprestimo.emPosse:
      return ChipRotulo(texto: s.rotulo, cor: AppColors.textSecondary, fundo: AppColors.surfaceAlt);
    case StatusEmprestimo.devolucaoSolicitada:
      return ChipRotulo(texto: s.rotulo, cor: AppColors.accent, fundo: AppColors.accentBackground);
    case StatusEmprestimo.devolvido:
      return ChipRotulo(texto: s.rotulo, cor: AppColors.success, fundo: AppColors.successBackground);
  }
}
