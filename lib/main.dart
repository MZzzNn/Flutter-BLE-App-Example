import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:test_bluetooth_app/screens/main/main_screen.dart';

import 'home/home_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter BLE Example',
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  BluetoothDevice? device;
  List<BluetoothService>? services;
  BluetoothCharacteristic? characteristic;
  StreamSubscription? scanSubscription;
  StreamSubscription? characteristicSubscription;

  final String SERVICE_UUID = "0000180c-0000-1000-8000-00805f9b34fb";
  final String CHARACTERISTIC_UUID = "00002a58-0000-1000-8000-00805f9b34fb";

  String status = "Not connected";
  int number = 1;

  @override
  void initState() {
    super.initState();
    flutterBlue.isOn.then((isOn) {
      if (isOn) {
        scanForDevices();
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Error"),
              content: const Text("Bluetooth is not turned on"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }
    });
  }

  @override
  void dispose() {
    _disbose();
    super.dispose();
  }
  _disbose() {
    scanSubscription?.cancel();
    characteristicSubscription?.cancel();
    super.dispose();
  }

  void scanForDevices() {
    scanSubscription = flutterBlue
        .scan(
      timeout: const Duration(seconds: 5),
      scanMode: ScanMode.balanced,
    ).listen(
      (scanResult) async {
        log("Device name: ${scanResult.device.name} , Device ID: ${scanResult.device.id},serviceUuids: ${scanResult.advertisementData.serviceUuids} ");
        if (scanResult.device.name.isNotEmpty && scanResult.advertisementData.serviceUuids.contains(SERVICE_UUID)) {
          setState(() {
            device = scanResult.device;
          });
          scanSubscription?.cancel();
          await connectToDevice();
        }
      },
      onError: (error) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Error"),
              content: Text(error.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> connectToDevice() async {
    if (device != null) {
      setState(() {
        status = "Connecting...";
      });
      await device!.connect();
      await discoverServices();
    }
  }

  Future<void> discoverServices() async {
    if (device != null) {
      setState(() {
        status = "Discovering services...";
      });
      services = await device!.discoverServices();
      await discoverCharacteristics();
    }
  }

  Future<void> discoverCharacteristics() async {
    log("services: $services");
    if (services != null && services!.isNotEmpty) {
      for (BluetoothService service in services!) {
        if (service.uuid.toString() == SERVICE_UUID) {
          for (BluetoothCharacteristic c in service.characteristics) {
            if (c.uuid.toString() == CHARACTERISTIC_UUID) {
              log("characteristic: $c");
              setState(() {
                characteristic = c;
                status = "Connected";
              });
              break;
            }
          }
        }
      }
    }
  }

  bool get isConnected => status == "Connected";

  _turnOnBluetooth() async {

    await flutterBlue.turnOn();
    scanForDevices();
  }
  _turnOffBluetooth() async{
    await flutterBlue.turnOff();
    await device?.disconnect();
    _disbose();
    setState(() {status = "Not connected";});
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Flutter BLE Example", style: TextStyle(color: Colors.black)),
        actions: [
          // toggle button to connect/disconnect
          StreamBuilder<BluetoothState>(
            stream: FlutterBluePlus.instance.state,
            initialData: BluetoothState.unknown,
            builder: (c, snapshot) {
              if (snapshot.data != BluetoothState.on) {
                return IconButton(
                    icon: const Icon(Icons.bluetooth_disabled, color: Colors.red),
                    onPressed: () async => await _turnOnBluetooth()
                );
              } else {
                return IconButton(
                    icon: const Icon(Icons.bluetooth,color: Colors.green),
                    onPressed: () async => await _turnOffBluetooth()
                );
              }
            },
          ),
        ],
      ),
      body: _statusWidget(status, number),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (int i = 1; i <= 5; i++)...{
            FloatingActionButton(
              onPressed: () async {
                log("characteristic: $characteristic ,send number: $i , code: ${[i]}");
                if (characteristic != null) {
                  setState(() {
                    number = i;
                  });
                  await characteristic!.write([i]);
                }
              },
              child: Text(i.toString()),
            ),
            const SizedBox(height: 8),
          }
        ],
      )
    );
  }
}


Widget _statusWidget(String status, int number) {
  if (status == "Not connected") {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bluetooth_disabled, size: 100, color: Colors.red),
          const SizedBox(height: 8),
          Text("Status: $status"),
        ],
      ),
    );
  } else if (status == "Connecting..." || status == "Discovering services...") {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 8),
          Text("Status: $status"),
        ],
      ),
    );
  } else {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bluetooth_connected, size: 100, color: Colors.green),
          const SizedBox(height: 8),
          Text("Status: $status"),
          const SizedBox(height: 8),
          Text("Send Number: $number"),
        ],
      ),
    );
  }
}