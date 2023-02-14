import 'package:flutter/material.dart';
import 'package:multicast_dns/multicast_dns.dart';

// Represents an instance of DrMem, as reported via mDNS.

class NodeEntry {
  final String name;
  final String location;
  final String address;

  NodeEntry(this.name, this.location, this.address);
}

// A DnsChooser starts an mDNS client session which listens for DrMem
// announcements. As reports come in, a ListView is updated.

class DnsChooser extends StatefulWidget {
  DnsChooser({Key? key}) : super(key: key);

  @override
  _ChooserState createState() => _ChooserState();
}

// This class does all the work for the DnsChooser.

class _ChooserState extends State<DnsChooser> {
  List<NodeEntry> _nodes = [];
  final MDnsClient client = MDnsClient();
  late Future<List<NodeEntry>> fut;

  // Start an mDNS client session.

  @override
  void initState() {
    super.initState();

    // Make the initial Future one that connects the client to the mDNS
    // service. It will resolve to `null` so the `FutureBuilder` can do
    // the appropriate refresh of the state and widgets.

    fut = (() async {
      print("starting the mDNS client ...");
      await client.start();
      print("done.");
      return <NodeEntry>[];
    })();
  }

  // Free up resources associated with the mDNS session.

  @override
  void dispose() {
    print("stopping client");
    client.stop();

    super.dispose();
  }

  Future<List<NodeEntry>> getNodes() async {
    final List<NodeEntry> list = [];

    print("querying mDNS for DrMem instances ...");

    final spQuery = ResourceRecordQuery.serverPointer('_drmem._tcp');

    await for (final ptr in client.lookup<PtrResourceRecord>(spQuery)) {
      print("found PtrRec: ${ptr}");

      final sQuery = ResourceRecordQuery.service(ptr.domainName);

      await for (final srv in client.lookup<SrvResourceRecord>(sQuery)) {
        print("found SrvRec: ${srv}");
        setState(
          () {
            list.add(NodeEntry(ptr.domainName.replaceFirst(".${ptr.name}", ""),
                "unknown", "${srv.target}:${srv.port}"));
          },
        );
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NodeEntry>?>(
        initialData: [],
        future: fut,
        builder: (context, snapshot) {
          print("in builder: ${snapshot}");

          if (snapshot.connectionState == ConnectionState.done) {
            // If we have data, then an MDNS record was received. Update the list
            // of nodes.

            if (snapshot.hasData) {
              for (final ii in snapshot.data!) {
                _nodes.add(ii);
              }
              fut = getNodes();
            }
          }

          // Build the widgets based on the current state.

          return _nodes.isEmpty
              ? CircularProgressIndicator()
              : Column(children: [
                  Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Available Nodes',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.left)),
                  Expanded(
                      child: ListView.builder(
                    itemCount: _nodes.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                          title: Text(_nodes[index].name),
                          contentPadding: const EdgeInsets.all(8.0),
                          subtitle: Text(_nodes[index].location),
                          trailing: Text(_nodes[index].address));
                    },
                  ))
                ]);
        });
  }
}
