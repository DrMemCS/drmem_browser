import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nsd/nsd.dart';
import 'package:drmem_provider/drmem_provider.dart';

import 'package:drmem_browser/model/model.dart';

String? propToString(Service info, String key) {
  final Uint8List? tmp = info.txt?[key];

  return tmp != null
      ? const Utf8Decoder(allowMalformed: true).convert(tmp)
      : null;
}

// Creates a widget that displays summary information for a node.

class NodeTile extends StatelessWidget {
  final String name;

  const NodeTile({required this.name, super.key});

  @override
  Widget build(BuildContext context) {
    final info = DrMem.getNodeInfo(context: context, node: name);
    final ThemeData td = Theme.of(context);

    // Return a GestureDetector -> Card -> ListTile.

    return GestureDetector(
      key: Key(name),
      onTap: info != null ? () => () : null,
      child: Card(
        elevation: 2.0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: info != null
              ? Row(children: [
                  Icon(Icons.developer_board,
                      color: info.announcing
                          ? td.colorScheme.secondary
                          : td.colorScheme.tertiary),
                  Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(info.name,
                                    style: td.textTheme.titleLarge),
                              ),
                              Text("${info.addr.host} : ${info.addr.port}",
                                  softWrap: true,
                                  style: td.textTheme.bodySmall!
                                      .copyWith(color: td.colorScheme.tertiary))
                            ]),
                      )),
                  Expanded(
                      flex: 2,
                      child: Text(info.location,
                          softWrap: true,
                          style: td.textTheme.bodyMedium!
                              .copyWith(color: td.colorScheme.tertiary))),
                  BlocBuilder<Model, AppState>(
                      builder: (context, state) => state.defaultNode ==
                              info.name
                          ? Icon(Icons.star, color: td.colorScheme.secondary)
                          : GestureDetector(
                              onTap: () => state.defaultNode = info.name,
                              child: Icon(Icons.star_border_outlined,
                                  color: td.colorScheme.tertiary)))
                ])
              : Text("ERROR: No info for node $name."),
        ),
      ),
    );
  }
}

// A DnsChooser starts an mDNS client session which listens for DrMem
// announcements. As reports come in, a ListView is updated.

class DnsChooser extends StatelessWidget {
  const DnsChooser({super.key});

  // Returns a function that creates a "tile". The returned function will use
  // the list of node names, that was passed to this function, to use to
  // lookup the node info.

  Widget? Function(BuildContext, int) buildTile(List<String> nodes) =>
      (BuildContext context, int index) => NodeTile(name: nodes[index]);

  // Displays content for when no DrMem nodes are detected or registered.

  Widget waitingWidget() => const Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Listening for nodes ..."),
          ),
          CircularProgressIndicator(),
        ],
      ));

  // Builds the view based on the contents of the nodes table.

  @override
  Widget build(BuildContext context) {
    final nodes = DrMem.getNodeNames(context: context).toList()..sort();

    return nodes.isEmpty
        ? waitingWidget()
        : Padding(
            padding: const EdgeInsets.all(4.0),
            child: ListView.builder(
              itemCount: nodes.length,
              itemBuilder: buildTile(nodes),
            ),
          );
  }
}
