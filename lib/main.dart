import 'package:flutter/material.dart';
import 'mDnsChooser.dart';

void main() {
  runApp(DrMemApp());
}

class DrMemApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DrMem Browser',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
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
  String? _node;

  // This widget is used when the user has selected a node.

  Widget displayNode(BuildContext context) {
    return Text('You picked: $_node');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DrMem Browser'),
      ),
      body: Center(child: _node == null ? DnsChooser() : displayNode(context)),
    );
  }
}
