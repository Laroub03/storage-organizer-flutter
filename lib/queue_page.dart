import 'dart:convert';

import 'package:barcodescanner/api_service.dart';
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
  bool _isSending = false;
  final List<BarcodeResult> _barcodeQueue =
      List<BarcodeResult>.empty(growable: true);
  final Map<String, int> _quantities = {};
  final Map<String, Map<String, dynamic>> _barcodeMetadata = {};
  final ApiService _apiService = ApiService();

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
  
  Future<void> sendToApi() async {
    if (_barcodeQueue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items in queue to send')),
      );
      return;
    }
    
    setState(() {
      _isSending = true;
    });
    
    try {
      // Load token if not already loaded
      if (!_apiService.isAuthenticated()) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          _apiService.setToken(token);
        } else {
          throw Exception('Not authenticated. Please log in first.');
        }
      }
      
      // Prepare data for API
      List<Map<String, dynamic>> productsData = [];
      
      for (int i = 0; i < _barcodeQueue.length; i++) {
        BarcodeResult result = _barcodeQueue[i];
        Map<String, dynamic> metadata = _barcodeMetadata[result.text] ?? {};
        int quantity = _quantities[result.text] ?? 1;
        
        // Get locationId and categoryId from metadata or use defaults
        int locationId = 1; // Default
        int categoryId = 1; // Default
        
        if (metadata.containsKey('locationId') && metadata['locationId'] != null) {
          locationId = metadata['locationId'] is int 
              ? metadata['locationId'] 
              : int.tryParse(metadata['locationId'].toString()) ?? 1;
        }
        
        if (metadata.containsKey('categoryId') && metadata['categoryId'] != null) {
          categoryId = metadata['categoryId'] is int 
              ? metadata['categoryId'] 
              : int.tryParse(metadata['categoryId'].toString()) ?? 1;
        }
        
        // Create product data - we use defaults for required fields if not set in metadata
        Map<String, dynamic> productData = {
          'name': metadata['name'] ?? 'Scanned Product',
          'description': metadata['description'] ?? 'Scanned with mobile app',
          'quantity': quantity,
          'barcode': result.text,
          'manufacturer': metadata['manufacturer'] ?? 'Unknown',
          'locationId': locationId,
          'categoryId': categoryId,
        };
        
        // Log the product data we're sending
        print('Preparing product: $productData');
        
        productsData.add(productData);
      }
      
      if (productsData.isEmpty) {
        throw Exception('No valid product data to send');
      }
      
      // Send to API
      print('Sending ${productsData.length} products to API');
      final results = await _apiService.createProductsBatch(productsData);
      print('Received ${results.length} products back from API');
      
      // Clear queue after successful send
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('barcode_data');
      
      setState(() {
        _barcodeQueue.clear();
        _quantities.clear();
        _barcodeMetadata.clear();
        _isSending = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully sent ${results.length} items to storage'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      print('Error in sendToApi: $e');
      
      setState(() {
        _isSending = false;
      });
      
      // Show more detailed error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending items: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
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
                  metadata: _barcodeMetadata[result.text],
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
                    _quantities.clear();
                    _barcodeMetadata.clear();
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
          ? Stack(
              children: [
                Column(
                  children: [listView],
                ),
                // Send button - positioned at bottom right
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: _isSending ? null : sendToApi,
                    backgroundColor: colorMainTheme,
                    child: _isSending
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

