import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:ferry/ferry.dart';
import 'package:drmem_browser/pkg/drmem_provider/schema/__generated__/monitor_device.req.gql.dart';
import 'package:drmem_browser/pkg/drmem_provider/schema/__generated__/monitor_device.data.gql.dart';
import 'package:drmem_browser/pkg/drmem_provider/schema/__generated__/monitor_device.var.gql.dart';

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

class DataWidget extends StatefulWidget {
  final Client sClient;
  final String device;
  final String? units;

  const DataWidget(this.device, this.sClient, this.units, {super.key});

  @override
  DataWidgetState createState() => DataWidgetState();
}

// Manages the state of the `DataWidget`. This widget needs to handle every
// data type supported by DrMem devices. It adjusts the representation based
// on the data type returned by the device.

class DataWidgetState extends State<DataWidget> {
  StreamSubscription? subReadings;
  GMonitorDeviceData_monitorDevice? value;
  String? errorText;

  // When this widget is mounted to the tree, we start up the GraphQL
  // subscription.

  @override
  void initState() {
    subReadings = widget.sClient
        .request(GMonitorDeviceReq((b) => b..vars.device = widget.device))
        .listen(_handleReadings);
    super.initState();
  }

  // Before the widget is entirely destroyed, cancel the GraphQL stream.

  @override
  void dispose() {
    subReadings?.cancel();
    super.dispose();
  }

  // When a new value arrives on the stream, save it to our state (which will
  // redraw the widget.)

  void _handleReadings(
      OperationResponse<GMonitorDeviceData, GMonitorDeviceVars> response) {
    // The GraphQL streams seem to return messages that track states of the
    // connection. We're only interested in new data so we ignore the other
    // messages.

    if (!response.loading) {
      // Report errors or update our state with new data.

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

      return buildErrorWidget(td, "Unknown type");
    }
  }
}
