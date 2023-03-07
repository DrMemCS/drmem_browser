import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nsd/nsd.dart';
import 'package:drmem_browser/model/model.dart';
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
    const TextTheme defTextTheme = TextTheme(
        titleSmall: TextStyle(fontSize: 16.0),
        titleMedium: TextStyle(fontSize: 18.0),
        titleLarge: TextStyle(fontSize: 24.0),
        bodySmall: TextStyle(fontSize: 14.0),
        bodyMedium: TextStyle(fontSize: 18.0),
        bodyLarge: TextStyle(fontSize: 20.0));

    return MaterialApp(
      title: 'DrMem Browser',
      theme: ThemeData(
          useMaterial3: true,
          textTheme: defTextTheme,
          colorScheme: ColorScheme.fromSeed(seedColor: primeColor)),
      darkTheme: ThemeData.dark()
          .copyWith(useMaterial3: true, textTheme: defTextTheme),
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

  // Creates the navigation bar. Right now it creates three icons to click on.

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

  Widget _display(BuildContext context) {
    switch (_selectIndex) {
      case 1:
        return displayParameters();

      case 2:
        return _displayLogic();

      case 0:
      default:
        return _displayNodes(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(child: Center(child: _display(context))),
        bottomNavigationBar: _buildNavBar());
  }
}
