import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '読み上げアプリ',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: SpeachPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SpeachPage extends StatefulWidget {
  SpeachPage({Key? key}) : super(key: key);

  @override
  State<SpeachPage> createState() => _SpeachPageState();
}

enum TtsState { playing, stopped, paused, continued }

class _SpeachPageState extends State<SpeachPage> {
  double volume = 1.0;
  double pitch = 1.0;
  double rate = 0.5;
  FlutterTts flutterTts = FlutterTts();
  String? Language;
  bool isCurrentLanguageInstalled = false;
  int _maxLength = 0;
  TextEditingController _editingController = TextEditingController();

  TtsState ttsState = TtsState.stopped;
  // List<dynamic> languages = [];

  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isIos => !kIsWeb && Platform.isIOS;
  bool get isWeb => kIsWeb;

  @override
  void initState() {
    super.initState();
    initTts();
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  void initTts() async {
    List<dynamic> languages = await flutterTts.getLanguages;
    print(languages);
    // languages.forEach((element) {
    //   print(element);
    // });
    _getMaxSpeechInputLengthSection();
    flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        ttsState = TtsState.stopped;
      });
    });

    if (isWeb || isIos) {
      flutterTts.setPauseHandler(() {
        setState(() {
          print("Paused");
          ttsState = TtsState.paused;
        });
      });

      flutterTts.setContinueHandler(() {
        setState(() {
          print("Continued");
          ttsState = TtsState.continued;
        });
      });
    }

    flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });
  }

  Future<void> _play() async {
    print('speack');
    print(_editingController.text);
    if (_editingController.text == "" || ttsState == TtsState.playing) return;
    // await flutterTts.setLanguage(Language?);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setVolume(volume);
    await flutterTts.setPitch(pitch);
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.speak(_editingController.text);
    setState(() {
      ttsState = TtsState.playing;
    });
  }

  Future<void> _stop() async {
    if (TtsState.playing == ttsState) {
      var result = await flutterTts.stop();
      if (result == 1) {
        setState(() {
          ttsState = TtsState.stopped;
        });
      }
    }
  }

  Future<void> _pause() async {
    if (TtsState.playing == ttsState) {
      var result = await flutterTts.pause();
      if (result == 1) {
        setState(() {
          ttsState = TtsState.paused;
        });
      }
    }
  }

  Future<dynamic> _getLanguages() => flutterTts.getLanguages;

  void _getMaxSpeechInputLengthSection() {
    flutterTts.getMaxSpeechInputLength.then((value) {
      setState(() {
        _maxLength = value!;
      });
    });
  }

  Widget _controllerSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
            onPressed: _play,
            icon: const Icon(
              Icons.play_arrow,
              color: Colors.green,
            )),
        IconButton(
            onPressed: _stop,
            icon: const Icon(
              Icons.stop,
              color: Colors.red,
            )),
      ],
    );
  }

  Widget _buildSliders() {
    return Column(
      children: [_volume(), _pitch(), _rate()],
    );
  }

  Widget _volume() {
    return Column(
      children: [
        Text('ボリューム'),
        Slider(
          value: volume,
          onChanged: (newVolume) {
            setState(() {
              volume = newVolume;
            });
          },
          min: 0.0,
          max: 1.0,
          label: "Volume: ${volume}",
          activeColor: Colors.blue,
        ),
      ],
    );
  }

  Widget _pitch() {
    return Column(
      children: [
        Text('ピッチ'),
        Slider(
          value: pitch,
          onChanged: (newPicth) {
            setState(() {
              pitch = newPicth;
            });
          },
          min: 0.0,
          max: 2.0,
          label: "Pitch: ${pitch}",
          activeColor: Colors.green,
        ),
      ],
    );
  }

  Widget _rate() {
    return Column(
      children: [
        Text('速さ'),
        Slider(
          value: rate,
          onChanged: (newRate) {
            setState(() {
              rate = newRate;
            });
          },
          min: 0.0,
          max: 1.0,
          label: "Rate: ${rate}",
          activeColor: Colors.red,
        ),
      ],
    );
  }

  Widget createFloatingActionButton(
      {required Icon icon, VoidCallback? onPressed, Color? backgroundColor}) {
    return FloatingActionButton(
      onPressed: onPressed,
      child: icon,
      backgroundColor: backgroundColor,
    );
  }

  Widget createEmptyContainer({double? width, double? height}) {
    if (width == null && height == null) Container();
    return Container(width: width, height: height);
  }

  Widget _futureBuilder() => FutureBuilder<dynamic>(
        future: _getLanguages(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            return _languageDropDownSection(snapshot.data);
          } else if (snapshot.hasError) {
            return Text('Error loading languages');
          } else {
            return Text('Loading Languages');
          }
        },
      );

  Widget _languageDropDownSection(dynamic languages) => Container(
        padding: EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton(
              items: getLanguageDropDownItem(languages),
              onChanged: changedLanguageDropDownItem,
              value: Language,
            ),
            Text(isCurrentLanguageInstalled ? 'installed' : 'not installed')
          ],
        ),
      );

  List<DropdownMenuItem<String>> getLanguageDropDownItem(dynamic languages) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in languages) {
      items.add(DropdownMenuItem(
        child: Text((type as String) == 'ja-JP' ? "日本語" : type as String),
        value: type as String,
      ));
    }
    return items;
  }

  void changedLanguageDropDownItem(String? selectedType) {
    setState(() {
      Language = selectedType;
      flutterTts.setLanguage(Language!);
      if (isAndroid) {
        flutterTts
            .isLanguageInstalled(Language!)
            .then((value) => isCurrentLanguageInstalled = (value as bool));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('読み上げアプリ（日本語）')),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _editingController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
              ),
              Text('最大文字数:${_maxLength}'),
              _buildSliders(),
              _controllerSection(),
              _futureBuilder(),
              createEmptyContainer(height: 60)
            ],
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          createFloatingActionButton(
              icon: Icon(
                Icons.play_arrow,
              ),
              onPressed: _play),
          // const SizedBox(
          //   width: 5,
          // ),
          // createFloatingActionButton(
          //     icon: Icon(
          //       Icons.pause,
          //     ),
          //     onPressed: _pause),
          SizedBox(
            width: 5,
          ),
          createFloatingActionButton(
              icon: Icon(
                Icons.stop,
              ),
              onPressed: _stop),
        ],
      ),
    );
  }
}
