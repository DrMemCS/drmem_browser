import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:drmem_browser/model/model.dart';
import 'package:drmem_browser/model/model_events.dart';
import 'package:drmem_browser/sheet/sheet_editor.dart';
import 'package:drmem_browser/sheet/sheet_runner.dart';

class ParamPage extends StatefulWidget {
  const ParamPage({super.key});

  @override
  State<ParamPage> createState() => _SheetsState();
}

class _SheetsState extends State<ParamPage> {
  bool editMode = false;
  final TextEditingController ctrlEditName = TextEditingController();

  @override
  void dispose() {
    ctrlEditName.dispose();
    super.dispose();
  }

  Widget getEditorAppBar() {
    final List<Widget> actions = [
      IconButton(
          key: const Key("AddSheet"),
          tooltip: "Add new sheet",
          onPressed: () => context.read<Model>().add(const AddSheet()),
          icon: const Icon(Icons.my_library_add_rounded)),
      IconButton(
          key: const Key("DelSheet"),
          tooltip: "Delete sheet",
          onPressed: () => context.read<Model>().add(const DeleteSheet()),
          icon: const Icon(Icons.delete_forever)),
      IconButton(
          key: const Key("EditSheet"),
          tooltip: "Edit sheet",
          onPressed: () => setState(() => editMode = !editMode),
          icon: const Icon(Icons.settings))
    ];

    return BlocBuilder<Model, AppState>(builder: (context, state) {
      ctrlEditName.text = state.selectedSheet;

      return AppBar(
          actions: actions,
          title: SizedBox(
            width: double.infinity,
            child: TextField(
              controller: ctrlEditName,
              onSubmitted: (value) {
                context.read<Model>().add(RenameSelectedSheet(value));
              },
            ),
          ));
    });
  }

  // Creates the AppBar with actions buttons that affect the current sheet.

  Widget getRunnerAppBar() {
    final List<Widget> actions = [
      IconButton(
          key: const Key("EditSheet"),
          tooltip: "Edit sheet",
          onPressed: () => setState(() => editMode = !editMode),
          icon: const Icon(Icons.settings))
    ];

    return BlocBuilder<Model, AppState>(builder: (context, state) {
      final FocusNode fn = FocusNode();
      List<String> items = state.sheetNames;

      return AppBar(
          actions: actions,
          title: SizedBox(
            width: double.infinity,
            child: DropdownButton<String>(
              focusNode: fn,
              underline: Container(),
              value: state.selectedSheet,
              items: items.map((String e) {
                return DropdownMenuItem(value: e, child: Text(e));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  context.read<Model>().add(SelectSheet(value));
                  fn.unfocus();
                }
              },
            ),
          ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      editMode ? getEditorAppBar() : getRunnerAppBar(),
      Expanded(child: editMode ? const SheetEditor() : const SheetRunner())
    ]);
  }
}
