import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gql_http_link/gql_http_link.dart';
import "package:gql_websocket_link/gql_websocket_link.dart";
import 'package:ferry/ferry.dart';
import 'package:drmem_browser/model/model.dart';
import 'sheet.dart';

// A SheetRunner widget takes the state of a Sheet and renders it. The Sheet's
// state is a list of BaseRow types. These rows are organized using a Column
// widget.
//
// Each row type has a run behavior that the derived class has to implement.
// Comment rows render their content as Markdown. Device rows start monitoring
// the specified device. If the device is settable, the row allows one to
// send settings to the device. The Chart row has configuration information to
// plot historical data for a set of devices.

class SheetRunner extends StatefulWidget {
  const SheetRunner({Key? key}) : super(key: key);

  @override
  State<SheetRunner> createState() => _SheetRunnerState();
}

// Holds the state for a Runner sheet. A runner sheet is a view where the rows
// are collecting data from DrMem.

class _SheetRunnerState extends State<SheetRunner> {
  // This is a GraphQL endpoint that can be used to make queries and
  // mutations. It gets passed to each row so they can use GraphQL to
  // update their content.

  late final Client _queryClient;

  // This is a GraphQL endpoint that is used to make subscriptions. It gets
  // passed to each row so they can, primarily, obtain device readings.

  late final Client _subClient;

  @override
  void initState() {
    // TODO: The URI is hardcoded to my personal RPi. We need to allow
    // sheets to pick which device on which node, so there should be N
    // GraphQL clients if your network has N nodes.

    _queryClient = Client(
        link: HttpLink(Uri(
                scheme: "http",
                host: "192.168.1.103",
                port: 3000,
                path: "/query")
            .toString()),
        cache: Cache());

    // TODO: The URI is hardcoded to my personal RPi. We need to allow
    // sheets to pick which device on which node, so there should be N
    // GraphQL clients if your network has N nodes.

    _subClient = Client(
        link: WebSocketLink(
            Uri(
              scheme: "ws",
              host: "192.168.1.103",
              port: 3000,
              path: "/subscribe",
            ).toString(),
            reconnectInterval: const Duration(seconds: 1)),
        cache: Cache());

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _queryClient.dispose();
    _subClient.dispose();
  }

  // Render the sheet. This consists of building a ListView containing all
  // the rows defined for the sheet. We build all the rows and insert them
  // in the view. This is less efficient, with resources, than using
  // `ListView.builder()` but we do this so we're not contantly restarting
  // subscriptions as rows go in and out of the visible part of the list.

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PageModel, List<BaseRow>>(builder: (context, state) {
      return ListView(
          padding: const EdgeInsets.all(4.0),
          children:
              // Loop through the rows and convert them to their Widget form.

              state
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(children: [
                          e.buildRowRunner(context, _queryClient, _subClient)
                        ]),
                      ))
                  .toList());
    });
  }
}
