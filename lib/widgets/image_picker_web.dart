import 'dart:async';
import 'dart:html' as html;

Future<Map<String, dynamic>?> pickImage() async {
  final completer = Completer<Map<String, dynamic>?>();
  final input = html.InputElement(type: 'file');
  input.accept = 'image/*';
  input.onChange.listen((event) {
    if (input.files == null || input.files!.isEmpty) {
      completer.complete(null);
      return;
    }
    final file = input.files![0];
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoadEnd.listen((loadEvent) {
      completer.complete({
        'bytes': reader.result as List<int>,
        'name': file.name,
      });
    });
  });
  input.click();
  return completer.future;
}
