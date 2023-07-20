import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:nsd/nsd.dart';
import 'package:drmem_browser/pkg/drmem_provider/drmem_provider.dart';
import 'package:drmem_browser/model/model.dart';
import 'package:drmem_browser/theme/theme.dart';
import 'mdns_chooser.dart';
import 'node_details.dart';
import 'param.dart';

// The entry point for the application.
Future<void> main() async {
  // Make sure everything is initialized before starting up our persistent
  // storage.

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize (and load) data associated with the persistent store.

  HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: await getApplicationDocumentsDirectory());

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
        child: DrMem(child: const BaseWidget()),
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
    final DrMem drmem = DrMem.of(context);

    drmem.addNode("rpi4", "192.168.1.103", 3000, "/drmem/q", "/drmem/s");

    return Scaffold(
        body: SafeArea(child: _display(context)),
        bottomNavigationBar: _buildNavBar());
  }
}
