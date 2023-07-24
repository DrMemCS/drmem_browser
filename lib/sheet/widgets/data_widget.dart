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

  Widget build(BuildContext context, String? units) {
    final data = this;

    // Booleans display a checkbox.

    if (data is DevBool) {
      return Checkbox(
        visualDensity: VisualDensity.compact,
        value: data.value,
        onChanged: null,
      );
    }

    // Integers display their value with an optional units designation.

    if (data is DevInt) {
      return Text(units != null ? "${data.value} $units" : "${data.value}");
    }

    // Doubles display their value with an optional units designation.

    if (data is DevFlt) {
      return Text(units != null ? "${data.value} $units" : "${data.value}");
    }

    // Strings are displayed as strings.

    if (data is DevStr) {
      return Text(data.value);
    }

    // If we don't recognize the type, display an error message.

    final ThemeData td = Theme.of(context);

    return buildErrorWidget(td, "unknown data type");
  }
}

// This widget is responsible for displaying live data. It will start the
// monitor subscription so that it is the only widget that has to refresh when
// new data arrives.

class DataWidget extends StatelessWidget {
  final String device;
  final String? units;

  const DataWidget(this.device, this.units, {super.key});

  // Create the appropriate widget based on the type of the incoming data.

  @override
  Widget build(BuildContext context) {
    final DrMem drmem = DrMem.of(context);

    return StreamBuilder(
        stream: drmem.monitorDevice("rpi4", device),
        builder: (context, snapshot) => snapshot.hasData
            ? snapshot.data!.value.build(context, units)
            : Container());
  }
}
