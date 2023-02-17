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
          : ListView.builder(
              itemCount: _nodes.length,
              itemBuilder: (BuildContext context, int index) {
                final info = _nodes[index];
                final String? location = info.txt?["location"] != null
                    ? Utf8Decoder(allowMalformed: true)
                        .convert(info.txt!["location"]!)
                    : null;
                final String host = info.host ?? "unknown";

                return GestureDetector(
                  onTap: () => widget.updState(info),
                  child: Card(
                    elevation: 4.0,
                    child: ListTile(
                        iconColor: Theme.of(context).colorScheme.tertiary,
                        leading: const Icon(Icons.computer_outlined),
                        title: Text(info.name ?? "**Unknown**"),
                        contentPadding: const EdgeInsets.all(8.0),
                        subtitle: location != null ? Text(location) : null,
                        trailing: Text(
                            "${host.substring(0, host.length - 1)}:${info.port}")),
                  ),
                );
              },
            );
    }
  }
}
