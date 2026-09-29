import 'package:flutter/material.dart';

void main() {
  runApp(const TagoPortailApp());
}

class TagoPortailApp extends StatelessWidget {
  const TagoPortailApp({super.key});

  @override
  Widget build(BuildContext WidgetContext) {
    return MaterialApp(
      title: 'TAGO PORTAIL',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext WidgetContext) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TAGO PORTAIL - Wi-Fi Zone'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Gestionnaire de Tickets local via AWebServer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                // Action pour générer un ticket
              },
              icon: const Icon(Icons.add),
              label: const Text('Générer un Ticket'),
            ),
          ],
        ),
      ),
    );
  }
}
