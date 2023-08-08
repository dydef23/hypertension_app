import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'CSVHelper.dart';
import 'result_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppTheme.appTitle, // Use the app title from AppTheme
      theme: AppTheme.theme, // Use the theme from AppTheme
      home: const MyHomePage(title: 'Text Classification'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final CsvHelper _csvHelper = CsvHelper();
  List<List<dynamic>> _csvData = [];
  String? _importedFileName;
  List<String>? _labels;
  bool _isClassified = false;
  String _result = '';
  late Interpreter _interpreter;
  String test = "";

  @override
  void initState() {
    super.initState();
    loadmodel(); // Load the TFLite model on app startup
  }

  Future<void> _loadCsvData() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      print("File picked: ${result.files.single.name}");
      String csvFilePath = result.files.single.path!;
      String data = await _csvHelper.readCsvFromFile(csvFilePath);
      List<List<dynamic>> parsedData = CsvToListConverter().convert(data);
      setState(() {
        _csvData = parsedData;
        _importedFileName = result.files.single.name;
      });
      _showSnackbar("File $_importedFileName berhasil diimpor");
    } else {
      setState(() {
        _importedFileName = null;
      });
      _showSnackbar("File import gagal atau dibatalkan");
    }
  }

  loadmodel() async {
    await Tflite.loadModel(
        model: 'assets/trained_model.tflite'
    );
  }
  void classification() {
    if (_csvData != null) {
      for (var row in _csvData!) {
        String genotype = row[0];
        int label = row[1];
        // Example classification logic based on 'genotype' and 'label'
        String result = label == 1 ? "Hypertension" : "No Hypertension";

        print("Genotype: $genotype -> $result");
      }
    } else {
      print("Data CSV belum diimpor atau belum tersedia.");
    }
  }

  void _goToPage2() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => result_page()),
    );
  }
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Classifier',
            ),
            ElevatedButton(
              onPressed: _goToPage2, // Panggil _goToPage2 ketika tombol ditekan.
              child: Text('Ke Halaman 2'),
            ),
            ElevatedButton(
              onPressed: _loadCsvData, // Panggil _loadCsvData ketika tombol ditekan.
              child: Text('Input CSV File'),
            ),
            if (_importedFileName != null)
              Text(
                'Imported File: $_importedFileName',
              ),
            const Text(
              'Result : ',
            ),
            if (_isClassified)
              Text(
                'Result: $_result',
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:  _loadCsvData,
        tooltip: 'Import File CSV',
        child: const Icon(Icons.file_upload),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
