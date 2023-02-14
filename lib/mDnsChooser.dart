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
  List<String> _nodes = [];
  final MDnsClient client = MDnsClient();
  late Future<String?> fut;

  // Start an mDNS client session.

  @override
  void initState() {
    super.initState();

    // Make the initial Future one that connects the client to the mDNS
    // service. It will resolve to `null` so the `FutureBuilder` can do
    // the appropriate refresh of the state and widgets.

    fut = (() async {
      await client.start();
      return null;
    })();
  }

  // Free up resources associated with the mDNS session.

  @override
  void dispose() {
    client.stop();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
        future: fut,
        builder: (context, snapshot) {
          // If we have data, then an MDNS record was received. Update the list
          // of nodes.

          if (snapshot.hasData) {
            setState(() {
              _nodes.add(snapshot.data!);
            });
          }

          // Build the widgets based on the current state.

          return _nodes.isEmpty
              ? const CircularProgressIndicator()
              : Column(children: [
                  Text('Available Nodes'),
                  Expanded(
                      child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _nodes.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Text('${_nodes[index]}');
                    },
                  ))
                ]);
        });
  }
}
