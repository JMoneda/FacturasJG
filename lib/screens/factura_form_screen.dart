import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final _tiqueteController = TextEditingController();
  final _fechaController = TextEditingController();
  final _placaController = TextEditingController();
  final _nombreDestinoController = TextEditingController();
  final _pesoController = TextEditingController();
  final _precioController = TextEditingController();
  final _totalController = TextEditingController();
  final _observacionesController = TextEditingController();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();

    // Si hay una factura, cargar los datos para editar
    if (widget.factura != null) {
      _isEditing = true;
      _tiqueteController.text = widget.factura!.tiquete;
      _fechaController.text = widget.factura!.fecha;
      _placaController.text = widget.factura!.placa;
      _nombreDestinoController.text = widget.factura!.nombreDestino;
      _pesoController.text = widget.factura!.peso.toString();
      _precioController.text = widget.factura!.precio.toString();
      _totalController.text = widget.factura!.total.toString();
      _observacionesController.text = widget.factura!.observaciones;
    } else {
      _fechaController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    }

    _pesoController.addListener(_calculateTotal);
    _precioController.addListener(_calculateTotal);
  }

  void _calculateTotal() {
    final peso = double.tryParse(_pesoController.text) ?? 0;
    final precio = double.tryParse(_precioController.text) ?? 0;
    // Convertir peso de kg a toneladas y multiplicar por precio
    final total = (peso / 1000) * precio;
    _totalController.text = total.toStringAsFixed(0);
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
    super.dispose();
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
        _fechaController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _saveFactura() async {
  if (!_formKey.currentState!.validate()) return;

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
    );

    if (_isEditing) {
      await _dbHelper.updateFactura(factura);
    } else {
      await _dbHelper.insertFactura(factura);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Factura')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _tiqueteController,
              decoration: const InputDecoration(
                labelText: 'Tiquete',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fechaController,
              decoration: const InputDecoration(
                labelText: 'Fecha',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: _selectDate,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo requerido' : null,
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
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombreDestinoController,
              decoration: const InputDecoration(
                labelText: 'Nombre Destino',
                border: OutlineInputBorder(),
                hintText: 'Ej: Sanimax',
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo requerido' : null,
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
                if (value?.isEmpty ?? true) return 'Campo requerido';
                if (double.tryParse(value!) == null) return 'Valor inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _precioController,
              decoration: const InputDecoration(
                labelText: 'Precio por Tonelada',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Campo requerido';
                if (double.tryParse(value!) == null) return 'Valor inválido';
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observacionesController,
              decoration: const InputDecoration(
                labelText: 'Observaciones (Opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveFactura,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : const Text(
                      'Guardar Factura',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
