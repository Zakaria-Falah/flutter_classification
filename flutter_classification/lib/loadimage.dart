// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:io';
import 'package:cnn_classification/MenuBarre.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_v2/tflite_v2.dart';

class LoadImage extends StatefulWidget {
  const LoadImage({Key? key}) : super(key: key);

  @override
  State<LoadImage> createState() => _LoadImageState();
}

class _LoadImageState extends State<LoadImage> {
  final ImagePicker _picker = ImagePicker();
  File? file;
  var outputs ;
  var v = "";
  bool imageSelected = false;


  @override
  void initState(){
    super.initState();
    loadmodel().then((value){
      setState(() {
        
      });
    });
  }

   Future<void> loadmodel() async{
      String res;
      res = (await Tflite.loadModel(
        model: "assets/model.tflite",
        labels: "assets/labels.txt",
      ))!;
      print("Model loading status : ${res}");
  }

  Future<void> _pickImage() async{
    try{
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if(image == null) return;
      setState(() {
        file = File(image.path);
        imageSelected = true;
      });
      await detectimage(file!);
      print('Image picked');
    }catch(e){
      print('Error picking image : $e');
    }
  }

  Future<void> detectimage(File image) async {
    int startTime = DateTime.now().millisecondsSinceEpoch;
    var predictions = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 1,
      threshold: 0.05,
      imageMean: 127.5,
      imageStd: 127.5,
      );
    setState(() {
      outputs = predictions;
      v = predictions.toString();
    });
    print("Output Shape: ${predictions![0]['shape']}"); 
    print("//////////////////////////////////////////////////");
    print(predictions);
    // print(dataList);
    print("//////////////////////////////////////////////////");
    int endTime = DateTime.now().millisecondsSinceEpoch;
    print("Inference took ${endTime - startTime}ms");

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Waste Image Clasification'),
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
            ) : const Text('No image selected'),
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
          child: const Icon(Icons.image)
          ),
    );
  }

  @override
  void dispose() {
    // Unload the model when the state is disposed
    Tflite.close();
    print('done');
    super.dispose();
  }
}