import 'package:flutter/material.dart';
import 'package:drmem_browser/pkg/drmem_provider/drmem_provider.dart';

// This builds widgets that show an error icon followed by red text
// indicating an unsupported type was received. This could happen if
// an older version of the app is reading a new version of DrMem.

Widget buildErrorWidget(ThemeData td, String msg) {
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

// Displays an error message using the snackbar.

void _displayError(BuildContext context, String msg) {
  final snackBar = SnackBar(
    backgroundColor: const Color.fromRGBO(183, 28, 28, 1),
    content: Text(msg, style: const TextStyle(color: Colors.yellow)),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

class _SettingTextEditor extends StatelessWidget {
  final DrMem drmem;
  final Device device;
  final void Function() exitFunc;
  final TextInputType? inpType;
  final DevValue? Function(BuildContext, String) parser;

  const _SettingTextEditor(
      {required this.drmem,
      required this.device,
      required this.exitFunc,
      this.inpType,
      required this.parser});

  @override
  Widget build(BuildContext context) {
    final td = Theme.of(context);

    return TextField(
        autofocus: true,
        style: td.textTheme.bodyMedium!.apply(color: Colors.cyan),
        textAlign: TextAlign.end,
        keyboardType: inpType,
        decoration: null,
        minLines: 1,
        maxLines: 1,
        onSubmitted: (value) async {
          exitFunc();

          final result = parser(context, value);

          if (result != null) {
            try {
              await drmem.setDevice(device, result);
            } catch (e) {
              if (context.mounted) {
                _displayError(context, e.toString());
              }
            }
          }
        });
  }
}

// Define an extension on the `DevValue` hierarchy.

extension on DevValue {
  // This extension builds a Widget that displays values of the given type. It
  // determines which subclass the object actually is to generate the
  // appropriate widget.

  Widget build(void Function() Function(DevValue)? setFunc, String? units) {
    final Color color = setFunc != null ? Colors.cyan : Colors.grey;
    final TextStyle style = TextStyle(color: color);

    Widget widget = switch (this) {
      DevBool(value: var v) => Icon(
          v ? Icons.radio_button_checked : Icons.radio_button_off,
          color: color),
      DevInt(value: var v) =>
        Text(units != null ? "$v $units" : "$v", style: style),
      DevFlt(value: var v) =>
        Text(units != null ? "$v $units" : "$v", style: style),
      DevStr(value: var v) => Text(v, style: style),
    };

    return setFunc != null
        ? GestureDetector(onTap: setFunc(this), child: widget)
        : widget;
  }

  // Builds a widget that can edit values of the current object type.

  Widget buildEditor(
      BuildContext context, Device device, void Function() exitFunc) {
    final DrMem drmem = DrMem.of(context);

    return switch (this) {
      DevBool() => buildBoolEditor(drmem, device, exitFunc),
      DevFlt() => buildFloatEditor(context, drmem, device, exitFunc),
      DevInt() => buildIntegerEditor(context, drmem, device, exitFunc),
      DevStr() => buildStringEditor(context, drmem, device, exitFunc),
    };
  }

  Widget buildFloatEditor(BuildContext context, DrMem drmem, Device device,
          void Function() exitFunc) =>
      _SettingTextEditor(
          drmem: drmem,
          device: device,
          exitFunc: exitFunc,
          inpType: TextInputType.number,
          parser: (context, value) {
            if (value.isNotEmpty) {
              try {
                return DevFlt(double.parse(value));
              } on FormatException {
                _displayError(
                    context, 'Bad numeric format ... setting ignored');
              }
            }
            return null;
          });

  Widget buildIntegerEditor(BuildContext context, DrMem drmem, Device device,
          void Function() exitFunc) =>
      _SettingTextEditor(
          drmem: drmem,
          device: device,
          exitFunc: exitFunc,
          inpType: TextInputType.number,
          parser: (context, value) {
            if (value.isNotEmpty) {
              try {
                return DevInt(int.parse(value));
              } on FormatException {
                _displayError(
                    context, 'Bad numeric format ... setting ignored');
              }
            }
            return null;
          });

  Widget buildStringEditor(BuildContext context, DrMem drmem, Device device,
          void Function() exitFunc) =>
      _SettingTextEditor(
          drmem: drmem,
          device: device,
          exitFunc: exitFunc,
          parser: (_, value) => DevStr(value));

  // Returns a widget tree which sends boolean values to a device. For the
  // boolean editor, we display two buttons which send `true` and `false`
  // values.

  Widget buildBoolEditor(
    DrMem drmem,
    Device device,
    void Function() exitFunc,
  ) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ElevatedButton(
                onPressed: () async {
                  exitFunc();
                  await drmem.setDevice(device, const DevBool(true));
                },
                child: const Text("true")),
          ),
          Expanded(
            child: ElevatedButton(
                onPressed: () async {
                  exitFunc();
                  await drmem.setDevice(device, const DevBool(false));
                },
                child: const Text("false")),
          ),
        ],
      );
}

// This widget is responsible for displaying live data. It will start the
// monitor subscription so that it is the only widget that has to refresh when
// new data arrives.

class DataWidget extends StatefulWidget {
  final Device device;
  final bool settable;
  final String? units;

  const DataWidget(this.device, this.settable, this.units, {super.key});

  @override
  State<DataWidget> createState() => _DataWidgetState();
}

class _DataWidgetState extends State<DataWidget> {
  // When `null`, we simply display the incoming data. If not-null, if is
  // the last value received from the stream and is an example of the data
  // we need to edit.

  DevValue? _editValue;

  // Builds a widget to display a DrMem value type. This focuses solely on
  // the widget that displays the value. If the value is to have associated
  // widgets, they can incorporate this widget.

  Widget _buildDisplayWidget(BuildContext context) {
    final DrMem drmem = DrMem.of(context);
    void Function() Function(DevValue)? setFunc =
        widget.settable ? (v) => (() => setState(() => _editValue = v)) : null;

    return StreamBuilder(
        stream: drmem.monitorDevice(widget.device),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data!.value;

            return data.build(setFunc, widget.units);
          } else {
            return Container();
          }
        });
  }

  // Create the appropriate widget based on the type of the incoming data.
  @override
  Widget build(BuildContext context) {
    final editValue = _editValue;

    return editValue != null
        ? Expanded(
            child: TapRegion(
              onTapOutside: (_) => setState(() => _editValue = null),
              child: editValue.buildEditor(
                context,
                widget.device,
                () => setState(() => _editValue = null),
              ),
            ),
          )
        : _buildDisplayWidget(context);
  }
}
