import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drmem_browser/model/model_events.dart';
import 'package:drmem_browser/model/model.dart';
import 'sheet.dart';

// Displays the sheet's contents as an editor. No data collection occurs while
// editing.

class SheetEditor extends StatefulWidget {
  const SheetEditor({Key? key}) : super(key: key);

  @override
  State<SheetEditor> createState() => _SheetEditorState();
}

// Manages the state of the sheet editor.

class _SheetEditorState extends State<SheetEditor> {
  // Builds a row of the sheet. Although the `BaseRow` class does most of the
  // heavy lifting, this function wraps the row editor with the proper spacing
  // and trash icon.

  Widget renderRow(BuildContext context, bool notEmpty, BaseRow e, int idx,
          bool movable) =>
      Padding(
        key: e.key,
        padding: EdgeInsets.fromLTRB(4.0, 4.0, movable ? 32.0 : 4.0, 4.0),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              e.buildRowEditor(context, idx),
              IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      context.read<PageModel>().add(DeleteRow(idx)),
                  icon: const Icon(Icons.delete))
            ]),
      );

  // Returns a function that appends a divider row to the sheet.

  void Function() mkAddDividerRow(BuildContext context) {
    return () =>
        context.read<PageModel>().add(AppendRow(EmptyRow(key: UniqueKey())));
  }

  // Returns a function that appends a device row to the sheet.

  void Function() mkAddDeviceRow(BuildContext context) {
    return () => context
        .read<PageModel>()
        .add(AppendRow(DeviceRow("", key: UniqueKey())));
  }

  // Returns a function that appends a plot row to the sheet.

  void Function() mkAddPlotRow(BuildContext context) {
    return () =>
        context.read<PageModel>().add(AppendRow(PlotRow(key: UniqueKey())));
  }

  // Returns a function that appends a comment row to the sheet.

  void Function() mkAddCommentRow(BuildContext context) {
    return () => context
        .read<PageModel>()
        .add(AppendRow(CommentRow("", key: UniqueKey())));
  }

  // Creates a button that performs an action. The action is defined by a
  // call to the `cb` argument, which should return a function performing
  // the action.

  Widget buildActionButton(BuildContext context,
      void Function() Function(BuildContext) cb, IconData id) {
    final ThemeData td = Theme.of(context);

    return FilledButton.icon(
      style: ButtonStyle(
        backgroundColor: MaterialStatePropertyAll<Color>(
            td.colorScheme.secondary.withOpacity(0.5)),
      ),
      onPressed: cb(context),
      icon: const Icon(Icons.add),
      label: Icon(id),
    );
  }

  // The main building method.

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PageModel, List<BaseRow>>(
        builder: (BuildContext context, state) {
      final bool movable = state.length > 1;

      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ReorderableListView(
                onReorder: (oldIndex, newIndex) =>
                    context.read<PageModel>().add(MoveRow(oldIndex, newIndex)),
                buildDefaultDragHandles: movable,
                padding: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 4.0),
                children: state.fold([], (acc, e) {
                  acc.add(renderRow(context, true, e, acc.length, movable));
                  return acc;
                })),
          ),
          Container(
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildActionButton(
                        context, mkAddDeviceRow, Icons.developer_board),
                    buildActionButton(context, mkAddPlotRow, Icons.auto_graph),
                    buildActionButton(context, mkAddCommentRow, Icons.chat),
                    buildActionButton(context, mkAddDividerRow,
                        Icons.indeterminate_check_box_outlined),
                  ]),
            ),
          )
        ],
      );
    });
  }
}
