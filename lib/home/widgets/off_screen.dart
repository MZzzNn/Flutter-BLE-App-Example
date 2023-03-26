

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../home_screen.dart';
import 'find_devices_screen.dart';

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key? key, this.state}) : super(key: key);

  final BluetoothState? state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
              style: Theme.of(context)
                  .primaryTextTheme
                  .subtitle2
                  ?.copyWith(color: Colors.white),
            ),
            ElevatedButton(
              onPressed: Platform.isAndroid
                  ? () async {
                print("111111111");
                try {
                  print('2222222222222');
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FindDevicesScreen(),
                      ));
                  var res = await FlutterBluePlus.instance.turnOn();
                  print("==== res === " + res.toString());
                  if (res) {}
                  // Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (context) => FindDevicesScreen(),
                  //     ));
                } catch (e) {
                  print("===== Excepton ====  " + e.toString());
                }
              }
                  : null,
              child: const Text('TURN ON'),
            ),
          ],
        ),
      ),
    );
  }
}
