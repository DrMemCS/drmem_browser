import 'package:drmem_browser/sheet/sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drmem_browser/model/model.dart';

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
  @override
  void initState() => super.initState();

  @override
  void dispose() => super.dispose();

  // Render the sheet. This consists of building a ListView containing all
  // the rows defined for the sheet. We build all the rows and insert them
  // in the view. This is less efficient, with resources, than using
  // `ListView.builder()` but we do this so we're not contantly restarting
  // subscriptions as rows go in and out of the visible part of the list.

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<Model, AppState>(builder: (context, state) {
      List<Card> groups = state.selected.rows
          .fold([<Widget>[]], (result, e) {
            if (e is EmptyRow) {
              result.add([]);
            } else {
              result.last.add(Padding(
                  key: e.key,
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: e.buildRowRunner(context)));
            }
            return result;
          })
          .where((e) => e.isNotEmpty)
          .map((e) => Card(
              margin: const EdgeInsets.fromLTRB(0.0, 6.0, 0.0, 0.0),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(mainAxisSize: MainAxisSize.max, children: e),
              )))
          .toList();

      return ListView(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          children: groups);
    });
  }
}
