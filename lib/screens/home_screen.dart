import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
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
  Map<String, List<Factura>> _facturasAgrupadas = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarFacturas();
  }

  Future<void> _cargarFacturas() async {
    setState(() => _isLoading = true);
    final facturas = await _dbHelper.getFacturasAgrupadasPorSemana();
    setState(() {
      _facturasAgrupadas = facturas;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facturas de Transporte'),
        backgroundColor: Colors.blue,
        actions: [
          // Botón para exportar
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar Excel',
            onSelected: (value) => _exportarExcel(value),
            itemBuilder: (BuildContext context) {
              List<PopupMenuEntry<String>> items = [
                const PopupMenuItem(
                  value: 'todas',
                  child: Row(
                    children: [
                      Icon(Icons.select_all, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Exportar todas las facturas'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
              ];

              // Agregar opción para cada semana
              for (var semana in _facturasAgrupadas.keys) {
                items.add(
                  PopupMenuItem(
                    value: semana,
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(child: Text(semana)),
                      ],
                    ),
                  ),
                );
              }

              return items;
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarFacturas,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _facturasAgrupadas.isEmpty
              ? _buildEmptyState()
              : _buildFacturasList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FacturaFormScreen()),
          );
          if (result == true) {
            _cargarFacturas();
          }
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay facturas registradas',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Presiona el botón + para agregar una',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildFacturasList() {
    // Ordenar las semanas (las más recientes primero)
    final semanasOrdenadas = _facturasAgrupadas.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: semanasOrdenadas.length,
      itemBuilder: (context, index) {
        final semana = semanasOrdenadas[index];
        final facturas = _facturasAgrupadas[semana]!;
        final totalSemana = facturas.fold<double>(0, (sum, f) => sum + f.total);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: index == 0, // Expandir solo la primera (más reciente)
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  '${facturas.length}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                semana,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '${facturas.length} factura${facturas.length != 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total: \$${totalSemana.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              children: [
                const Divider(height: 1),
                ...facturas.map((factura) => _buildFacturaTile(factura)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFacturaTile(Factura factura) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            factura.placa,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              color: Colors.blue.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      title: Text(
        'Tiquete: ${factura.tiquete}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${factura.fecha} - ${factura.nombreDestino}'),
          Text(
            '${factura.peso}kg × \$${factura.precio} = \$${factura.total.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _editarFactura(factura),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmarEliminar(factura),
          ),
        ],
      ),
      onTap: () => _editarFactura(factura),
    );
  }

  Future<void> _editarFactura(Factura factura) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FacturaFormScreen(factura: factura),
      ),
    );
    if (result == true) {
      _cargarFacturas();
    }
  }

  Future<void> _confirmarEliminar(Factura factura) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Desea eliminar la factura ${factura.tiquete}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _dbHelper.deleteFactura(factura.id!);
      _cargarFacturas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Factura eliminada')),
        );
      }
    }
  }

  Future<void> _exportarExcel(String opcion) async {
  try {
    List<Factura> facturasAExportar;
    String nombreArchivo;

    if (opcion == 'todas') {
      facturasAExportar = await _dbHelper.getAllFacturas();
      nombreArchivo = 'facturas_todas';
    } else {
      facturasAExportar = await _dbHelper.getFacturasPorSemana(opcion);
      nombreArchivo = 'facturas_${opcion.replaceAll(' ', '_').replaceAll('/', '-')}';
    }

    if (facturasAExportar.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay facturas para exportar')),
        );
      }
      return;
    }

    // Exportar y obtener la ruta del archivo
    final filePath = await ExcelService.exportToExcel(
      facturasAExportar,
      nombreArchivo: nombreArchivo,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(
            opcion == 'todas'
                ? 'Archivo guardado en Descargas\n${facturasAExportar.length} facturas exportadas'
                : 'Archivo guardado en Descargas\n${facturasAExportar.length} facturas de $opcion',
          ),
          action: SnackBarAction(
            label: 'ABRIR',
            onPressed: () async {
              final result = await OpenFile.open(filePath);
              if (result.type != ResultType.done) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No se pudo abrir el archivo: ${result.message}')),
                  );
                }
              }
            },
          ),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: $e')),
      );
    }
  }
}
}