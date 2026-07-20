import 'dart:math';

String minidenticon(String seed, {int saturation = 95, int lightness = 45}) {
  // 1. FNV-1a Hash sederhana untuk memetakan string menjadi integer unik
  int hash = 2166136261;
  for (int i = 0; i < seed.length; i++) {
    hash ^= seed.codeUnitAt(i);
    hash = (hash * 16777619) & 0xFFFFFFFF;
  }

  // 2. Tentukan Hue (0 - 360 derajat) berdasarkan sisa bagi hash
  int hue = (hash % 360).abs();

  // Konversi HSL ke Hex Color agar didukung penuh oleh flutter_svg
  String hexColor = _hslToHex(
    hue.toDouble(),
    saturation.toDouble(),
    lightness.toDouble(),
  );

  // 3. Bangun matriks 5x5 secara simetris (3 kolom pertama menentukan 2 kolom terakhir)
  String rects = '';
  int bitIndex = 0;

  for (int x = 0; x < 3; x++) {
    for (int y = 0; y < 5; y++) {
      // Ambil bit ke-n dari hash untuk menentukan kotak ini diisi atau tidak
      bool isFilled = ((hash >> bitIndex) & 1) == 1;
      bitIndex++;

      if (isFilled) {
        // Gambar kotak di posisi koordinat grid utama
        rects += '<rect x="$x" y="$y" width="1" height="1" />';

        // Jika bukan kolom tengah (x != 2), buat salinan simetrisnya di sisi kanan
        if (x < 2) {
          int symmetricX = 4 - x;
          rects += '<rect x="$symmetricX" y="$y" width="1" height="1" />';
        }
      }
    }
  }

  // 4. Bungkus ke dalam format SVG standar dengan koordinat viewBox pas 5x5
  return '''
  <svg viewBox="0 0 5 5" xmlns="http://www.w3.org/2000/svg" fill="$hexColor">
    $rects
  </svg>
  ''';
}

// Fungsi bantu untuk mengubah HSL menjadi Hex String valid (#RRGGBB)
String _hslToHex(double h, double s, double l) {
  s /= 100;
  l /= 100;

  double c = (1 - (2 * l - 1).abs()) * s;
  double x = c * (1 - ((h / 60) % 2 - 1).abs());
  double m = l - c / 2;

  double r = 0, g = 0, b = 0;

  if (h >= 0 && h < 60) {
    r = c;
    g = x;
    b = 0;
  } else if (h >= 60 && h < 120) {
    r = x;
    g = c;
    b = 0;
  } else if (h >= 120 && h < 180) {
    r = 0;
    g = c;
    b = x;
  } else if (h >= 180 && h < 240) {
    r = 0;
    g = x;
    b = c;
  } else if (h >= 240 && h < 300) {
    r = x;
    g = 0;
    b = c;
  } else if (h >= 300 && h < 360) {
    r = c;
    g = 0;
    b = x;
  }

  int rInt = ((r + m) * 255).round().clamp(0, 255);
  int gInt = ((g + m) * 255).round().clamp(0, 255);
  int bInt = ((b + m) * 255).round().clamp(0, 255);

  return '#${rInt.toRadixString(16).padLeft(2, '0')}${gInt.toRadixString(16).padLeft(2, '0')}${bInt.toRadixString(16).padLeft(2, '0')}';
}
