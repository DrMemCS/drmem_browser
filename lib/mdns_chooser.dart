import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nsd/nsd.dart';

String? propToString(Service info, String key) {
  final Uint8List? tmp = info.txt?[key];

  return tmp != null
      ? const Utf8Decoder(allowMalformed: true).convert(tmp)
      : null;
}

// A DnsChooser starts an mDNS client session which listens for DrMem
// announcements. As reports come in, a ListView is updated.

class DnsChooser extends StatefulWidget {
  final void Function(Service) updState;

  const DnsChooser(this.updState, {Key? key}) : super(key: key);

  @override
  ChooserState createState() => ChooserState();
}

// This class holds the state for the DnsChooser.

class ChooserState extends State<DnsChooser> {
  List<Service> _nodes = [];
  Discovery? discovery;

  @override
  void dispose() {
    if (discovery != null) {
      discovery!.removeServiceListener(serviceUpdate);
      developer.log("unregistered", name: "mdns.announce");
      stopDiscovery(discovery!);
      developer.log("stopped", name: "mdns.connection");
      discovery = null;
    }
    super.dispose();
  }

  // Updates the list of nodes based on the new ServiceStatus. The Service is
  // initially removed from the list because we occasionally get two "found"
  // reports and the entry would be added twice.

  void serviceUpdate(Service service, ServiceStatus status) {
    // If the node was configured with a preferred address, replace the host
    // and port fields with the configured one.

    final List<String>? preferred =
        propToString(service, "pref-addr")?.split(":");

    if (preferred != null && preferred.length == 2) {
      service = Service(
          name: service.name,
          type: service.type,
          host: preferred[0],
          txt: service.txt,
          addresses: service.addresses,
          port: int.tryParse(preferred[1]) ?? service.port);
    } else

    // If the host name ends with a period (like on MacOS), remove it. Since
    // `Service` is immutable, we have to make a new instance and copy all
    // the fields.

    if (service.host!.endsWith(".")) {
      service = Service(
          name: service.name,
          type: service.type,
          host: service.host!.substring(0, service.host!.length - 1),
          txt: service.txt,
          addresses: service.addresses,
          port: service.port);
    }

    List<Service> tmp =
        _nodes.where((element) => element.name != service.name).toList();

    if (status == ServiceStatus.found) {
      developer.log("host ${service.name}, port ${service.port}",
          name: "mdns.announce.add");
      tmp.add(service);
      tmp.sort((a, b) => a.name!.compareTo(b.name!));
    } else {
      developer.log("host ${service.name}, port ${service.port}",
          name: "mdns.announce.remove");
    }
    setState(() => _nodes = tmp);
  }

  // Creates a "tile" that gets displayed in the ListView.

  Widget buildTile(BuildContext context, int index) {
    final info = _nodes[index];
    final String host = info.host ?? "unknown";
    final ThemeData td = Theme.of(context);

    // Determine the location string, which is displayed as "subtitle" in the
    // tile. The location is provided in the mDNS payload as u8 data so we have
    // to convert it to a UTF-8 string. Invlid Unicode characters are replaced
    // with an error character.

    final String? location = propToString(info, "location");

    // Return a GestureDetector -> Card -> ListTile.

    return GestureDetector(
      onTap: () => widget.updState(info),
      child: Card(
        elevation: 2.0,
        child: ListTile(
            key: Key(host),
            leading: Icon(Icons.developer_board, color: td.colorScheme.primary),
            title: Text(info.name ?? "**Unknown**",
                style: td.textTheme.titleLarge),
            contentPadding: const EdgeInsets.all(8.0),
            subtitle: location != null
                ? Text(location,
                    style: td.textTheme.bodySmall!
                        .copyWith(color: td.colorScheme.tertiary))
                : null,
            trailing: Text("$host : ${info.port}",
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: td.textTheme.bodySmall)),
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
        developer.log("started", name: "mdns.connection");
        discovery!.addServiceListener(serviceUpdate);
        developer.log("registered", name: "mdns.announce");
      })();

      // Return a `FutureBuilder` which only displays a progress indicator.
      // Once the dependent future resolves, this code path won't be used
      // anymore.

      return FutureBuilder(
          future: fut,
          builder: (ctxt, snap) => const Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Setting up mDNS ..."),
                  ),
                  CircularProgressIndicator(),
                ],
              )));
    } else {
      // If the list of nodes is empty, return a progress indicator. Otherwise,
      // display a ListView containing the contents of the list.

      return _nodes.isEmpty
          ? const Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Listening for nodes ..."),
                ),
                CircularProgressIndicator(),
              ],
            ))
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
