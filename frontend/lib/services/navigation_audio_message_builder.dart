import '../models/route_navigation_instruction.dart';

class NavigationAudioMessageBuilder {
  const NavigationAudioMessageBuilder._();

  static String buildFarApproachMessage(RouteNavigationInstruction instruction) {
    final String? maneuver = _maneuverLabel(instruction);
    if (maneuver != null) return 'En 100 metros, $maneuver';

    return _fallbackInstructionText(instruction);
  }

  static String buildApproachMessage(RouteNavigationInstruction instruction) {
    final String? maneuver = _maneuverLabel(instruction);
    if (maneuver != null) return 'En 30 metros, $maneuver';

    return _fallbackInstructionText(instruction);
  }

  static String buildImmediateMessage(RouteNavigationInstruction instruction) {
    final String? maneuver = _maneuverLabel(instruction, immediate: true);
    if (maneuver != null) return maneuver;

    return _fallbackInstructionText(instruction);
  }

  static String buildDangerMessage() {
    return 'Cuidado, estás dentro del radio de afectación de un peligro';
  }

  static String buildArrivalMessage() {
    return 'Has llegado a tu destino';
  }

  static String? _maneuverLabel(RouteNavigationInstruction instruction, {bool immediate = false}) {
    switch (instruction.sign) {
      case -3:
        return immediate ? 'Gira ahora a la izquierda' : 'gira a la izquierda';
      case -2:
        return immediate ? 'Gira ahora a la izquierda' : 'gira a la izquierda';
      case -1:
        return immediate ? 'Gira ahora levemente a la izquierda' : 'gira levemente a la izquierda';
      case 1:
        return immediate ? 'Gira ahora levemente a la derecha' : 'gira levemente a la derecha';
      case 2:
        return immediate ? 'Gira ahora a la derecha' : 'gira a la derecha';
      case 3:
        return immediate ? 'Gira ahora a la derecha' : 'gira a la derecha';
      case 6:
        return _roundaboutLabel(instruction, immediate: immediate);
      case -98:
        return immediate ? 'Haz ahora un retorno' : 'haz un retorno';
      case 98:
        return immediate ? 'Haz ahora un retorno' : 'haz un retorno';
      default:
        return null;
    }
  }

  static String _roundaboutLabel(RouteNavigationInstruction instruction, {required bool immediate}) {
    final int? exitNumber = instruction.exitNumber ?? _extractExitNumber(instruction.text);
    final String exitText = exitNumber == null ? '' : ' y toma ${_roundaboutExitLabel(exitNumber)}';

    return immediate ? 'Entra ahora a la rotonda$exitText' : 'entra a la rotonda$exitText';
  }

  static int? _extractExitNumber(String text) {
    final String normalized = text.toLowerCase();
    final RegExpMatch? flexibleMatch = RegExp(
      r'(?:salida|exit)\s+(?:numero\s+)?(\d+)|(\d+)\D{0,4}(?:salida|exit)',
    ).firstMatch(normalized);
    final String? flexibleRaw = flexibleMatch?.group(1) ?? flexibleMatch?.group(2);
    if (flexibleRaw != null) return int.tryParse(flexibleRaw);

    final RegExpMatch? match = RegExp(
      r'(?:salida|exit)\s+(\d+)|(\d+)\s*(?:a|ª|ra|da|ta)?\s*(?:salida|exit)',
    ).firstMatch(normalized);
    final String? raw = match?.group(1) ?? match?.group(2);
    return raw == null ? null : int.tryParse(raw);
  }

  static String _roundaboutExitLabel(int exitNumber) {
    switch (exitNumber) {
      case 1:
        return 'la primera salida';
      case 2:
        return 'la segunda salida';
      case 3:
        return 'la tercera salida';
      case 4:
        return 'la cuarta salida';
      case 5:
        return 'la quinta salida';
      case 6:
        return 'la sexta salida';
      case 7:
        return 'la septima salida';
      case 8:
        return 'la octava salida';
      case 9:
        return 'la novena salida';
      default:
        return 'la salida numero $exitNumber';
    }
  }

  static String _fallbackInstructionText(RouteNavigationInstruction instruction) {
    final String text = instruction.text.trim();
    if (text.isEmpty) return 'Continua por la ruta';
    return text;
  }
}
