import 'package:flutter/material.dart';
import 'package:nsd/nsd.dart';
import 'mDnsChooser.dart' show propToString;

Widget header(BuildContext context, String label) {
  return Padding(
    padding: const EdgeInsets.only(top: 16.0),
    child: Text(label, style: Theme.of(context).textTheme.titleMedium),
  );
}

Widget infoSection(BuildContext context, String label, Widget? child) {
  return Column(
    children: [header(context, label)],
  );
}

Widget buildProperty(BuildContext context, String label, String? value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style: TextStyle(color: Theme.of(context).secondaryHeaderColor)),
      Text("${value ?? "unknown"}")
    ],
  );
}

// Creates a widget that displays the information associated with a node.

Widget displayNode(BuildContext context, Service node) {
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
            Text(node.name ?? "** Unknown Name **",
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
                  context, "location", propToString(node, "location")),
              buildProperty(context, "address", "${node.host}:${node.port}"),
              header(context, "GraphQL Endpoints"),
              buildProperty(context, "queries", propToString(node, "queries")),
              buildProperty(
                  context, "mutations", propToString(node, "mutations")),
              buildProperty(context, "subscriptions",
                  propToString(node, "subscriptions")),
            ],
          ),
        ),
        infoSection(context, "Drivers", null),
        infoSection(context, "Devices", null),
      ],
    ),
  );
}
