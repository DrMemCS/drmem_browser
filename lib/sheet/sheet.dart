import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drmem_browser/model/page_events.dart';
import 'package:drmem_browser/model/model.dart';

// The base class for all row types. A sheet is a list of objects derived
// from BaseRow.

abstract class BaseRow {
  const BaseRow();

  Widget buildRowEditor(BuildContext context, int index);
  Widget buildRowRunner(BuildContext context);
  Icon getIcon();
}

// This type isn't ever saved in a sheet's configuration. It automatically
// gets inserted when an empty sheet goes into edit mode. By providing this
// placeholder, the user can turn it into one of the other row types.

class EmptyRow extends BaseRow {
  const EmptyRow() : super();

  @override
  Icon getIcon() => const Icon(Icons.menu);

  @override
  Widget buildRowEditor(BuildContext context, int index) {
    return const Expanded(
        child: Padding(padding: EdgeInsets.only(top: 8.0), child: Divider()));
  }

  @override
  Widget buildRowRunner(BuildContext context) {
    return const Expanded(child: Divider());
  }
}

// This row type holds text which allows the user to add comments to the sheet.

class CommentRow extends BaseRow {
  final String comment;

  CommentRow(this.comment) : super();

  @override
  Icon getIcon() => const Icon(Icons.chat);

  @override
  Widget buildRowEditor(BuildContext context, index) {
    return _CommentEditor(index, comment);
  }

  @override
  Widget buildRowRunner(BuildContext context) {
    return Expanded(
      child: MarkdownBody(
        data: comment,
        fitContent: true,
        styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
        styleSheet: MarkdownStyleSheet(
            p: TextStyle(color: Theme.of(context).disabledColor)),
      ),
    );
  }
}

// This row type monitors a device.

class DeviceRow extends BaseRow {
  final String name;
  final bool settable;

  const DeviceRow(this.name, this.settable) : super();

  @override
  Icon getIcon() => const Icon(Icons.developer_board);

  @override
  Widget buildRowEditor(BuildContext context, int index) {
    return Text("edit: $name");
  }

  @override
  Widget buildRowRunner(BuildContext context) {
    return Text("monitor: $name");
  }
}

// This row type displays a plot.

class PlotRow extends BaseRow {
  const PlotRow() : super();

  @override
  Icon getIcon() => const Icon(Icons.auto_graph);

  @override
  Widget buildRowEditor(BuildContext context, int index) {
    return const Text("edit plot");
  }

  @override
  Widget buildRowRunner(BuildContext context) {
    return const Text("display plot");
  }
}

class _CommentEditor extends StatefulWidget {
  final int idx;
  final String text;

  const _CommentEditor(this.idx, this.text, {Key? key}) : super(key: key);

  @override
  _CommentEditorState createState() => _CommentEditorState();
}

class _CommentEditorState extends State<_CommentEditor> {
  late final TextEditingController controller;
  bool changed = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.text);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            fit: FlexFit.loose,
            child: TextField(
                minLines: 1,
                maxLines: null,
                decoration: const InputDecoration(
                    labelText: "Comment (in Markdown)",
                    border: OutlineInputBorder(
                        borderSide: BorderSide(style: BorderStyle.solid))),
                keyboardType: TextInputType.multiline,
                controller: controller,
                onChanged: (value) => setState(() => changed = true)),
          ),
          TextButton(
              onPressed: changed
                  ? () {
                      setState(() => changed = false);
                      context.read<PageModel>().add(
                          UpdateRow(widget.idx, CommentRow(controller.text)));
                    }
                  : null,
              child: const Text("Save"))
        ],
      ),
    );
  }
}
