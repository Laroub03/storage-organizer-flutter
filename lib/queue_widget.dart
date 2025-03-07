import 'dart:convert';

import 'package:barcodescanner/queue_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_sdk/dynamsoft_barcode.dart';
import 'global.dart';
import 'package:shared_preferences/shared_preferences.dart';


class MyCustomWidget extends StatefulWidget {
  final BarcodeResult result;
  final int quantity;
  final Function cbDeleted;
  final Function cbOpenResultPage;
  final Function(int)? onQuantityChanged;
  final Map<String, dynamic>? metadata; // Metadata passed as a parameter

  const MyCustomWidget({
    super.key,
    required this.result,
    required this.quantity,
    required this.cbDeleted,
    required this.cbOpenResultPage,
    this.onQuantityChanged,
    this.metadata,
  });

  @override
  State<MyCustomWidget> createState() => _MyCustomWidgetState();
}

class _MyCustomWidgetState extends State<MyCustomWidget> {
  late int quantity;
  final List<String> warehouses = ['Warehouse A', 'Warehouse B', 'Warehouse C'];

  @override
  void initState() {
    super.initState();
    quantity = widget.quantity;
  }

  void _showEditDialog(BuildContext context, BarcodeResult result) {
    // Initialize controllers with existing values
    Map<String, dynamic> metadata = widget.metadata ?? {};

    TextEditingController nameController = TextEditingController(text: metadata['name'] ?? '');
    TextEditingController manufacturerController = TextEditingController(text: metadata['manufacturer'] ?? '');
    TextEditingController locationController = TextEditingController(text: metadata['location'] ?? '');
    String selectedWarehouse = metadata['warehouse'] ?? warehouses[0];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: colorBackground,
              title: Text('Edit Product', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Product Name',
                        labelStyle: TextStyle(color: colorSubtitle),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: colorSubtitle),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: colorBlue),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: manufacturerController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Manufacturer',
                        labelStyle: TextStyle(color: colorSubtitle),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: colorSubtitle),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: colorBlue),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: locationController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Location/Shelf',
                        labelStyle: TextStyle(color: colorSubtitle),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: colorSubtitle),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: colorBlue),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedWarehouse,
                      dropdownColor: colorBackground,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Warehouse',
                        labelStyle: TextStyle(color: colorSubtitle),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: colorSubtitle),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: colorBlue),
                        ),
                      ),
                      items: warehouses.map((String warehouse) {
                        return DropdownMenuItem<String>(
                          value: warehouse,
                          child: Text(warehouse),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedWarehouse = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel', style: TextStyle(color: colorSubtitle)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Save', style: TextStyle(color: colorBlue)),
                  onPressed: () async {
                    // Save the edited data
                    final SharedPreferences prefs = await SharedPreferences.getInstance();
                    List<String> data = prefs.getStringList('barcode_data') ?? [];

                    // Find the index of the barcode with the same text
                    int existingIndex = -1;
                    for (int i = 0; i < data.length; i++) {
                      Map<String, dynamic> jsonMap = jsonDecode(data[i]);
                      BarcodeResult barcodeResult = BarcodeResult.fromJson(jsonMap);
                      if (barcodeResult.text == result.text) {
                        existingIndex = i;
                        break;
                      }
                    }

                    if (existingIndex >= 0) {
                      // Update the metadata
                      Map<String, dynamic> jsonMap = jsonDecode(data[existingIndex]);
                      if (jsonMap['metadata'] == null) {
                        jsonMap['metadata'] = {};
                      }

                      jsonMap['metadata']['name'] = nameController.text;
                      jsonMap['metadata']['manufacturer'] = manufacturerController.text;
                      jsonMap['metadata']['location'] = locationController.text;
                      jsonMap['metadata']['warehouse'] = selectedWarehouse;

                      // Preserve existing quantity
                      if (!jsonMap['metadata'].containsKey('quantity')) {
                        jsonMap['metadata']['quantity'] = widget.quantity;
                      }

                      // Save back to SharedPreferences
                      data[existingIndex] = jsonEncode(jsonMap);
                      await prefs.setStringList('barcode_data', data);

                      // Close the dialog
                      Navigator.of(context).pop();

                      // Refresh the queue
                      if (mounted) {
                        context.findAncestorStateOfType<QueuePageState>()?.loadQueue();
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _incrementQuantity() {
    setState(() {
      quantity++;
    });
    if (widget.onQuantityChanged != null) {
      widget.onQuantityChanged!(quantity);
    }
  }

  void _decrementQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
      if (widget.onQuantityChanged != null) {
        widget.onQuantityChanged!(quantity);
      }
    } else {
      // If quantity would become 0, delete the item
      widget.cbDeleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.black),
      child: Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 16, left: 30),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.metadata != null &&
                            widget.metadata!.containsKey('name') &&
                            widget.metadata!['name'] != null
                        ? widget.metadata!['name']
                        : 'Barcode:',
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    widget.result.text,
                    style: TextStyle(
                        color: colorSubtitle,
                        fontSize: 14,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (widget.metadata != null &&
                      widget.metadata!.containsKey('manufacturer') &&
                      widget.metadata!['manufacturer'] != null)
                    Text(
                      'Manufacturer: ${widget.metadata!['manufacturer']}',
                      style: TextStyle(
                          color: colorSubtitle,
                          fontSize: 12,
                          overflow: TextOverflow.ellipsis),
                    ),
                  if (widget.metadata != null &&
                      widget.metadata!.containsKey('location') &&
                      widget.metadata!['location'] != null)
                    Text(
                      'Location: ${widget.metadata!['location']}',
                      style: TextStyle(
                          color: colorSubtitle,
                          fontSize: 12,
                          overflow: TextOverflow.ellipsis),
                    ),
                  if (widget.metadata != null &&
                      widget.metadata!.containsKey('warehouse') &&
                      widget.metadata!['warehouse'] != null)
                    Text(
                      'Warehouse: ${widget.metadata!['warehouse']}',
                      style: TextStyle(
                          color: colorSubtitle,
                          fontSize: 12,
                          overflow: TextOverflow.ellipsis),
                    ),
                ]),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 20),
                  color: Colors.white,
                  onPressed: _decrementQuantity,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorBackground,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$quantity',
                    style:
                        const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  color: Colors.white,
                  onPressed: _incrementQuantity,
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              color: Colors.white,
              onPressed: () async {
                final RenderBox button =
                    context.findRenderObject() as RenderBox;

                final RelativeRect position = RelativeRect.fromLTRB(
                  100,
                  button.localToGlobal(Offset.zero).dy,
                  40,
                  0,
                );

                final selected = await showMenu(
                  context: context,
                  position: position,
                  color: colorBackground,
                  items: [
                    const PopupMenuItem<int>(
                        value: 0,
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.white),
                        )),
                    const PopupMenuItem<int>(
                        value: 1,
                        child: Text(
                          'Copy',
                          style: TextStyle(color: Colors.white),
                        )),
                    const PopupMenuItem<int>(
                        value: 2,
                        child: Text(
                          'Edit',
                          style: TextStyle(color: Colors.white),
                        )),
                  ],
                );

                if (selected != null) {
                  if (selected == 0) {
                    // delete
                    widget.cbDeleted();
                  } else if (selected == 1) {
                    // copy
                    Clipboard.setData(ClipboardData(
                        text: 'Barcode: ${widget.result.text}'));
                  } else if (selected == 2) {
                    // edit
                    _showEditDialog(context, widget.result);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}