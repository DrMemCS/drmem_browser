import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:drmem_browser/pkg/drmem_provider/drmem_provider.dart';
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
  final EdgeInsets headerInsets =
      const EdgeInsets.only(top: 20.0, bottom: 8.0, left: 8.0);
  final EdgeInsets all8 = const EdgeInsets.all(8.0);

  // Returns a widget that serves as a section header.

  Widget header(BuildContext context, String label) {
    final ThemeData td = Theme.of(context);

    return Padding(
        padding: const EdgeInsets.only(
            top: 16.0, bottom: 8.0, left: 4.0, right: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(4.0, 0.0, 4.0, 4.0),
              child: Text(label, style: td.textTheme.bodyLarge),
            )
          ],
        ));
  }

  // Returns a widget that renders property information. This consists of a
  // dimmed label followed by its value in a highlighted color.

  Widget buildProperty(
      BuildContext context, String label, int labelFlex, String? value) {
    final ThemeData td = Theme.of(context);

    return Row(
      children: [
        Flexible(
          fit: FlexFit.tight,
          flex: labelFlex,
          child: Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(color: td.hintColor)),
          ),
        ),
        Flexible(
            fit: FlexFit.tight,
            flex: 20,
            child: Text(value ?? "unknown",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: td.colorScheme.primary)))
      ],
    );
  }

  // Returns a widget that displays the title of the page. The title
  // includes a gratuitous icon followed by the name of the node.

  Widget titleWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
      child: Row(children: [
        const Icon(Icons.developer_board),
        Container(width: 12.0),
        Text(widget.node.name ?? "** Unknown Name **",
            style: Theme.of(context).textTheme.titleLarge),
      ]),
    );
  }

  // Build the widget.

  @override
  Widget build(BuildContext context) {
    final DrMem drmem = DrMem.of(context);

    final Service info = widget.node;
    final DateTime? bootTime =
        DateTime.tryParse(propToString(info, "boot-time") ?? "");
    const int nodePropFlex = 8;
    const int gqlPropFlex = 14;

    return Padding(
      padding: all8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleWidget(context),
          Expanded(
            child: SingleChildScrollView(
              clipBehavior: Clip.hardEdge,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildProperty(context, "version", nodePropFlex,
                      propToString(info, "version")),
                  buildProperty(context, "address", nodePropFlex,
                      "${info.host}:${info.port}"),
                  buildProperty(context, "location", nodePropFlex,
                      propToString(info, "location")),
                  buildProperty(context, "boot time", nodePropFlex,
                      bootTime?.toLocal().toString() ?? "unknown"),
                  header(context, "GraphQL Endpoints"),
                  buildProperty(context, "queries", gqlPropFlex,
                      propToString(info, "queries")),
                  buildProperty(context, "mutations", gqlPropFlex,
                      propToString(info, "mutations")),
                  buildProperty(context, "subscriptions", gqlPropFlex,
                      propToString(info, "subscriptions")),
                  header(context, "Drivers"),
                  FutureBuilder(
                    future: drmem.getDriverInfo("rpi4"),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return _DriversListView(drivers: snapshot.data!);
                      } else if (snapshot.hasError) {
                        return const Icon(Icons.error_outline,
                            color: Colors.red);
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                  header(context, "Devices"),
                  FutureBuilder(
                    future: drmem.getDeviceInfo("rpi4", device: "*"),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return _DevicesListView(devices: snapshot.data!);
                      } else if (snapshot.hasError) {
                        return const Icon(Icons.error_outline,
                            color: Colors.red);
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Builds a row of driver information, including the Help button which brings
// up a window containing the description text for the driver.

Padding buildDrvInfoRow(DriverInfo info, BuildContext context) {
  final ThemeData td = Theme.of(context);

  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Flexible(
          flex: 8,
          fit: FlexFit.tight,
          child: Text(info.name,
              textAlign: TextAlign.end,
              style: TextStyle(color: td.colorScheme.primary))),
      Container(width: 10.0),
      Flexible(
          flex: 16,
          fit: FlexFit.tight,
          child: Text(info.summary, style: TextStyle(color: td.hintColor))),
      Container(width: 10.0),
      IconButton(
          color: td.colorScheme.secondary,
          onPressed: () async {
            return showDialog(
              context: context,
              builder: (context) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                      color: Theme.of(context).cardColor,
                      child: Column(
                        children: [
                          Expanded(child: Markdown(data: info.description)),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Close")),
                          )
                        ],
                      )),
                );
              },
            );
          },
          icon: const Icon(Icons.help))
    ]),
  );
}

Widget _buildChip(ThemeData td, String content) {
  return Container(
    decoration: BoxDecoration(
        border: Border.all(color: td.hintColor),
        borderRadius: BorderRadius.circular(8.0),
        shape: BoxShape.rectangle,
        color: td.disabledColor),
    child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text(content, style: td.textTheme.labelMedium)),
  );
}

String makeDateChipContent(String label, DateTime dt) {
  final year = dt.year.toString().padLeft(4, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final day = dt.day.toString().padLeft(2, '0');
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');

  return "$label: $year-$month-$day, $hour:$minute";
}

List<Widget> _buildChips(BuildContext context, DevInfo info) {
  final ThemeData td = Theme.of(context);
  final List<Widget> tmp = [
    _buildChip(td, info.settable ? "settable" : "read-only")
  ];

  // TODO: Add this back in.
  //
  // if (info.driver != null) {
  //   tmp.add(_buildChip(td, "driver: ${info.driver.name}"));
  // }

  if (info.units != null) {
    tmp.add(_buildChip(td, "units: ${info.units}"));
  }

  // If there's a "history" record with this device, add chips that display
  // this information.

  if (info.history != null) {
    tmp.add(_buildChip(td, "points: ${info.history!.totalPoints}"));
    tmp.add(_buildChip(
        td, makeDateChipContent("oldest", info.history!.oldest.stamp)));
    tmp.add(_buildChip(
        td, makeDateChipContent("last", info.history!.newest.stamp)));
  }

  return tmp;
}

Padding buildDevInfoRow(DevInfo info, BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(left: 20.0, bottom: 16.0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onDoubleTap: () {
            Future.wait([Clipboard.setData(ClipboardData(text: info.name))]);
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Added ${info.name} to clipboard")));
          },
          child: Text(info.name,
              textAlign: TextAlign.start,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 4.0, left: 20.0, right: 20.0),
        child: SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: 10.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.end,
            children: _buildChips(context, info),
          ),
        ),
      )
    ]),
  );
}

// Local widget which displays a list of drivers.

class _DriversListView extends StatelessWidget {
  final List<DriverInfo> drivers;

  const _DriversListView({Key? key, required this.drivers}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> d = drivers.map((e) => buildDrvInfoRow(e, context)).toList();
    List<Widget> all = [
      Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 0.0, 8.0, 16.0),
        child: Text(
            "This node is configured with these ${drivers.length} drivers.",
            style: TextStyle(color: Theme.of(context).hintColor)),
      )
    ];

    all.addAll(d);

    return Column(children: all);
  }
}

// Local widget which displays a list of drivers.

class _DevicesListView extends StatelessWidget {
  final List<DevInfo> devices;

  const _DevicesListView({Key? key, required this.devices}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Iterable<Widget> d = devices.map((e) => buildDevInfoRow(e, context));
    List<Widget> all = [
      Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 0.0, 8.0, 16.0),
        child: Text(
            "This node provides ${devices.length} devices. Double tap on a device name to copy it to the clipboard.",
            style: TextStyle(color: Theme.of(context).hintColor)),
      )
    ];

    all.addAll(d);
    return Column(children: all);
  }
}
// This public function returns the widget that displays node information.

Widget displayNode(Service node) => _NodeInfo(node);
