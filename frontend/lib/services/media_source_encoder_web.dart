Future<String?> encodeImageSourceToDataUri(String source) async {
  if (source.startsWith('data:image')) {
    return source;
  }
  return null;
}
