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
  List<Palavra> _todasPalavras = [];
  List<Palavra> _palavrasFiltradas = [];
  Map<int, String> _maoImages = {};
  String? _selectedLetter;
  Palavra? _palavraSelecionada;

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
    } catch (e) {
      print('Erro ao carregar palavras: $e');
    }
  }

  void _filtrarPalavras(String letra) {
    setState(() {
      if (_selectedLetter == letra) {
        _selectedLetter = null;
        _palavrasFiltradas = [];
      } else {
        _selectedLetter = letra;
        _palavrasFiltradas =
            _todasPalavras.where((palavra) => palavra.letra == letra).toList();
      }
      _palavraSelecionada = null;
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

  void _buscarPalavra() {
    String texto = _textController.text.trim();
    if (texto.isEmpty) {
      _mostrarMensagem('Por favor, digite uma palavra.');
      return;
    }

    Palavra? palavraEncontrada = _todasPalavras.firstWhere(
      (palavra) => palavra.palavra.toLowerCase() == texto.toLowerCase(),
      orElse: () => Palavra(
        ident: -1,
        id: -1,
        letra: '',
        palavra: '',
        descricao: '',
        libras: '',
        exemplo: '',
        video: '',
        mao: -1,
      ),
    );

    if (palavraEncontrada.ident != -1) {
      setState(() {
        _palavraSelecionada = palavraEncontrada;
      });
    } else {
      _mostrarMensagem('Palavra não encontrada no dicionário.');
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
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
          // Letras na lateral
          Container(
            width: 50,
            child: ListView(
              children: List.generate(26, (index) {
                String letter = String.fromCharCode(65 + index);
                return ListTile(
                  title: Text(letter),
                  onTap: () => _filtrarPalavras(letter),
                  tileColor: _selectedLetter == letter
                      ? Colors.blue.withOpacity(0.3)
                      : null,
                );
              }),
            ),
          ),
          // Conteúdo principal
          Expanded(
            child: Column(
              children: [
                // Input no topo
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Digite uma palavra',
                    ),
                  ),
                ),
                // Botão Traduzir
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton(
                    onPressed: _buscarPalavra,
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      alignment: Alignment.center,
                      child: Text('Traduzir', style: TextStyle(fontSize: 18)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4B0082), // Cor roxa escura
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                // Ícone Libras ou área de exibição
                Expanded(
                  child: _selectedLetter == null && _palavraSelecionada == null
                      ? Column(
                          children: [
                            SizedBox(height: 20), // Espaçamento acima do ícone
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: Colors.grey, width: 2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.asset(
                                  'assets/libras_icon.png',
                                  height: 160,
                                  width: 260,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        )
                      : _palavraSelecionada != null
                          ? SingleChildScrollView(
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      _palavraSelecionada!.palavra,
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    height: 200,
                                    child: Image.network(
                                      _getImageUrl(_palavraSelecionada!.mao),
                                      loadingBuilder: (BuildContext context,
                                          Widget child,
                                          ImageChunkEvent? loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                            child: CircularProgressIndicator());
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        print(
                                            'Erro ao carregar imagem: $error');
                                        return Icon(Icons.error);
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Descrição: ${_palavraSelecionada!.descricao}'),
                                        SizedBox(height: 8),
                                        Text(
                                            'Exemplo: ${_palavraSelecionada!.exemplo}'),
                                        SizedBox(height: 8),
                                        if (_palavraSelecionada!
                                            .video.isNotEmpty)
                                          VideoPlayerWidget(
                                              videoUrl: _getVideoUrl(
                                                  _palavraSelecionada!.video))
                                        else
                                          Text(
                                              'Nenhum vídeo disponível para esta palavra.'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _palavrasFiltradas.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title:
                                      Text(_palavrasFiltradas[index].palavra),
                                  onTap: () {
                                    setState(() {
                                      _palavraSelecionada =
                                          _palavrasFiltradas[index];
                                    });
                                  },
                                );
                              },
                            ),
                ),
              ],
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
        SizedBox(height: 20), // Espaçamento adicionado acima do vídeo
        FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Center(
                child: Container(
                  width: 250, // Largura fixa do vídeo
                  height: 150, // Altura fixa do vídeo
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Text('Erro ao carregar o vídeo: ${snapshot.error}');
            } else {
              return const Center(
                child: SizedBox(
                  width: 250,
                  height: 150,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
          },
        ),
        SizedBox(height: 10),
        Center(
          child: ElevatedButton(
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
        ),
      ],
    );
  }
}
