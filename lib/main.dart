import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool loggedIn = prefs.getBool('is_logged_in') ?? false;

    if (loggedIn) {
      int userId = prefs.getInt('user_id') ?? 0;
      setState(() {
        isLoggedIn = true;
      });
      UserIdSingleton.setUserId(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => LoginScreen(
              onLogin: (userId) {
                UserIdSingleton.setUserId(userId);
              },
            ),
        '/home': (context, {arguments}) =>
            MyHome(userId: UserIdSingleton.userId ?? 0),
      },
    );
  }
}

class MyHome extends StatefulWidget {
  final int userId;

  MyHome({Key? key, required this.userId}) : super(key: key);

  @override
  _MyHomeState createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  DatabaseHelper dbHelper = DatabaseHelper();
  int? userId;

  List<Map<String, dynamic>> sedes = [];
  dynamic selectedSede;
  Map<String, dynamic> selectedSedeDetails = {};

  List<Map<String, dynamic>> eventos = [];
  dynamic selectedEvento;
  dynamic selectedEventoId;
  String qrContent = '';

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late QRViewController controller;
  bool isCameraReady = false;

  @override
  void initState() {
    super.initState();
    userId = widget.userId; // Initialize userId here
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      List<Map<String, dynamic>> staticSedes = [
        {'id': 1, 'nombre': 'Centro de convenciones: Salón Joaquín Cisneros '},
        {'id': 2, 'nombre': 'Centro de convenciones: Sala Nellie Campobello'},
        {
          'id': 3,
          'nombre': 'Centro de convenciones: Sala Pablo Gonzales Casanova'
        },
        {'id': 4, 'nombre': 'Domo blanco'},
        {'id': 5, 'nombre': 'Centro de convenciones'},
        {'id': 6, 'nombre': 'Centro de convenciones'},
        {'id': 7, 'nombre': 'Lienzo charro Salón Tlaxcala'},
        {'id': 8, 'nombre': 'Sala Fernando Solana'},
        {'id': 9, 'nombre': 'Sala María Montessori'},
        {'id': 10, 'nombre': 'Sala Pablo Latapí Sarre'},
        {'id': 11, 'nombre': 'Sala Gabriela Mistral'},
        {'id': 12, 'nombre': 'Sala Alfonsina Storni'},
        {'id': 13, 'nombre': 'Sala Alfonso Reyes'},
        {'id': 14, 'nombre': 'Sala Leonarda Gómez Blanco'},
        {'id': 15, 'nombre': 'Centro de Convenciones '},
        {'id': 16, 'nombre': 'Centro Expositor'},
      ];

// Asigna las sedes estáticas a la variable sedes
      setState(() {
        sedes = staticSedes;
        userId = widget.userId;
      });
    } catch (error) {
      // Mostrar un mensaje de error al usuario
      print('Error fetching data: $error');
    }
  }

  Future<void> fetchSedeDetails(dynamic sedeId) async {
    try {
      // Lista de stands estáticos por sede
      Map<int, String> staticStands = {
        1: 'Congreso NUMET',
        2: 'Feria del Libro',
        3: 'Feria del Libro',
        4: 'Olimpiadas STEM',
        5: 'Encuentro Académico PRONI',
        6: 'Expo Proyectos Científicos EMS',
        7: 'Conferencias temáticas',
        8: 'Conferencias temáticas',
        9: 'Ponencias',
        10: 'Ponencias',
        11: 'Talleres',
        12: 'Foros de discusión',
        13: 'Experiencias exitosas',
        14: 'Carteles',
        15: 'Presentaciones de libros',
        16: 'Talleres',
        17: 'Primera Feria Estatal del libro',
        18: 'Presentaciones y Actividades',
        19: 'Actividades Coordinación de',
      };

      int staticSedeId = sedeId as int;

      if (staticStands.containsKey(staticSedeId)) {
        String stand = staticStands[staticSedeId] ?? '';

        setState(() {
          selectedSedeDetails = {'stand': stand};
          selectedEvento = null;
        });

        print('Sede Details: $selectedSedeDetails');
      } else {
        print('ID de la sede no coincide con ningún stand');
      }
    } catch (error) {
      print('Error fetching sede details: $error');
    }
  }

  Future<void> fetchEventos(dynamic sedeId) async {
    try {
      print('Fetching eventos for Sede ID: $sedeId');

      // Lista de eventos estáticos para cada sede con hora de inicio y fin
      Map<int, List<Map<String, dynamic>>> staticEventsBySede = {
        1: [
          {
            'id': 1,
            'horaInicio': '08:00',
            'horaFin': '09:00',
            'fecha': '2023-11-29',
            'nombre': 'Recepción de invitados',
          },
          {
            'id': 2,
            'horaInicio': '09:00',
            'horaFin': '10:00',
            'fecha': '2023-11-29',
            'nombre': 'Inauguración',
          },
          {
            'id': 3,
            'horaInicio': '10:00',
            'horaFin': '11:00',
            'fecha': '2023-11-29',
            'nombre': 'Liderazgo escolar distribuido. Mario Uribe Briceño',
          },
          {
            'id': 4,
            'horaInicio': '11:00',
            'horaFin': '12:00',
            'fecha': '2023-11-29',
            'nombre':
                '¿Estás list@ para competir con un robot? Graciela Rojas Montemayor',
          },
          {
            'id': 5,
            'horaInicio': '12:00',
            'horaFin': '13:00',
            'fecha': '2023-11-29',
            'nombre':
                'Creando una cultura de curiosidad: el poder y potencial de las mujeres en STEM María Diana Lorena Rubio Navarro ',
          },
          {
            'id': 6,
            'horaInicio': '13:00',
            'horaFin': '14:00',
            'fecha': '2023-11-29',
            'nombre':
                'México: Territorio STEM+ Construyendo Ciudadanía Responsable',
          },
          {
            'id': 7,
            'horaInicio': '14:00',
            'horaFin': '15:00',
            'fecha': '2023-11-29',
            'nombre':
                'Democracia y participación estudiantil en Educación Media Superior en el marco de la Nueva Escuela Mexicana Ernesto Ramírez Vicente',
          },
          {
            'id': 8,
            'horaInicio': '15:00',
            'horaFin': '16:00',
            'fecha': '2023-11-29',
            'nombre':
                'El ingles y la educacion inclusiva. Humberto Farjan Ayala',
          },
          {
            'id': 9,
            'horaInicio': '16:00',
            'horaFin': '17:00',
            'fecha': '2023-11-29',
            'nombre':
                'Género, feminismos e interseccionalidades Gisela Zaremberg',
          },
          {
            'id': 54,
            'horaInicio': '09:00',
            'horaFin': '10:00',
            'fecha': '2023-11-30',
            'nombre':
                'Bogota territorio STEM, una experiencia para compartir y construir. Ricardo Andrés Triana González',
          },
          {
            'id': 55,
            'horaInicio': '10:00',
            'horaFin': '11:00',
            'fecha': '2023-11-30',
            'nombre':
                'Repensar la planeacion y la gestion del territorio en tiempos de incertidumbre . Horacio Bozzano',
          },
          {
            'id': 56,
            'horaInicio': '11:00',
            'horaFin': '12:00 ',
            'fecha': '2023-11-30',
            'nombre':
                'El futuro de la Educacion Superior en Mexico. Jesica Imelda Saavedra Venítez',
          },
          {
            'id': 57,
            'horaInicio': '12:00',
            'horaFin': '13:00',
            'fecha': '2023-11-30',
            'nombre':
                'Pensar, sentir, hacer,Educar en conciencia Paulina Latapi Escalante',
          },
          {
            'id': 58,
            'horaInicio': '13:00',
            'horaFin': '14:00',
            'fecha': '2023-11-30',
            'nombre':
                'Enseñanza del ingles a traves de proyectos STEM. Jose Luis Amaya Espinosa de los Monteros ',
          },
          {
            'id': 59,
            'horaInicio': '14:00',
            'horaFin': '15:00',
            'fecha': '2023-11-30',
            'nombre': 'Patrimonio y educacion. Gabriela Pulido Lano ',
          },
          {
            'id': 60,
            'horaInicio': '15:00',
            'horaFin': '16:00',
            'fecha': '2023-11-30',
            'nombre':
                'La nobleza indigena ante la Politica de Educacion Superior en la nueva España en el siglo XVIII. Rodolfo Aguirre Salvador ',
          },
          {
            'id': 61,
            'horaInicio': '16:00',
            'horaFin': '17:00 ',
            'fecha': '2023-11-30',
            'nombre':
                'Los libros de texto gratuito y el programa analitico. Sady Arturo Loaiza Escalona ',
          },
          {
            'id': 62,
            'horaInicio': '17:00',
            'horaFin': '18:00',
            'fecha': '2023-11-30',
            'nombre':
                'Una perspectiva docente en la implantacion del plan de Estudio 2022. Angel Diaz Barriga Casales',
          },
          {
            'id': 104,
            'horaInicio': '8:00',
            'horaFin': '18:00',
            'fecha': '2023-11-29',
            'nombre': 'Entrada general',
          },
          {
            'id': 105,
            'horaInicio': '8:00',
            'horaFin': '18:00',
            'fecha': '2023-11-30',
            'nombre': 'Entrada general',
          },
        ],
        2: [
          {
            'id': 10,
            'horaInicio': '10:00',
            'horaFin': '11:30',
            'fecha': '2023-11-29',
            'nombre': 'Ek Balam. Sareki López.',
          },
          {
            'id': 11,
            'horaInicio': '10:00',
            'horaFin': '11:30',
            'fecha': '2023-11-29',
            'nombre': 'Campo de papalotes Alejandro Ipatzi Pérez.',
          },
          {
            'id': 12,
            'horaInicio': '11:30',
            'fecha': '2023-11-29',
            'nombre': 'In xinachtli in tlahtolli Fabiola Carrillo Tieco',
          },
          {
            'id': 13,
            'horaInicio': '11:30',
            'fecha': '2023-11-29',
            'nombre': 'Narracion oral Trotelote. Angelica Flores Montealegre',
          },
          {
            'id': 19,
            'horaInicio': '13:30',
            'horaFin': '16:00',
            'fecha': '2023-11-29',
            'nombre': 'Encuadernacion',
          },
          {
            'id': 20,
            'horaInicio': '13:30',
            'horaFin': '16:00',
            'fecha': '2023-11-29',
            'nombre':
                'Tlaoxtica in tlhtolli (Desgranando la palabra). Ethel Xochitiotzi Pérez',
          },
          {
            'id': 21,
            'horaInicio': '13:30',
            'horaFin': '16:00',
            'fecha': '2023-11-29',
            'nombre': 'Retablos. Alba Tzuyuki Flores Romero',
          },
          {
            'id': 22,
            'horaInicio': '13:30',
            'horaFin': '16:00',
            'fecha': '2023-11-29',
            'nombre':
                'Clinica de narrativa oral (Librobus). Norma Márquez Cuevas, Medardo London y Mazas Dueñas',
          },
          {
            'id': 23,
            'horaInicio': '16:00',
            'fecha': '2023-11-29',
            'nombre': 'La risa del Joker Yassir Zarate Mendez ',
          },
          {
            'id': 63,
            'horaInicio': '08:00',
            'horaFin': '09:00',
            'fecha': '2023-11-30',
            'nombre': 'Via lactea. Gabriela Conde Moreno ',
          },
          {
            'id': 64,
            'horaInicio': '09:00',
            'horaFin': '10:00',
            'fecha': '2023-11-30',
            'nombre': 'Tartalina. Antonia Carrillo ',
          },
          {
            'id': 65,
            'horaInicio': '09:00',
            'horaFin': '10:00',
            'fecha': '2023-11-30',
            'nombre': 'Un comienso inesperado',
          },
          {
            'id': 66,
            'horaInicio': '10:00',
            'horaFin': '15:00',
            'fecha': '2023-11-30',
            'nombre':
                'Antologia poetica: Los animales que matamos, flores amarillas, parpados de agua y pantone 347. Alba Daniela Escobar Juarez',
          },
          {
            'id': 67,
            'horaInicio': '10:00',
            'horaFin': '15:00',
            'fecha': '2023-11-30',
            'nombre': 'Los pequeños macabros . Yesenia Raquel Cabrera Barrios',
          },
          {
            'id': 68,
            'horaInicio': '10:00',
            'horaFin': '15:00',
            'fecha': '2023-11-30',
            'nombre':
                'Voces de esperanza . Ma. Teresa Cristina Gonzales Cuamatzi.',
          },
          {
            'id': 69,
            'horaInicio': '10:00',
            'horaFin': '15:00',
            'fecha': '2023-11-30',
            'nombre': 'Microfilomes de terror. Gerardo Lima Molina',
          },
          {
            'id': 70,
            'horaInicio': '10:00',
            'horaFin': '15:00',
            'fecha': '2023-11-30',
            'nombre':
                'El reino de la salamandra. Horacio Gabriel Saavedra Castillo. ',
          },
          {
            'id': 71,
            'horaInicio': '10:00',
            'horaFin': '15:00',
            'fecha': '2023-11-30',
            'nombre': 'Los tres dias del gorrion. Luis Miguel Estrada Orozco',
          },
          {
            'id': 72,
            'horaInicio': '10:00',
            'horaFin': '15:00',
            'fecha': '2023-11-30',
            'nombre': 'Clinica de narracion oral. Renata Luna Marines ',
          },
          {
            'id': 73,
            'horaInicio': '10:00',
            'horaFin': '15:00',
            'fecha': '2023-11-30',
            'nombre':
                'Clinicas de narrativa Oral (Librobus-FCE-EDUCAL): Norma Marquez Cuevas,Medardo London Mazos Dueñas',
          },
          {
            'id': 104,
            'horaInicio': '8:00',
            'horaFin': '18:00',
            'fecha': '2023-11-29',
            'nombre': 'Entrada general',
          },
          {
            'id': 105,
            'horaInicio': '8:00',
            'horaFin': '18:00',
            'fecha': '2023-11-30',
            'nombre': 'Entrada general',
          },
        ],
        3: [
          {
            'id': 28,
            'horaInicio': '08:30',
            'horaFin': '09:30',
            'fecha': '2023-11-29',
            'nombre': 'Ingreso de los equipos y acondicionamiento de espacios.',
          },
          {
            'id': 29,
            'horaInicio': '09:45',
            'horaFin': '10:00',
            'fecha': '2023-11-29',
            'nombre': 'Inauguracion de las olimpiadas STEM. Yu nt\'eni 2023',
          },
          {
            'id': 30,
            'horaInicio': '10:30',
            'horaFin': '12:30',
            'fecha': '2023-11-29',
            'nombre': 'Evaluacion de equipos',
          },
          {
            'id': 31,
            'horaInicio': '10:00',
            'horaFin': '11:00',
            'fecha': '2023-11-29',
            'nombre':
                'Despierta tu curiosa mente con STEM Maria Diana Lorena Rubio Navarro',
          },
          {
            'id': 32,
            'horaInicio': '13:30',
            'horaFin': '14:30',
            'fecha': '2023-11-29',
            'nombre': 'Proceso de evaluacion ',
          },
          {
            'id': 33,
            'horaInicio': '14:30',
            'horaFin': '15:30',
            'fecha': '2023-11-29',
            'nombre':
                'Gran final Olimpiadas STEM. Yu nt \'eni 2023 entrega de reconocimientos ',
          },
          {
            'id': 34,
            'horaInicio': '15:30',
            'horaFin': '18:00',
            'fecha': '2023-11-29',
            'nombre': 'Conferencia de prensa con los equipos ganadores ',
          },
          {
            'id': 102,
            'horaInicio': '15:00',
            'horaFin': '16:00',
            'fecha': '2023-11-30',
            'nombre': 'Para entender la ciencia . Yani Betancourt Gonzalez',
          },
          {
            'id': 103,
            'horaInicio': '15:00',
            'horaFin': '16:30',
            'fecha': '2023-11-30',
            'nombre': 'Reflexion y dialogo entre pares ',
          },
          {
            'id': 104,
            'horaInicio': '8:00',
            'horaFin': '18:00',
            'fecha': '2023-11-29',
            'nombre': 'Entrada general',
          },
          {
            'id': 105,
            'horaInicio': '8:00',
            'horaFin': '18:00',
            'fecha': '2023-11-30',
            'nombre': 'Entrada general',
          },
        ],
        4: [
          {
            'id': 211,
            'horaInicio': '09:00',
            'horaFin': '17:00',
            'fecha': '2023-11-30',
            'nombre': 'Inscripcion Cubo Rubik',
          },
          {
            'id': 212,
            'horaInicio': '09:00',
            'horaFin': '10:00',
            'fecha': '2023-11-30',
            'nombre': 'Inscripcion a torneos',
          },
          {
            'id': 213,
            'horaInicio': '10:00',
            'horaFin': '17:00',
            'fecha': '2023-11-30',
            'nombre':
                'Torneo de Ajedrez, Torneo Cubo Rubik, Torneo de TCG Yu-Gi-Oh!,Torneo de TCG Pokémon',
          },
          {
            'id': 214,
            'horaInicio': '12:00',
            'horaFin': '14:00',
            'fecha': '2023-11-30',
            'nombre': 'DJ Peter Miller',
          },
          {
            'id': 215,
            'horaInicio': '14:00',
            'horaFin': '15:00',
            'fecha': '2023-11-30',
            'nombre': 'Inscripcion a torneos',
          },
          {
            'id': 216,
            'horaInicio': '15:00',
            'horaFin': '17:00',
            'fecha': '2023-11-30',
            'nombre': 'Demostracion de sables de luz y esgrima',
          },
          {
            'id': 35,
            'horaInicio': '08:30',
            'horaFin': '09:00',
            'fecha': '2023-11-29',
            'nombre': 'Registro',
          },
          {
            'id': 36,
            'horaInicio': '09:00',
            'horaFin': '09:30',
            'fecha': '2023-11-29',
            'nombre': 'Presentacion general e inauguracion ',
          },
          {
            'id': 37,
            'horaInicio': '09:30',
            'horaFin': '10:30',
            'fecha': '2023-11-29',
            'nombre':
                'Enseñanza de las cuatro habilidades del idioma de cara de Nuevo Modelo Educativo Adriana Teresa Palomo Corona',
          },
          {
            'id': 38,
            'horaInicio': '10:30',
            'horaFin': '11:30',
            'fecha': '2023-11-29',
            'nombre': 'Estrategias para la enseñanza del ingles ',
          },
          {
            'id': 39,
            'horaInicio': '11:30',
            'horaFin': '12:30',
            'fecha': '2023-11-29',
            'nombre':
                'El uso de herramientas tecnologicas para la enseñanza de una lengua extranjera(ingles). Federico Gonzalez Hernandez ',
            'ctNumetSede_id': 4,
          },
          {
            'id': 40,
            'horaInicio': '12:30',
            'horaFin': '13:30',
            'fecha': '2023-11-29',
            'nombre':
                'El nuevo Modelo Educativo Tlaxcalteca y su implicacion para el ingles Metodologias emergentes de la enseñanza de ingles: glotodidacta. Humberto Forjan Ayala ',
          },
          {
            'id': 85,
            'horaInicio': '08:00',
            'horaFin': '09:00',
            'fecha': '2023-11-30',
            'nombre': 'Registro y presentacion general de la agenda ',
          },
          {
            'id': 86,
            'horaInicio': '09:00',
            'horaFin': '10:00',
            'fecha': '2023-11-30',
            'nombre':
                'Importancia del aprendizaje de la lengua del extranjera. Adriana Teresa Palomo Corona',
          },
          {
            'id': 87,
            'horaInicio': '10:00',
            'horaFin': '11:00',
            'fecha': '2023-11-30',
            'nombre': 'Estrategias para la enseñanza del inlgles ',
          },
          {
            'id': 88,
            'horaInicio': '11:00',
            'horaFin': '12:00',
            'fecha': '2023-11-30',
            'nombre':
                'Interculturalidad y enseñanza de lenguas. Jose Luis Amaya Espinosa de los Monteros ',
          },
          {
            'id': 89,
            'horaInicio': '12:00',
            'horaFin': '13:00',
            'fecha': '2023-11-30',
            'nombre':
                'Proyecto de artes y ciencias slife. Federico Gonzales Hernandez ',
          },
          {
            'id': 90,
            'horaInicio': '13:00',
            'horaFin': '14:00',
            'fecha': '2023-11-30',
            'nombre': 'Estrategias para la enseñanza del ingles',
          },
          {
            'id': 91,
            'horaInicio': '14:00',
            'horaFin': '15:00',
            'fecha': '2023-11-30',
            'nombre': 'Experiencias exitosas sobre la enseñanza del ingles ',
          },
          {
            'id': 92,
            'horaInicio': '15:00',
            'horaFin': '16:00',
            'fecha': '2023-11-30',
            'nombre': 'Dialogues for teaching English ',
          },
          {
            'id': 104,
            'horaInicio': '8:00',
            'horaFin': '18:00',
            'fecha': '2023-11-29',
            'nombre': 'Entrada general',
          },
          {
            'id': 105,
            'horaInicio': '8:00',
            'horaFin': '18:00',
            'fecha': '2023-11-30',
            'nombre': 'Entrada general',
          },
        ],
        5: [
          {
            'id': 165,
            'horaInicio': '10:00',
            'horaFin': '18:00',
            'fecha': '2023-11-29',
            'nombre': 'Exposición de carteles y Presentación de autores',
          },
          {
            'id': 166,
            'horaInicio': '10:00',
            'horaFin': '18:00',
            'fecha': '2023-11-30',
            'nombre': 'Exposición de carteles y Presentación de autores',
          },
          {
            'id': 167,
            'horaInicio': '10:00',
            'horaFin': '10:40',
            'fecha': '2023-11-29',
            'nombre': 'Ek balam. Sareki López ',
          },
          {
            'id': 168,
            'horaInicio': '10:40',
            'horaFin': '11:30',
            'fecha': '2023-11-29',
            'nombre': 'Campo de Papalotes. Alejandro Ipatzi Pérez',
          },
          {
            'id': 169,
            'horaInicio': '11:30',
            'horaFin': '12:20',
            'fecha': '2023-11-29',
            'nombre':
                'Conferencia: La importancia de la literatura náhuatl In xinachtli in tlahtolli. Fabiola Carrillo Tieco',
          },
          {
            'id': 170,
            'horaInicio': '12:20',
            'horaFin': '13:10',
            'fecha': '2023-11-29',
            'nombre': 'La rebeldía de pensar. Óscar de la Borbolla',
          },
          {
            'id': 171,
            'horaInicio': '13:10',
            'horaFin': '14:20',
            'fecha': '2023-11-29',
            'nombre': 'Júrame que te casaste virgen. Beatriz Escalante',
          },
          {
            'id': 172,
            'horaInicio': '14:20',
            'horaFin': '15:00',
            'fecha': '2023-11-29',
            'nombre':
                'Tlaoxtica in tlhtolli (Desgranando la palabra). Ethel Xochitiotzin Pérez',
          },
          {
            'id': 173,
            'horaInicio': '15:00',
            'horaFin': '16:00',
            'fecha': '2023-11-29',
            'nombre': 'Retablos, Alba Tzuyuki Flores Romero',
          },
          {
            'id': 174,
            'horaInicio': '16:00',
            'horaFin': '16:40',
            'fecha': '2023-11-29',
            'nombre': 'La risa del Joker. Yassir Zárate Méndez',
          },
          {
            'id': 175,
            'horaInicio': '08:00',
            'horaFin': '09:00',
            'fecha': '2023-11-30',
            'nombre': 'Vía Láctea. Gabriela Conde Moreno',
          },
          {
            'id': 176,
            'horaInicio': '09:00',
            'horaFin': '10:00',
            'fecha': '2023-11-30',
            'nombre': 'Tartalina, Antonia Carrillo',
          },
          {
            'id': 177,
            'horaInicio': '10:00',
            'horaFin': '11:00',
            'fecha': '2023-11-30',
            'nombre':
                'Antología Poética: Los animales que matamos Flores amarillas, párpados de agua Pantone 347. Alva Daniela Escobar Juárez ',
          },
          {
            'id': 178,
            'horaInicio': '11:00',
            'horaFin': '12:00',
            'fecha': '2023-11-30',
            'nombre':
                'Filosfofia de las luciérnagas. Ma. Teresa Cristina González Cuamatzi',
          },
          {
            'id': 179,
            'horaInicio': '12:00',
            'horaFin': '12:50',
            'fecha': '2023-11-30',
            'nombre': 'Los tres días del gorrión. Luis Miguel Estrada Orozco',
          },
          {
            'id': 180,
            'horaInicio': '13:00',
            'horaFin': '13:30',
            'fecha': '2023-11-30',
            'nombre':
                'Un comienzo Inesperado. Compañía: Teatro Luna de Papel Actuaciones: Mariana Gálvez y Norma Márquez',
          },
          {
            'id': 181,
            'horaInicio': '13:30',
            'horaFin': '14:20',
            'fecha': '2023-11-30',
            'nombre':
                'El reino de la salamandra. Horacio Gabriel Saavedra Castillo',
          },
          {
            'id': 182,
            'horaInicio': '14:20',
            'horaFin': '15:00',
            'fecha': '2023-11-30',
            'nombre': 'De chile, mole y pozole. Kurt Harbarth ',
          },
          {
            'id': 183,
            'horaInicio': '15:00',
            'horaFin': '16:30',
            'fecha': '2023-11-30',
            'nombre':
                'La ruta del hielo y la sal (Zárate) Volver a la piel (Porcayo), José Luis Zárate Gerardo Porcayo',
          },
          {
            'id': 184,
            'horaInicio': '16:30',
            'horaFin': '17:20',
            'fecha': '2023-11-30',
            'nombre': 'Los pequeños macabros. Yesenia Raquel Cabrera Barrios',
          },
          {
            'id': 185,
            'horaInicio': '17:20',
            'horaFin': '18:00',
            'fecha': '2023-11-30',
            'nombre': 'Microfilmes de terror. Gerardo Lima Molina',
          },
          {
            'id': 268,
            'horaInicio': '10:00',
            'horaFin': '10:10',
            'fecha': '2023-11-29',
            'nombre': 'Taller: Encuadernación. Alejandro Ipatzi Pérez',
          },
          {
            'id': 269,
            'horaInicio': '10:10',
            'horaFin': '11:00',
            'fecha': '2023-11-29',
            'nombre': 'Narración Oral. Angelita Flores Montealegre',
          },
          {
            'id': 270,
            'horaInicio': '11:40',
            'horaFin': '12:30',
            'fecha': '2023-11-30',
            'nombre': 'Taller: Clínica de Narración Oral. Renata Luna Marines',
          },
          {
            'id': 271,
            'horaInicio': '14:00',
            'horaFin': '14:20',
            'fecha': '2023-11-30',
            'nombre': 'Narración. Renata Luna Marines',
          },
        ],
        6: [
          {
            'id': 14,
            'horaInicio': '09:30',
            'horaFin': '11:30',
            'fecha': '2023-11-29',
            'nombre':
                'Maguey aguamiel/Pulque: una vision para el desarrollo territorial. Edgar Ivan Cruz Roldan.',
          },
          {
            'id': 15,
            'horaInicio': '09:30',
            'horaFin': '11:30',
            'fecha': '2023-11-29',
            'nombre':
                'Hidalgo. Elecciones en el siglo XXI. Hacia la alternancia ',
          },
          {
            'id': 16,
            'horaInicio': '09:30',
            'horaFin': '11:30',
            'fecha': '2023-11-29',
            'nombre':
                'Conferencia y firma del convenio de donacion de la biblioteca de Angel Garcia Cook. Diego Prieto',
          },
          {
            'id': 17,
            'horaInicio': '12:20',
            'horaFin': '13:10',
            'fecha': '2023-11-29',
            'nombre': 'La rebeldía de pensar Óscar de la Borbolla',
          },
          {
            'id': 18,
            'horaInicio': '13:10',
            'horaFin': '14:20',
            'fecha': '2023-11-29',
            'nombre': 'Júrame que te casaste virgen Beatriz Escalante',
          },
          {
            'id': 24,
            'horaInicio': '13:30',
            'horaFin': '17:15',
            'fecha': '2023-11-29',
            'nombre':
                'Estudios de parentesco en tiempos de globalizacion Laura Collin, Jose Luis Cisneros y Dora del Carmen Yautenzi Diaz.',
          },
          {
            'id': 25,
            'horaInicio': '13:30',
            'horaFin': '17:15',
            'fecha': '2023-11-29',
            'nombre': 'Corazonar las justicias Laura Edith Savedra Hernandez ',
          },
          {
            'id': 26,
            'horaInicio': '13:15',
            'horaFin': '17:15',
            'fecha': '2023-11-29',
            'nombre':
                'La nueva regionalizacion en el marco de la cuarta transformacion en Hidalgo. Maximiliano Gracia Hernandez.',
          },
          {
            'id': 27,
            'horaInicio': '13:15',
            'horaFin': '17:15',
            'fecha': '2023-11-29',
            'nombre':
                'Recuento de los trabajos para salvaguardia del patrimonio cultural inmaterial de Tlaxcala. Patricia Pórtela, Jose Juan Zamora y Sejen Luna',
          },
          {
            'id': 74,
            'horaInicio': '09:00',
            'horaFin': '10:15',
            'fecha': '2023-11-30',
            'nombre':
                'Modelo de gestion social y cambio climatico en la region centro de Mexico, factores estructurales para mitigar el cambio climaticos. Sergio Flores.',
          },
          {
            'id': 75,
            'horaInicio': '09:00',
            'horaFin': '10:15',
            'fecha': '2023-11-30',
            'nombre':
                'Marco para la buena direccion y el liderazgo escolar. Mario Uribe ',
          },
          {
            'id': 76,
            'horaInicio': '11:15',
            'horaFin': '17:15',
            'fecha': '2023-11-30',
            'nombre':
                'Transformar dialogos de saberes en dialogos de haceres.Ciencia,comiunidad y politicas publicas. Horacio Bozzano',
          },
          {
            'id': 77,
            'horaInicio': '11:15',
            'horaFin': '17:15',
            'fecha': '2023-11-30',
            'nombre':
                'Aproximaciones antropologicas a la diversidad biocultural de Tlaxcala. Milton Hernandez Garcia, Jorge Guevara Hernández y Nazario Sanchez Mastranzo.',
          },
          {
            'id': 78,
            'horaInicio': '11:15',
            'horaFin': '17:15',
            'fecha': '2023-11-30',
            'nombre':
                'Campos social y regional en el contexto de la migracion transnacional. Jose Dionicio Vazquez Vazquez ',
          },
          {
            'id': 79,
            'horaInicio': '11:15',
            'horaFin': '17:15',
            'fecha': '2023-11-30',
            'nombre':
                'Democracia y participacion de la niñez y juventud . Elizabeth Piedras Martinez',
          },
          {
            'id': 80,
            'horaInicio': '11:15',
            'horaFin': '17:15',
            'fecha': '2023-11-30',
            'nombre':
                'Las emociones Transportan aprendizajes . Flora Cahuantzi Vazques ',
          },
          {
            'id': 81,
            'horaInicio': '11:15',
            'horaFin': '17:15',
            'fecha': '2023-11-30',
            'nombre': 'Corporativo Hueyotlipan. Miguel Benavides  ',
          },
          {
            'id': 82,
            'horaInicio': '11:15',
            'horaFin': '17:15',
            'fecha': '2023-11-30',
            'nombre': 'El maravilloso mundo del ajedrez. Jose Luis Perez',
          },
          {
            'id': 83,
            'horaInicio': '15:00',
            'horaFin': '16:30',
            'fecha': '2023-11-30',
            'nombre': 'La ruta del hielo y la sal Jose Luis Zarate.',
          },
          {
            'id': 84,
            'horaInicio': '15:00',
            'horaFin': '16:30',
            'fecha': '2023-11-30',
            'nombre': 'Volver a la piel . Gerardo Porcayo ',
          },
          {
            'id': 104,
            'horaInicio': '8:00',
            'horaFin': '18:00',
            'fecha': '2023-11-29',
            'nombre': 'Entrada general',
          },
          {
            'id': 105,
            'horaInicio': '8:00',
            'horaFin': '18:00',
            'fecha': '2023-11-30',
            'nombre': 'Entrada general',
          },
        ],
        7: [
          {
            'id': 287,
            'horaInicio': '10:00',
            'horaFin': '14:30',
            'fecha': '2023-11-29',
            'nombre':
                'Taller “Técnicas para la transformación de conflictos escolares y la construcción de paz”. Mediadores del Centro de Justicia Alternativa del TSJE. ',
          },
          {
            'id': 288,
            'horaInicio': '11:00',
            'horaFin': '13:00',
            'fecha': '2023-11-29',
            'nombre':
                '"Conferencia “La participación de las juventudes en el humanismo mexicano”. Mtro. Omar Cuatianquiz Ávila.',
          },
          {
            'id': 289,
            'horaInicio': '13:00',
            'horaFin': '14:30',
            'fecha': '2023-11-29',
            'nombre':
                'Taller “Reflexión y diálogo entre pares”. Coordina Supervisores  SEMS',
          },
          {
            'id': 290,
            'horaInicio': '15:30',
            'horaFin': '18:00',
            'fecha': '2023-11-29',
            'nombre':
                'Taller “Reflexión y diálogo entre pares”. Coordina Supervisores  SEMS',
          },
        ],
        8: [
          {
            'id': 281,
            'horaInicio': '14:00',
            'horaFin': '14:30',
            'fecha': '2023-11-29',
            'nombre':
                'Estrategias de procesos en el sector industrial y social. José Víctor Galaviz Rodríguez, Noemí González León, José Aníbal Quintero Hernandez',
          },
          {
            'id': 282,
            'horaInicio': '14:30',
            'horaFin': '15:00',
            'fecha': '2023-11-29',
            'nombre':
                'Escuela y familia: Misión imposible. 27 maneras de implicar a las familias educativamente. María Esperanza López Domínguez, Catalina Teroba Jaime, Mabel Minor Hernández.',
          },
        ],
        9: [
          {
            'id': 217,
            'horaInicio': '09:00',
            'horaFin': '10:00',
            'fecha': '2023-11-30',
            'nombre':
                'Prevención de la violencia hacia los animales como estrategia de seguridad nacional. Stefany Pérez Bustamante',
          },
          {
            'id': 218,
            'horaInicio': '10:00',
            'horaFin': '11:00',
            'fecha': '2023-11-30',
            'nombre':
                'Sensibilización al cambio climático en entornos educativos mediante soluciones basadas en la naturaleza. Alma Griselda Pinillo Flores',
          },
          {
            'id': 219,
            'horaInicio': '11:00',
            'horaFin': '12:00',
            'fecha': '2023-11-30',
            'nombre':
                'La afectividad en el proceso de enseñanza aprendizaje. José Gabriel Montes Sosa',
          },
          {
            'id': 247,
            'horaInicio': '11:00',
            'horaFin': '12:00',
            'fecha': '2023-11-29',
            'nombre':
                'Apropiación del Plan de Estudio en Edu- cación Básica a partir de la contextualización y articulación del codiseño. Luis Eduardo García Medel',
          },
          {
            'id': 248,
            'horaInicio': '12:00',
            'horaFin': '13:00',
            'fecha': '2023-11-29',
            'nombre':
                'Las orientaciones didácticas. El punto de partida de la planeación docente. Mauro Cote Moreno',
          },
          {
            'id': 249,
            'horaInicio': '13:00',
            'horaFin': '14:00',
            'fecha': '2023-11-29',
            'nombre':
                'El diseño de una situación de aprendizaje en matemáticas. Mauro Cote Moreno',
          },
          {
            'id': 250,
            'horaInicio': '14:00',
            'horaFin': '15:00',
            'fecha': '2023-11-29',
            'nombre':
                'Planeación didáctica con enfoque inclusivo. Laura Coyotzi Nava',
          },
          {
            'id': 251,
            'horaInicio': '15:00',
            'horaFin': '16:00',
            'fecha': '2023-11-29',
            'nombre':
                'Las artes en la Nueva Escuela Mexicana. Artes visuales, teatro, danza y música. Gregoria García Nava',
          },
          {
            'id': 252,
            'horaInicio': '16:00',
            'horaFin': '17:00',
            'fecha': '2023-11-29',
            'nombre':
                'Diseño del plano didáctico empleando la metodología del Aprendizaje Basado en Proyectos ABP para abordar temáticas de relevancia comunitaria en el marco de la Nueva Escuela Mexicana. Rogelio Monreal Monreal',
          },
          {
            'id': 253,
            'horaInicio': '12:00',
            'horaFin': '13:00',
            'fecha': '2023-11-30',
            'nombre':
                'La planeación didáctica y su vinculación correcta ¿dónde quedaron las matemá- ticas?. Karla Paredes Aguilar',
          },
          {
            'id': 254,
            'horaInicio': '13:00',
            'horaFin': '14:00',
            'fecha': '2023-11-30',
            'nombre':
                'Uso de un enfoque multidimensional para evaluar la comprensión del conoci- miento matemático de los estudiantes. Irving Aaron Díaz Espinoza',
          },
          {
            'id': 255,
            'horaInicio': '14:00',
            'horaFin': '15:00',
            'fecha': '2023-11-30',
            'nombre':
                'Proyecto ABP. Tu historia en las calles. Jaime Castro Ramírez, Rodolfo Mendoza Meléndez, Carina Calva Sevilla',
          },
          {
            'id': 256,
            'horaInicio': '15:00',
            'horaFin': '16:00',
            'fecha': '2023-11-30',
            'nombre':
                'Creación de un aula virtual en Face- book. Nathaly Varela Baltierra',
          },
        ],
        10: [
          {
            'id': 106,
            'horaInicio': '11:00',
            'horaFin': '11:15',
            'fecha': '2023-11-29',
            'nombre':
                'Género y formación docente: visibilización del enfoque de género en la formación de formadores de la Licenciatura en Ciencias de la Educación de la Universidad Autónoma de Tlaxcala. Luz Maialen Montiel Vásquez',
          },
          {
            'id': 107,
            'horaInicio': '11:15',
            'horaFin': '11:30',
            'fecha': '2023-11-29',
            'nombre':
                'Estrategias de intervención para un modelo de inclusión educativa para prevenir y erradicar la violencia de género en la ENPPFMM a través de sus tres áreas sustantivas. Nachlliery Pérez Soberanis',
          },
          {
            'id': 108,
            'horaInicio': '11:30',
            'horaFin': '11:45',
            'fecha': '2023-11-29',
            'nombre':
                'Análisis de la educación con perspectiva de género en la niñez como instrumento de la Cultura de Paz en Tlaxcala. Geovanny Pérez López',
          },
          {
            'id': 109,
            'horaInicio': '11:45',
            'horaFin': '12:00',
            'fecha': '2023-11-29',
            'nombre':
                'La inclusión y género, las nuevas perspectivas en la Ley General de Acceso a las Mujeres a una Vida Libre de Violencia con enfoque a Derechos Humanos. María Del Carmen Cruz Padilla',
          },
          {
            'id': 110,
            'horaInicio': '12:30',
            'horaFin': '12:45',
            'fecha': '2023-11-29',
            'nombre':
                'Inteligencia Artificial en educación matemática. Geovani Daniel Nolasco Negrete',
          },
          {
            'id': 111,
            'horaInicio': '12:45',
            'horaFin': '13:00',
            'fecha': '2023-11-29',
            'nombre':
                'Propuesta de intervención educativa para la enseñanza del límite de una función con GeoGebra en la formación docente. Saul Elizarrarás Baena, Orlando Vázquez Pérez',
          },
          {
            'id': 112,
            'horaInicio': '13:00',
            'horaFin': '13:15',
            'fecha': '2023-11-29',
            'nombre':
                'Las niñas y las matemáticas, currículum oculto y género. Maribel Macias Olmos',
          },
          {
            'id': 113,
            'horaInicio': '13:15',
            'horaFin': '13:30',
            'fecha': '2023-11-29',
            'nombre':
                'Socio epistemología de la matemática educativa. Alfredo Paredes Paredes',
          },
          {
            'id': 114,
            'horaInicio': '14:00',
            'horaFin': '14:15',
            'fecha': '2023-11-29',
            'nombre':
                'La construcción del saber pedagógico didáctico y su relación con la autonomía profesional docente. Aurora Estela Rodríguez García',
          },
          {
            'id': 115,
            'horaInicio': '14:15',
            'horaFin': '14:30',
            'fecha': '2023-11-29',
            'nombre':
                'La construcción del programa analítico en Preescolar y su vinculación con el Programa Escolar de Mejora Continua. Blanca Cuautle Diaz',
          },
          {
            'id': 116,
            'horaInicio': '14:30',
            'horaFin': '14:45',
            'fecha': '2023-11-29',
            'nombre':
                'Una experiencia desde la coordinación académica en la construcción del Programa Analítico. Patricia Guevara Moreno',
          },
          {
            'id': 117,
            'horaInicio': '14:45',
            'horaFin': '15:00',
            'fecha': '2023-11-29',
            'nombre':
                'La construcción de los Programas Analíticos en los Consejos Técnicos de Secundarias Generales. Emmanuel del Ángel Moyano',
          },
          {
            'id': 118,
            'horaInicio': '15:30',
            'horaFin': '15:50',
            'fecha': '2023-11-29',
            'nombre':
                'Evaluación del liderazgo educativo como habilidad blanda en la Licenciatura en la Facultad de Ciencias de la Educación de la Universidad Autónoma de Tlaxcala. Monserrat Acevedo Alvarado, Omar Habib Martínez Lira, Alejandro Juárez Hernández',
          },
          {
            'id': 119,
            'horaInicio': '15:50',
            'horaFin': '16:10',
            'fecha': '2023-11-29',
            'nombre':
                'Competencias investigativas en los docentes normalistas. José Ponce Magno',
          },
          {
            'id': 120,
            'horaInicio': '16:10',
            'horaFin': '16:30',
            'fecha': '2023-11-29',
            'nombre':
                'Los docentes universitarios de educación ¿qué leen y dónde buscan información?. Miguel Ortiz Ortiz',
          },
          {
            'id': 121,
            'horaInicio': '17:00',
            'horaFin': '17:15',
            'fecha': '2023-11-29',
            'nombre':
                'Conciencia histórica y microhistoria ejes de la Nueva Escuela Mexicana para la formación de profesores de Historia de México. Jorge Arturo Vásquez Mora',
          },
          {
            'id': 122,
            'horaInicio': '17:15',
            'horaFin': '17:30',
            'fecha': '2023-11-29',
            'nombre':
                'El uso de las TIC como herramienta principal en la Educación a Distancia. Araceli Ramos Hernández',
          },
          {
            'id': 123,
            'horaInicio': '17:30',
            'horaFin': '17:45',
            'fecha': '2023-11-29',
            'nombre':
                'Educación matemática crítica y transformación social una alternativa para la formación docente. Saúl Elizarrarás Baena, Orlando Vázquez Pérez, José Luis Medardo Quiroz Gleason',
          },
          {
            'id': 124,
            'horaInicio': '11:00',
            'horaFin': '11:15',
            'fecha': '2023-11-30',
            'nombre':
                'El uso de la metodología STEAM para desarrollar el pensamiento crítico de los alumnos de Telesecundaria. Jesús Orlando Castañeda Dávila',
          },
          {
            'id': 125,
            'horaInicio': '11:15',
            'horaFin': '11:30',
            'fecha': '2023-11-30',
            'nombre':
                'Años de Educación Ambiental en el CECyTE 19 Totolac. Pedro Ramos Carvajal',
          },
          {
            'id': 126,
            'horaInicio': '11:30',
            'horaFin': '11:45',
            'fecha': '2023-11-30',
            'nombre':
                'Promoción de prácticas para la sensibilización ambiental y desarrollo sostenible en contextos escolares. Oliva Pérez Mendoza',
          },
          {
            'id': 127,
            'horaInicio': '11:45',
            'horaFin': '12:00',
            'fecha': '2023-11-30',
            'nombre':
                'WhatsApp como herramienta mediadora del aprendizaje en estudiantes del CECyTE Tlaxcala. Cinthia Quiroz Animas',
          },
          {
            'id': 128,
            'horaInicio': '12:30',
            'horaFin': '12:45',
            'fecha': '2023-11-30',
            'nombre':
                'La formación inicial docente intercultural plurilingüe y comunitaria. Plan de Estudio, el principio de ruptura epistémica. Juan José Lecona González',
          },
          {
            'id': 129,
            'horaInicio': '12:45',
            'horaFin': '13:00',
            'fecha': '2023-11-30',
            'nombre':
                'La multidimensionalidad del aprendizaje explorando nuevas perspectivas educativas en la era de la interculturalidad. Rogelio Monreal Moreno',
          },
          {
            'id': 130,
            'horaInicio': '13:00',
            'horaFin': '13:15',
            'fecha': '2023-11-30',
            'nombre':
                'La explicación de la interdisciplinariedad dentro de los Libros de Texto Gratuitos a través de la epistemología. Cecilia Medrano Martínez',
          },
          {
            'id': 131,
            'horaInicio': '13:15',
            'horaFin': '13:30',
            'fecha': '2023-11-30',
            'nombre':
                'Fomento a la lectura en el Estado de Tlaxcala en Educación Básica. Pavel Lima Rodríguez',
          },
          {
            'id': 132,
            'horaInicio': '14:00',
            'horaFin': '14:15',
            'fecha': '2023-11-30',
            'nombre':
                'La evaluación formativa y los estándares de evaluación en estudiantes de Educación Normal Primaria. Reporte parcial de investigación. José Ponce Magno',
          },
          {
            'id': 133,
            'horaInicio': '14:15',
            'horaFin': '14:30',
            'fecha': '2023-11-30',
            'nombre':
                'Evaluación socioformativa en el proceso de aprendizaje de lengua materna, Español ll, caso de estudio en el turno matutino de la Esc. Sec. Gral. Ignacio Manuel Altamirano. Elizabeth Mogollán Cisneros',
          },
          {
            'id': 134,
            'horaInicio': '14:30',
            'horaFin': '14:45',
            'fecha': '2023-11-30',
            'nombre':
                'Evaluación del trabajo colaborativo como habilidad blanda desde el aprendizaje actitudinal. Madeleine Cocoliztli Romano Omar, Habib Martínez, Lira Alejandro, Juárez Hernández',
          },
          {
            'id': 135,
            'horaInicio': '14:45',
            'horaFin': '15:00',
            'fecha': '2023-11-30',
            'nombre':
                'La planeación didáctica por proyectos interdisciplinarios con base en el enfoque del Plan de Estudio, Araceli Trejo Padilla, Alejandro Palma Suárez',
          },
          {
            'id': 136,
            'horaInicio': '15:30',
            'horaFin': '15:45',
            'fecha': '2023-11-30',
            'nombre':
                'El enfoque de la educación inclusiva y sus consecuencias. Arminda Morales Villeda',
          },
          {
            'id': 137,
            'horaInicio': '15:45',
            'horaFin': '16:00',
            'fecha': '2023-11-30',
            'nombre':
                'Cuáles son las implicaciones de la diversidad estudiantil desde la perspectiva de la inclusión el caso de la Licenciatura en Educación y tecnologías digitales de la UAM LERMA. Mitzi Danae Morales Montes, María Guadalupe López Sandova',
          },
          {
            'id': 138,
            'horaInicio': '16:00',
            'horaFin': '16:15',
            'fecha': '2023-11-30',
            'nombre':
                'El análisis de trayectorias académicas como herramienta para el desarrollo de estrategias para la inclusión en Educación Superior. María Guadalupe López Sandoval, Oscar Hernández Razo, Mitzi Danae Morales Montes',
          },
          {
            'id': 139,
            'horaInicio': '16:15',
            'horaFin': '16:30',
            'fecha': '2023-11-30',
            'nombre':
                'Educación para todos: fomento de la inclusión en la Educación Superior, Ismael Cortes Maldonado',
          },
          {
            'id': 140,
            'horaInicio': '17:00',
            'horaFin': '17:15',
            'fecha': '2023-11-30',
            'nombre':
                'Práctica docente y las TIC en Educación Media Superior, importancia del desarrollo de competencias digitales docentes caso CBTIS Huamantla, Tlaxcala. Jesús Adrián Peña Díaz',
          },
          {
            'id': 141,
            'horaInicio': '17:15',
            'horaFin': '17:30',
            'fecha': '2023-11-30',
            'nombre':
                'Propuesta de una estrategia didáctica que fomenta un aprendizaje autónomo en módulos técnicos profesionales en la Educación Media Superior (CONALEP). Gloria Patricia Sánchez Sánchez',
          },
          {
            'id': 142,
            'horaInicio': '17:30',
            'horaFin': '17:45',
            'fecha': '2023-11-30',
            'nombre':
                'Investigación y desarrollo tecnológico como una estrategia para disminuir la deserción escolar y formar recursos humanos de alta calidad. José Vicente Cervantes Mejía',
          },
          {
            'id': 143,
            'horaInicio': '17:45',
            'horaFin': '18:00',
            'fecha': '2023-11-30',
            'nombre':
                'Las becas federales en el bienestar de los estudiantes de los CBTAS en el Estado de Tlaxcala, México. Elia Jaimes Hernández',
          },
        ],
        11: [
          {
            'id': 186,
            'horaInicio': '11:00',
            'horaFin': '15:00',
            'fecha': '2023-11-29',
            'nombre':
                'La formación docente en Educación Básica. El caso del Estado de Tlaxcala. Andrea Flores Valtierra Adriana Carro Olvera.',
          },
          {
            'id': 187,
            'horaInicio': '11:15',
            'horaFin': '11:30',
            'fecha': '2023-11-29',
            'nombre':
                'La organización escolar de primaria. Una caracterización de su diseño institucional y un acercamiento a su operación e impactos. Araceli Vázquez Fuentes',
          },
          {
            'id': 188,
            'horaInicio': '11:30',
            'horaFin': '11:45',
            'fecha': '2023-11-29',
            'nombre':
                'Aceptar la complejidad de los problemas educativos nos acerca a soluciones efectivas. Vicente Leopoldo, Avendaño Fernández Eliseo Carro Juárez.',
          },
          {
            'id': 189,
            'horaInicio': '11:45',
            'horaFin': '12:00',
            'fecha': '2023-11-29',
            'nombre':
                'El estrés y la labor docente. Salud emocional del docente para brindar entornos de aprendizaje de excelencia. Luis Fernando Torrentera Sánchez.',
          },
          {
            'id': 191,
            'horaInicio': '12:45',
            'horaFin': '13:00',
            'fecha': '2023-11-29',
            'nombre':
                'Sistemas educativos: trayectoria y futuro holográfico. Francisco Gómez Muño, Margarita Pérez Camarillo',
          },
          {
            'id': 192,
            'horaInicio': '13:00',
            'horaFin': '13:15',
            'fecha': '2023-11-29',
            'nombre':
                'Transformar a un niño en un ciudadano. Martha Ester Gonzalez Lira',
          },
          {
            'id': 193,
            'horaInicio': '14:00',
            'horaFin': '14:15',
            'fecha': '2023-11-29',
            'nombre':
                'Las emociones y su importancia en el proceso de aprendizaje. Estudio de caso en la Escuela Primaria Paz Díaz Monfil de Panzacola Tlaxcala. Yuvelin Muñoz Vázquez.',
          },
          {
            'id': 194,
            'horaInicio': '14:15',
            'horaFin': '14:30',
            'fecha': '2023-11-29',
            'nombre':
                'La comunicación asertiva, efectiva y afectiva en el aprendizaje sociocultura. Rolando Morales Meneses.',
          },
          {
            'id': 195,
            'horaInicio': '14:30',
            'horaFin': '14:45',
            'fecha': '2023-11-29',
            'nombre':
                'Construyendo puentes de autoestima, clave para una Cultura de Paz en el aula. Eber Medina Flores',
          },
          {
            'id': 196,
            'horaInicio': '14:45',
            'horaFin': '15:00',
            'fecha': '2023-11-29',
            'nombre':
                'La banda de guerra una propuesta extra curricular en la Nueva Escuela Mexicana como una actividad promotora de la Cultura de Paz en Educación Básica. José Ramiro Rojas Cuamatzi',
          },
          {
            'id': 197,
            'horaInicio': '15:30',
            'horaFin': '15:45',
            'fecha': '2023-11-29',
            'nombre':
                'La enseñanza de la geometría en la formación docente inicial inscrita en el Plan y Programas de Estudio 2022. Orlando Vázquez Pérez, Saul Elizarrarás Baena',
          },
          {
            'id': 198,
            'horaInicio': '15:45',
            'horaFin': '16:00',
            'fecha': '2023-11-29',
            'nombre': 'Humanismo tangible. Mariana López Castañeda',
          },
          {
            'id': 199,
            'horaInicio': '16:00',
            'horaFin': '16:15',
            'fecha': '2023-11-29',
            'nombre':
                'La Educación Superior y la investigación: oportunidades. Jacobo Tolamatl Michcol, José Antonio Varela Loyola',
          },
          {
            'id': 200,
            'horaInicio': '16:15',
            'horaFin': '16:30',
            'fecha': '2023-11-29',
            'nombre':
                'Ensamblando un Modelo de Formación Dual para la Universidad Tecnológica de Tlaxcala. Pablo Sánchez López, José Luis Hernández Corona.',
          },
          {
            'id': 201,
            'horaInicio': '17:00',
            'horaFin': '17:15',
            'fecha': '2023-11-29',
            'nombre':
                'Educación Física y deporte escolar en primarias. Joaquín Checa Sánchez',
          },
          {
            'id': 202,
            'horaInicio': '17:15',
            'horaFin': '17:30',
            'fecha': '2023-11-29',
            'nombre':
                'Diseño y construcción de estanques para la práctica de acuacultura en la producción de peces a nivel piloto. Edith Oropeza Villalobos',
          },
          {
            'id': 203,
            'horaInicio': '17:30',
            'horaFin': '17:45',
            'fecha': '2023-11-29',
            'nombre': 'Vinculando y pescando ando. Efraín Briones Pérez',
          },
          {
            'id': 204,
            'horaInicio': '17:45',
            'horaFin': '18:00',
            'fecha': '2023-11-29',
            'nombre':
                'Intervención escolar para prevenir el consumo de alcohol en estudiantes del CECyTE 19 de Totolac, Tlaxcala. Raúl Barba Pérez, Florencia Durán Zambrano',
          },
          {
            'id': 220,
            'horaInicio': '11:00',
            'horaFin': '11:20',
            'fecha': '2023-11-30',
            'nombre':
                'La familia del alumno como el primer con- tacto de la escuela con la comunidad. Juan Ubaldo Cua- pio Bautista',
          },
          {
            'id': 221,
            'horaInicio': '11:20',
            'horaFin': '11:40',
            'fecha': '2023-11-30',
            'nombre':
                'La influencia de las tareas de enseñanza en las actitudes de los estudiantes. Rolando Castillo Filomeno',
          },
          {
            'id': 222,
            'horaInicio': '12:30',
            'horaFin': '12:45',
            'fecha': '2023-11-30',
            'nombre':
                'La función de las teorías implícitas en el desarrollo de los Consejos Técnicos Escolares. Roxana Cabrera Sampayo',
          },
          {
            'id': 223,
            'horaInicio': '12:45',
            'horaFin': '13:00',
            'fecha': '2023-11-30',
            'nombre':
                'Organización y funcionamiento de los Consejos Técnicos Escolares durante la pandemia por Covid-19. El caso de Tlaxcala, México. Roxana Cabrera Sampayo, Adriana Carro Olvera',
          },
          {
            'id': 224,
            'horaInicio': '13:00',
            'horaFin': '13:15',
            'fecha': '2023-11-30',
            'nombre':
                'La implementación del Consejo Técnico Escolar en una zona escolar de nivel primaria en Tlaxcala. Ángel Iván Ramírez Juárez',
          },
          {
            'id': 225,
            'horaInicio': '13:15',
            'horaFin': '13:30',
            'fecha': '2023-11-30',
            'nombre':
                'Liderazgo pedagógico de la función di- rectiva para el funcionamiento de los Consejos Técnicos Escolares. Emmanuel del Ángel Moyano, Ana Bertha Luna Miranda',
          },
          {
            'id': 226,
            'horaInicio': '14:00',
            'horaFin': '14:20',
            'fecha': '2023-11-30',
            'nombre':
                'Domótica e IA para el aprendizaje en la NEM. Crystian Meza Flores',
          },
          {
            'id': 227,
            'horaInicio': '14:20',
            'horaFin': '14:40',
            'fecha': '2023-11-30',
            'nombre':
                'Cómo desarrollar proyectos STEM de Inteligencia Artificial. Julio Cesar Valdez Ahuatzi',
          },
          {
            'id': 228,
            'horaInicio': '14:40',
            'horaFin': '15:00',
            'fecha': '2023-11-30',
            'nombre':
                'La Inteligencia Artificial: una herramienta para el futuro. Uriel Juárez Zainos',
          },
          {
            'id': 229,
            'horaInicio': '15:30',
            'horaFin': '15:45',
            'fecha': '2023-11-30',
            'nombre':
                'Cómo viven y cómo enfrentan la violencia escolar. Ariadne Vázquez López',
          },
          {
            'id': 230,
            'horaInicio': '15:45',
            'horaFin': '16:00',
            'fecha': '2023-11-30',
            'nombre':
                'La afectividad en el proceso de enseñanza aprendizaje. José Gabriel Montes Sosa',
          },
          {
            'id': 231,
            'horaInicio': '16:00',
            'horaFin': '16:15',
            'fecha': '2023-11-30',
            'nombre': 'Violencia escolar. Eduardo Chávez Palma',
          },
          {
            'id': 232,
            'horaInicio': '16:15',
            'horaFin': '16:30',
            'fecha': '2023-11-30',
            'nombre':
                'Espacios socioemocionales en la tutoría académica para la disminución de la deserción escolar en los estudiantes tlaxcaltecas de nuevo ingreso a la Educación Media Superior. Roberto Castillo Vega',
          },
          {
            'id': 233,
            'horaInicio': '17:00',
            'horaFin': '17:15',
            'fecha': '2023-11-30',
            'nombre':
                'Proyectos comunitarios socioformativos. Estrategia didáctica para el fortalecimien- to de la práctica profesional en Educación Normal. José Manuel Vázquez Antonio, Jennifer Vázquez Antonio, Itzel Ponce López',
          },
          {
            'id': 234,
            'horaInicio': '17:15',
            'horaFin': '17:30',
            'fecha': '2023-11-30',
            'nombre':
                'Proyectos artísticos interdisciplinarios. Ma de Los Ángeles Moreno Carvajal',
          },
          {
            'id': 235,
            'horaInicio': '17:30',
            'horaFin': '17:45',
            'fecha': '2023-11-30',
            'nombre':
                'Diseño y construcción de estanques para la práctica de acuacultura en la producción de peces a nivel piloto. Edith Oropeza Villalobos',
          },
          {
            'id': 236,
            'horaInicio': '17:45',
            'horaFin': '18:00',
            'fecha': '2023-11-30',
            'nombre':
                'La práctica y planificación pedagógica para la formación situada. Jaffet Abelardo Moreno García',
          },
          {
            'id': 237,
            'horaInicio': '11:00',
            'horaFin': '11:15',
            'fecha': '2023-11-30',
            'nombre': 'Robots en realidad mixta. Max Gheraldo Pérez Mendoza',
          },
          {
            'id': 238,
            'horaInicio': '11:15',
            'horaFin': '11:30',
            'fecha': '2023-11-30',
            'nombre':
                '10 años de la Educación Ambiental en el CECyTE 19 Totolac. Pedro Ramos Carvajal',
          },
          {
            'id': 239,
            'horaInicio': '11:30',
            'horaFin': '11:45',
            'fecha': '2023-11-30',
            'nombre': 'La educación que necesitamos. Sergio Oropeza Hernández',
          },
          {
            'id': 240,
            'horaInicio': '11:45',
            'horaFin': '12:00',
            'fecha': '2023-11-30',
            'nombre':
                'La planeación didáctica y su vínculo con las matemáticas. Luis Alberto Hernández Águila',
          },
          {
            'id': 241,
            'horaInicio': '12:00',
            'horaFin': '12:15',
            'fecha': '2023-11-30',
            'nombre': 'Leer en Tiktok. Ana María Pérez Olvera',
          },
          {
            'id': 242,
            'horaInicio': '12:30',
            'horaFin': '12:45',
            'fecha': '2023-11-30',
            'nombre':
                'El arte para fomentar una Cultura de Paz. Karen Barranco',
          },
          {
            'id': 243,
            'horaInicio': '12:45',
            'horaFin': '13:00',
            'fecha': '2023-11-30',
            'nombre':
                'Reproducción de discursos excluyentes, que generan ambientes de violencia es- colar. Guillermo Varela Báez',
          },
          {
            'id': 244,
            'horaInicio': '13:00',
            'horaFin': '13:15',
            'fecha': '2023-11-30',
            'nombre': 'Liderazgo y gestión educativa. Silvia Verónica Paul',
          },
          {
            'id': 245,
            'horaInicio': '13:15',
            'horaFin': '13:30',
            'fecha': '2023-11-30',
            'nombre':
                'Perspectivas ante el acoso y la violencia escolar. Karla María Márquez Arroyo',
          },
          {
            'id': 246,
            'horaInicio': '13:30',
            'horaFin': '13:45',
            'fecha': '2023-11-30',
            'nombre':
                'Liderazgo y gestión educativa. José Ricardo Raymundo Fernández Delgadillo',
          },
        ],
        12: [
          {
            'id': 283,
            'horaInicio': '11:50',
            'horaFin': '12:20',
            'fecha': '2023-11-29',
            'nombre':
                'El papel del docente binacional en el marco de la Nueva Escuela Mexicana. Norma Vianey Tizapán Mendoza, Kenia Flores García Christry Corona Durán',
          },
          {
            'id': 284,
            'horaInicio': '13:10',
            'horaFin': '13:50',
            'fecha': '2023-11-29',
            'nombre':
                'Prevención de la trata de personas en las escuelas de Tlaxcala. Jesús Juárez Reyes, Marisol Flores García, Rene López Pérez, María Guadalupe Cervantes Cervantes',
          },
          {
            'id': 285,
            'horaInicio': '14:40',
            'horaFin': '15:10',
            'fecha': '2023-11-29',
            'nombre':
                'En busca de la dignificación docente. Ernesto Ramírez Vicente, Laura Susana Acosta Pérez, Darney Mendoza Morales',
          },
          {
            'id': 286,
            'horaInicio': '16:30',
            'horaFin': '17:10',
            'fecha': '2023-11-29',
            'nombre':
                'Las maestras de Educación Básica en Tlaxcala México. Su trayectoria frente a las desigualdades de género. Rosabel Juárez Barradas, Leticia Romo Hernández, Ana Esther Torres Flores',
          },
        ],
        13: [
          {
            'id': 144,
            'horaInicio': '11:00',
            'horaFin': '11:20',
            'fecha': '2023-11-29',
            'nombre':
                'Huella hídrica y ecológica en nuestro entorno. Gisela Vásquez Vásquez',
          },
          {
            'id': 145,
            'horaInicio': '11:30',
            'horaFin': '11:50',
            'fecha': '2023-11-29',
            'nombre':
                'La indagación estrategia para el desarrollo de habilidades científicas. Maribel Macias Olmos',
          },
          {
            'id': 146,
            'horaInicio': '12:00',
            'horaFin': '12:20',
            'fecha': '2023-11-29',
            'nombre':
                'Conocimientos previos y autoaprendizaje de las matemáticas usando las TIC en el CBTA 134 (automáticas). Francisca Dolores Matlalcuatzi Rugerio',
          },
          {
            'id': 147,
            'horaInicio': '12:30',
            'horaFin': '12:50',
            'fecha': '2023-11-29',
            'nombre':
                'Estrategias didácticas para la Educación ambiental y desarrollo sostenible ante el fenómeno de cambio climático en el CBT 6/16 Benito Juárez de la comunidad de San Simón Tlatlauquitepec, Tlax. Carolina Netzahuatl Muñoz',
          },
          {
            'id': 148,
            'horaInicio': '13:00',
            'horaFin': '13:20',
            'fecha': '2023-11-29',
            'nombre': 'Tradiciones lenguajes y ética. Gregoria García Nava',
          },
          {
            'id': 149,
            'horaInicio': '13:30',
            'horaFin': '13:50',
            'fecha': '2023-11-29',
            'nombre':
                'Aprendizaje móvil (M-LEARNING) y aplicaciones digitales como herramientas técnicas en el aprendizaje del idioma inglés. Fernando Olvera Romero',
          },
          {
            'id': 150,
            'horaInicio': '14:00',
            'horaFin': '14:20',
            'fecha': '2023-11-29',
            'nombre':
                'Una percepción sobre aprendizajes por proyectos relacionando las matemáticas y las problemáticas sociales. María Elena Vargas Martínez',
          },
          {
            'id': 151,
            'horaInicio': '14:30',
            'horaFin': '14:50',
            'fecha': '2023-11-29',
            'nombre': 'Programa de PEER TUTORING. María Griselda Maza Diaz',
          },
          {
            'id': 152,
            'horaInicio': '15:00',
            'horaFin': '15:20',
            'fecha': '2023-11-29',
            'nombre':
                'Educación Dual CONALEP, Tlaxcala. Luis Girón Soriano, Olga Leslie Vega Terrazas, Elisabeth Fernández de Lara Xochihua',
          },
          {
            'id': 153,
            'horaInicio': '15:30',
            'horaFin': '15:50',
            'fecha': '2023-11-29',
            'nombre': 'Humanismo tangible. Mariana López Castañeda',
          },
          {
            'id': 154,
            'horaInicio': '16:00',
            'horaFin': '16:20',
            'fecha': '2023-11-29',
            'nombre': 'Ajedrez. Anallely Rocha Ramírez',
          },
          {
            'id': 155,
            'horaInicio': '11:00',
            'horaFin': '11:20',
            'fecha': '2023-11-30',
            'nombre':
                'Estrategia de fortalecimiento académico como experiencia significativa para el desarrollo del aprendizaje autónomo en los estudiantes del CECyTEC 10 Yauhquemecan. Patricia Alejandra González Ramos',
          },
          {
            'id': 156,
            'horaInicio': '11:30',
            'horaFin': '11:50',
            'fecha': '2023-11-30',
            'nombre':
                'Atender la educación socioemocional a través de obras pictóricas. Claudia Yohualli Morales Martínez',
          },
          {
            'id': 157,
            'horaInicio': '12:00',
            'horaFin': '12:20',
            'fecha': '2023-11-30',
            'nombre':
                'Un proyecto de vida desde la escuela. María Esperanza López Domínguez',
          },
          {
            'id': 158,
            'horaInicio': '12:30',
            'horaFin': '12:50',
            'fecha': '2023-11-30',
            'nombre':
                'Las emociones en el proceso formativo. Alejandro González Juárez',
          },
          {
            'id': 159,
            'horaInicio': '13:00',
            'horaFin': '13:20',
            'fecha': '2023-11-30',
            'nombre':
                'Violencia de género desde la densidad de la materia. Bertín Papacetzi Guerrero',
          },
          {
            'id': 160,
            'horaInicio': '13:30',
            'horaFin': '13:50',
            'fecha': '2023-11-30',
            'nombre': 'Caminos en la educación. Araceli Ramos Hernández',
          },
          {
            'id': 161,
            'horaInicio': '14:00',
            'horaFin': '14:20',
            'fecha': '2023-11-30',
            'nombre':
                'Los nuevos Libros de Texto Gratuito y su uso en el aula. Irma Vázquez Guerrero',
          },
          {
            'id': 162,
            'horaInicio': '14:30',
            'horaFin': '14:50',
            'fecha': '2023-11-30',
            'nombre':
                'Conociendo a una mujer Huamantla. Erika Yamal Torres Pérez',
          },
          {
            'id': 163,
            'horaInicio': '15:00',
            'horaFin': '15:20',
            'fecha': '2023-11-30',
            'nombre':
                'Mi experiencia como innovadora. Nidia Lizeth Hernández Vázquez',
          },
          {
            'id': 164,
            'horaInicio': '15:30',
            'horaFin': '15:50',
            'fecha': '2023-11-30',
            'nombre':
                'Informe final Aprendizajes Clave para la educación integral. Plan y Programas de Estudio para la Educación Básica. Alejandro Cruz Carro',
          },
        ],
        14: [
          {
            'id': 205,
            'horaInicio': '11:00',
            'horaFin': '12:00',
            'fecha': '2023-11-29',
            'nombre':
                'Enseñanza lúdica de las ciencias. Víctor Manuel Xicohténcatl Ahuactzi',
          },
          {
            'id': 206,
            'horaInicio': '12:00',
            'horaFin': '13:00',
            'fecha': '2023-11-29',
            'nombre':
                'Los otros algoritmos para las operaciones básicas. Sergio Bello Vázquez',
          },
          {
            'id': 207,
            'horaInicio': '13:00',
            'horaFin': '14:00',
            'fecha': '2023-11-29',
            'nombre':
                'Material estructurado y no estructurado para la enseñanza de las fracciones. Sergio Bello Vázquez',
          },
          {
            'id': 208,
            'horaInicio': '14:00',
            'horaFin': '15:00',
            'fecha': '2023-11-29',
            'nombre':
                'Uso de herramientas de Inteligencia Artificial en la enseñanza con enfoque STEM. Ivette Hernández, Dávila Marco Antonio Morales Caporal.',
          },
          {
            'id': 209,
            'horaInicio': '15:00',
            'horaFin': '16:00',
            'fecha': '2023-11-29',
            'nombre':
                'Secuencias y estrategias didácticas a través de la Inteligencia Artificial. Javier Huerta Huerta',
          },
          {
            'id': 210,
            'horaInicio': '16:00',
            'horaFin': '17:00',
            'fecha': '2023-11-29',
            'nombre':
                'Produce y elabora tus propios alimentos. María Elena Castro Arvizu',
          },
          {
            'id': 257,
            'horaInicio': '12:00',
            'horaFin': '13:00',
            'fecha': '2023-11-30',
            'nombre':
                'Patios de recreo, un espacio para promover la Cultura de Paz. María Esperanza López Domínguez',
          },
          {
            'id': 258,
            'horaInicio': '13:00',
            'horaFin': '14:00',
            'fecha': '2023-11-30',
            'nombre':
                'Comunicación y reflexión en círculos KAI fomentando la colaboración grupal. Francisca Guadalupe Barajas García, Jesús Orlando Castañeda Dávila',
          },
          {
            'id': 259,
            'horaInicio': '14:00',
            'horaFin': '15:00',
            'fecha': '2023-11-30',
            'nombre': 'Libertad emocional. Alfonso Morales Onofre',
          },
          {
            'id': 260,
            'horaInicio': '12:00',
            'horaFin': '12:30',
            'fecha': '2023-11-29',
            'nombre':
                'Artes NEM ABP. Nathaly Varela Baltierra, Guillermo Varela Báez',
          },
          {
            'id': 261,
            'horaInicio': '12:30',
            'horaFin': '13:00',
            'fecha': '2023-11-29',
            'nombre':
                'Wikieducación prácticas y experiencias educativas de México con Wikipedia y otros recursos abiertos. Esteban García López, Marybeth Flores Vázquez',
          },
          {
            'id': 262,
            'horaInicio': '13:00',
            'horaFin': '13:30',
            'fecha': '2023-11-29',
            'nombre':
                'Educación, violencia y género. Una mirada a la experiencia desde la convivencia en las escuelas. Melisa Padilla Pluma, Aurelia Flores Hernández',
          },
          {
            'id': 263,
            'horaInicio': '13:30',
            'horaFin': '14:00',
            'fecha': '2023-11-29',
            'nombre':
                'Investigación e innovación educativa. Perspectivas y prácticas docentes. Rosa Angélica Pliego Morales, Pascuala Avendaño Báez',
          },
          {
            'id': 264,
            'horaInicio': '12:00',
            'horaFin': '12:30',
            'fecha': '2023-11-30',
            'nombre':
                'La escuela holográfica. Miguel Ortiz Ortiz, Ángel Iván Ramírez Juárez',
          },
          {
            'id': 265,
            'horaInicio': '12:30',
            'horaFin': '13:00',
            'fecha': '2023-11-30',
            'nombre':
                'Tlaxcala. Nuestro Patrimonio Cultural. Adriana Atonal González, Elizabeth Méndez León',
          },
          {
            'id': 266,
            'horaInicio': '13:00',
            'horaFin': '13:30',
            'fecha': '2023-11-30',
            'nombre':
                'Lienzo de Tlaxcala. Guillermo Andrey Jiménez Torres, Carolina Patricia Hernández Reyes',
          },
          {
            'id': 267,
            'horaInicio': '13:30',
            'horaFin': '14:00',
            'fecha': '2023-11-30',
            'nombre':
                'Tequezquital. Óscar David Toribio López, Ana Lilia Durán Nieto',
          },
        ],
        16: [
          {
            'id': 272,
            'horaInicio': '09:00',
            'horaFin': '10:15',
            'fecha': '2023-11-29',
            'nombre':
                'Modelo de gestión social y cambio climático en la región centro de México, factores estructurales para mitigar el cambio climático: Horizonte 2050. Dr. Sergio Flores, Dra. Montserrat Miquel Hernández, Dr. José Luis Carmona',
          },
          {
            'id': 273,
            'horaInicio': '10:15',
            'horaFin': '11:15',
            'fecha': '2023-11-29',
            'nombre':
                'Marco para la buena dirección y el liderazgo escolar. Dr. Mario Uribe Briceño',
          },
          {
            'id': 274,
            'horaInicio': '11:15',
            'horaFin': '12:15',
            'fecha': '2023-11-29',
            'nombre':
                'Transformar diálogos de saberes en diálogos de haceres. Ciencia, comunidad y políticas públicas. Dr. Horacio Bozzano',
          },
          {
            'id': 275,
            'horaInicio': '14:15',
            'horaFin': '15:15',
            'fecha': '2023-11-29',
            'nombre':
                'Aproximaciones antropoló- gicas a la diversidad biocul- tural de Tlaxcala. Milton Hernández García, Jorge Guevara Hernández y Nazario Sánchez Mastranzo (INAH)',
          },
          {
            'id': 276,
            'horaInicio': '15:15',
            'horaFin': '14:15',
            'fecha': '2023-11-29',
            'nombre':
                'Campo social y regional en el contexto de la migración transnacional. Dr. José Dionicio Vázquez Vázquez',
          },
          {
            'id': 277,
            'horaInicio': '12:15',
            'horaFin': '13:15',
            'fecha': '2023-11-29',
            'nombre':
                'Democracia y participa ción de la niñez y juventud. Mtra. Elizabeth Piedras Martínez',
          },
          {
            'id': 278,
            'horaInicio': '13:15',
            'horaFin': '14:15',
            'fecha': '2023-11-29',
            'nombre':
                'Las emociones transpor tan aprendizajes. Dra. Flora Cahuantzi  Vázquez',
          },
          {
            'id': 279,
            'horaInicio': '16:15',
            'horaFin': '17:15',
            'fecha': '2023-11-29',
            'nombre':
                'Cortometraje Corporati vo Hueyotlipan. Miguel Benavides Independiente',
          },
          {
            'id': 280,
            'horaInicio': '17:15',
            'horaFin': '18:15',
            'fecha': '2023-11-29',
            'nombre': 'El maravilloso mundo del ajedrez. José Luis Pérez',
          },
          {
            'id': 292,
            'horaInicio': '08:10',
            'horaFin': '08:20',
            'fecha': '2023-11-29',
            'nombre':
                'Organización de los equipos de trabajo para los talleres y distribución de materiales.',
          },
          {
            'id': 293,
            'horaInicio': '08:30',
            'horaFin': '10:30',
            'fecha': '2023-11-29',
            'nombre': 'Elaboración de bordados y piñatas',
          },
          {
            'id': 294,
            'horaInicio': '11:00',
            'horaFin': '13:00',
            'fecha': '2023-11-29',
            'nombre': 'Seguimiento de las actividades de los talleres',
          },
        ],
      };

      int staticSedeId = sedeId as int;
      if (staticEventsBySede.containsKey(staticSedeId)) {
        List<Map<String, dynamic>> staticEvents =
            staticEventsBySede[staticSedeId]!;
        TimeOfDay now = TimeOfDay.now();
        print(now);

        DateTime nowDateTime = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          now.hour,
          now.minute,
        );

        List<Map<String, dynamic>> filteredEvents = staticEvents.where((event) {
          DateTime horaInicio = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            int.parse(event['horaInicio'].split(':')[0]),
            int.parse(event['horaInicio'].split(':')[1]),
          );

          DateTime horaFin = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            int.parse(event['horaFin'].split(':')[0]),
            int.parse(event['horaFin'].split(':')[1]),
          );

          print(horaInicio);
          print(horaFin);

          return nowDateTime.isAfter(horaInicio) &&
              nowDateTime.isBefore(horaFin);
        }).toList();

        setState(() {
          eventos = filteredEvents;
        });

        print('Eventos: $eventos');
      } else {
        print('ID de la sede no coincide con ningún evento');
      }
    } catch (error) {
      print('Error fetching eventos: $error');
    }
  }

  Future<void> _openQRScanner(BuildContext context) async {
    print('User ID al abrir el lector QR: $userId');
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => QRViewExample(
        onQRScanned: (content) {
          setState(() {
            qrContent = content;
          });
        },
        selectedEventoId: selectedEventoId,
        userId: userId,
      ),
    ));
  }

  Future<void> _showDatabase(BuildContext context) async {
    final dbHelper = DatabaseHelper();
    final List<Map<String, dynamic>> events =
        await dbHelper.getAllEventAttendances();

    // Eliminar entradas duplicadas basadas en dtNumetAsistencia_id e ctNumetItinerario_id
    List<Map<String, dynamic>> uniqueEvents = [];
    Set<String> uniqueEntries = Set();

    for (var event in events) {
      String entryKey =
          '${event['dtNumetAsistencia_id']}_${event['ctNumetItinerario_id']}';

      if (!uniqueEntries.contains(entryKey)) {
        uniqueEntries.add(entryKey);
        uniqueEvents.add(event);
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Eventos Registrados en la Base de Datos'),
          content: SingleChildScrollView(
            child: Column(
              children: uniqueEvents.map((event) {
                return ListTile(
                  title: Text(
                      'Usuario registrado: ${event['dtNumetAsistencia_id']}'),
                  subtitle: Text(
                    'Evento: ${event['ctNumetItinerario_id']}\n'
                    'Usuario que registró: ${event['ctUsuarios_in']}\n'
                    'Fecha y hora de registro: ${event['fecha_in']}',
                  ),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () {
                _sendDataToServer(context, uniqueEvents);
                // Puedes optar por eliminar todas las entradas duplicadas localmente
                // o solo las que se enviarán al servidor (_sendDataToServer).
                // dbHelper.deleteAllEventAttendances();
              },
              child: Text('Enviar Datos'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteAllEventAttendances() async {
    Database db = await dbHelper.database;
    await db.delete('dtNumetEventoAsistencia');
  }

  Future<void> _sendDataToServer(
      BuildContext context, List<Map<String, dynamic>> events) async {
    print('Datos antes de enviar al servidor: $events');

    Map<String, dynamic> data = {'data': events};

    try {
      var response = await http.post(
        Uri.parse(
            'https://si-exactaa.septlaxcala.gob.mx/numet/subirBDlocal.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> result = json.decode(response.body);

        if (result['success'] == true) {
          print('Datos enviados al servidor con éxito');

          await dbHelper.deleteAllEventAttendances();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Datos enviados al servidor y eliminados localmente'),
            ),
          );
        } else {
          print(
              'Error al enviar datos al servidor. Mensaje: ${result['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Error al enviar datos al servidor. ${result['message']}'),
            ),
          );
        }
      } else {
        print(
            'Error al enviar datos al servidor. Código de estado: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar datos al servidor'),
          ),
        );
      }
    } catch (error) {
      print('Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Datos ya insertados en la base de datos'),
        ),
      );
      await dbHelper.deleteAllEventAttendances();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asistencia')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bgApp2.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Lugar',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton(
                      isExpanded: true,
                      value: selectedSede,
                      onChanged: (selectedValue) async {
                        setState(() {
                          selectedSede = selectedValue;
                        });

                        await fetchSedeDetails(selectedSede);
                        await fetchEventos(selectedSede);
                      },
                      items: sedes.map((sede) {
                        return DropdownMenuItem(
                          value: sede['id'],
                          child: Text(sede['nombre']),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Stand:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              selectedSedeDetails.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            ' ${selectedSedeDetails['stand']}',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(height: 20),
              Text(''),
              SizedBox(height: 20),
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Eventos',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton(
                      isExpanded: true,
                      value: selectedEvento,
                      onChanged: (selectedValue) {
                        setState(() {
                          selectedEvento = selectedValue;
                          selectedEventoId =
                              selectedEvento; // Guarda el ID del evento seleccionado
                        });
                      },
                      items: eventos.map((event) {
                        // Agrega estas líneas para obtener la fecha actual
                        DateTime now = DateTime.now();

                        // Agrega estas líneas para obtener la fecha del evento
                        DateTime fechaEvento = DateTime.parse(event['fecha']);

                        // Agrega esta línea para verificar si el evento es en el día actual
                        bool esDiaActual = fechaEvento.year == now.year &&
                            fechaEvento.month == now.month &&
                            fechaEvento.day == now.day;

                        return DropdownMenuItem(
                          value: event['id'],
                          child: Text(
                            event['nombre'],
                            style: TextStyle(
                              color: esDiaActual ? Colors.black : Colors.red,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _openQRScanner(context);
                },
                child: const Text('Abrir lector QR'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _showDatabase(context);
                },
                child: const Text('Mostrar Base de Datos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserIdSingleton {
  static int? _userId;

  static int? get userId => _userId;

  static setUserId(int id) {
    _userId = id;
  }
}

class DatabaseHelper {
  static Database? _database;
  String get formattedDate {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(
      DateTime.now().toUtc().subtract(Duration(hours: 6)),
    );
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'numet_database.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    print('Creating table dtNumetEventoAsistencia');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS dtNumetEventoAsistencia (
      dtNumetAsistencia_id INTEGER NOT NULL,
      ctNumetItinerario_id INTEGER NOT NULL,
      ctUsuarios_in INTEGER NOT NULL,
      fecha_in DATETIME NOT NULL DEFAULT (
        strftime('%Y-%m-%d %H:%M:%f', 'NOW', 'localtime', '-6 hours')
      )
    )
  ''');

    // Imprime los tipos de datos de cada columna
    var tableInfo =
        await db.rawQuery('PRAGMA table_info(dtNumetEventoAsistencia);');
    print('Column Types:');
    tableInfo.forEach((column) {
      print('${column['name']}: ${column['type']}');
    });
  }

  Future<void> insertEventAttendance(
      Map<String, dynamic> data, int userId) async {
    try {
      Database db = await database;

      print('Data before insertion: $data');

      await db.insert('dtNumetEventoAsistencia', {
        'dtNumetAsistencia_id': data['dtNumetAsistencia_id'],
        'ctNumetItinerario_id': data['ctNumetItinerario_id'],
        'ctUsuarios_in': userId,
        'fecha_in': formattedDate,
      });

      print('Data inserted successfully');

      print('ctUsuarios_in: $userId');
    } catch (e) {
      print('Error inserting data into the database: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllEventAttendances() async {
    Database db = await database;
    return await db.query('dtNumetEventoAsistencia');
  }

  Future<void> deleteAllEventAttendances() async {
    Database db = await database;
    await db.delete('dtNumetEventoAsistencia');
  }
}

class QRViewExample extends StatefulWidget {
  final Function(String) onQRScanned;
  final dynamic selectedEventoId;
  final int? userId;

  const QRViewExample({
    Key? key,
    required this.onQRScanned,
    required this.selectedEventoId,
    required this.userId,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final DatabaseHelper dbHelper = DatabaseHelper();

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  if (result != null)
                    Text(
                        'Bienvenido CNTLX23-00${result!.code} al evento ${widget.selectedEventoId}')
                  else
                    const Text('Contenido del qr'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                          onPressed: () async {
                            await controller?.pauseCamera();
                            setState(() {
                              isCameraPaused = true;
                            });
                          },
                          child: const Text('Pausar imagen',
                              style: TextStyle(fontSize: 20)),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                          onPressed: () async {
                            await controller?.resumeCamera();
                            setState(() {
                              isCameraPaused = false;
                            });
                          },
                          child: const Text('Play imagen',
                              style: TextStyle(fontSize: 20)),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Color(0xFFAA182C),
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  bool isCameraPaused =
      false; // Agregamos un nuevo estado para controlar si la cámara está pausada

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    controller.scannedDataStream.listen((scanData) async {
      setState(() {
        result = scanData;
        widget.onQRScanned(result?.code ?? '');
      });

      int userId = widget.userId ?? 0;
      String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(
        DateTime.now().toUtc().subtract(Duration(hours: 6)),
      );

      try {
        List<Map<String, dynamic>> existingEvents =
            await dbHelper.getAllEventAttendances();
        bool eventAlreadyExists = existingEvents.any((event) =>
            event['dtNumetAsistencia_id'] == result?.code &&
            event['ctNumetItinerario_id'] == widget.selectedEventoId &&
            event['ctUsuarios_in'] == userId &&
            event['fecha_in'] == formattedDate);

        if (!eventAlreadyExists) {
          await dbHelper.insertEventAttendance({
            'dtNumetAsistencia_id': result?.code ?? '',
            'ctNumetItinerario_id': widget.selectedEventoId,
            'ctUsuarios_in': userId,
            'fecha_in': formattedDate,
          }, widget.userId!);
        } else {
          print('La asistencia al evento ya existe en la base de datos local.');
        }
      } catch (e) {
        print('Error al insertar la asistencia al evento: $e');
      }

      if (isCameraPaused) {
        controller.resumeCamera(); // Si la cámara estaba pausada, la reanudamos
        setState(() {
          isCameraPaused = false;
        });
      }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

class LoginScreen extends StatefulWidget {
  final Function(int) onLogin;

  LoginScreen({Key? key, required this.onLogin}) : super(key: key);
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  int? userId;

  Future<void> _login(BuildContext context) async {
    if (userController.text.isEmpty || passwordController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Por favor, completa todos los campos",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 5,
        backgroundColor: Color(0xFFAA182C),
        textColor: Colors.white,
      );
      return;
    }

    var url =
        Uri.parse('https://si-exactaa.septlaxcala.gob.mx/numet/login.php');

    var data = {
      'user': userController.text,
      'pass': passwordController.text,
    };

    var response = await http.post(url, body: data);

    if (response.statusCode == 200) {
      var result = json.decode(response.body);
      if (result != null &&
          result['success'] != null &&
          result['user_id'] != null) {
        setState(() {
          userId = result['user_id'];
          print('User ID: $userId');
          widget.onLogin(userId!);

          // Almacena el estado de inicio de sesión y el ID de usuario en SharedPreferences
          _saveLoginState(userId!);
        });
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Fluttertoast.showToast(
          msg: "Contraseña o usuario incorrectos",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 5,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } else {
      print('Error: ${response.statusCode}');
    }
  }

  Future<void> _saveLoginState(int userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('user_id', userId);
    prefs.setBool('is_logged_in', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bgApp.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: 25.0),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Bienvenido",
                          style: TextStyle(
                            fontSize: 28.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15.0),
                    TextField(
                      controller: userController,
                      decoration: InputDecoration(
                        hintText: "Usuario",
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20.0),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Contraseña",
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 32.0),
                    ElevatedButton(
                      onPressed: () => _login(context),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: Color(0xFF572772),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          constraints: BoxConstraints(
                            maxWidth: double.infinity,
                            minHeight: 50.0,
                          ),
                          child: Text(
                            "Iniciar sesión",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
