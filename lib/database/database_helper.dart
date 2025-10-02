import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/factura.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'facturas.db');
    return await openDatabase(
      path,
      version: 2, // INCREMENTAR VERSION
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // NUEVO
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE facturas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tiquete TEXT NOT NULL,
        fecha TEXT NOT NULL,
        placa TEXT NOT NULL,
        nombre_destino TEXT NOT NULL,
        peso REAL NOT NULL,
        precio REAL NOT NULL,
        total REAL NOT NULL,
        observaciones TEXT,
        fecha_creacion INTEGER NOT NULL,
        semana TEXT NOT NULL
      )
    ''');
  }

  // NUEVA FUNCIÓN para migrar datos existentes
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE facturas ADD COLUMN semana TEXT DEFAULT "Sin semana"');
      
      // Actualizar registros existentes con semana calculada
      final facturas = await db.query('facturas');
      for (var factura in facturas) {
        final fecha = factura['fecha'] as String;
        final semana = _calcularSemanaDesdeString(fecha);
        await db.update(
          'facturas',
          {'semana': semana},
          where: 'id = ?',
          whereArgs: [factura['id']],
        );
      }
    }
  }

  String _calcularSemanaDesdeString(String fecha) {
    try {
      final partes = fecha.split('/');
      final dia = int.parse(partes[0]);
      final mes = int.parse(partes[1]);
      final ano = int.parse(partes[2]);
      final fechaObj = DateTime(ano, mes, dia);
      
      return Factura.generarNombreSemana(fechaObj);
    } catch (e) {
      return 'Sin semana';
    }
  }

  Future<int> insertFactura(Factura factura) async {
    final db = await database;
    return await db.insert('facturas', factura.toMap());
  }

  Future<List<Factura>> getAllFacturas() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'facturas',
      orderBy: 'fecha_creacion DESC',
    );
    return List.generate(maps.length, (i) => Factura.fromMap(maps[i]));
  }

  // NUEVA FUNCIÓN: Obtener facturas agrupadas por semana
  Future<Map<String, List<Factura>>> getFacturasAgrupadasPorSemana() async {
    final facturas = await getAllFacturas();
    final Map<String, List<Factura>> agrupadas = {};
    
    for (var factura in facturas) {
      if (!agrupadas.containsKey(factura.semana)) {
        agrupadas[factura.semana] = [];
      }
      agrupadas[factura.semana]!.add(factura);
    }
    
    return agrupadas;
  }

  // NUEVA FUNCIÓN: Obtener facturas de una semana específica
  Future<List<Factura>> getFacturasPorSemana(String semana) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'facturas',
      where: 'semana = ?',
      whereArgs: [semana],
      orderBy: 'fecha_creacion DESC',
    );
    return List.generate(maps.length, (i) => Factura.fromMap(maps[i]));
  }

  Future<int> updateFactura(Factura factura) async {
    final db = await database;
    return await db.update(
      'facturas',
      factura.toMap(),
      where: 'id = ?',
      whereArgs: [factura.id],
    );
  }

  Future<int> deleteFactura(int id) async {
    final db = await database;
    return await db.delete(
      'facturas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // NUEVA FUNCIÓN: Obtener lista de semanas únicas
  Future<List<String>> getSemanas() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT DISTINCT semana FROM facturas ORDER BY semana DESC'
    );
    return result.map((row) => row['semana'] as String).toList();
  }
}