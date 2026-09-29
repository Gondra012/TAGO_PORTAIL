import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

void main() => runApp(const TagoPortailApp());

class TagoPortailApp extends StatelessWidget {
  const TagoPortailApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TAGO PORTAIL',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
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
  final String _apiUrl = 'http://10.5.5';
  
  BlueThermalPrinter printer = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;
  bool _isActionLoading = false;
  String _statusMessage = "Initialisation...";

  List<dynamic> _forfaits = [];
  Map<String, dynamic>? _selectedForfait;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
    _chargerForfaits();
  }

  // Téléchargement dynamique des forfaits configurés par l'administrateur
  Future<void> _chargerForfaits() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        setState(() {
          _forfaits = jsonDecode(response.body);
          if (_forfaits.isNotEmpty) _selectedForfait = _forfaits[0];
          _statusMessage = "Forfaits synchronisés avec succès !";
        });
      }
    } catch (e) {
      setState(() => _statusMessage = "Impossible de récupérer les tarifs depuis AWebServer.");
    }
  }

  Future<void> _initBluetooth() async {
    try {
      List<BluetoothDevice> devices = await printer.getBondedDevices();
      bool? isConnected = await printer.isConnected;
      setState(() {
        _devices = devices;
        _connected = isConnected ?? false;
      });
    } catch (_) {}
  }

  void _connectPrinter() {
    if (_selectedDevice != null) {
      printer.connect(_selectedDevice!).then((_) {
        setState(() {
          _connected = true;
          _statusMessage = "Imprimante prête !";
        });
      });
    }
  }

  Future<void> _vendreTicket() async {
    if (!_connected || _selectedForfait == null) return;

    setState(() {
      _isActionLoading = true;
      _statusMessage = "Création du code d'accès...";
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        body: {
          'profil': _selectedForfait!['profil'],
          'nom_forfait': _selectedForfait!['nom']
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Impression du ticket avec prix dynamique
        printer.printNewLine();
        printer.printCustom("TAGO PORTAIL", 3, 1); 
        printer.printCustom("Transport Burkinabe d'energie", 1, 1);
        printer.printCustom("--------------------------------", 1, 1);
        printer.printCustom("TICKET FORFAIT : ${_selectedForfait!['nom']}", 1, 1);
        printer.printCustom("Prix : ${_selectedForfait!['prix']}", 2, 1);
        printer.printCustom("--------------------------------", 1, 1);
        printer.printCustom("Code Utilisateur : ${data['username']}", 2, 0); 
        printer.printCustom("Mot de passe     : ${data['password']}", 2, 0);
        printer.printNewLine();
        printer.printCustom("Merci et bon surf !", 1, 1);
        printer.printNewLine();
        printer.printNewLine();
        printer.paperCut();

        setState(() => _statusMessage = "Ticket ${_selectedForfait!['nom']} imprimé !");
      }
    } catch (e) {
      setState(() => _statusMessage = "Erreur d'impression ou coupure réseau.");
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TAGO PORTAIL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _chargerForfaits)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Menu Imprimante
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<BluetoothDevice>(
                        items: _devices.map((d) => DropdownMenuItem(value: d, child: Text(d.name ?? "Imprimante"))).toList(),
                        onChanged: (d) => setState(() => _selectedDevice = d),
                        value: _selectedDevice,
                        isExpanded: true,
                        hint: const Text("Sélectionner l'imprimante"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _connectPrinter,
                      style: ElevatedButton.styleFrom(backgroundColor: _connected ? Colors.green : Colors.blue),
                      child: Text(_connected ? "OK" : "Lier", style: const TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Choisissez la formule à éditer :", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // Liste dynamique des forfaits
            Expanded(
              child: _forfaits.isEmpty
                  ? const Center(child: Text("Aucun forfait trouvé. Vérifiez AWebServer."))
                  : ListView.builder(
                      itemCount: _forfaits.length,
                      itemBuilder: (context, index) {
                        final item = _forfaits[index];
                        final isSelected = _selectedForfait?['id'] == item['id'];
                        return Card(
                          color: isSelected ? Colors.blue.withOpacity(0.15) : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: isSelected ? Colors.blue : Colors.transparent, width: 1.5),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.wifi_tethering, color: Colors.blue),
                            title: Text(item['nom'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Profil MikroTik : ${item['profil']}"),
                            trailing: Text(item['prix'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                            onChanged: null,
                            onTap: () => setState(() => _selectedForfait = item),
                          ),
                        );
                      },
                    ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15.0),
              child: Text(_statusMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
            ),
            
            // Bouton de vente
            _isActionLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _connected && _selectedForfait != null ? _vendreTicket : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.print, color: Colors.white, size: 26),
                    label: Text(
                      _selectedForfait != null ? "IMPRIMER : ${_selectedForfait!['nom']}" : "CHOISISSEZ UN FORFAIT",
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
