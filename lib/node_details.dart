import 'package:flutter/material.dart';
import 'package:nsd/nsd.dart';
import 'mdns_chooser.dart';

// This is an immutable Widget that displays node information.

class _NodeInfo extends StatefulWidget {
  final Service node;

  const _NodeInfo(this.node, {Key? key}) : super(key: key);

  @override
  _State createState() => _State();
}

// This state object is necessary because, to display all the node information,
// we need to make two GraphQL requests to the node.

class _State extends State<_NodeInfo> {
  Widget header(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget infoSection(BuildContext context, String label, Widget? child) {
    return Column(
      children: [header(context, label)],
    );
  }

  Widget buildProperty(BuildContext context, String label, String? value) {
    final ThemeData td = Theme.of(context);

    return Row(
      children: [
        Flexible(
          fit: FlexFit.tight,
          flex: 8,
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(color: td.hintColor)),
        ),
        Container(width: 10.0),
        Flexible(
            fit: FlexFit.tight,
            flex: 20,
            child: Text(value ?? "unknown",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: td.indicatorColor)))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(children: [
              const Padding(
                padding: EdgeInsets.only(left: 8.0, right: 16.0),
                child: Icon(Icons.developer_board),
              ),
              Text(widget.node.name ?? "** Unknown Name **",
                  style: Theme.of(context).textTheme.titleLarge),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildProperty(
                    context, "location", propToString(widget.node, "location")),
                buildProperty(context, "address",
                    "${widget.node.host}:${widget.node.port}"),
                header(context, "GraphQL Endpoints"),
                buildProperty(
                    context, "queries", propToString(widget.node, "queries")),
                buildProperty(context, "mutations",
                    propToString(widget.node, "mutations")),
                buildProperty(context, "subscriptions",
                    propToString(widget.node, "subscriptions")),
              ],
            ),
          ),
          infoSection(context, "Drivers", null),
          infoSection(context, "Devices", null),
        ],
      ),
    );
  }
}

// This public function returns the widget that displays node information.

Widget displayNode(Service node) => _NodeInfo(node);
