import 'dart:async';
import 'dart:developer' as developer;
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
import 'package:drmem_browser/model/model_events.dart';
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
      hintText: label,
      isDense: true,
      hoverColor: td.colorScheme.secondary.withOpacity(0.25),
      focusColor: td.colorScheme.primary.withOpacity(0.25),
      fillColor: td.colorScheme.secondary.withOpacity(0.125),
      filled: true,
      border: InputBorder.none);
}

// This builds widgets that show an error icon followed by red text
// indicating an unsupported type was received. This could happen if
// an older version of the app is reading a new version of DrMem.

Widget _buildErrorWidget(ThemeData td, String msg) {
  Color errorColor = td.colorScheme.error;

  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Icon(Icons.error, size: 16.0, color: errorColor),
      ),
      Text(msg, style: TextStyle(color: errorColor))
    ],
  );
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

// This widget is responsible for displaying live data. It will start the
// monitor subscription so that it is the only widget that has to refresh when
// new data arrives.

class _DataWidget extends StatefulWidget {
  final Client sClient;
  final String device;
  final String? units;

  const _DataWidget(this.device, this.sClient, this.units);

  @override
  _DataWidgetState createState() => _DataWidgetState();
}

class _DataWidgetState extends State<_DataWidget> {
  StreamSubscription? subReadings;
  GMonitorDeviceData_monitorDevice? value;
  String? errorText;

  @override
  void initState() {
    subReadings = widget.sClient
        .request(GMonitorDeviceReq((b) => b..vars.device = widget.device))
        .listen(_handleReadings);
    super.initState();
  }

  @override
  void dispose() {
    subReadings?.cancel();
    super.dispose();
  }

  void _handleReadings(
      OperationResponse<GMonitorDeviceData, GMonitorDeviceVars> response) {
    if (!response.loading) {
      if (response.hasErrors) {
        developer.log("error",
            name: "graphql.MonitorDevice", error: "$response");
      } else {
        setState(() {
          value = response.data?.monitorDevice;
        });
      }
    }
  }

  // Displays a checkbox widget to display bookean values.

  Widget _displayBoolean(bool value) {
    return Checkbox(
      visualDensity: VisualDensity.compact,
      value: value,
      onChanged: null,
    );
  }

  Widget _displayInteger(int value, String? units) {
    if (units != null) {
      return Text("$value $units");
    } else {
      return Text("$value");
    }
  }

  Widget _displayDouble(double value, String? units) {
    if (units != null) {
      return Text("$value $units");
    } else {
      return Text("$value");
    }
  }

  // Create the appropriate widget based on the type of the incoming data.

  @override
  Widget build(BuildContext context) {
    ThemeData td = Theme.of(context);

    if (value == null) {
      return Container();
    } else {
      if (value!.boolValue != null) {
        return _displayBoolean(value!.boolValue!);
      }

      if (value!.intValue != null) {
        return _displayInteger(value!.intValue!, widget.units);
      }

      if (value!.floatValue != null) {
        return _displayDouble(value!.floatValue!, widget.units);
      }

      if (value!.stringValue != null) {
        return Text("${value!.stringValue}");
      }

      return _buildErrorWidget(td, "Unknown type");
    }
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
    // Start a GraphQL query to receive information about the device.

    subMeta = widget.qClient
        .request(GGetDeviceReq(((b) => b..vars.name = widget.name)))
        .listen(_handleDeviceInfo);

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
                  : _DataWidget(widget.name, widget.sClient, info!.units))
              : _buildErrorWidget(td, errorText!)
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
                onChanged: (value) => context.read<PageModel>().add(
                      UpdateRow(widget.idx, DeviceRow(controller.text, false)),
                    )),
          ),
        ],
      ),
    );
  }
}
