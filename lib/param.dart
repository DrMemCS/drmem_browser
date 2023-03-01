import 'package:flutter/material.dart';
import 'package:drmem_browser/sheet/sheet_editor.dart';
import 'package:drmem_browser/sheet/sheet_runner.dart';

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
    return AppBar(actions: <Widget>[
      IconButton(
          tooltip: "Add new sheet",
          onPressed: !editMode
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('TODO: Add a new, empty sheet.')));
                }
              : null,
          icon: const Icon(Icons.my_library_add_rounded)),
      IconButton(
          tooltip: "Delete sheet",
          onPressed: !editMode
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('TODO: Delete current sheet.')));
                }
              : null,
          icon: const Icon(Icons.delete_forever)),
      IconButton(
          tooltip: "Edit sheet",
          onPressed: () => setState(() => editMode = !editMode),
          icon: const Icon(Icons.edit)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      buildAppBar(context),
      Expanded(child: editMode ? const SheetEditor() : const SheetRunner())
    ]);
  }
}
