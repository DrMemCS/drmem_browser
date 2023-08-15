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

// Define an extension on the `DevValue` hierarchy.

extension on DevValue {
  // This extension builds a Widget that displays values of the given type. It
  // determines which subclass the object actually is to generate the
  // appropriate widget.

  Widget build(BuildContext context,
      void Function() Function(DevValue)? setFunc, String? units) {
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
      BuildContext context, String device, void Function() exitFunc) {
    final DrMem drmem = DrMem.of(context);

    return switch (this) {
      DevBool() => buildBoolEditor(drmem, device, exitFunc),
      DevFlt() => buildFloatEditor(context, drmem, device, exitFunc),
      DevInt() ||
      DevStr() =>
        const Icon(Icons.question_mark, color: Colors.red),
    };
  }

  Widget buildFloatEditor(
      BuildContext context, drmem, String device, void Function() exitFunc) {
    return TextField(
      autofocus: true,
      textAlign: TextAlign.end,
      decoration: null,
      minLines: 1,
      maxLines: 1,
      onSubmitted: (value) async {
        exitFunc();

        if (value.isNotEmpty) {
          try {
            double val = double.parse(value);

            await drmem.setDevice("rpi4", device, DevFlt(val));
          } on FormatException {
            const snackBar = SnackBar(
              backgroundColor: Color.fromRGBO(183, 28, 28, 1),
              content: Text('Bad numeric format.',
                  style: TextStyle(color: Colors.yellow)),
            );

            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
      },
    );
  }

  // Returns a widget tree which sends boolean values to a device. For the
  // boolean editor, we display two buttons which send `true` and `false`
  // values.

  Widget buildBoolEditor(
    DrMem drmem,
    String device,
    void Function() exitFunc,
  ) =>
      Row(
        children: [
          TextButton(
              onPressed: () async {
                exitFunc();
                await drmem.setDevice("rpi4", device, const DevBool(true));
              },
              child: const Text("true")),
          TextButton(
              onPressed: () async {
                exitFunc();
                await drmem.setDevice("rpi4", device, const DevBool(false));
              },
              child: const Text("false")),
        ],
      );
}

// This widget is responsible for displaying live data. It will start the
// monitor subscription so that it is the only widget that has to refresh when
// new data arrives.

class DataWidget extends StatefulWidget {
  final String device;
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
        stream: drmem.monitorDevice("rpi4", widget.device),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data!.value;

            return data.build(context, setFunc, widget.units);
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
