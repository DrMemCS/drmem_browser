import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:ferry/ferry.dart';
import 'package:drmem_browser/schema/__generated__/get_device.req.gql.dart';
import 'package:drmem_browser/schema/__generated__/get_device.data.gql.dart';
import 'package:drmem_browser/schema/__generated__/get_device.var.gql.dart';
import 'package:drmem_browser/schema/__generated__/monitor_device.req.gql.dart';
import 'package:drmem_browser/schema/__generated__/monitor_device.data.gql.dart';
import 'package:drmem_browser/schema/__generated__/monitor_device.var.gql.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drmem_browser/model/page_events.dart';
import 'package:drmem_browser/model/model.dart';

// The base class for all row types. A sheet is a list of objects derived
// from BaseRow.

abstract class BaseRow {
  const BaseRow();

  Widget buildRowEditor(BuildContext context, int index);
  Widget buildRowRunner(BuildContext context, Client qClient, Client sClient);
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
  Widget buildRowRunner(BuildContext context, Client qClient, Client sClient) {
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
  Widget buildRowRunner(BuildContext context, Client qClient, Client sClient) {
    return Expanded(
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
    return _DeviceEditor(index, name);
  }

  @override
  Widget buildRowRunner(BuildContext context, Client qClient, Client sClient) {
    return _DeviceWidget(qClient, sClient, name);
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
  Widget buildRowRunner(BuildContext context, Client qClient, Client sClient) {
    return const Text("display plot");
  }
}

InputDecoration _getTextFieldDecoration(BuildContext context, String label) {
  final ThemeData td = Theme.of(context);

  return InputDecoration(
      alignLabelWithHint: true,
      contentPadding: const EdgeInsets.all(12.0),
      hintStyle: td.textTheme.bodyMedium!
          .copyWith(color: td.colorScheme.onBackground.withOpacity(0.25)),
      isDense: true,
      hoverColor: td.colorScheme.secondary.withOpacity(0.25),
      focusColor: td.colorScheme.primary.withOpacity(0.25),
      fillColor: td.colorScheme.secondary.withOpacity(0.125),
      filled: true,
      hintText: label,
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
  StreamSubscription? subReadings;

  String? errorText;
  String? units;
  GMonitorDeviceData_monitorDevice? value;

  void _handleDeviceInfo(
      OperationResponse<GGetDeviceData, GGetDeviceVars> response) {
    if (!response.loading) {
      if (response.hasErrors) {
        print("error: $response");
      } else if (response.data?.deviceInfo.isNotEmpty ?? false) {
        setState(() {
          errorText = null;
          units = response.data?.deviceInfo.first.units;
        });

        // This sets up the subscription which receives device updates.

        subReadings = widget.sClient
            .request(GMonitorDeviceReq((b) => b..vars.device = widget.name))
            .listen(_handleReadings);
      } else {
        setState(() => errorText = "Device not found.");
      }
    }
  }

  Widget _displayReading(BuildContext context) {
    if (value == null) {
      return Container();
    } else {
      if (value!.boolValue != null) {
        return Checkbox(
            visualDensity: VisualDensity.compact,
            value: value!.boolValue,
            onChanged: null);
      }

      if (value!.intValue != null) {
        return Text("${value!.intValue} ${units ?? '?'}");
      }

      if (value!.floatValue != null) {
        return Text("${value!.floatValue} ${units ?? '?'}");
      }

      if (value!.stringValue != null) {
        return Text("${value!.stringValue}");
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(Icons.error,
                size: 16.0, color: Theme.of(context).errorColor),
          ),
          Text("unknown type",
              style: TextStyle(color: Theme.of(context).errorColor)),
        ],
      );
    }
  }

  void _handleReadings(
      OperationResponse<GMonitorDeviceData, GMonitorDeviceVars> response) {
    if (!response.loading) {
      if (response.hasErrors) {
        print("error: $response");
      } else {
        setState(() {
          value = response.data?.monitorDevice;
        });
      }
    }
  }
  // Set up the GraphQL requests to populate the fields in the Device Row.

  @override
  void initState() {
    // Start a GraphQL query to receive information about the device.

    subMeta = widget.qClient
        .request(GGetDeviceReq(((b) => b..vars.name = widget.name)))
        .listen(_handleDeviceInfo);

    super.initState();
  }

  @override
  void dispose() {
    subMeta?.cancel();
    subReadings?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Theme.of(context).indicatorColor),
            ),
          ),
          errorText == null
              ? _displayReading(context)
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.error,
                          size: 16.0, color: Theme.of(context).errorColor),
                    ),
                    Text(errorText!,
                        style: TextStyle(color: Theme.of(context).errorColor)),
                  ],
                )
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
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) =>
                      re.hasMatch(newValue.text) ? newValue : oldValue)
                ],
                minLines: 1,
                maxLines: 1,
                decoration: _getTextFieldDecoration(context, "Device name"),
                controller: controller,
                onChanged: (value) => context.read<PageModel>().add(
                      UpdateRow(widget.idx, DeviceRow(controller.text, false)),
                    )),
          ),
        ],
      ),
    );
  }
}
