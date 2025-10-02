import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/factura.dart';

class ExcelService {
  static Future<String> exportToExcel(
    List<Factura> facturas, 
    {String? nombreArchivo}
  ) async {
    if (facturas.isEmpty) {
      throw Exception('No hay facturas para exportar');
    }

    var excel = Excel.createExcel();
    
    // Crear la hoja Facturas primero
    excel['Facturas'];
    
    // Ahora eliminar Sheet1
    excel.delete('Sheet1');
    
    // Obtener la hoja Facturas
    Sheet sheet = excel['Facturas'];

    // Encabezados con estilo
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.blue,
      fontColorHex: ExcelColor.white,
    );

    // Agregar encabezados
    final headers = [
      'Tiquete',
      'Fecha',
      'Placa',
      'Nombre Destino',
      'Peso',
      'Precio',
      'Total',
      'Observaciones',
      'Semana',
    ];

    var headerRow = headers.map((h) => TextCellValue(h)).toList();
    sheet.appendRow(headerRow);

    // Aplicar estilo a encabezados
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.cellStyle = headerStyle;
    }

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
        TextCellValue(factura.semana),
      ]);
    }

    // Agregar fila de TOTAL
    final totalGeneral = facturas.fold<double>(0, (sum, f) => sum + f.total);
    final totalRowIndex = facturas.length + 1;
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRowIndex))
      .value = TextCellValue('TOTAL:');
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: totalRowIndex))
      .value = DoubleCellValue(totalGeneral);

    // Estilo de negrita para el total
    final totalStyle = CellStyle(bold: true);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRowIndex))
      .cellStyle = totalStyle;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: totalRowIndex))
      .cellStyle = totalStyle;

    // Guardar archivo en Descargas
    var fileBytes = excel.save();
    
    // Usar nombre personalizado si se proporciona
    var fileName = nombreArchivo ?? 'facturas';
    fileName = '${fileName}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    
    String filePath;
    
    // Intentar guardar en la carpeta de Descargas (Android)
    try {
      // Para Android - guardar en Downloads
      final directory = Directory('/storage/emulated/0/Download');
      
      if (await directory.exists()) {
        filePath = '${directory.path}/$fileName';
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes!);
      } else {
        // Fallback a directorio de documentos de la app
        final appDirectory = await getApplicationDocumentsDirectory();
        filePath = '${appDirectory.path}/$fileName';
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes!);
      }
    } catch (e) {
      // Si falla, usar directorio externo
      final externalDirectory = await getExternalStorageDirectory();
      filePath = '${externalDirectory!.path}/$fileName';
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes!);
    }

    // Compartir archivo Y retornar la ruta donde se guardó
    await Share.shareXFiles(
      [XFile(filePath)], 
      text: 'Facturas de Transporte - Guardado en: $filePath'
    );
    
    // Retornar la ruta del archivo
    return filePath;
  }
}