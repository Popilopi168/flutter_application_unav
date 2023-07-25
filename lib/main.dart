import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            child: const Text('Take Picture'),
            onPressed: () async {
              final ImagePicker ipicker = ImagePicker();
              XFile? pickedFile = await ipicker.pickImage(source: ImageSource.camera);

              if (pickedFile != null) {
                File image = File(pickedFile.path);
                Directory tempDir = await getTemporaryDirectory();
                File tempImage = await image.copy('${tempDir.path}/tempImage.jpg');

                // Send the image to the server.
                try {
                  Socket.connect("128.122.136.173", 30001).then((serverSocket) {
                  print('Connected to server.');
                  serverSocket.add(tempImage.readAsBytesSync());
                  print('Image sent to server.');
                  serverSocket.destroy();
                  });
                } catch (e) {
                  print('Could not connect to the server: $e');
                };
              } else {
                print('No image selected.');
              }
            },
          ),
        ),
      ),
    );
  }
}
