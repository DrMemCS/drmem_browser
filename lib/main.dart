import 'package:drmem_browser/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nsd/nsd.dart';
import 'mdns_chooser.dart';
import 'node_details.dart';
import 'param.dart';

void main() {
  runApp(const DrMemApp());
}

class DrMemApp extends StatelessWidget {
  const DrMemApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color primeColor = Colors.teal;

    return MaterialApp(
      title: 'DrMem Browser',
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: primeColor)),
      darkTheme: ThemeData.dark()
          .copyWith(useMaterial3: true, colorScheme: const ColorScheme.dark()),
      themeMode: ThemeMode.system,
      home: BlocProvider(
        create: (_) => PageModel(),
        child: const BaseWidget(),
      ),
    );
  }
}

class BaseWidget extends StatefulWidget {
  const BaseWidget({Key? key}) : super(key: key);

  @override
  BaseState createState() => BaseState();
}

class BaseState extends State<BaseWidget> {
  Service? nodeInfo;
  int _selectIndex = 0;

  void changePage(value) {
    setState(() {
      _selectIndex = value;
      nodeInfo = null;
    });
  }

  // Creates the navigation bar.

  BottomNavigationBar _buildNavBar() {
    return BottomNavigationBar(
        currentIndex: _selectIndex,
        onTap: changePage,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: "Nodes"),
          BottomNavigationBarItem(
              icon: Icon(Icons.web_stories), label: "Sheets"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Logic"),
        ]);
  }

  // Displays the list of nodes or the "details" subpage.

  Widget _displayNodes(BuildContext context) {
    return nodeInfo == null
        ? DnsChooser((s) => setState(() => nodeInfo = s))
        : displayNode(nodeInfo!);
  }

  // This page will be used to edit the Logic in a DrMem instance.

  Widget _displayLogic() {
    return const Text("TODO: Edit logic.");
  }

  // This method determine which widget should be the main body of the display
  // based on the value of the navbar.

  Widget _buildBody(BuildContext context) {
    return SafeArea(
      child: Center(
          child: _selectIndex == 0
              ? _displayNodes(context)
              : (_selectIndex == 1 ? displayParameters() : _displayLogic())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(child: Center(child: _display(context))),
        bottomNavigationBar: _buildNavBar());
  }
}
