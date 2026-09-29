import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const TagoPortailApp());
}

class TagoPortailApp extends StatelessWidget {
  const TagoPortailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TAGO PORTAIL',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // L'adresse IP locale de votre serveur AWebServer (à ajuster si elle change)
  final String _serverUrl = 'http://10.5.5';
  
  String _statusMessage = "En attente de test de connexion...";
  bool _isLoading = false;
  Color _statusColor = Colors.grey;
  String _routerInfo = "";

  // Fonction pour appeler le script PHP sur AWebServer
  Future<void> _testerLiaison() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Connexion au serveur local en cours...";
      _statusColor = Colors.blue;
      _routerInfo = "";
    });

    try {
      final response = await http.get(Uri.parse(_serverUrl)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _statusMessage = data['message'] ?? "Connexion réussie !";
          _statusColor = Colors.green;
          _routerInfo = "Modèle : ${data['model']}\nVersion OS : ${data['version']}";
        });
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _statusMessage = data['message'] ?? "Erreur de connexion au routeur.";
          _statusColor = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Erreur : Impossible de joindre AWebServer.\nVérifiez l'adresse IP ou le wifi.";
        _statusColor = Colors.red;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TAGO PORTAIL - Wi-Fi Zone', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.router, size: 80, color: Colors.blue),
              ),
              const SizedBox(height: 30),
              const Text(
                'Gestionnaire MikroTik Local via AWebServer',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Zone d'affichage du statut de connexion
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _statusColor, width: 1.5),
                ),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              if (_routerInfo.isNotEmpty) ...[
                const SizedBox(height: 15),
                Text(
                  _routerInfo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black87, fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 40),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _testerLiaison,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tester la liaison MikroTik', style: TextStyle(fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
