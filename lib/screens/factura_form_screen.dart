import 'package:flutter/material.dart';
import '../models/factura.dart';
import '../database/database_helper.dart';

class FacturaFormScreen extends StatefulWidget {
  final Factura? factura;

  const FacturaFormScreen({super.key, this.factura});

  @override
  State<FacturaFormScreen> createState() => _FacturaFormScreenState();
}

class _FacturaFormScreenState extends State<FacturaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper();
  
  late TextEditingController _tiqueteController;
  late TextEditingController _fechaController;
  late TextEditingController _placaController;
  late TextEditingController _nombreDestinoController;
  late TextEditingController _pesoController;
  late TextEditingController _precioController;
  late TextEditingController _totalController;
  late TextEditingController _observacionesController;
  late TextEditingController _semanaController; // NUEVO

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.factura != null;
    
    _tiqueteController = TextEditingController(text: widget.factura?.tiquete ?? '');
    _fechaController = TextEditingController(text: widget.factura?.fecha ?? _getFechaHoy());
    _placaController = TextEditingController(text: widget.factura?.placa ?? '');
    _nombreDestinoController = TextEditingController(text: widget.factura?.nombreDestino ?? '');
    _pesoController = TextEditingController(text: widget.factura?.peso.toString() ?? '');
    _precioController = TextEditingController(text: widget.factura?.precio.toString() ?? '');
    _totalController = TextEditingController(text: widget.factura?.total.toString() ?? '0.0');
    _observacionesController = TextEditingController(text: widget.factura?.observaciones ?? '');
    
    // NUEVO: Inicializar semana
    _semanaController = TextEditingController(
      text: widget.factura?.semana ?? Factura.generarNombreSemana(DateTime.now())
    );

    _pesoController.addListener(_calcularTotal);
    _precioController.addListener(_calcularTotal);
  }

  String _getFechaHoy() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  void _calcularTotal() {
    final peso = double.tryParse(_pesoController.text) ?? 0;
    final precio = double.tryParse(_precioController.text) ?? 0;
    final total = (peso / 1000) * precio;
    _totalController.text = total.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _tiqueteController.dispose();
    _fechaController.dispose();
    _placaController.dispose();
    _nombreDestinoController.dispose();
    _pesoController.dispose();
    _precioController.dispose();
    _totalController.dispose();
    _observacionesController.dispose();
    _semanaController.dispose(); // NUEVO
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Factura' : 'Nueva Factura'),
        backgroundColor: Colors.blue,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Campo Semana - NUEVO
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Período / Semana',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _semanaController,
                      decoration: InputDecoration(
                        hintText: 'Ej: Semana 1 - 2025',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Generar automáticamente',
                          onPressed: () {
                            setState(() {
                              _semanaController.text = Factura.generarNombreSemana(DateTime.now());
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese el período o semana';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Resto de los campos existentes...
            TextFormField(
              controller: _tiqueteController,
              decoration: const InputDecoration(
                labelText: 'Tiquete',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese el número de tiquete';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _fechaController,
              decoration: const InputDecoration(
                labelText: 'Fecha (DD/MM/AAAA)',
                border: OutlineInputBorder(),
                suffixIcon: 
                Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: _selectDate,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese la fecha';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _placaController,
              decoration: const InputDecoration(
                labelText: 'Placa',
                border: OutlineInputBorder(),
                hintText: 'Ej: FDP082',
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese la placa';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _nombreDestinoController,
              decoration: const InputDecoration(
                labelText: 'Nombre Destino',
                border: OutlineInputBorder(),
                hintText: 'Ej: Sanimax',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese el destino';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _pesoController,
              decoration: const InputDecoration(
                labelText: 'Peso (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese el peso';
                }
                if (double.tryParse(value) == null) {
                  return 'Ingrese un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _precioController,
              decoration: const InputDecoration(
                labelText: 'Precio por tonelada',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese el precio';
                }
                if (double.tryParse(value) == null) {
                  return 'Ingrese un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _totalController,
              decoration: const InputDecoration(
                labelText: 'Total',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              readOnly: true,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _observacionesController,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isSaving ? null : _guardarFactura,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _isEditing ? 'Actualizar' : 'Guardar',
                      style: const TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
    setState(() {
      _fechaController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      // Actualizar automáticamente la semana cuando cambia la fecha
      _semanaController.text = Factura.generarNombreSemana(picked);
    });
    }
  }

  Future<void> _guardarFactura() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final factura = Factura(
        id: _isEditing ? widget.factura!.id : null,
        tiquete: _tiqueteController.text,
        fecha: _fechaController.text,
        placa: _placaController.text.toUpperCase(),
        nombreDestino: _nombreDestinoController.text,
        peso: double.parse(_pesoController.text),
        precio: double.parse(_precioController.text),
        total: double.parse(_totalController.text),
        observaciones: _observacionesController.text,
        fechaCreacion: _isEditing ? widget.factura!.fechaCreacion : DateTime.now(),
        semana: _semanaController.text, // NUEVO
      );

      if (_isEditing) {
        await _dbHelper.updateFactura(factura);
      } else {
        await _dbHelper.insertFactura(factura);
      }

      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.pop(context, true); // Retornar true para indicar que hubo cambios
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Factura actualizada' : 'Factura guardada exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}