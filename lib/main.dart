import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  runApp(const LinkPeruApp());
}

class LinkPeruApp extends StatelessWidget {
  const LinkPeruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LinkPerú',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    });

    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0172B2), Color(0xFF001645)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Contenido principal centrado
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', height: 120),
                const SizedBox(height: 20),
                const Text(
                  "LinkPerú",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Texto e imagen en la esquina inferior derecha
          Positioned(
            bottom: 20,
            right: 20,
            child: Row(
              children: [
                const Text(
                  "Desarrollado por Jandup",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset(
                  'assets/jandup.png', // Ruta de tu imagen
                  height: 24, // Tamaño de la imagen
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum DataState { loading, success, error }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DataState dataState = DataState.loading;
  List<dynamic> buttons = [];

  @override
  void initState() {
    super.initState();
    fetchButtons();
  }

  Future<void> fetchButtons() async {
    try {
      final response = await http.get(
        Uri.parse('https://linkperu.jandup.com/getDetailBotton'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final validButtons = data.where((button) {
            return button.containsKey('imagen') &&
                button.containsKey('nombre') &&
                button.containsKey('link');
          }).toList();

          setState(() {
            buttons = validButtons;
            dataState = DataState.success;
          });
        } else {
          setState(() {
            dataState = DataState.error;
          });
          print("El API no devolvió datos válidos.");
        }
      } else {
        setState(() {
          dataState = DataState.error;
        });
        print('Error al obtener los datos: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        dataState = DataState.error;
      });
      print('Error al conectar con el backend: $e');
    }
  }

  Widget _buildButtonCard(dynamic button) {
    final String? imageUrl = button['imagen'];
    final String? name = button['nombre'];
    final String? link = button['link'];

    if (imageUrl == null || name == null || link == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WebViewPage(url: link)),
      ),
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LinkPerú',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0172B2),
      ),
      body: Builder(
        builder: (context) {
          if (dataState == DataState.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (dataState == DataState.error) {
            return const Center(
              child: Text(
                'Ocurrió un error al cargar los datos.',
                style: TextStyle(color: Colors.red),
              ),
            );
          } else {
            return buttons.isEmpty
                ? const Center(
                    child: Text('No se encontraron servicios disponibles.'),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                    ),
                    itemCount: buttons.length,
                    itemBuilder: (context, index) =>
                        _buildButtonCard(buttons[index]),
                  );
          }
        },
      ),
    );
  }
}

class WebViewPage extends StatefulWidget {
  final String url;

  const WebViewPage({super.key, required this.url});

  @override
  // ignore: library_private_types_in_public_api
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late InAppWebViewController webViewController;

  String formatUrl(String url) {
    Uri uri = Uri.parse(url);

    // Validaciones específicas para dominios
    if (uri.host.contains("minedu.gob.pe")) {
      // Añadir parámetros requeridos para el dominio de MINEDU
      Map<String, String> requiredParams = {
        "client_id": "pe.web-app.portal",
        "redirect_uri": "https://www.perueduca.pe/#/home",
        "state": "default-state",
        "response_mode": "fragment",
        "response_type": "code",
        "scope": "openid",
        "nonce": "default-nonce",
      };

      Map<String, String> updatedParams = {...uri.queryParameters};
      requiredParams.forEach((key, value) {
        if (!updatedParams.containsKey(key)) {
          updatedParams[key] = value;
        }
      });

      return uri.replace(queryParameters: updatedParams).toString();
    }

    // Si es otro dominio (como RENIEC), no realizar modificaciones
    return url;
  }

  @override
  Widget build(BuildContext context) {
    String formattedUrl = formatUrl(widget.url);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle'),
        backgroundColor: const Color(0xFF0172B2),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(formattedUrl)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          domStorageEnabled: true,
          cacheEnabled: true,
          mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
        ),
        onWebViewCreated: (controller) {
          webViewController = controller;
        },
        onLoadStart: (controller, url) {
          print("Iniciando carga de URL: $url");
        },
        onLoadStop: (controller, url) async {
          print("Carga completa de URL: $url");
        },
        onLoadError: (controller, url, code, message) {
          print(
              "Error al cargar la URL: $url\nCódigo: $code\nMensaje: $message");
        },
        onConsoleMessage: (controller, consoleMessage) {
          print("Nivel: ${consoleMessage.messageLevel}");
          print("Mensaje: ${consoleMessage.message}");
        },
      ),
    );
  }
}
