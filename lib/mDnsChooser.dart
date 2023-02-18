import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nsd/nsd.dart';

// A DnsChooser starts an mDNS client session which listens for DrMem
// announcements. As reports come in, a ListView is updated.

class DnsChooser extends StatefulWidget {
  final void Function(Service) updState;

  DnsChooser(this.updState, {Key? key}) : super(key: key);

  @override
  _ChooserState createState() => _ChooserState();
}

// This class holds the state for the DnsChooser.

class _ChooserState extends State<DnsChooser> {
  List<Service> _nodes = [];
  Discovery? discovery;

  void serviceUpdate(Service service, ServiceStatus status) {
    if (status == ServiceStatus.found) {
      setState(() {
        print(service);
        _nodes.add(service);
        _nodes.sort(
          (a, b) => a.name!.compareTo(b.name!),
        );
      });
    } else {
      setState(() {
        _nodes =
            _nodes.where((element) => element.name != service.name).toList();
      });
    }
  }

  // Creates a "tile" that gets displayed in the ListView.

  Widget buildTile(BuildContext context, int index) {
    final info = _nodes[index];
    final String host = info.host ?? "unknown";

    // Determine the location string, which is displayed as "subtitle" in the
    // tile. The location is provided in the mDNS payload as u8 data so we have
    // to convert it to a UTF-8 string. Invlid Unicode characters are replaced
    // with an error character.

    final String? location = info.txt?["location"] != null
        ? Utf8Decoder(allowMalformed: true).convert(info.txt!["location"]!)
        : null;

    // Return a GestureDetector -> Card -> ListTile.

    return GestureDetector(
      onTap: () => widget.updState(info),
      child: Card(
        elevation: 2.0,
        child: ListTile(
            leading: const Icon(Icons.computer_outlined),
            title: Text(info.name ?? "**Unknown**"),
            contentPadding: const EdgeInsets.all(8.0),
            subtitle: location != null ? Text(location) : null,
            trailing: Text("${host}:${info.port}")),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (discovery == null) {
      // Our mDNS listener, `discovery` needs to be initialized. This future
      // starts the background process that monitors mDNS announcements. After
      // the task is started, it registers a callback which receives incoming
      // service announcements.

      final Future<void> fut = (() async {
        discovery = await startDiscovery('_drmem._tcp');
        discovery!.addServiceListener(serviceUpdate);
      })();

      // Return a `FutureBuilder` which only displays a progress indicator.
      // Once the dependent future resolves, this code path won't be used
      // anymore.

      return FutureBuilder(
          future: fut, builder: (_ctxt, _snap) => CircularProgressIndicator());
    } else {
      // If the list of nodes is empty, return a progress indicator. Otherwise,
      // display a ListView containing the contents of the list.

      return _nodes.isEmpty
          ? CircularProgressIndicator()
          : Padding(
              padding: const EdgeInsets.all(4.0),
              child: ListView.builder(
                itemCount: _nodes.length,
                itemBuilder: buildTile,
              ),
            );
    }
  }
}
