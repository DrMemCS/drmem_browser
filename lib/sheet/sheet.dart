import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:ferry/ferry.dart';
import 'package:drmem_browser/schema/__generated__/get_device.req.gql.dart';
import 'package:drmem_browser/schema/__generated__/get_device.data.gql.dart';
import 'package:drmem_browser/schema/__generated__/get_device.var.gql.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drmem_browser/model/model_events.dart';
import 'package:drmem_browser/model/model.dart';
import 'widgets/data_widget.dart';

// The base class for all row types. A sheet is a list of objects derived
// from BaseRow.

abstract class BaseRow {
  final Key key;

  const BaseRow({required this.key});

  Widget buildRowEditor(BuildContext context, int index);
  Widget buildRowRunner(BuildContext context, Client qClient, Client sClient);
  Icon getIcon();

  Map<String, dynamic> toJson();

  // Factory method that can take a map from a JSON string and convert to a
  // derived BaseRow class.

  static BaseRow? fromJson(Map<String, dynamic> map, {Key? key}) {
    switch (map['type']) {
      case 'empty':
        return EmptyRow(key: key ?? UniqueKey());

      case 'comment':
        {
          String? comment = map['content'];

          if (comment != null) {
            return CommentRow(comment, key: key ?? UniqueKey());
          }
          return null;
        }

      case 'device':
        {
          String? device = map['device'];

          if (device != null) {
            return DeviceRow(device, key: key ?? UniqueKey());
          }
          return null;
        }

      case 'plot':
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
  Widget buildRowRunner(BuildContext context, Client qClient, Client sClient) {
    return const Divider();
  }

  @override
  Map<String, dynamic> toJson() => {'type': 'empty'};
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
  Widget buildRowRunner(BuildContext context, Client qClient, Client sClient) {
    return Container(
      constraints: const BoxConstraints(minHeight: 32.0),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: MarkdownBody(
          data: comment,
          fitContent: true,
          styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
          styleSheet: MarkdownStyleSheet(
              p: TextStyle(color: Theme.of(context).disabledColor)),
        ),
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {'type': 'comment', 'content': comment};
}

// This row type monitors a device.

class DeviceRow extends BaseRow {
  final String name;

  const DeviceRow(this.name, {required super.key});

  @override
  Icon getIcon() => const Icon(Icons.developer_board);

  @override
  Widget buildRowEditor(BuildContext context, int index) {
    return _DeviceEditor(index, name);
  }

  @override
  Widget buildRowRunner(BuildContext context, Client qClient, Client sClient) {
    return _DeviceWidget(qClient, sClient, name);
  }

  @override
  Map<String, dynamic> toJson() => {'type': 'device', 'device': name};
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
  Widget buildRowRunner(BuildContext context, Client qClient, Client sClient) {
    return const Text("display plot");
  }

  @override
  Map<String, dynamic> toJson() => {'type': 'plot'};
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
                      context.read<PageModel>().add(UpdateRow(widget.idx,
                          CommentRow(controller.text, key: UniqueKey())));
                    }
                  : null,
              child: const Text("Save"))
        ],
      ),
    );
  }
}

class _DeviceWidget extends StatefulWidget {
  final Client qClient;
  final Client sClient;
  final String name;

  const _DeviceWidget(this.qClient, this.sClient, this.name, {Key? key})
      : super(key: key);

  @override
  _DeviceWidgetState createState() => _DeviceWidgetState();
}

class _DeviceWidgetState extends State<_DeviceWidget> {
  StreamSubscription? subMeta;
  GGetDeviceData_deviceInfo? info;
  String? errorText;

  void _handleDeviceInfo(
      OperationResponse<GGetDeviceData, GGetDeviceVars> response) {
    developer.log("response: ${response.loading}", name: "graphql.GetDevice");
    if (!response.loading) {
      if (response.hasErrors) {
        developer.log("error returned",
            name: "graphql.GetDevice", error: "$response");
      } else if (response.data?.deviceInfo.isNotEmpty ?? false) {
        setState(() {
          errorText = null;
          info = response.data?.deviceInfo.first;
        });
      } else {
        setState(() => errorText = "Device not found.");
      }

      // Free up resources associated with the request.

      subMeta?.cancel();
      subMeta = null;
    }
  }

  // Set up the GraphQL requests to populate the fields in the Device Row.

  @override
  void initState() {
    // If a device name was given, start a GraphQL query to receive information
    // about the device. Otherwise, set the error text and avoid doing the
    // request/replies.

    if (widget.name.isNotEmpty) {
      subMeta = widget.qClient
          .request(GGetDeviceReq(((b) => b..vars.name = widget.name)))
          .listen(_handleDeviceInfo);
    } else {
      errorText = "No device name";
    }

    super.initState();
  }

  @override
  void dispose() {
    subMeta?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData td = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 32.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: td.indicatorColor),
            ),
          ),
          errorText == null
              ? (info == null
                  ? Container()
                  : DataWidget(widget.name, widget.sClient, info!.units))
              : buildErrorWidget(td, errorText!)
        ],
      ),
    );
  }
}

class _DeviceEditor extends StatefulWidget {
  final int idx;
  final String device;

  const _DeviceEditor(this.idx, this.device, {Key? key}) : super(key: key);

  @override
  _DeviceEditorState createState() => _DeviceEditorState();
}

class _DeviceEditorState extends State<_DeviceEditor> {
  late final TextEditingController controller;
  final RegExp re = RegExp(r'^[-:\w\d]*$');

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.device);
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
        children: [
          Flexible(
            fit: FlexFit.loose,
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
                controller: controller,
                onSubmitted: (value) => context.read<PageModel>().add(
                      UpdateRow(widget.idx,
                          DeviceRow(controller.text, key: UniqueKey())),
                    )),
          ),
        ],
      ),
    );
  }
}
