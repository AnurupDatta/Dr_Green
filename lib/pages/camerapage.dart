import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

class Camerapage extends StatefulWidget {
  const Camerapage({super.key});

  @override
  State<Camerapage> createState() => _CamerapageState();
}

class _CamerapageState extends State<Camerapage> {
  CameraImage? cameraImage;
  CameraController? cameraController;
  String output = '';
  List<CameraDescription>? cameras;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    loadModel();
  }

  Future<void> initializeCamera() async {
    try {
      // Retrieve the list of available cameras
      cameras = await availableCameras();

      if (cameras != null && cameras!.isNotEmpty) {
        cameraController =
            CameraController(cameras![0], ResolutionPreset.medium);

        await cameraController!.initialize();

        if (mounted) {
          setState(() {
            cameraController!.startImageStream((imagestream) {
              cameraImage = imagestream;
              runModel();
            });
          });
        }
      } else {
        print("No cameras found");
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<void> runModel() async {
    if (cameraImage != null) {
      var predictions = await Tflite.runModelOnFrame(
        bytesList: cameraImage!.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 2,
        threshold: 0.1,
        asynch: true,
      );

      if (predictions != null) {
        setState(() {
          output = predictions.map((e) => e['label']).join(', ');
        });
      }
    }
  }

  Future<void> loadModel() async {
    try {
      await Tflite.loadModel(
        model: "assets/model_unquant.tflite",
        labels: "assets/labels.txt",
      );
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          "Test Your Plant",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              width: MediaQuery.of(context).size.width,
              child: cameraController == null ||
                      !cameraController!.value.isInitialized
                  ? const Center(
                      child: Text(
                        "Loading Camera...",
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : AspectRatio(
                      aspectRatio: cameraController!.value.aspectRatio,
                      child: CameraPreview(cameraController!),
                    ),
            ),
          ),
          Text(
            output.isEmpty ? "No Predictions Yet" : output,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
    );
  }
}
