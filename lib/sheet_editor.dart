import 'package:drmem_browser/page_events.dart';
import 'package:flutter/material.dart';
import 'package:drmem_browser/model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'sheet.dart';

enum RowMenuItems {
  empty,
  asComment,
  asDevice,
  asChart,
  addAbove,
  addBelow,
  delete
}

class SheetEditor extends StatelessWidget {
  const SheetEditor({Key? key}) : super(key: key);

  Widget buildMenuButton(
      BuildContext context, bool notEmpty, BaseRow br, int index) {
    return PopupMenuButton<RowMenuItems>(
      icon: br.getIcon(),
      initialValue: RowMenuItems.empty,
      // Callback that sets the selected popup menu item.
      onSelected: (RowMenuItems item) {},
      itemBuilder: (BuildContext context) {
        List<PopupMenuEntry<RowMenuItems>> common = [
          PopupMenuItem<RowMenuItems>(
              value: RowMenuItems.empty,
              child: const Text("Divider"),
              onTap: () {
                context
                    .read<PageModel>()
                    .add(UpdateRow(index, const EmptyRow()));
              }),
          PopupMenuItem<RowMenuItems>(
              value: RowMenuItems.asComment,
              child: const Text("To Comment"),
              onTap: () {
                context.read<PageModel>().add(UpdateRow(index, CommentRow("")));
              }),
          PopupMenuItem<RowMenuItems>(
              value: RowMenuItems.asDevice,
              child: const Text("To Device"),
              onTap: () {
                context
                    .read<PageModel>()
                    .add(UpdateRow(index, const DeviceRow("", false)));
              }),
          PopupMenuItem<RowMenuItems>(
              value: RowMenuItems.asChart,
              child: const Text("To Chart"),
              onTap: () {
                context
                    .read<PageModel>()
                    .add(UpdateRow(index, const PlotRow()));
              })
        ];

        if (notEmpty) {
          common.addAll([
            PopupMenuItem<RowMenuItems>(
                value: RowMenuItems.addAbove,
                child: const Text("Add row above"),
                onTap: () {
                  context
                      .read<PageModel>()
                      .add(InsertBeforeRow(index, const EmptyRow()));
                }),
            PopupMenuItem<RowMenuItems>(
                value: RowMenuItems.addBelow,
                child: const Text("Add row below"),
                onTap: () {
                  context
                      .read<PageModel>()
                      .add(InsertAfterRow(index, const EmptyRow()));
                }),
            PopupMenuItem<RowMenuItems>(
                value: RowMenuItems.delete,
                child: const Text("Delete current row"),
                onTap: () {
                  context.read<PageModel>().add(DeleteRow(index));
                })
          ]);
        }

        return common;
      },
    );
  }

  Widget renderRow(BuildContext context, bool notEmpty, BaseRow e, int idx) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        buildMenuButton(context, notEmpty, e, idx),
        e.buildRowEditor(context, idx)
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PageModel, List<BaseRow>>(
        builder: (BuildContext context, state) {
      return ListView(
          padding: const EdgeInsets.all(4.0),
          children: state.isNotEmpty
              ? state
                  .asMap()
                  .map((index, value) {
                    return MapEntry(
                        index, renderRow(context, true, value, index));
                  })
                  .values
                  .toList()
              : [renderRow(context, false, const EmptyRow(), 0)]);
    });
  }
}
