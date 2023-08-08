import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
class Classifier {
  // name of the model file
  final _modelFile = 'trained_model.tflite';

  // Maximum length of sentence
  final int _sentenceLen = 256;
  late Map<String, int> _dict;

  // TensorFlow Lite Interpreter object
  late Interpreter _interpreter;

  Classifier() {
    // Load model when the classifier is initialized.
    _loadModel();
  }

  void _loadModel() async {
    // Creating the interpreter using Interpreter.fromAsset
    _interpreter = await Interpreter.fromAsset(_modelFile);
    print('Interpreter loaded successfully');
  }


}