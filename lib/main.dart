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
  String fecha;
  String horaRecogida;
  String nombre;
  String seguro;
  String origen;
  String destino;
  String telefono;
  String horaTto;
  String tipo;
  String tes;
  String notas; // Notas adicionales

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
    this.notas = '',
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
    'notas': notas,
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
    notas: map['notas'] ?? '',
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
      debugPrint('Error: $e');
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

  void _guardarNotaRapida(Aviso aviso, String nuevaNota) {
    setState(() {
      aviso.notas = nuevaNota;
    });
    _guardarAvisos();
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
                        onActualizarNota: (nota) => _guardarNotaRapida(item, nota),
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
  final Function(String) onActualizarNota;

  const TarjetaAviso({
    super.key,
    required this.aviso,
    required this.onEditar,
    required this.onBorrar,
    required this.onActualizarNota,
  });

  // Abre el teclado telefónico (marcador) sin llamar directamente
  void _abrirMarcador(BuildContext context, String tel) async {
    final limpio = tel.replaceAll(RegExp(r'[^0-9+]'), '');
    if (limpio.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay número de teléfono válido.')),
      );
      return;
    }
    final uri = Uri.parse('tel:$limpio');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el marcador.')),
        );
      }
    }
  }

  // Abre Google Maps con la dirección exacta
  void _abrirEnMaps(BuildContext context, String direccion) async {
    if (direccion.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La dirección está vacía.')),
      );
      return;
    }
    final query = Uri.encodeComponent(direccion.trim());
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir Google Maps.')),
        );
      }
    }
  }

  // Diálogo para añadir/modificar notas de forma rápida
  void _dialogoEditarNota(BuildContext context) {
    final ctrl = TextEditingController(text: aviso.notas);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: Color(0xFF0F172A)),
            SizedBox(width: 8),
            Text('Notas del Aviso', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ej: 3º piso sin ascensor, requiere silla, llamar al timbre B...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: const Color(0xFFFFD600),
            ),
            onPressed: () {
              onActualizarNota(ctrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('Guardar Nota'),
          ),
        ],
      ),
    );
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
            // Cabecera: Horas y Seguro
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

            // Nombre
            Text(
              aviso.nombre.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),

            // ORIGEN (pulsable para abrir Maps)
            InkWell(
              onTap: () => _abrirEnMaps(context, aviso.origen),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.trip_origin, size: 18, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'ORIGEN: ${aviso.origen}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.map, size: 13, color: Colors.green),
                          SizedBox(width: 3),
                          Text('Maps', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // DESTINO (pulsable para abrir Maps)
            InkWell(
              onTap: () => _abrirEnMaps(context, aviso.destino),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'DESTINO: ${aviso.destino}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.map, size: 13, color: Colors.red),
                          SizedBox(width: 3),
                          Text('Maps', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // NOTAS (si existen, se muestran en un cuadro destacado)
            if (aviso.notas.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFF92400E)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        aviso.notas,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 16),

            // Fila inferior: Botón Teléfono, Notas, TES y Editar/Borrar
            Row(
              children: [
                if (aviso.telefono.isNotEmpty)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.phone, size: 14),
                    label: Text(aviso.telefono, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _abrirMarcador(context, aviso.telefono),
                  ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Añadir o editar notas',
                  icon: Icon(
                    aviso.notas.isEmpty ? Icons.note_add_outlined : Icons.note_alt,
                    size: 20,
                    color: aviso.notas.isEmpty ? Colors.grey : const Color(0xFFB45309),
                  ),
                  onPressed: () => _dialogoEditarNota(context),
                ),
                const Spacer(),
                Text('TES: ${aviso.tes}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.blueGrey),
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
  late TextEditingController _notasCtrl;

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
    _notasCtrl = TextEditingController(text: a?.notas ?? '');
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
              const SizedBox(height: 10),
              TextFormField(
                controller: _notasCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notas adicionales (Opcional)',
                  hintText: 'Ej: Silla de ruedas, no timbre, avisar antes...',
                  border: OutlineInputBorder(),
                ),
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
                      notas: _notasCtrl.text,
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
