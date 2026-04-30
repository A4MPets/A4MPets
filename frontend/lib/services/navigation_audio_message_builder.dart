import '../models/route_navigation_instruction.dart';

class NavigationAudioMessageBuilder {
  const NavigationAudioMessageBuilder._();

  static String buildFarApproachMessage(RouteNavigationInstruction instruction) {
    final String? maneuver = _maneuverLabel(instruction.sign);
    if (maneuver != null) {
      return 'En 100 metros, $maneuver';
    }

    return _fallbackInstructionText(instruction);
  }

  static String buildApproachMessage(RouteNavigationInstruction instruction) {
    final String? maneuver = _maneuverLabel(instruction.sign);
    if (maneuver != null) {
      return 'En 30 metros, $maneuver';
    }

    return _fallbackInstructionText(instruction);
  }

  static String buildImmediateMessage(RouteNavigationInstruction instruction) {
    final String? maneuver = _maneuverLabel(instruction.sign, immediate: true);
    if (maneuver != null) {
      return maneuver;
    }

    return _fallbackInstructionText(instruction);
  }

  static String buildDangerMessage() {
    return 'Cuidado, estás dentro del radio de afectación de un peligro';
  }

  static String buildArrivalMessage() {
    return 'Has llegado a tu destino';
  }

  static String? _maneuverLabel(int sign, {bool immediate = false}) {
    switch (sign) {
      case -3:
        return immediate
            ? 'Gira ahora pronunciadamente a la izquierda'
            : 'gira pronunciadamente a la izquierda';
      case -2:
        return immediate ? 'Gira ahora a la izquierda' : 'gira a la izquierda';
      case -1:
        return immediate
            ? 'Gira ahora levemente a la izquierda'
            : 'gira levemente a la izquierda';
      case 1:
        return immediate
            ? 'Gira ahora levemente a la derecha'
            : 'gira levemente a la derecha';
      case 2:
        return immediate ? 'Gira ahora a la derecha' : 'gira a la derecha';
      case 3:
        return immediate
            ? 'Gira ahora pronunciadamente a la derecha'
            : 'gira pronunciadamente a la derecha';
      case 6:
        return immediate
            ? 'Entra ahora a la rotonda'
            : 'entra a la rotonda';
      case -98:
        return immediate ? 'Haz ahora un retorno' : 'haz un retorno';
      case 98:
        return immediate ? 'Haz ahora un retorno' : 'haz un retorno';
      default:
        return null;
    }
  }

  static String _fallbackInstructionText(RouteNavigationInstruction instruction) {
    final String text = instruction.text.trim();
    if (text.isEmpty) {
      return 'Continua por la ruta';
    }
    return text;
  }
}
