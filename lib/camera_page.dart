import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_sdk/dynamsoft_barcode.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'camera/camera_manager.dart';
import 'global.dart';

import 'result_page.dart';
import 'setting_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  late CameraManager _cameraManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (kIsWeb) {
      // barcodeReader.setParameters(scannerTemplate);
    }

    _cameraManager = CameraManager(
        context: context,
        cbRefreshUi: refreshUI,
        cbIsMounted: isMounted,
        cbNavigation: navigation);
    _cameraManager.initState();
  }

  void navigation(dynamic order) {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(barcodeResults: order),
        ));
  }

  void refreshUI() {
    setState(() {});
  }

  bool isMounted() {
    return mounted;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraManager.stopVideo();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraManager.controller == null ||
        !_cameraManager.controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraManager.controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _cameraManager.toggleCamera(0);
    }
  }

  List<Widget> createCameraPreview() {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return [
        SizedBox(width: 640, height: 480, child: _cameraManager.getPreview()),
        Positioned(
          top: 0.0,
          right: 0.0,
          bottom: 0,
          left: 0.0,
          child: createOverlay(
            _cameraManager.barcodeResults,
          ),
        ),
      ];
    } else {
      if (_cameraManager.controller != null &&
          _cameraManager.previewSize != null) {
        double width = _cameraManager.previewSize!.width;
        double height = _cameraManager.previewSize!.height;
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          if (MediaQuery.of(context).size.width <
              MediaQuery.of(context).size.height) {
            width = _cameraManager.previewSize!.height;
            height = _cameraManager.previewSize!.width;
          }
        }

        return [
          SizedBox(
              width: width, height: height, child: _cameraManager.getPreview()),
          Positioned(
            top: 0.0,
            right: 0.0,
            bottom: 0,
            left: 0.0,
            child: createOverlay(
              _cameraManager.barcodeResults,
            ),
          ),
        ];
      } else {
        return [const CircularProgressIndicator()];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var captureButton = InkWell(
      onTap: () {
        _cameraManager.isReadyToGo = true;
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.green, width: 3),
        ),
        child: const Icon(
          Icons.add,
          color: Colors.green,
          size: 40,
        ),
      ),
    );
    
    var deleteButton = InkWell(
      onTap: () async {
        if (_cameraManager.barcodeResults != null && _cameraManager.barcodeResults!.isNotEmpty) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          var results = prefs.getStringList('barcode_data');
          if (results != null) {
            for (BarcodeResult result in _cameraManager.barcodeResults!) {
              String text = result.text;
              bool exists = false;
              int index = -1;
              
              // Find the barcode in the stored data
              for (int i = 0; i < results.length; i++) {
                Map<String, dynamic> jsonMap = jsonDecode(results[i]);
                BarcodeResult storedResult = BarcodeResult.fromJson(jsonMap);
                if (storedResult.text == text) {
                  exists = true;
                  index = i;
                  break;
                }
              }
              
              if (exists && index >= 0) {
                // Get the JSON for this item
                Map<String, dynamic> jsonMap = jsonDecode(results[index]);
                
                // Get current quantity
                Map<String, dynamic>? metadata = jsonMap['metadata'] as Map<String, dynamic>?;
                int quantity = 1;
                if (metadata != null && metadata.containsKey('quantity')) {
                  quantity = metadata['quantity'] as int;
                }
                
                if (quantity > 1) {
                  // Decrement quantity
                  if (jsonMap['metadata'] == null) {
                    jsonMap['metadata'] = {};
                  }
                  jsonMap['metadata']['quantity'] = quantity - 1;
                  results[index] = jsonEncode(jsonMap);
                  prefs.setStringList('barcode_data', results);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Decreased quantity for barcode: $text')),
                  );
                } else {
                  // Remove the barcode if quantity would become 0
                  results.removeAt(index);
                  prefs.setStringList('barcode_data', results);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Removed barcode: $text')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Barcode not found in queue')),
                );
              }
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No barcode detected')),
          );
        }
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.red, width: 3),
        ),
        child: const Icon(
          Icons.remove,
          color: Colors.red,
          size: 40,
        ),
      ),
    );

    return WillPopScope(
        onWillPop: () async {
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text(
              'Barcode Scanner',
              style: TextStyle(color: Colors.white),
            ),
            iconTheme: const IconThemeData(
              color: Colors
                  .white, // Set the color of the back arrow and other icons
            ),
          ),
          body: Stack(
            children: <Widget>[
              Positioned(
                top: 0,
                right: 0,
                left: 0,
                bottom: 0,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: Stack(
                    children: createCameraPreview(),
                  ),
                ),
              ),
              Positioned(
                bottom: 80,
                left: 80,
                child: deleteButton,
              ),
              Positioned(
                bottom: 80,
                right: 80,
                child: captureButton,
              ),
            ],
          ),
          floatingActionButton: Opacity(
            opacity: 0.5,
            child: FloatingActionButton(
              backgroundColor: Colors.black,
              child: const Icon(Icons.flip_camera_android),
              onPressed: () {
                _cameraManager.switchCamera();
              },
            ),
          ),
        ));
  }
}
