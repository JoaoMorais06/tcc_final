import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TCC Libras',
      theme: ThemeData.dark(),
      home: TradutorScreen(),
    );
  }
}

class Palavra {
  final int ident;
  final int id;
  final String letra;
  final String palavra;
  final String descricao;
  final String libras;
  final String exemplo;
  final String video;
  final int mao;

  Palavra({
    required this.ident,
    required this.id,
    required this.letra,
    required this.palavra,
    required this.descricao,
    required this.libras,
    required this.exemplo,
    required this.video,
    required this.mao,
  });

  factory Palavra.fromJson(Map<String, dynamic> json) {
    return Palavra(
      ident: json['ident'],
      id: json['id'],
      letra: json['letra']?.toString().toUpperCase() ?? '',
      palavra: json['palavra'],
      descricao: json['descricao'],
      libras: json['libras'],
      exemplo: json['exemplo'],
      video: json['video'],
      mao: json['mao'] is String ? int.parse(json['mao']) : json['mao'],
    );
  }
}

class TradutorScreen extends StatefulWidget {
  @override
  _TradutorScreenState createState() => _TradutorScreenState();
}

class _TradutorScreenState extends State<TradutorScreen> {
  TextEditingController _textController = TextEditingController();
  String _selectedLetter = 'A';
  List<Palavra> _todasPalavras = [];
  List<Palavra> _palavrasFiltradas = [];
  Map<int, String> _maoImages = {};

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    await _carregarMaoJson();
    await _carregarPalavras();
  }

  Future<void> _carregarMaoJson() async {
    try {
      String jsonString = await rootBundle.loadString('assets/mao.json');
      List<dynamic> maoData = json.decode(jsonString);
      for (var item in maoData) {
        _maoImages[int.parse(item['id'])] = item['url'];
      }
    } catch (e) {
      print('Erro ao carregar mao.json: $e');
    }
  }

  Future<void> _carregarPalavras() async {
    try {
      String jsonString = await rootBundle.loadString('assets/palavras.json');
      List<dynamic> palavrasData = json.decode(jsonString);
      _todasPalavras =
          palavrasData.map((json) => Palavra.fromJson(json)).toList();
      _filtrarPalavras(_selectedLetter);
    } catch (e) {
      print('Erro ao carregar palavras: $e');
    }
  }

  void _filtrarPalavras(String filtro) {
    setState(() {
      if (filtro.length == 1) {
        _selectedLetter = filtro.toUpperCase();
        _palavrasFiltradas = _todasPalavras
            .where((palavra) => palavra.letra == _selectedLetter)
            .toList();
      } else {
        _palavrasFiltradas = _todasPalavras
            .where((palavra) =>
                palavra.palavra.toLowerCase().contains(filtro.toLowerCase()))
            .toList();
      }
    });
  }

  String _getImageUrl(int maoId) {
    String? imageUrl = _maoImages[maoId];
    if (imageUrl != null) {
      return 'https://www.ines.gov.br/dicionario-de-libras/public/media/mao/$imageUrl';
    }
    return '';
  }

  String _getVideoUrl(String videoParam) {
    return 'https://www.ines.gov.br/dicionario-de-libras/public/media/palavras/videos/$videoParam';
  }

  Future<void> _preloadImage(String imageUrl) async {
    try {
      await precacheImage(NetworkImage(imageUrl), context);
    } catch (e) {
      print('Erro ao pré-carregar imagem: $e');
    }
  }

  void _mostrarDetalhesPalavra(Palavra palavra) async {
    String imageUrl = _getImageUrl(palavra.mao);
    String videoUrl = _getVideoUrl(palavra.video);

    await _preloadImage(imageUrl);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: double.minPositive,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      palavra.palavra,
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    height: 200,
                    child: Center(
                      child: Image.network(
                        imageUrl,
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('Erro ao carregar imagem: $error');
                          print('URL da imagem: $imageUrl');
                          print('Stack trace: $stackTrace');
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error, color: Colors.red),
                              Text('Não foi possível carregar a imagem',
                                  style: TextStyle(color: Colors.red)),
                              Text('Erro: $error',
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 10)),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Descrição: ${palavra.descricao}'),
                        SizedBox(height: 8),
                        Text('Exemplo: ${palavra.exemplo}'),
                        SizedBox(height: 8),
                        if (palavra.video.isNotEmpty)
                          VideoPlayerWidget(videoUrl: videoUrl)
                        else
                          Text('Nenhum vídeo disponível para esta palavra.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tradutor de Português para Libras'),
      ),
      body: Row(
        children: [
          Container(
            width: 50,
            color: Colors.grey[800],
            child: ListView(
              children: [
                for (var letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''))
                  GestureDetector(
                    onTap: () {
                      _textController.text = letter;
                      _filtrarPalavras(letter);
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      color:
                          _selectedLetter == letter ? Colors.blue[700] : null,
                      child: Text(
                        letter,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: _selectedLetter == letter
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Digite o texto',
                    ),
                    onChanged: _filtrarPalavras,
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: _palavrasFiltradas.isEmpty
                        ? Center(child: Text('Nenhuma palavra encontrada'))
                        : ListView.builder(
                            itemCount: _palavrasFiltradas.length,
                            itemBuilder: (context, index) {
                              var palavra = _palavrasFiltradas[index];
                              return ListTile(
                                title: Text(palavra.palavra),
                                onTap: () => _mostrarDetalhesPalavra(palavra),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                _controller.play();
              }
            });
          },
          child: Icon(
            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          ),
        ),
      ],
    );
  }
}
