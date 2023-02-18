import 'package:flutter/material.dart';
import 'package:nsd/nsd.dart';
import 'mDnsChooser.dart';
import 'node_details.dart';

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
  int _selectIndex = 0;

  // Creates the navigation bar.

  BottomNavigationBar _buildNavBar() {
    return BottomNavigationBar(
        currentIndex: _selectIndex,
        onTap: (value) {
          setState(() {
            _selectIndex = value;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: "Nodes"),
          BottomNavigationBarItem(
              icon: Icon(Icons.web_stories), label: "Sheets"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Logic"),
        ]);
  }

  // Displays the list of nodes or the "details" subpage.

  Widget _displayNodes() {
    return nodeInfo == null
        ? DnsChooser((s) {
            setState(() {
              nodeInfo = s;
            });
          })
        : displayNode(nodeInfo!);
  }

  // Display "parameter page".

  Widget _displayParameters() {
    return Text("TODO: Acquire data from DrMem.");
  }

  // This page will be used to edit the Logic in a DrMem instance.

  Widget _displayLogic() {
    return Text("TODO: Edit logic.");
  }

  // This method determine which widget should be the main body of the display
  // based on the value of the navbar.

  Widget _buildBody() {
    return Center(
        child: _selectIndex == 0
            ? _displayNodes()
            : (_selectIndex == 1 ? _displayParameters() : _displayLogic()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: _buildNavBar(),
    );
  }
}
