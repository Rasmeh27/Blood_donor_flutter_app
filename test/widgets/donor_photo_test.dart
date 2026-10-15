import 'dart:typed_data';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:proyecto_laboratorio_intec/src/general/utils/photo_picker.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/donor_registration/screens/donor_registration_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/profile/screens/profile_screen.dart';

import '../support/fake_backend.dart';
import '../support/widget_helpers.dart';

// PNG real de 1x1 píxel
final pngPixel = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');

Map<String, dynamic> donorJson({bool hasPhoto = false}) => {
      'id': 1,
      'name': 'Ana Donante',
      'contactNumber': '+18092249304',
      'bloodGroup': 'B+',
      'location': 'Santiago',
      'lastDonationDate': '2026-06-01',
      'visibleInSearch': false,
      'hasPhoto': hasPhoto,
    };

void main() {
  late FakeBackend backend;
  final pickedSources = <ImageSource>[];

  setUp(() {
    pickedSources.clear();
    backend = FakeBackend((request) {
      if (request.url.path.endsWith('/donors/me/photo')) {
        return request.method == 'GET'
            ? http.Response.bytes(pngPixel, 200, headers: {'content-type': 'image/png'})
            : FakeBackend.json(donorJson(hasPhoto: true), 200);
      }
      if (request.url.path.endsWith('/users/me')) return FakeBackend.json(userJson(), 200);
      return FakeBackend.json(donorJson(), 200);
    });
  });

  Future<PickedPhoto?> fakePicker(ImageSource source) async {
    pickedSources.add(source);
    return PickedPhoto(pngPixel, 'foto.png');
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  // Las imágenes de assets se decodifican de forma asíncrona; sin esto miden 0 px de alto en el test
  Future<void> loadImages(WidgetTester tester) async {
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pumpAndSettle();
  }

  Finder icon(String asset) => find.byWidgetPredicate(
      (widget) => widget is Image && widget.image is AssetImage && (widget.image as AssetImage).assetName == asset);

  testWidgets('galería y cámara abren el selector y muestran la vista previa', (tester) async {
    await installServices(backend, loggedIn: true);
    await pumpPushed(tester, DonorRegistrationForm(pickPhoto: fakePicker));
    await loadImages(tester);
    expect(icon('assets/icons/profile.png'), findsOneWidget);

    await tapVisible(tester, icon('assets/icons/gallary.png'));
    expect(pickedSources, [ImageSource.gallery]);
    expect(find.byType(ClipOval), findsOneWidget);
    expect(icon('assets/icons/profile.png'), findsNothing);

    await tapVisible(tester, icon('assets/icons/camera_2.png'));
    expect(pickedSources, [ImageSource.gallery, ImageSource.camera]);
  });

  testWidgets('Complete guarda el donante y sube la foto como multipart', (tester) async {
    await installServices(backend, loggedIn: true);
    await pumpPushed(tester, DonorRegistrationForm(pickPhoto: fakePicker));
    await loadImages(tester);

    await tapVisible(tester, icon('assets/icons/gallary.png'));
    await tapVisible(tester, find.text('Complete'));

    final methods = backend.requests.map((r) => '${r.method} ${r.url.path}').toList();
    expect(methods, containsAllInOrder(['PUT /api/v1/donors/me', 'PUT /api/v1/donors/me/photo']));
    final upload = backend.requestsTo('PUT', '/donors/me/photo').single;
    expect(upload.headers['content-type'], startsWith('multipart/form-data'));
    expect(utf8.decode(upload.bodyBytes, allowMalformed: true), contains('name="photo"; filename="foto.png"'));
    expect(find.text('Donor information updated'), findsOneWidget);
  });

  testWidgets('cancelar el selector no cambia nada', (tester) async {
    await installServices(backend, loggedIn: true);
    await pumpPushed(tester, DonorRegistrationForm(pickPhoto: (_) async => null));
    await loadImages(tester);

    await tapVisible(tester, icon('assets/icons/gallary.png'));

    expect(tester.takeException(), isNull);
    expect(icon('assets/icons/profile.png'), findsOneWidget);
  });

  testWidgets('rechaza archivos que no son JPG o PNG', (tester) async {
    await installServices(backend, loggedIn: true);
    await pumpPushed(tester, DonorRegistrationForm(
      pickPhoto: (_) async => PickedPhoto(utf8.encode('no es una imagen'), 'falsa.jpg'),
    ));
    await loadImages(tester);

    await tapVisible(tester, icon('assets/icons/gallary.png'));

    expect(find.text('The photo must be a JPG or PNG image'), findsOneWidget);
    expect(icon('assets/icons/profile.png'), findsOneWidget);
  });

  testWidgets('precarga la foto guardada del donante y Profile la muestra como avatar', (tester) async {
    backend.handler = (request) {
      if (request.url.path.endsWith('/donors/me/photo')) {
        return http.Response.bytes(pngPixel, 200, headers: {'content-type': 'image/png'});
      }
      if (request.url.path.endsWith('/users/me')) return FakeBackend.json(userJson(), 200);
      return FakeBackend.json(donorJson(hasPhoto: true), 200);
    };
    await installServices(backend, loggedIn: true);
    await pumpApp(tester, DonorRegistrationForm(pickPhoto: fakePicker));

    expect(backend.requestsTo('GET', '/donors/me/photo'), hasLength(1));
    expect(find.byType(ClipOval), findsOneWidget);

    await pumpApp(tester, const ProfileScreen());
    expect(find.byType(ClipOval), findsOneWidget);
    expect(icon('assets/images/profile.png'), findsNWidgets(1)); // solo el avatar del AppBar
  });

  test('validación de la foto: formato por contenido y tamaño máximo', () {
    expect(validatePhoto(pngPixel), isNull);
    expect(validatePhoto(utf8.encode('texto')), 'The photo must be a JPG or PNG image');
    final tooLarge = List<int>.filled(maxPhotoBytes + 1, 0)..setAll(0, [0xFF, 0xD8, 0xFF]);
    expect(validatePhoto(Uint8List.fromList(tooLarge)), 'The photo cannot be larger than 2 MB');
  });
}
