import 'package:flutter/material.dart';
import 'package:drmem_browser/sheet/sheet_editor.dart';
import 'package:drmem_browser/sheet/sheet_runner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drmem_browser/model/model.dart';

// Display "parameter page".

Widget displayParameters() {
  return _ParamPage();
}

class _ParamPage extends StatefulWidget {
  @override
  _SheetsState createState() => _SheetsState();
}

class _SheetsState extends State<_ParamPage> {
  bool editMode = false;

  // Creates the AppBar with actions buttons that affect the current sheet.

  AppBar buildAppBar(BuildContext context) {
    final List<Widget> actions = editMode
        ? [
            IconButton(
                tooltip: "Add new sheet",
                onPressed: !editMode
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('TODO: Add a new, empty sheet.')));
                      }
                    : null,
                icon: const Icon(Icons.my_library_add_rounded)),
            IconButton(
                tooltip: "Delete sheet",
                onPressed: !editMode
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('TODO: Delete current sheet.')));
                      }
                    : null,
                icon: const Icon(Icons.delete_forever)),
          ]
        : [];

    actions.add(IconButton(
        tooltip: "Edit sheet",
        onPressed: () => setState(() => editMode = !editMode),
        icon: const Icon(Icons.edit)));

    return AppBar(
        actions: actions,
        title: Text(context.read<Model>().state.selectedSheet));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      buildAppBar(context),
      Expanded(child: editMode ? const SheetEditor() : const SheetRunner())
    ]);
  }
}
