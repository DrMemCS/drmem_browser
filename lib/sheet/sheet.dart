import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drmem_provider/drmem_provider.dart';
import 'package:drmem_browser/model/model_events.dart';
import 'package:drmem_browser/model/model.dart';
import 'widgets/data_widget.dart';

// The base class for all row types. A sheet is a list of objects derived
// from BaseRow.

abstract class BaseRow {
  final Key key;

  const BaseRow({required this.key});

  Widget buildRowEditor(BuildContext context, int index);
  Widget buildRowRunner(BuildContext context);
  Icon getIcon();

  Map<String, dynamic> toJson();

  // Factory method that can take a map from a JSON string and convert to a
  // derived BaseRow class.

  static BaseRow? fromJson(Map<String, dynamic> map, {Key? key}) {
    switch (map) {
      case {'type': "empty"}:
        return EmptyRow(key: key ?? UniqueKey());

      case {'type': "comment", 'content': String comment}:
        return CommentRow(comment, key: key ?? UniqueKey());

      case {'type': "device", 'device': String device}:
        return DeviceRow(device, label: map['label'], key: key ?? UniqueKey());

      case {'type': "plot"}:
        return PlotRow(key: key ?? UniqueKey());

      default:
        return null;
    }
  }
}

// This type isn't ever saved in a sheet's configuration. It automatically
// gets inserted when an empty sheet goes into edit mode. By providing this
// placeholder, the user can turn it into one of the other row types.

class EmptyRow extends BaseRow {
  const EmptyRow({required super.key});

  @override
  Icon getIcon() => const Icon(Icons.menu);

  @override
  Widget buildRowEditor(BuildContext context, int index) {
    return const Expanded(
        child: Padding(padding: EdgeInsets.only(top: 8.0), child: Divider()));
  }

  @override
  Widget buildRowRunner(BuildContext context) {
    return const Divider();
  }

  @override
  Map<String, dynamic> toJson() => {'type': "empty"};

  @override
  int get hashCode => 0;

  @override
  bool operator ==(Object other) {
    return other is EmptyRow;
  }
}

// This row type holds text which allows the user to add comments to the sheet.

class CommentRow extends BaseRow {
  final String comment;

  const CommentRow(this.comment, {required super.key});

  @override
  Icon getIcon() => const Icon(Icons.chat);

  @override
  Widget buildRowEditor(BuildContext context, index) {
    return _CommentEditor(index, comment);
  }

  @override
  Widget buildRowRunner(BuildContext context) {
    final ThemeData td = Theme.of(context);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 32.0),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: MarkdownBody(
          data: comment,
          fitContent: true,
          styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
          styleSheet:
              MarkdownStyleSheet(p: TextStyle(color: td.colorScheme.tertiary)),
        ),
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {'type': "comment", 'content': comment};

  @override
  int get hashCode => 1 + comment.hashCode;

  @override
  bool operator ==(Object other) {
    return other is CommentRow && comment == other.comment;
  }
}

// This row type monitors a device.

class DeviceRow extends BaseRow {
  final String name;
  final String? label;

  const DeviceRow(this.name, {this.label, required super.key});

  @override
  Icon getIcon() => const Icon(Icons.developer_board);

  @override
  Widget buildRowEditor(BuildContext context, int index) {
    return _DeviceEditor(index, name, label: label);
  }

  @override
  Widget buildRowRunner(BuildContext context) {
    return _DeviceWidget(label, name);
  }

  @override
  Map<String, dynamic> toJson() {
    var tmp = {'type': "device", 'device': name};

    if (label != null && label!.isNotEmpty) {
      tmp['label'] = label!;
    }
    return tmp;
  }

  @override
  int get hashCode => 2 + name.hashCode + label.hashCode;

  @override
  bool operator ==(Object other) {
    return other is DeviceRow && name == other.name && label == other.label;
  }
}

// This row type displays a plot.

class PlotRow extends BaseRow {
  const PlotRow({required super.key});

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

  @override
  Map<String, dynamic> toJson() => {'type': "plot"};

  @override
  int get hashCode => 3;

  @override
  bool operator ==(Object other) {
    return other is PlotRow;
  }
}

InputDecoration _getTextFieldDecoration(BuildContext context, String label) {
  final ThemeData td = Theme.of(context);

  return InputDecoration(
      alignLabelWithHint: true,
      contentPadding: const EdgeInsets.all(12.0),
      hintStyle: td.textTheme.bodyMedium!
          .copyWith(color: td.colorScheme.onBackground.withOpacity(0.25)),
      hintText: label,
      isDense: true,
      hoverColor: td.colorScheme.secondary.withOpacity(0.25),
      focusColor: td.colorScheme.primary.withOpacity(0.25),
      fillColor: td.colorScheme.secondary.withOpacity(0.125),
      filled: true,
      border: InputBorder.none);
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
                style: Theme.of(context).textTheme.bodyMedium,
                autocorrect: true,
                minLines: 1,
                maxLines: null,
                decoration: _getTextFieldDecoration(
                    context, "Comment (using Markdown)"),
                keyboardType: TextInputType.multiline,
                controller: controller,
                onChanged: (value) => setState(() => changed = true)),
          ),
          TextButton(
              onPressed: changed
                  ? () {
                      setState(() => changed = false);
                      context.read<Model>().add(UpdateRow(widget.idx,
                          CommentRow(controller.text, key: UniqueKey())));
                    }
                  : null,
              child: const Text("Save"))
        ],
      ),
    );
  }
}

class _DeviceWidget extends StatelessWidget {
  final String? label;
  final String name;

  const _DeviceWidget(this.label, this.name, {Key? key}) : super(key: key);

  // Returns the text that needs to be displayed on the left side of the row.

  String get text => label != null && label!.isNotEmpty ? label! : name;

  @override
  Widget build(BuildContext context) {
    final DrMem drmem = DrMem.of(context);
    final ThemeData td = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 32.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: td.colorScheme.primary),
            ),
          ),
          FutureBuilder(
              future: drmem.getDeviceInfo(
                  device: DevicePattern(node: "rpi4", name: name)),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final data = snapshot.data!;

                  if (data.isNotEmpty) {
                    final info = data.first;

                    return DataWidget(
                        Device(name: name), info.settable, info.units);
                  } else {
                    return buildErrorWidget(td, "device not found");
                  }
                } else if (snapshot.hasError) {
                  return buildErrorWidget(td, "${snapshot.error}");
                } else {
                  return const Text("loading ...");
                }
              }),
        ],
      ),
    );
  }
}

class _DeviceEditor extends StatefulWidget {
  final int _idx;
  final String _device;
  final String _label;

  const _DeviceEditor(this._idx, this._device, {String? label})
      : _label = label ?? "";

  @override
  _DeviceEditorState createState() => _DeviceEditorState();
}

class _DeviceEditorState extends State<_DeviceEditor> {
  late final TextEditingController ctrlDevice;
  late final TextEditingController ctrlLabel;
  final RegExp re = RegExp(r'^[-:\w\d]*$');

  @override
  void initState() {
    ctrlDevice = TextEditingController(text: widget._device);
    ctrlLabel = TextEditingController(text: widget._label);
    super.initState();
  }

  @override
  void dispose() {
    ctrlDevice.dispose();
    ctrlLabel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Flexible(
            fit: FlexFit.loose,
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextField(
                  autocorrect: false,
                  style: Theme.of(context).textTheme.bodyMedium,
                  inputFormatters: [
                    TextInputFormatter.withFunction((oldValue, newValue) =>
                        re.hasMatch(newValue.text) ? newValue : oldValue)
                  ],
                  minLines: 1,
                  maxLines: 1,
                  decoration: _getTextFieldDecoration(context, "Device name"),
                  controller: ctrlDevice,
                  onSubmitted: (value) => context.read<Model>().add(
                        UpdateRow(
                            widget._idx,
                            DeviceRow(value,
                                label: ctrlLabel.text, key: UniqueKey())),
                      )),
            ),
          ),
          Flexible(
            fit: FlexFit.loose,
            flex: 1,
            child: TextField(
                autocorrect: false,
                style: Theme.of(context).textTheme.bodyMedium,
                minLines: 1,
                maxLines: 1,
                decoration:
                    _getTextFieldDecoration(context, "Label (optional)"),
                controller: ctrlLabel,
                onSubmitted: (value) => context.read<Model>().add(
                      UpdateRow(
                          widget._idx,
                          DeviceRow(ctrlDevice.text,
                              label: value, key: UniqueKey())),
                    )),
          ),
        ],
      ),
    );
  }
}
