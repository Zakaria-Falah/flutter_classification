import 'dart:io';
import 'dart:typed_data';
import 'package:cnn_classification/MenuBarre.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_v2/tflite_v2.dart';

class LoadImage2 extends StatefulWidget {
  const LoadImage2({Key? key}) : super(key: key);

  @override
  State<LoadImage2> createState() => _LoadImage2State();
}

class _LoadImage2State extends State<LoadImage2> {
  final ImagePicker _picker = ImagePicker();
  File? file;
  List<dynamic>? outputs;
  var v = "";
  bool imageSelected = false;

  @override
  void initState() {
    super.initState();
    loadmodel().then((value) {
      setState(() {});
    });
  }

  Future<void> loadmodel() async {
    String res;
    res = (await Tflite.loadModel(
      model: "assets/model1.tflite",
      labels: "assets/labels1.txt",
    ))!;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      setState(() {
        file = File(image.path);
        imageSelected = true;
      });
      await detectimage(file!);
      print('Image picked');
    } catch (e) {
      print('Error picking image : $e');
    }
  }


  Future<void> detectimage(File image) async {
    int startTime = DateTime.now().millisecondsSinceEpoch;
    
    var rawBytes = await file!.readAsBytes();
    var imageTensor = await img.decodeImage(Uint8List.fromList(rawBytes));
    var resizedImage = img.copyResize(imageTensor!, width: 28, height: 28);
    var inputValues = Float32List(28 * 28 * 1);
    for (var y = 0; y < 28; y++) {
      for (var x = 0; x < 28; x++) {
        var pixelValue = resizedImage.getPixel(x, y);
        inputValues[y * 28 + x] = (pixelValue >> 16 & 0xFF) / 255.0;
      }
    }
    print('Input values: $inputValues');
    var predictions = await Tflite.runModelOnBinary(
      binary: inputValues.buffer.asUint8List(),
      numResults: 10,
      threshold: 0.5,
    );
    print('Raw output: $predictions');
    setState(() {
      outputs = predictions;
    });
}

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Waste Image Classification'),
      ),
      drawer: const MenuBarre(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            file != null
                ? Image.file(
                    file!,
                    height: 200,
                    width: 200,
                  )
                : const Text('No image selected'),
            const SizedBox(height: 20),
                        outputs != null && outputs!.isNotEmpty ?
            Text(outputs![0]['label'].toString().substring(2),style: const TextStyle(color: Colors.red),) : const Text(''),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _pickImage();
        },
        tooltip: 'Pick Image from Gallery',
        child: const Icon(Icons.image),
      ),
    );
  }

  @override
  void dispose() {
    
    Tflite.close();
    super.dispose();
  }
}
