import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:tflite/tflite.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'app_theme.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class result_page extends StatefulWidget {
  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<result_page> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    final XFile? imageFile = await _cameraController!.takePicture();

    if (imageFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text('Captured Image'),
            ),
            body: Center(
              child: Image.asset(imageFile.path),
            ),
          ),
        ),
      );
    }
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
          floatingActionButton: FloatingActionButton(
            onPressed: _takePicture,
            tooltip: 'Take Picture',
            child: Icon(Icons.camera_alt),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(AppTheme.appTitle),
      ),
      body: Center(
        child: Text(
          'This is the Result Page',
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCamera,
        tooltip: 'Camera',
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}
