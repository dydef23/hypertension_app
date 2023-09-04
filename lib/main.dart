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
      home: const MyHomePage(title: 'Hypertension Prediction'),
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
  bool _isClassified = false;
  String _result = '';
  String _resultNumb = '';
  late Interpreter _interpreter;
  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    loadmodel(); // Load the TFLite model on app startup
    // _initializeCamera();
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

      // Encoding
      List<List<dynamic>> tempData = [];

      if (parsedData.length >= 2) {
        List<dynamic> secondRow = parsedData[1];
        List<dynamic> processedSecondRow = [];
        List<dynamic> test = [];
        var split = secondRow.toString().split(";");

        for (var cell in split) {
          String cellValue = cell.toString();
            if (cellValue == "TT" || cellValue == "AA") {
              processedSecondRow.add(0);
            } else {
              processedSecondRow.add(1);
            }
        }

        String formattedCell = processedSecondRow.join(';') ;
        test.add(formattedCell);

        tempData.add(test); // Update the second row with the processed data
        _csvData = tempData;
      }

      _showSnackbar("File $_importedFileName berhasil diimpor");

      setState(() {
        _csvData = tempData;
        _importedFileName = result.files.single.name;
      });

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

      List<double> input = convertUint8ListToDoubleList(byteslist);

      var output = List<double>.filled(1, 0).reshape([1, 1]);

      _interpreter.run(input, output);

      if(output[0].toString() == "[1.0]"){
        _result = "Increased Risk of Hypertension";
      }else{
        _result = "Normal Risk of Hypertension";
      }
      //
      _resultNumb = output[0].toString();
      //
      setState(() {
        _isClassified = true;
      });

      print("Output : $output");

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

  double convertStringToDouble(String stringValue) {
    return double.parse(stringValue);
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

  List<double> convertListDynamicToListDouble(List<dynamic> dynamicList) {
    List<double> doubleList = [];

    for (var value in dynamicList) {
      if (value is int) {
        doubleList.add(value.toDouble());
      } else if (value is double) {
        doubleList.add(value);
      } else if (value is String) {
        double? parsedValue = double.tryParse(value);
        if (parsedValue != null) {
          doubleList.add(parsedValue);
        }
      }
    }

    return doubleList;
  }

  // void _goToPage2() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (context) => camera_page()),
  //   );
  // }


  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Future<void> _initializeCamera() async {
  //   _cameras = await availableCameras();
  //
  //   if (_cameras != null && _cameras!.isNotEmpty) {
  //     _cameraController = CameraController(_cameras![0], ResolutionPreset.medium);
  //
  //     await _cameraController!.initialize().then((_) {
  //       if (!mounted) {
  //         return;
  //       }
  //       setState(() {});
  //     });
  //   }
  // }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // void _openCamera() {
  //   if (_cameraController == null || !_cameraController!.value.isInitialized) {
  //     return;
  //   }
  //
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => Scaffold(
  //         appBar: AppBar(
  //           title: Text('Camera Preview'),
  //         ),
  //         body: Center(
  //           child: CameraPreview(_cameraController!),
  //         ),
  //       ),
  //     ),
  //   );
  // }

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
        /*backgroundColor: Theme.of(context).colorScheme.inversePrimary,*/
        backgroundColor: Color(0xFFDC2738),
        centerTitle: true,
        title: Text(widget.title,
            style: TextStyle(
              color: Colors.white, // Mengatur warna teks menjadi putih
            ),
          ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('assets/logo.png'),
            /*const Text(
              'Classifier',
            ),*/
            ElevatedButton(
              onPressed: _loadCsvData, // Panggil _loadCsvData ketika tombol ditekan.
              style: ElevatedButton.styleFrom(
                primary: Colors.red, // Mengatur warna latar belakang tombol menjadi merah
                onPrimary: Colors.white, // Mengatur warna teks menjadi putih
              ),
              child: Text('Input CSV File'),
            ),
            ElevatedButton(
              onPressed: classification,
              style: ElevatedButton.styleFrom(
                primary: Colors.white, // Latar belakang putih
                onPrimary: Colors.black, // Teks hitam
                side: BorderSide(color: Colors.red, width: 1.0),  // Border merah
              ),// Panggil _goToPage2 ketika tombol ditekan.
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
              backgroundColor: Colors.red, // Latar belakang merah
              foregroundColor: Colors.white,
              child: const Icon(Icons.camera_alt),
            ),
          ),
          Container(
            margin: EdgeInsets.all(10),
            child: FloatingActionButton(
              onPressed:  _loadCsvData,
              tooltip: 'Import File CSV',
              backgroundColor: Colors.red, // Latar belakang merah
              foregroundColor: Colors.white,
              child: const Icon(Icons.file_upload),
            ),
          )
        ],
      ) // This trailing comma makes auto-formatting nicer for build methods.
    );
  }


}
