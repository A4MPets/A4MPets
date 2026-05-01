import 'dart:convert';

void main() {
  const String jsonStr = '[{"id": 1}]';
  final List<dynamic> decoded = jsonDecode(jsonStr) as List<dynamic>;
  
  try {
    final List<Map<String, Object?>> list = decoded.map((dynamic item) => item as Map<String, Object?>).toList();
    print('Success!');
  } catch (e) {
    print('Error: $e');
  }
}
