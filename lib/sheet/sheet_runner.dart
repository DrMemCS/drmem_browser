import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:drmem_browser/model/model.dart';
import 'package:drmem_browser/sheet/row.dart';

// A SheetRunner widget takes the state of a Sheet and renders it. The Sheet's
// state is a list of BaseRow types. These rows are organized using a Column
// widget.
//
// Each row type has a run behavior that the derived class has to implement
// (comment rows render their content as Markdown; device rows start monitoring
// the specified device, etc.) If the device is settable, the row allows one to
// send settings to the device. The Chart row has configuration information to
// plot historical data for a set of devices.

class SheetRunner extends StatelessWidget {
  const SheetRunner({super.key});

  // Render the sheet. This consists of building a ListView containing `Card`s
  // which, in turn, contain a group of widgets. `EmptyRow` rows define the
  // boundary of groups.
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<Model, AppState>(builder: (context, state) {
        final List<Card> groups = state.selected.rows

            // Build a list of lists of widgets. We start with a list that has
            // one empty list. As we iterate across the row types on the page,
            // we do one of two things:
            //
            // 1) If the row is an `EmptyRow`, it signifies a new Card. In this
            //    case we append an empty list.
            // 2) Any other row type, we append it to the list at the end of
            //    the list.

            .fold(
                [<Widget>[]],
                (result, e) => switch (e) {
                      EmptyRow() => result..add([]),
                      DeviceRow() || PlotRow() || CommentRow() => result
                        ..last.add(Padding(
                            key: e.key,
                            padding: const EdgeInsets.only(bottom: 2.0),
                            child: e.buildRowRunner(context)))
                    })

            // As we iterate through the list of widget lists, this method will
            // filter out the empty lists.

            .where((e) => e.isNotEmpty)

            // All we have left are non-empty lists. Treat them as a group and
            // add them in a `Card`.

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
