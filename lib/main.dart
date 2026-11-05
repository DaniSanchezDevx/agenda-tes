import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AgendaSanitariaApp());
}

class AgendaSanitariaApp extends StatelessWidget {
  const AgendaSanitariaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenda TES',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD600),
          primary: const Color(0xFF0F172A),
          secondary: const Color(0xFFFFC107),
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: const AgendaScreen(),
    );
  }
}

class Aviso {
  String id;
  String fecha; // Formato yyyy-MM-dd
  String horaRecogida;
  String nombre;
  String seguro;
  String origen;
  String destino;
  String telefono;
  String horaTto;
  String tipo;
  String tes;

  Aviso({
    required this.id,
    required this.fecha,
    required this.horaRecogida,
    required this.nombre,
    required this.seguro,
    required this.origen,
    required this.destino,
    required this.telefono,
    required this.horaTto,
    required this.tipo,
    required this.tes,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'fecha': fecha,
    'horaRecogida': horaRecogida,
    'nombre': nombre,
    'seguro': seguro,
    'origen': origen,
    'destino': destino,
    'telefono': telefono,
    'horaTto': horaTto,
    'tipo': tipo,
    'tes': tes,
  };

  factory Aviso.fromMap(Map<String, dynamic> map) => Aviso(
    id: map['id'] ?? '',
    fecha: map['fecha'] ?? '',
    horaRecogida: map['horaRecogida'] ?? '',
    nombre: map['nombre'] ?? '',
    seguro: map['seguro'] ?? '',
    origen: map['origen'] ?? '',
    destino: map['destino'] ?? '',
    telefono: map['telefono'] ?? '',
    horaTto: map['horaTto'] ?? '',
    tipo: map['tipo'] ?? '',
    tes: map['tes'] ?? '',
  );
}

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _diaSeleccionado = DateTime.now();
  List<Aviso> _todosLosAvisos = [];

  @override
  void initState() {
    super.initState();
    _cargarAvisos();
  }

  String _formatearFechaTexto(DateTime d) {
    const dias = ['LUNES', 'MARTES', 'MIÉRCOLES', 'JUEVES', 'VIERNES', 'SÁBADO', 'DOMINGO'];
    const meses = ['ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO', 'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE'];
    return '${dias[d.weekday - 1]}, ${d.day} DE ${meses[d.month - 1]}';
  }

  String _fechaClave(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _cargarAvisos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? avisosJson = prefs.getString('avisos_locales');
      if (avisosJson != null) {
        final List dec = jsonDecode(avisosJson);
        setState(() {
          _todosLosAvisos = dec.map((e) => Aviso.fromMap(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error cargando avisos: $e');
    }
  }

  Future<void> _guardarAvisos() async {
    final prefs = await SharedPreferences.getInstance();
    final String enc = jsonEncode(_todosLosAvisos.map((e) => e.toMap()).toList());
    await prefs.setString('avisos_locales', enc);
  }

  List<Aviso> get _avisosDelDia {
    final clave = _fechaClave(_diaSeleccionado);
    return _todosLosAvisos.where((a) => a.fecha == clave).toList()
      ..sort((a, b) => a.horaRecogida.compareTo(b.horaRecogida));
  }

  void _seleccionarFecha(DateTime dia) {
    setState(() {
      _diaSeleccionado = dia;
    });
  }

  void _abrirFormulario({Aviso? avisoExistente}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => FormularioAviso(
        fechaClavePredeterminada: _fechaClave(_diaSeleccionado),
        avisoExistente: avisoExistente,
        alGuardar: (nuevoAviso) {
          setState(() {
            if (avisoExistente != null) {
              final idx = _todosLosAvisos.indexWhere((a) => a.id == avisoExistente.id);
              if (idx != -1) _todosLosAvisos[idx] = nuevoAviso;
            } else {
              _todosLosAvisos.add(nuevoAviso);
            }
          });
          _guardarAvisos();
        },
      ),
    );
  }

  void _borrarAviso(String id) {
    setState(() {
      _todosLosAvisos.removeWhere((a) => a.id == id);
    });
    _guardarAvisos();
  }

  @override
  Widget build(BuildContext context) {
    final avisos = _avisosDelDia;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AGENDA TRASLADOS TES',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Color(0xFFFFD600)),
            onPressed: () async {
              final seleccion = await showDatePicker(
                context: context,
                initialDate: _diaSeleccionado,
                firstDate: DateTime(2023),
                lastDate: DateTime(2030),
              );
              if (seleccion != null) _seleccionarFecha(seleccion);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            color: const Color(0xFFFFD600),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  onPressed: () => _seleccionarFecha(_diaSeleccionado.subtract(const Duration(days: 1))),
                ),
                Text(
                  _formatearFechaTexto(_diaSeleccionado),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 20),
                  onPressed: () => _seleccionarFecha(_diaSeleccionado.add(const Duration(days: 1))),
                ),
              ],
            ),
          ),
          Expanded(
            child: avisos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        Text(
                          'No hay traslados para este día',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: avisos.length,
                    itemBuilder: (ctx, i) {
                      final item = avisos[i];
                      return TarjetaAviso(
                        aviso: item,
                        onEditar: () => _abrirFormulario(avisoExistente: item),
                        onBorrar: () => _borrarAviso(item.id),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: const Color(0xFFFFD600),
        icon: const Icon(Icons.add),
        label: const Text('NUEVO AVISO', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _abrirFormulario(),
      ),
    );
  }
}

class TarjetaAviso extends StatelessWidget {
  final Aviso aviso;
  final VoidCallback onEditar;
  final VoidCallback onBorrar;

  const TarjetaAviso({
    super.key,
    required this.aviso,
    required this.onEditar,
    required this.onBorrar,
  });

  void _hacerLlamada(String tel) async {
    final uri = Uri.parse('tel:$tel');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _abrirMapa(String direccion) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(direccion)}');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD600),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'RECOGIDA: ${aviso.horaRecogida}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                if (aviso.horaTto.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'TTO: ${aviso.horaTto}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    aviso.seguro.toUpperCase(),
                    style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Text(
              aviso.nombre.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _abrirMapa(aviso.origen),
              child: Row(
                children: [
                  const Icon(Icons.trip_origin, size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'ORIGEN: ${aviso.origen}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Icon(Icons.directions, size: 16, color: Colors.blue),
                ],
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _abrirMapa(aviso.destino),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'DESTINO: ${aviso.destino}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Icon(Icons.directions, size: 16, color: Colors.blue),
                ],
              ),
            ),
            const Divider(height: 16),
            Row(
              children: [
                if (aviso.telefono.isNotEmpty)
                  ActionChip(
                    avatar: const Icon(Icons.phone, size: 15, color: Colors.green),
                    label: Text(aviso.telefono, style: const TextStyle(fontSize: 12)),
                    onPressed: () => _hacerLlamada(aviso.telefono),
                  ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    aviso.tipo,
                    style: TextStyle(color: Colors.orange.shade900, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Text('TES: ${aviso.tes}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                  onPressed: onEditar,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                  onPressed: onBorrar,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class FormularioAviso extends StatefulWidget {
  final String fechaClavePredeterminada;
  final Aviso? avisoExistente;
  final Function(Aviso) alGuardar;

  const FormularioAviso({
    super.key,
    required this.fechaClavePredeterminada,
    this.avisoExistente,
    required this.alGuardar,
  });

  @override
  State<FormularioAviso> createState() => _FormularioAvisoState();
}

class _FormularioAvisoState extends State<FormularioAviso> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _horaRecogidaCtrl;
  late TextEditingController _nombreCtrl;
  late TextEditingController _seguroCtrl;
  late TextEditingController _origenCtrl;
  late TextEditingController _destinoCtrl;
  late TextEditingController _telCtrl;
  late TextEditingController _horaTtoCtrl;
  late TextEditingController _tipoCtrl;
  late TextEditingController _tesCtrl;

  @override
  void initState() {
    super.initState();
    final a = widget.avisoExistente;
    _horaRecogidaCtrl = TextEditingController(text: a?.horaRecogida ?? '08:30');
    _nombreCtrl = TextEditingController(text: a?.nombre ?? '');
    _seguroCtrl = TextEditingController(text: a?.seguro ?? 'ASISA');
    _origenCtrl = TextEditingController(text: a?.origen ?? '');
    _destinoCtrl = TextEditingController(text: a?.destino ?? '');
    _telCtrl = TextEditingController(text: a?.telefono ?? '');
    _horaTtoCtrl = TextEditingController(text: a?.horaTto ?? '');
    _tipoCtrl = TextEditingController(text: a?.tipo ?? 'IDA Y VUELTA');
    _tesCtrl = TextEditingController(text: a?.tes ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.avisoExistente == null ? 'Nuevo Traslado Sanitario' : 'Editar Traslado',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _horaRecogidaCtrl,
                      decoration: const InputDecoration(labelText: 'Hora Recogida *', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _horaTtoCtrl,
                      decoration: const InputDecoration(labelText: 'Hora Tto.', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del Paciente *', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _seguroCtrl,
                      decoration: const InputDecoration(labelText: 'Seguro (Ej: ASISA)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _telCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _origenCtrl,
                decoration: const InputDecoration(labelText: 'Origen (Calle, Localidad)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _destinoCtrl,
                decoration: const InputDecoration(labelText: 'Destino (Hospital / Consulta)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tipoCtrl,
                      decoration: const InputDecoration(labelText: 'Tipo (IDA Y VUELTA)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _tesCtrl,
                      decoration: const InputDecoration(labelText: 'TES asignado', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: const Color(0xFFFFD600),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final nuevo = Aviso(
                      id: widget.avisoExistente?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      fecha: widget.avisoExistente?.fecha ?? widget.fechaClavePredeterminada,
                      horaRecogida: _horaRecogidaCtrl.text,
                      nombre: _nombreCtrl.text,
                      seguro: _seguroCtrl.text,
                      origen: _origenCtrl.text,
                      destino: _destinoCtrl.text,
                      telefono: _telCtrl.text,
                      horaTto: _horaTtoCtrl.text,
                      tipo: _tipoCtrl.text,
                      tes: _tesCtrl.text,
                    );
                    widget.alGuardar(nuevo);
                    Navigator.pop(context);
                  }
                },
                child: const Text('GUARDAR TRASLADO', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
