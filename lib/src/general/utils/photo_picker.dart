import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Imagen elegida por el usuario, lista para previsualizar y subir.
class PickedPhoto {
  final Uint8List bytes;
  final String fileName;

  const PickedPhoto(this.bytes, this.fileName);
}

/// Abre la cámara o la galería; devuelve null si el usuario cancela.
typedef PhotoPicker = Future<PickedPhoto?> Function(ImageSource source);

const maxPhotoBytes = 2 * 1024 * 1024;

/// Selector real del dispositivo. La imagen se reduce y comprime antes de subirla.
Future<PickedPhoto?> pickPhotoFromDevice(ImageSource source) async {
  final file = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
  );
  if (file == null) return null;
  return PickedPhoto(await file.readAsBytes(), file.name);
}

/// Mismas reglas que el backend: JPG o PNG (según su contenido) y máximo 2 MB.
String? validatePhoto(Uint8List bytes) {
  if (bytes.length > maxPhotoBytes) return 'The photo cannot be larger than 2 MB';
  final isJpeg = bytes.length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
  final isPng = bytes.length > 7 &&
      bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47;
  return isJpeg || isPng ? null : 'The photo must be a JPG or PNG image';
}
