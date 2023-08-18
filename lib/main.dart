import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hypertension_app/qr_page.dart';
import 'package:tflite/tflite.dart';
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'CSVHelper.dart';
import 'camera_page.dart';
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
  String _resultNumb = '';
  late Interpreter _interpreter;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    loadmodel(); // Load the TFLite model on app startup
    _initializeCamera();
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
     _interpreter = await Interpreter.fromAsset("assets/trained_model.tflite");
  }

  void classification() {
    if (_csvData != null && _interpreter != null) {
      List<Uint8List> byteslist = _csvData.map((row) {
        return convertStringToBytes(row[0].toString());
      }).toList();

      List<Float32List> string = _csvData.map((row) {
        return convertStringToFloat(row[0].toString());
      }).toList();

      List<double> input = convertUint8ListToDoubleList(byteslist);

      var output = List<double>.filled(1, 0).reshape([1, 1]);

      _interpreter.run(input, output);

      if(output[0].toString() == "[1.0]"){
        _result = "Increased Risk of Hypertension";
      }else{
        _result = "Normal Risk of Hypertension";
      }

      _resultNumb = output[0].toString();
      var _allResult = output.toString();

      setState(() {
        _isClassified = true;
      });

      // print(inputFix);
      print(_interpreter.getInputTensors());
      print(_interpreter.getOutputTensors());
      print(output);
      print(_allResult);
      // print(_resultNumb);

    } else {
      print("Data CSV belum diimpor atau belum tersedia.");
    }
  }

  Future<List<Uint8List>> loadAndPreprocessCSVData() async {
    List<Uint8List> bytesList = _csvData.map((row) {
      return convertStringToBytes(row[0].toString());
    }).toList();

    return bytesList;
  }

  Uint8List convertStringToBytes(String stringValue) {
    return Uint8List.fromList(stringValue.codeUnits);
    // return Float32List.fromList(stringValue.codeUnits);
  }

  Float32List convertStringToFloat(String stringValue) {
    Uint8List uint8Values = Uint8List.fromList(stringValue.codeUnits);

    Float32List floatValues = Float32List(uint8Values.length);
    for (int i = 0; i < uint8Values.length; i++) {
      floatValues[i] = uint8Values[i].toDouble();
    }

    return floatValues;
  }

  List<double> convertUint8ListToDoubleList(List<Uint8List> uint8Lists) {
    List<double> result = [];

    for (var uint8List in uint8Lists) {
      List<int> intList = uint8List.toList();
      List<double> doubleList = intList.map((value) => value.toDouble()).toList();
      result.addAll(doubleList);
    }

    return result;
  }

  void _goToPage2() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => camera_page()),
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

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();

    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController = CameraController(_cameras![0], ResolutionPreset.medium);

      await _cameraController!.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _openCamera() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Camera Preview'),
          ),
          body: Center(
            child: CameraPreview(_cameraController!),
          ),
        ),
      ),
    );
  }

  void _goToScan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => qr_page()),
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
              onPressed: _loadCsvData, // Panggil _loadCsvData ketika tombol ditekan.
              child: Text('Input CSV File'),
            ),
            ElevatedButton(
              onPressed: classification, // Panggil _goToPage2 ketika tombol ditekan.
              child: Text('Classify'),
            ),
            if (_importedFileName != null)
              Text(
                'Imported File: $_importedFileName',
              ),
            if (_isClassified)
              Text(
                'Result: $_resultNumb ($_result)',
              ),
          ],
        ),
      ),
      floatingActionButton: Wrap(
        direction: Axis.vertical,
        children: <Widget>[
          Container(
            margin: EdgeInsets.all(10),
            child: FloatingActionButton(
              onPressed: _goToScan,
              tooltip: 'Camera',
              child: const Icon(Icons.camera_alt),
            ),
          ),
          Container(
            margin: EdgeInsets.all(10),
            child: FloatingActionButton(
              onPressed:  _loadCsvData,
              tooltip: 'Import File CSV',
              child: const Icon(Icons.file_upload),
            ),
          )
        ],
      ) // This trailing comma makes auto-formatting nicer for build methods.
    );
  }


}
