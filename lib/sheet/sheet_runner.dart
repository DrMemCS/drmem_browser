import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gql_http_link/gql_http_link.dart';
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

class _SheetRunnerState extends State<SheetRunner> {
  late final _client = Client(
      link: HttpLink(
          Uri(scheme: "http", host: "192.168.1.103", port: 3000, path: "/query")
              .toString()),
      cache: Cache());

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PageModel, List<BaseRow>>(builder: (context, state) {
      return ListView(
          padding: const EdgeInsets.all(4.0),
          children: state
              .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(children: [e.buildRowRunner(context, _client)]),
                  ))
              .toList());
    });
  }
}
