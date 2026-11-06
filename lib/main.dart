import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const AvisosTesApp());
}

class AvisosTesApp extends StatelessWidget {
  const AvisosTesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avisos TES',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFF22C55E),
          surface: Color(0xFF1E293B),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
          ),
          labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
      home: const FormularioAvisoScreen(),
    );
  }
}

class FormularioAvisoScreen extends StatefulWidget {
  const FormularioAvisoScreen({super.key});

  @override
  State<FormularioAvisoScreen> createState() => _FormularioAvisoScreenState();
}

class _FormularioAvisoScreenState extends State<FormularioAvisoScreen> {
  // Controladores de texto
  DateTime? _fechaSeleccionada = DateTime.now();
  String? _provinciaSeleccionada;
  final TextEditingController _aseguradoController = TextEditingController();
  final TextEditingController _dniNumController = TextEditingController();
  final TextEditingController _dniLetraController = TextEditingController();
  final TextEditingController _polizaController = TextEditingController();
  final TextEditingController _autorizacionController = TextEditingController();
  String? _tipoSeleccionado;
  final TextEditingController _origenController = TextEditingController();
  final TextEditingController _destinoController = TextEditingController();
  TimeOfDay? _horaLlamada;
  TimeOfDay? _horaAsistencia;
  TimeOfDay? _horaDestino;
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _anotacionesController = TextEditingController();

  final List<String> _provinciasCyL = [
    'Zamora',
    'Salamanca',
    'Valladolid',
    'León',
    'Burgos',
    'Palencia',
    'Ávila',
    'Segovia',
    'Soria',
  ];

  final List<String> _tiposTraslado = [
    'Alta',
    'Urgencia',
    'Interhospitalario',
  ];

  // Cálculo automático de la letra del DNI según los 8 números
  void _calcularLetraDni(String valor) {
    const letras = "TRWAGMYFPDXBNJZSQVHLCKE";
    if (valor.length == 8 && int.tryParse(valor) != null) {
      int num = int.parse(valor);
      _dniLetraController.text = letras[num % 23];
    }
  }

  // Selector de Fecha
  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF38BDF8),
              onPrimary: Colors.black,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  // Selector de Hora Digital (Formato 24h)
  Future<void> _seleccionarHora(Function(TimeOfDay) onSelected, TimeOfDay? actual) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: actual ?? TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF38BDF8),
                onPrimary: Colors.black,
                surface: Color(0xFF1E293B),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        onSelected(picked);
      });
    }
  }

  String _formatearFecha(DateTime? dt) {
    if (dt == null) return '';
    String d = dt.day.toString().padLeft(2, '0');
    String m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  String _formatearHora(TimeOfDay? t) {
    if (t == null) return '';
    String h = t.hour.toString().padLeft(2, '0');
    String m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // Construir mensaje exacto para WhatsApp
  String _construirMensajeWhatsApp() {
    List<String> lineas = [];

    if (_fechaSeleccionada != null) {
      lineas.add('*FECHA*: ${_formatearFecha(_fechaSeleccionada)}');
    }
    if (_provinciaSeleccionada != null && _provinciaSeleccionada!.isNotEmpty) {
      lineas.add('*PROVINCIA*: $_provinciaSeleccionada');
    }
    if (_aseguradoController.text.trim().isNotEmpty) {
      lineas.add('*ASEGURADO*: ${_aseguradoController.text.trim()}');
    }
    String dniTotal = '${_dniNumController.text.trim()}${_dniLetraController.text.trim().toUpperCase()}';
    if (dniTotal.isNotEmpty) {
      lineas.add('*DNI*: $dniTotal');
    }
    if (_polizaController.text.trim().isNotEmpty) {
      lineas.add('*Nº PÓLIZA*: ${_polizaController.text.trim()}');
    }
    if (_autorizacionController.text.trim().isNotEmpty) {
      lineas.add('*Nº AUTORIZACION*: ${_autorizacionController.text.trim()}');
    }
    if (_tipoSeleccionado != null && _tipoSeleccionado!.isNotEmpty) {
      lineas.add('*TIPO*: $_tipoSeleccionado');
    }
    if (_origenController.text.trim().isNotEmpty) {
      lineas.add('*ORIGEN*: ${_origenController.text.trim()}');
    }
    if (_destinoController.text.trim().isNotEmpty) {
      lineas.add('*DESTINO*: ${_destinoController.text.trim()}');
    }
    if (_horaLlamada != null) {
      lineas.add('*HORA DE LLAMADA*: ${_formatearHora(_horaLlamada)}');
    }
    if (_horaAsistencia != null) {
      lineas.add('*HORA ASISTENCIA*: ${_formatearHora(_horaAsistencia)}');
    }
    if (_horaDestino != null) {
      lineas.add('*HORA DESTINO*: ${_formatearHora(_horaDestino)}');
    }
    if (_telefonoController.text.trim().isNotEmpty) {
      lineas.add('*TELEFONO*: ${_telefonoController.text.trim()}');
    }
    if (_anotacionesController.text.trim().isNotEmpty) {
      lineas.add(_anotacionesController.text.trim());
    }

    return lineas.join('\n');
  }

  void _copiarAlPortapapeles() {
    String mensaje = _construirMensajeWhatsApp();
    if (mensaje.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rellena al menos un dato antes de copiar'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Clipboard.setData(ClipboardData(text: mensaje));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text('¡Aviso copiado para WhatsApp!'),
          ],
        ),
        backgroundColor: Color(0xFF22C55E),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _limpiarFormulario() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('¿Vaciar aviso?'),
        content: const Text('Se borrarán todos los campos para tomar uno nuevo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _fechaSeleccionada = DateTime.now();
                _provinciaSeleccionada = null;
                _aseguradoController.clear();
                _dniNumController.clear();
                _dniLetraController.clear();
                _polizaController.clear();
                _autorizacionController.clear();
                _tipoSeleccionado = null;
                _origenController.clear();
                _destinoController.clear();
                _horaLlamada = null;
                _horaAsistencia = null;
                _horaDestino = null;
                _telefonoController.clear();
                _anotacionesController.clear();
              });
            },
            child: const Text('Vaciar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toma de Avisos TES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          children: [
            // FECHA Y PROVINCIA
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _seleccionarFecha,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'FECHA'),
                      child: Text(
                        _formatearFecha(_fechaSeleccionada),
                        style: const TextStyle(fontSize: 15, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _provinciaSeleccionada,
                    decoration: const InputDecoration(labelText: 'PROVINCIA'),
                    hint: const Text('Seleccionar', style: TextStyle(fontSize: 14)),
                    items: _provinciasCyL.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) => setState(() => _provinciaSeleccionada = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ASEGURADO
            TextField(
              controller: _aseguradoController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'ASEGURADO',
                hintText: 'Nombre y apellidos',
              ),
            ),
            const SizedBox(height: 12),

            // DNI (Teclado numérico con cálculo de letra)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _dniNumController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                    onChanged: _calcularLetraDni,
                    decoration: const InputDecoration(
                      labelText: 'DNI (NÚMEROS)',
                      hintText: '8 dígitos',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _dniLetraController,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [LengthLimitingTextInputFormatter(1)],
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'LETRA',
                      hintText: 'Letra',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // PÓLIZA Y AUTORIZACIÓN (Teclado numérico)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _polizaController,
                    keyboardType: TextInputType.phone, // Permite números y guiones como 100849601112-01
                    decoration: const InputDecoration(
                      labelText: 'Nº PÓLIZA',
                      hintText: 'Ej: 100849601112-01',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _autorizacionController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nº AUTORIZACIÓN',
                      hintText: 'Ej: 183138',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // TIPO
            DropdownButtonFormField<String>(
              value: _tipoSeleccionado,
              decoration: const InputDecoration(labelText: 'TIPO'),
              hint: const Text('Seleccionar tipo de traslado', style: TextStyle(fontSize: 14)),
              items: _tiposTraslado.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => setState(() => _tipoSeleccionado = val),
            ),
            const SizedBox(height: 12),

            // ORIGEN
            TextField(
              controller: _origenController,
              decoration: const InputDecoration(
                labelText: 'ORIGEN',
                hintText: 'Hospital, habitación, domicilio...',
              ),
            ),
            const SizedBox(height: 12),

            // DESTINO
            TextField(
              controller: _destinoController,
              decoration: const InputDecoration(
                labelText: 'DESTINO',
                hintText: 'Dirección y población de destino',
              ),
            ),
            const SizedBox(height: 12),

            // HORAS DIGITALES (Llamada, Asistencia, Destino)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _seleccionarHora((t) => _horaLlamada = t, _horaLlamada),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'H. LLAMADA'),
                      child: Text(
                        _horaLlamada != null ? _formatearHora(_horaLlamada) : '--:--',
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: InkWell(
                    onTap: () => _seleccionarHora((t) => _horaAsistencia = t, _horaAsistencia),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'H. ASIST.'),
                      child: Text(
                        _horaAsistencia != null ? _formatearHora(_horaAsistencia) : '--:--',
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: InkWell(
                    onTap: () => _seleccionarHora((t) => _horaDestino = t, _horaDestino),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'H. DEST.'),
                      child: Text(
                        _horaDestino != null ? _formatearHora(_horaDestino) : '--:--',
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // TELÉFONO
            TextField(
              controller: _telefonoController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'TELÉFONO',
                hintText: 'Ej: 649940048',
              ),
            ),
            const SizedBox(height: 12),

            // ANOTACIONES
            TextField(
              controller: _anotacionesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ANOTACIONES',
                hintText: 'Ej: Con camilla, oxígeno, etc.',
              ),
            ),
            const SizedBox(height: 80), // Margen inferior para que no tape la barra flotante
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          border: Border(top: BorderSide(color: Color(0xFF334155))),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _limpiarFormulario,
                child: const Text('BORRAR', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _copiarAlPortapapeles,
                icon: const Icon(Icons.copy, color: Color(0xFF052E16)),
                label: const Text(
                  'COPIAR AVISO',
                  style: TextStyle(color: Color(0xFF052E16), fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
