import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/factura.dart';

class ExcelService {
  static Future<void> exportToExcel(List<Factura> facturas) async {
    var excel = Excel.createExcel();
    
    // Crear la hoja Facturas primero
    excel['Facturas'];
    
    // Ahora eliminar Sheet1
    excel.delete('Sheet1');
    
    // Obtener la hoja Facturas
    Sheet sheet = excel['Facturas'];

    // Encabezados
    sheet.appendRow([
      TextCellValue('Tiquete'),
      TextCellValue('Fecha'),
      TextCellValue('Placa'),
      TextCellValue('Nombre Destino'),
      TextCellValue('Peso'),
      TextCellValue('Precio'),
      TextCellValue('Total'),
      TextCellValue('Observaciones'),
    ]);

    // Datos
    for (var factura in facturas) {
      sheet.appendRow([
        TextCellValue(factura.tiquete),
        TextCellValue(factura.fecha),
        TextCellValue(factura.placa),
        TextCellValue(factura.nombreDestino),
        DoubleCellValue(factura.peso),
        DoubleCellValue(factura.precio),
        DoubleCellValue(factura.total),
        TextCellValue(factura.observaciones),
      ]);
    }

    // Guardar archivo
    var fileBytes = excel.save();
    var directory = await getApplicationDocumentsDirectory();
    var fileName = 'facturas_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    var filePath = '${directory.path}/$fileName';

    File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes!);

    // Compartir archivo
    await Share.shareXFiles([XFile(filePath)], text: 'Facturas de Transporte');
  }
}