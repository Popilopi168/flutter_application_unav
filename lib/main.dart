import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:flutter/services.dart';



Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        // Pass the appropriate camera to the TakePictureScreen widget.
        camera: firstCamera,
      ),
    ),
  );
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );
    SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
      ]); 

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
    // change oriantation when place camera horizontally ---- unfinished
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.

      //tap the screen to take the pic
      body: GestureDetector(
        onTap:() async {try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Attempt to take a picture and get the file `image`
            // where it was saved.
            final imgTaken = await _controller.takePicture();

            if (!mounted) return;

            // If the picture was taken, sent it to server
            if (imgTaken != null) {
                // File image = File(imgTaken.path);
                // Directory tempDir = await getTemporaryDirectory();
                // File tempImage = await image.copy('${tempDir.path}/tempImage.jpg');

                // Send the image to the server.
                try {
                  final serverSocket = await Socket.connect("128.122.136.173", 30003);
                  print('Connected to server.');
                  int fileLength = await imgTaken.length();
                  String fileLengthStr = fileLength.toString().padLeft(10, '0');
                  serverSocket.write(1);
                  serverSocket.write(fileLengthStr);
                  await serverSocket.addStream(imgTaken.openRead());
                  print('Image sent to server.');
                  serverSocket.destroy();
                } catch (e) {
                  print('Could not connect to the server: $e');
                }
              } else {
                print('No image selected.');
              }


          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
},
        child: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final mediaSize = MediaQuery.of(context).size;
            final scale = 1 / (_controller.value.aspectRatio * mediaSize.aspectRatio);
            return ClipRect(
              clipper: _MediaSizeClipper(mediaSize),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topCenter,
                child: CameraPreview(_controller),
              ),
            );
            // // If the Future is complete, display the preview.
            // return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      )
    );
  }
}


//to make a full size screen camera preview
class _MediaSizeClipper extends CustomClipper<Rect> {
  final Size mediaSize;
  const _MediaSizeClipper(this.mediaSize);
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, mediaSize.width, mediaSize.height);
  }
  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }
}