import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/factura.dart';
import '../database/database_helper.dart';
import 'factura_form_screen.dart';
import '../services/excel_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Factura> _facturas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFacturas();
  }

  Future<void> _loadFacturas() async {
    setState(() => _isLoading = true);
    final facturas = await _dbHelper.getAllFacturas();
    setState(() {
      _facturas = facturas;
      _isLoading = false;
    });
  }

  Future<void> _deleteFactura(int id) async {
    await _dbHelper.deleteFactura(id);
    _loadFacturas();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Factura eliminada')));
    }
  }

  Future<void> _exportToExcel() async {
    if (_facturas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay facturas para exportar')),
      );
      return;
    }

    try {
      await ExcelService.exportToExcel(_facturas);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel generado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facturas de Transporte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportToExcel,
            tooltip: 'Exportar a Excel',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _facturas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay facturas registradas',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toca el botón + para agregar una',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _facturas.length,
              itemBuilder: (context, index) {
                final factura = _facturas[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FacturaFormScreen(factura: factura),
                        ),
                      );
                      _loadFacturas();
                    },
                    title: Text(
                      'Tiquete: ${factura.tiquete}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Fecha: ${factura.fecha}'),
                        Text('Placa: ${factura.placa}'),
                        Text('Destino: ${factura.nombreDestino}'),
                        Text('Peso: ${factura.peso}'),
                        Text(
                          'Total: ${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(factura.total)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirmar'),
                            content: const Text('¿Eliminar esta factura?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && factura.id != null) {
                          _deleteFactura(factura.id!);
                        }
                      },
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FacturaFormScreen()),
          );
          _loadFacturas();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
