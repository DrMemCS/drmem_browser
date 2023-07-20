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

// This widget is responsible for displaying live data. It will start the
// monitor subscription so that it is the only widget that has to refresh when
// new data arrives.

class DataWidget extends StatelessWidget {
  final String device;
  final String? units;

  const DataWidget(this.device, this.units, {super.key});

  // Displays a checkbox widget to display boolean value

  Widget _displayBoolean(bool value) {
    return Checkbox(
      visualDensity: VisualDensity.compact,
      value: value,
      onChanged: null,
    );
  }

  // For integers, display them as text (along with the units -- if there
  // are any.)

  Widget _displayInteger(int value, String? units) {
    if (units != null) {
      return Text("$value $units");
    } else {
      return Text("$value");
    }
  }

  // For floating point, display them as text (along with the units -- if
  // there are any.)

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
    final DrMem drmem = DrMem.of(context);

    return StreamBuilder(
      stream: drmem.monitorDevice("rpi4", device),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = snapshot.data!.value;

          if (data is DevBool) {
            return _displayBoolean(data.value);
          }

          if (data is DevInt) {
            return _displayInteger(data.value, units);
          }

          if (data is DevFlt) {
            return _displayDouble(data.value, units);
          }

          if (data is DevStr) {
            return Text(data.value);
          }
        }
        return Container();
      },
    );
  }
}
