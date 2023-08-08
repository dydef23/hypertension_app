import 'dart:io';
import 'package:csv/csv.dart';

class CsvHelper {
  Future<String> readCsvFromFile(String filePath) async {
    File file = File(filePath);
    return await file.readAsString();
  }
}
