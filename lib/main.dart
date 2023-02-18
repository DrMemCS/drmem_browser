import 'package:flutter/material.dart';
import 'package:nsd/nsd.dart';
import 'mDnsChooser.dart';

void main() {
  runApp(DrMemApp());
}

class DrMemApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Color primeColor = Colors.teal;

    return MaterialApp(
      title: 'DrMem Browser',
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: primeColor)),
      darkTheme: ThemeData.dark()
          .copyWith(useMaterial3: true, colorScheme: ColorScheme.dark()),
      themeMode: ThemeMode.system,
      home: BaseWidget(),
    );
  }
}

class BaseWidget extends StatefulWidget {
  BaseWidget({Key? key}) : super(key: key);

  @override
  _BaseState createState() => _BaseState();
}

class _BaseState extends State<BaseWidget> {
  Service? nodeInfo;

  // This widget is used when the user has selected a node.

  Widget displayNode() {
    return Text('You picked: ${nodeInfo!.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DrMem Browser'),
      ),
      body: Center(
          child: nodeInfo == null
              ? DnsChooser((s) {
                  setState(() {
                    nodeInfo = s;
                  });
                })
              : displayNode()),
    );
  }
}
