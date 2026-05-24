import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lijsttedoen/main.dart';

void main() {
  testWidgets('Todo list app smoke test', (WidgetTester tester) async {
    // Set mock initial values for SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Bangun aplikasi utama dan picu frame awal.
    await tester.pumpWidget(const MyApp());
    
    // Tunggu proses asinkron SharedPreferences selesai dan loading berakhir
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verifikasi bahwa teks header "tasks left" atau sisa tugas muncul di layar utama
    expect(find.textContaining('tasks left'), findsOneWidget);

    // Verifikasi bahwa ikon FAB tambah tugas baru ada di layar
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
