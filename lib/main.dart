import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nsd/nsd.dart';
import 'package:drmem_browser/model/model.dart';
import 'package:drmem_browser/theme/theme.dart';
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
    return MaterialApp(
      title: 'DrMem Browser',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,

      // Provides the app model. This needs to be near the top of the widget
      // tree so that all subpages have access to the model data.

      home: BlocProvider(
        create: (_) => Model(),
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
        ]);
  }

  // Displays the list of nodes or the "details" subpage.

  Widget _displayNodes(BuildContext context) {
    return nodeInfo == null
        ? DnsChooser((s) => setState(() => nodeInfo = s))
        : displayNode(nodeInfo!);
  }

  Widget _display(BuildContext context) {
    switch (_selectIndex) {
      case 1:
        return displayParameters();

      case 0:
      default:
        return _displayNodes(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(child: _display(context)),
        bottomNavigationBar: _buildNavBar());
  }
}
