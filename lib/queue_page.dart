import 'dart:convert';

import 'package:barcodescanner/queue_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_sdk/dynamsoft_barcode.dart';
import 'global.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override
  State<QueuePage> createState() => QueuePageState();
}

class QueuePageState extends State<QueuePage> {
  bool _isLoaded = false;
  final List<BarcodeResult> _barcodeQueue =
      List<BarcodeResult>.empty(growable: true);
  final Map<String, int> _quantities = {};
  final Map<String, Map<String, dynamic>> _barcodeMetadata = {};

  @override
  void initState() {
    super.initState();
    loadQueue();
  }

  Future<void> loadQueue() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var data = prefs.getStringList('barcode_data');
    if (data != null) {
      _barcodeQueue.clear();
      _quantities.clear();
      _barcodeMetadata.clear(); // Clear existing metadata

      for (String json in data) {
        Map<String, dynamic> jsonMap = jsonDecode(json);

        // Try to get quantity from metadata
        int quantity = 1;
        if (jsonMap.containsKey('metadata') && jsonMap['metadata'] != null) {
          Map<String, dynamic> metadata =
              jsonMap['metadata'] as Map<String, dynamic>;
          if (metadata.containsKey('quantity')) {
            quantity = metadata['quantity'] as int;
          }
        }

        BarcodeResult barcodeResult = BarcodeResult.fromJson(jsonMap);
        _barcodeQueue.add(barcodeResult);
        _quantities[barcodeResult.text] = quantity;

        // Store metadata separately
        if (jsonMap.containsKey('metadata') && jsonMap['metadata'] != null) {
          _barcodeMetadata[barcodeResult.text] =
              jsonMap['metadata'] as Map<String, dynamic>;
        }
      }
    }
    setState(() {
      _isLoaded = true;
    });
  }

  Future<void> updateQuantity(int index, int quantity) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> data = prefs.getStringList('barcode_data') as List<String>;

    // Get the JSON for the item
    Map<String, dynamic> jsonMap = jsonDecode(data[index]);

    // Ensure metadata exists
    if (jsonMap['metadata'] == null) {
      jsonMap['metadata'] = {};
    }

    // Update quantity
    jsonMap['metadata']['quantity'] = quantity;
    _quantities[_barcodeQueue[index].text] = quantity;

    // Save back to SharedPreferences
    data[index] = jsonEncode(jsonMap);
    prefs.setStringList('barcode_data', data);
  }

  Future<void> addSameBarcodeToQueue(BarcodeResult result) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> data = prefs.getStringList('barcode_data') ?? [];

    // Find the index of the barcode with the same text
    int existingIndex = -1;
    for (int i = 0; i < _barcodeQueue.length; i++) {
      if (_barcodeQueue[i].text == result.text) {
        existingIndex = i;
        break;
      }
    }

    if (existingIndex >= 0) {
      // Barcode exists, increment quantity
      int currentQuantity = _quantities[result.text] ?? 1;
      int newQuantity = currentQuantity + 1;

      // Update quantities map
      _quantities[result.text] = newQuantity;

      // Update in SharedPreferences
      Map<String, dynamic> jsonMap = jsonDecode(data[existingIndex]);
      if (jsonMap['metadata'] == null) {
        jsonMap['metadata'] = {};
      }
      jsonMap['metadata']['quantity'] = newQuantity;
      data[existingIndex] = jsonEncode(jsonMap);
      prefs.setStringList('barcode_data', data);

      setState(() {});
    } else {
      // Barcode doesn't exist, add it
      Map<String, dynamic> jsonMap = result.toJson();
      if (jsonMap['metadata'] == null) {
        jsonMap['metadata'] = {};
      }
      jsonMap['metadata']['quantity'] = 1;
      _quantities[result.text] = 1;

      // Store metadata separately
      _barcodeMetadata[result.text] =
          jsonMap['metadata'] as Map<String, dynamic>;

      data.add(jsonEncode(jsonMap));
      prefs.setStringList('barcode_data', data);

      _barcodeQueue.add(result);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    var listView = Expanded(
        child: ListView.builder(
            itemCount: _barcodeQueue.length,
            itemBuilder: (context, index) {
              BarcodeResult result = _barcodeQueue[index];
              // Get quantity from map
              int quantity = _quantities[result.text] ?? 1;

              return MyCustomWidget(
                  result: result,
                  quantity: quantity,
                  cbDeleted: () async {
                    _barcodeQueue.removeAt(index);
                    _quantities.remove(result.text);

                    final SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    List<String> data =
                        prefs.getStringList('barcode_data') as List<String>;
                    data.removeAt(index);
                    prefs.setStringList('barcode_data', data);
                    setState(() {});
                  },
                  cbOpenResultPage: () {},
                  onQuantityChanged: (newQuantity) {
                    updateQuantity(index, newQuantity);
                  });
            }));
    return Scaffold(
      appBar: AppBar(
        title: Text('Queue',
            style: TextStyle(
              fontSize: 22,
              color: colorTitle,
            )),
        centerTitle: true,
        backgroundColor: colorMainTheme,
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 30),
              child: IconButton(
                onPressed: () async {
                  final SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.remove('barcode_data');
                  setState(() {
                    _barcodeQueue.clear();
                  });
                },
                icon: Image.asset(
                  "images/icon-delete.png",
                  width: 26,
                  height: 26,
                  fit: BoxFit.cover,
                ),
              ))
        ],
      ),
      body: _isLoaded
          ? Column(
              children: [listView],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

