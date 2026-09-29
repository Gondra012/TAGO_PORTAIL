import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

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
  final String _serverUrl = 'http://10.5.5';
  
  BlueThermalPrinter printer = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;
  bool _isPrinting = false;
  String _statusMessage = "Associez votre imprimante Bluetooth";

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  // Initialisation et recherche des périphériques Bluetooth
  Future<void> _initBluetooth() async {
    try {
      List<BluetoothDevice> devices = await printer.getBondedDevices();
      bool? isConnected = await printer.isConnected;
      setState(() {
        _devices = devices;
        _connected = isConnected ?? false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Erreur Bluetooth : Activez le Bluetooth";
      });
    }
  }

  // Connexion à l'imprimante sélectionnée
  void _connectPrinter() {
    if (_selectedDevice != null) {
      printer.connect(_selectedDevice!).then((value) {
        setState(() {
          _connected = true;
          _statusMessage = "Imprimante connectée avec succès !";
        });
      }).catchError((error) {
        setState(() {
          _connected = false;
          _statusMessage = "Échec de la connexion à l'imprimante.";
        });
      });
    }
  }

  // Action principale : Générer sur MikroTik ET Imprimer le ticket physique
  Future<void> _genererEtImprimerTicket() async {
    if (!_connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez d'abord connecter votre imprimante thermique !")),
      );
      return;
    }

    setState(() {
      _isPrinting = true;
      _statusMessage = "Création du ticket sur le MikroTik...";
    });

    try {
      // 1. Demande de création du ticket au serveur local PHP (Profil par défaut : 1h)
      final response = await http.post(
        Uri.parse(_serverUrl),
        body: {'profil': '1h'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String username = data['username'];
        String password = data['password'];
        String validite = data['validite'] ?? "1 Heure";

        setState(() {
          _statusMessage = "Ticket créé ! Impression en cours...";
        });

        // 2. Envoi du design de reçu à l'imprimante ESC/POS
        printer.printNewLine();
        printer.printCustom("TAGO PORTAIL", 3, 1); // Texte en gras et centré
        printer.printCustom("Transport Burkinabe d'energie", 1, 1);
        printer.printCustom("--------------------------------", 1, 1);
        printer.printNewLine();
        printer.printCustom("CODE ACCES WI-FI", 2, 1);
        printer.printCustom("Utilisateur : $username", 2, 0); // Alignement gauche
        printer.printCustom("Mot de passe : $password", 2, 0);
        printer.printNewLine();
        printer.printCustom("Duree de validite : $validite", 1, 1);
        printer.printCustom("--------------------------------", 1, 1);
        printer.printCustom("Merci pour votre confiance !", 1, 1);
        printer.printNewLine();
        printer.printNewLine();
        printer.paperCut(); // Découpe du papier (si supportée par la machine)

        setState(() {
          _statusMessage = "Ticket imprimé avec succès !";
        });
      } else {
        setState(() {
          _statusMessage = "Erreur de création : Problème API MikroTik.";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Erreur réseau : AWebServer injoignable.";
      });
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TAGO PORTAIL - Impression', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Sélection Imprimante
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    const Text("Configuration de l'imprimante", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<BluetoothDevice>(
                            items: _devices.map((device) => DropdownMenuItem(value: device, child: Text(device.name ?? "Inconnu"))).toList(),
                            onChanged: (device) {
                              setState(() => _selectedDevice = device);
                            },
                            value: _selectedDevice,
                            isExpanded: true,
                            hint: const Text("Sélectionner l'imprimante"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _connectPrinter,
                          style: ElevatedButton.styleFrom(backgroundColor: _connected ? Colors.green : Colors.orange),
                          child: Text(_connected ? "Connecté" : "Associer", style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Zone d'affichage du statut
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: _connected ? Colors.green : Colors.black54, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            // Bouton Principal de Production de Ticket
            _isPrinting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _genererEtImprimerTicket,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.print, size: 30),
                    label: const Text('IMPRIMER TICKET WI-FI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
