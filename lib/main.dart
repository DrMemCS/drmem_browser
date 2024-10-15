import "dart:developer" as dev;

import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drmem_provider/drmem_provider.dart';

import 'package:drmem_browser/model/model_events.dart';
import 'package:drmem_browser/model/model.dart';
import 'package:drmem_browser/theme/theme.dart';
import 'package:drmem_browser/mdns_chooser.dart';
import 'package:drmem_browser/param.dart';

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
  const DrMemApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'DrMem Browser',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // Provides the app model. This needs to be near the top of the widget
      // tree so that all subpages have access to the model data.

      home: BlocProvider(
        lazy: false,
        create: (_) => Model(),
        child: const DrMem(child: _NodeUpdater(child: _BaseWidget())),
      ));
}

class _NodeUpdater extends StatelessWidget {
  final Widget child;

  const _NodeUpdater({required this.child});

  @override
  Widget build(BuildContext context) {
    final clientId = context.read<Model>().state.clientId;

    dev.log("adding _NodeUpdater to context", name: "foundation");

    // Register all the known DrMem nodes with the `DrMem` widget.

    context.read<Model>().state.getNodeNames().forEach((node) => DrMem.addNode(
        context, context.read<Model>().state.getNodeInfo(node)!, clientId));

    return FutureBuilder(
        future: DrMem.mdnsSubscribe(context),
        builder: (context, snapshot) {
          // If the snapshot has data, then the future completed. The value
          // returned from the future is the stream of mDNS announcements.

          if (snapshot.hasData) {
            dev.log("subscribed to mDNS", name: "foundation");
            return StreamBuilder(
                stream: snapshot.data,
                builder: (context, snapshot) {
                  // If the snapshot from the stream has data, then it's a node
                  // announcement. Report the information to the application.

                  if (snapshot.hasData) {
                    final nodeState =
                        snapshot.data!.bootTime == null ? "lost" : "found";

                    dev.log("node ${snapshot.data!.name} was $nodeState",
                        name: "foundation");

                    // Add the node to our persistent storage.

                    context.read<Model>().add(AddNode(snapshot.data!));

                    // Have DrMem create client connection objects to the node.

                    DrMem.addNode(context, snapshot.data!, clientId);
                  }
                  return child;
                });
          } else {
            return const CircularProgressIndicator();
          }
        });
  }
}

class _BaseWidget extends StatefulWidget {
  const _BaseWidget();

  @override
  _BaseState createState() => _BaseState();
}

class _BaseState extends State<_BaseWidget> {
  int _selectIndex = 0;

  void changePage(value) => setState(() => _selectIndex = value);

  // Creates the navigation bar. Right now it creates three icons to click on.

  BottomNavigationBar _buildNavBar() => BottomNavigationBar(
          currentIndex: _selectIndex,
          onTap: changePage,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.devices), label: "Nodes"),
            BottomNavigationBarItem(
                icon: Icon(Icons.web_stories), label: "Sheets"),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: "Settings"),
          ]);

  Widget _display(BuildContext context) => switch (_selectIndex) {
        1 => const ParamPage(),
        2 => Container(),
        _ => const DnsChooser()
      };

  @override
  Widget build(BuildContext context) => Scaffold(
      body: SafeArea(child: _display(context)),
      bottomNavigationBar: _buildNavBar());
}
