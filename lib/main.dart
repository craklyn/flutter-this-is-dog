import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:another_brother/label_info.dart';
import 'package:another_brother/printer_info.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final controller = PageController(initialPage: 1);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Another Brother Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: PageView(children: [
//        BleRjPrintHappyMothersDay(title: 'RJ-4250WB BLE Sample'),
        QlBluetoothPrintHappyMothersDay(
            title: 'Animated face and nametag printing!'),
      ]),
    );
  }
}

// DEBUG NEW
class QlBluetoothPrintHappyMothersDay extends StatefulWidget {
  QlBluetoothPrintHappyMothersDay({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _QlBluetoothPrintHappyMothersDayState createState() =>
      _QlBluetoothPrintHappyMothersDayState();
}

class _QlBluetoothPrintHappyMothersDayState
    extends State<QlBluetoothPrintHappyMothersDay> {
  bool _error = false;
  var _belated = "";
  var _mdAddress = "";
  var _mdDate = "Mother's day";
  var _assetImage = 'assets/blank.png';
  GlobalKey _globalKey = GlobalKey();
  Uint8List pngBytes;
  AudioCache _audioCache;
  var _image = "assets/all_your_base_closed.jpeg";
  Timer timer;
  List<double> mouthTimes;
  int milliseconds = 0;

  @override
  void initState() {
    super.initState();
    // create this only once
    _audioCache = AudioCache(
        prefix: "assets/",
        fixedPlayer: AudioPlayer()..setReleaseMode(ReleaseMode.STOP));
  }

  /*
  Future<void> _capturePng() async {
    RenderRepaintBoundary boundary =
        globalKey.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage();
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    print(pngBytes);
  }
  */

  Future<void> _capturePng() async {
    try {
      final RenderRepaintBoundary boundary =
          _globalKey.currentContext.findRenderObject();
      final image = await boundary.toImage(pixelRatio: 2.0); // image quality
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      pngBytes = byteData.buffer.asUint8List();

//      final directory = (await getApplicationDocumentsDirectory()).path;
//      File imgFile = new File('$directory/mother_label.png');
//      mother_label_image = '$directory/mother_label.png';
//      imgFile.writeAsBytes(pngBytes);
    } catch (e) {
      print(e);
    }
  }

  void update_mouth(_) {
    setState(() {
      milliseconds += 100;
    });

    var talking =
        mouthTimes.where((x) => (x - milliseconds).abs() < 100).length > 0;

    // print(milliseconds);
//    print(talking);

    if (talking) {
      if (_image == "assets/all_your_base_open.png") {
        setState(() => _image = "assets/all_your_base_closed.jpeg");
      } else {
        setState(() => _image = "assets/all_your_base_open.png");
      }
    } else {
      setState(() => _image = "assets/all_your_base_closed.jpeg");
    }
  }

  void all_your_base_animate(context) async {
    String data = await DefaultAssetBundle.of(context)
        .loadString("assets/transcribe-all-your-base.json");
    final jsonResult = json.decode(data);

    var wordsJson = jsonResult['results']['items'] as List;
    wordsJson = wordsJson.where((x) => x.containsKey("start_time")).toList();

    List<double> tagObjs = wordsJson
        .map<double>((x) => double.parse(x['start_time']) * 1000)
        .toList();

    /*
        List<double> tagObjs_start = wordsJson
        .map<double>((x) => double.parse(x['start_time']) * 1000)
        .toList();
    List<double> tagObjs_end = wordsJson
        .map<double>((x) => double.parse(x['end_time']) * 1000)
        .toList();

    var tagObjs = new List<double>.from(tagObjs_start)..addAll(tagObjs_end);
     */

//    print(tagObjs);

    setState(() {
      mouthTimes = tagObjs;
      milliseconds = 0;
    });

    setState(() {
      timer = Timer.periodic(Duration(milliseconds: 100), update_mouth);
    });
  }

  void printContext(BuildContext context) async {
    var printer = new Printer();
    var printInfo = PrinterInfo();
    printInfo.printerModel = Model.QL_1110NWB;
    printInfo.printMode = PrintMode.FIT_TO_PAGE;
    printInfo.isAutoCut = true;
    printInfo.port = Port.BLUETOOTH;
    // Set the label type.
    printInfo.labelNameIndex = QL1100.ordinalFromID(QL1100.W103.getId());

    // Set the printer info so we can use the SDK to get the printers.
    await printer.setPrinterInfo(printInfo);

    // Get a list of printers with my model available in the network.
    List<BluetoothPrinter> printers =
        await printer.getBluetoothPrinters([Model.QL_1110NWB.getName()]);

    if (printers.isEmpty) {
      // Show a message if no printers are found.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("No paired printers found on your device."),
        ),
      ));

      return;
    }
    // Get the IP Address from the first printer found.
    printInfo.macAddress = printers.single.macAddress;

    printer.setPrinterInfo(printInfo);
    printer.printImage(await loadImage('assets/mynameis.png'));
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ElevatedButton(
            onPressed: () {
              _audioCache.play('allbase.mp3');
              all_your_base_animate(context);
            },
            child: Text("Sign in to event"),
          ),
          new Image(image: new AssetImage(_image)),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              //"Do not forget to grant permissions to your app in Settings.",
              "\n",
              textAlign: TextAlign.center,
            ),
          ),
          RepaintBoundary(
            key: _globalKey,
          ),
        ],
      ),

      /*
      floatingActionButton: FloatingActionButton(
        onPressed: () => print(context),
        tooltip: 'Print',
        child: Icon(Icons.print),
      ), // This trailing comma makes auto-formatting nicer for build methods.
      */
    );
  }

  Future<ui.Image> loadImage(String assetPath) async {
    final ByteData img = await rootBundle.load(assetPath);
    final Completer<ui.Image> completer = new Completer();
    ui.decodeImageFromList(new Uint8List.view(img.buffer), (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  Future<ui.Image> loadImageFromUint8List(Uint8List encoded_image) async {
    final Completer<ui.Image> completer = new Completer();
    ui.decodeImageFromList(encoded_image, (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }
}
