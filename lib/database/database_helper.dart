import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/factura.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
    if (kIsWeb) {
      // Para web, usar una base de datos en memoria
      return await openDatabase(
        'facturas.db',
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } else {
      // Para móvil
      String path = join(await getDatabasesPath(), 'facturas.db');
      return await openDatabase(
        path,
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
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
        fecha_creacion INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // Eliminar tabla antigua y crear nueva
    await db.execute('DROP TABLE IF EXISTS facturas');
    await _onCreate(db, newVersion);
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
    return await db.delete('facturas', where: 'id = ?', whereArgs: [id]);
  }
}