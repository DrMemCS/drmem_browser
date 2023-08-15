/// This package provides access to DrMem nodes.

import 'dart:async';
import 'package:flutter/material.dart';
import "package:gql_websocket_link/gql_websocket_link.dart";
import 'package:gql_http_link/gql_http_link.dart';
import 'package:drmem_browser/pkg/drmem_provider/schema/__generated__/set_device.data.gql.dart';
import 'package:drmem_browser/pkg/drmem_provider/schema/__generated__/set_device.req.gql.dart';
import 'package:drmem_browser/pkg/drmem_provider/schema/__generated__/drmem.schema.gql.dart';
import 'package:drmem_browser/pkg/drmem_provider/schema/__generated__/driver_info.data.gql.dart';
import 'package:drmem_browser/pkg/drmem_provider/schema/__generated__/driver_info.req.gql.dart';
import 'package:drmem_browser/pkg/drmem_provider/schema/__generated__/get_device.data.gql.dart';
import 'package:drmem_browser/pkg/drmem_provider/schema/__generated__/get_device.req.gql.dart';
import 'package:drmem_browser/pkg/drmem_provider/schema/__generated__/monitor_device.req.gql.dart';
import 'package:ferry/ferry.dart';

/// The base class for all types returned by a device.

sealed class DevValue {
  const DevValue();

  GSettingDataBuilder toBuilder();
}

/// Holds values returned by boolean devices.

class DevBool extends DevValue {
  final bool value;

  const DevBool(this.value);

  @override
  GSettingDataBuilder toBuilder() => GSettingDataBuilder()..Gbool = value;
}

/// Holds values returned by int devices.

class DevInt extends DevValue {
  final int value;

  const DevInt(this.value);

  @override
  GSettingDataBuilder toBuilder() => GSettingDataBuilder()..Gint = value;
}

/// Holds values returned by floating point devices.

class DevFlt extends DevValue {
  final double value;

  const DevFlt(this.value);

  @override
  GSettingDataBuilder toBuilder() => GSettingDataBuilder()..flt = value;
}

/// Holds values returned by devices that return strings.

class DevStr extends DevValue {
  final String value;

  const DevStr(this.value);

  @override
  GSettingDataBuilder toBuilder() => GSettingDataBuilder()..str = value;
}

/// Represents a reading of a device.

class Reading {
  /// This field represents the time that the device value was saved. This value
  /// should be very close to when the associated hardware was sampled. It is
  /// up to the driver to keep this promise.
  final DateTime stamp;

  /// The value of the device.
  late final DevValue value;

  Reading(this.stamp, this.value);

  /// Creates a [Reading] value from a set of values.
  Reading.from(GDateTimeUtc dt, bool? b, int? i, double? d, String? s)
      : stamp = DateTime.parse(dt.value) {
    // Only one data value is valid. This switch statement converts the data
    // to the correct DevValue-derived type, as well as checking for all
    // `null`s or multiple values being returned.

    switch ((b, i, d, s)) {
      case (_, null, null, null) when b != null:
        value = DevBool(b);

      case (null, _, null, null) when i != null:
        value = DevInt(i);

      case (null, null, _, null) when d != null:
        value = DevFlt(d);

      case (null, null, null, _) when s != null:
        value = DevStr(s);

      case (null, null, null, null):
        throw (Exception("reading has no data"));

      default:
        throw (Exception("reading has multiple value types"));
    }
  }

  /// Creates a [Reading] value from a GraphQL [setDevice] reply value.

  Reading.fromSetResult(GSetDeviceData_setDevice reply)
      : this.from(reply.stamp, reply.boolValue, reply.intValue,
            reply.floatValue, reply.stringValue);
}

/// Represents the history associated with a device. This is a snapshot of the
/// history, at the time of the query. There's no guarantee how long this
/// information will remain accurate.

class DevHistory {
  /// Indicates how many data points were in the device's history at the time
  /// of the query.
  final int totalPoints;

  /// The oldest reading, at the time of the query. It is possible that, after
  /// this query returns, the oldest point is dropped due to new points being
  /// added.
  final Reading oldest;

  /// The most recent reading, at the time of the query. It is possible that,
  /// after this query returns, a newer point gets added to the history.
  final Reading newest;

  const DevHistory(this.totalPoints, this.oldest, this.newest);

  /// Converts the GraphQL-generated reply type into a friendlier, Dart version.
  static DevHistory? from(GGetDeviceData_deviceInfo_history o) {
    if (o.firstPoint != null && o.lastPoint != null) {
      final oldest = o.firstPoint!;
      final newest = o.lastPoint!;

      return DevHistory(
          o.totalPoints,
          Reading.from(oldest.stamp, oldest.boolValue, oldest.intValue,
              oldest.floatValue, oldest.stringValue),
          Reading.from(newest.stamp, newest.boolValue, newest.intValue,
              newest.floatValue, newest.stringValue));
    } else {
      return null;
    }
  }
}

/// The result type for the [DrMem.getDriverInfo] query.

class DriverInfo {
  final String name;
  final String summary;
  final String description;

  const DriverInfo(this.name, this.summary, this.description);

  DriverInfo.from(GAllDriversData_driverInfo o)
      : name = o.name,
        summary = o.summary,
        description = o.description;
}

/// The result type for the [DrMem.getDeviceInfo] query.

class DevInfo {
  /// Full name of device.
  final String name;

  /// Indicates whether the device is settable.
  final bool settable;

  /// Specifies the engineering units for the device. Some devices (e.g.
  /// boolean device) don't have units associated with the value. In those
  /// cases, this field will be `null`.
  final String? units;

  /// If the device has any history in the backend storage, this field will
  /// contain information related to it.
  final DevHistory? history;

  const DevInfo(this.name, this.settable, this.units, this.history);
}

/// The [DrMem] widget implements a "provider" widget for an application's
/// tree. It manages GraphQL connections to registered DrMem nodes. It should be
/// located near the top of the tree so it remains stable during the life of
/// the application.

class DrMem extends InheritedWidget {
  // This map holds the GraphQL endpoints for known, DrMem nodes. If the
  // endpoints are `null`, we haven't yet made contact with it.

  final Map<String, (Client, Client)> _nodes = {};

  /// Creates the widget and associates it with a widget subtree.

  DrMem({required super.child, super.key});

  // Helper function to create the GraphQL query URI.

  static String _buildQueryUri(String host, int port, String qEnd) =>
      Uri(scheme: "http", host: host, port: port, path: qEnd).toString();

  // Helper function to create the GraphQL subscription URI.

  static String _buildSubUri(String host, int port, String sEnd) =>
      Uri(scheme: "ws", host: host, port: port, path: sEnd).toString();

  /// Adds a new node to the table of known DrMem nodes. When this completes,
  /// the application can interact with the node using the rest of the API.
  ///
  /// `name` is the name of the node. On a given subnet, all DrMem node should
  /// have unique names.
  ///
  /// `host` is the IP address of the host.
  ///
  /// `port` is the port number to use.
  ///
  /// `qEnd` is the URL path needed to get to the GraphQL query/mutation
  /// handler.
  ///
  /// `sEnd` is the URL path needed to get to the GraphQL subscription handler.

  void addNode(String name, String host, int port, String qEnd, String sEnd) =>
      _nodes[name] = (
        Client(
            link: HttpLink(_buildQueryUri(host, port, qEnd)), cache: Cache()),
        Client(
            link: WebSocketLink(_buildSubUri(host, port, sEnd),
                reconnectInterval: const Duration(seconds: 1),
                initialPayload: {
                  "headers": {"sec-websocket-protocol": "graphql-ws"}
                }),
            cache: Cache())
      );

  /// Removes a node from the table. The application should make sure that it
  /// has closed all subscriptions to the node because it will receive errors
  /// on any in-flight transactions.

  void removeNode(String name) {
    _nodes.remove(name);
  }

  /// Returns the instance of this class higher up in the widget tree.

  static DrMem of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DrMem>()!;

  // This class only has connections to the nodes so it never has to notify
  // any observers about updates.

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;

  // Translates the response of a [getDeviceInfo] query into a `List<DevInfo>`.

  List<DevInfo> _toDevInfoList(GGetDeviceData result) => result.deviceInfo
      .map((e) => DevInfo(
            e.deviceName,
            e.settable,
            e.units,
            DevHistory.from(e.history),
          ))
      .toList();

  // This internal function generalizes a GraphQL "RPC" call. In the `ferry`
  // GraphQL package, all GraphQL interactions return a stream -- even RPCs.
  // The incoming packets indicate the states the request goes through. This
  // function finds the packet that has the return value and passes it to a
  // translation function to get the final value.

  Future<Result> _rpc<TData, TVars, Result>(String node,
      OperationRequest<TData, TVars> request, Result Function(TData) xlat) {
    final entry = _nodes[node];

    if (entry != null) {
      final (query, _) = entry;

      return query
          .request(request)
          .where((response) => !response.loading)
          .first
          .then((value) {
        if (value.hasErrors) {
          throw Exception(value.graphqlErrors);
        } else {
          final data = value.data;

          if (data != null) {
            return xlat(data);
          } else {
            throw Exception("no data was returned from request");
          }
        }
      });
    } else {
      return Future.error(Exception('$node is not known'));
    }
  }

  /// Sets a value of a DrMem device.
  ///
  /// The target device must be settable.
  ///
  /// [node] is the name of the DrMem node that hosts the device.
  ///
  /// [device] is the name fo the device.
  ///
  /// [value] is the value to set. Most devices enforce a value type. For
  /// instance, "enable" devices are typically boolean. If the incorrect type
  /// is sent, the driver will return an error. See the driver documentation
  /// to see what data type is supported by the device.
  ///
  /// The functon returns a [Reading] structure echoing the setting and
  /// containing the timestamp of when the setting was applied. Some drivers
  /// will return an error when a setting value is out of range. Other drivers
  /// may accept the value, but clip it to remain in range. See the driver docs
  /// to understand the behavior.

  Future<Reading> setDevice(String node, String device, DevValue value) => _rpc(
      node,
      GSetDeviceReq((b) => b
        ..vars.device = device
        ..vars.value = value.toBuilder()),
      (result) => Reading.fromSetResult(result.setDevice));

  /// Retrieves driver information from a DrMem node.
  ///
  /// Each instance of DrMem interacts with it own set of hardware devices and,
  /// therefore, is built with a custom set of drviers. This function queries
  /// the node for available information on its set of drivers.
  ///
  /// [node] is the name of the DrMem node used when registering it with
  /// [addNode].

  Future<List<DriverInfo>> getDriverInfo(String node) => _rpc(
        node,
        GAllDriversReq((b) => b),
        (result) => result.driverInfo.map(DriverInfo.from).toList(),
      );

  /// Returns information about a device.
  ///
  /// [node] indicates which DrMem node should be queried.
  ///
  /// [device] specifies which device's information should be returned. If a
  /// unique, existing device name is given, a one-element `List` will be
  /// returned. If the device parameter specifies a pattern, all matching
  /// devices will have their information returned.
  ///
  /// Returns a Future that resolves to a `List` of device information
  /// ([DevInfo]), or an error.

  Future<List<DevInfo>> getDeviceInfo(String node, {required String device}) =>
      _rpc(node, GGetDeviceReq((b) => b..vars.name = device), _toDevInfoList);

  // Returns a date builder or `null`, based on the date parameter.

  GDateTimeUtcBuilder? _buildDate(DateTime? dt) {
    if (dt != null) {
      final b = GDateTimeUtcBuilder();

      b.value = dt.toIso8601String();
      return b;
    } else {
      return null;
    }
  }

  // Returns an appropriate GDateRangeBuilder based on the two input dates.
  // In DrMem's GraphQL API, if both dates are `null`, we don't provide a
  // date range (i.e. `null`). Otherwise we return a builder (possibly with
  // one of the date fields `null`.)

  GDateRangeBuilder? _buildDateRange(DateTime? a, DateTime? b) {
    if (a != null && b != null) {
      return GDateRangeBuilder()
        ..start = _buildDate(a)
        ..end = _buildDate(b);
    } else {
      return null;
    }
  }

  /// Returns a stream of readings for a device.
  ///
  /// This method provides many flexible ways to obtain device readings. Some
  /// of these options may be limited, if the DrMem node is using the simple
  /// backend (which only saves one point of history.)
  ///
  /// [node] is the name of the DrMem node that is sent the request.
  ///
  /// [device] is the name of the device whose readings should be streamed.
  ///
  /// [startTime] and [endTime] are optional arguments which create a range
  /// of time in which readings should be returned. If both are `null`, the
  /// latest and all future readings are returned until the stream is closed.
  /// If `startTime` is null, the latest reading is returned and all future
  /// readings until `endTime` is reached. If `endTime` is null, then all
  /// readings from `startTime` until the current time are returned followed
  /// by all future readings until the stream is closed. If both times are
  /// before the current time, just the data between the two times is returned.
  /// If both times are after the current time, then readings won't begin until
  /// `startTime` if reached.
  ///
  /// DrMem's configuration determines the size of a device's history. This
  /// function can only return what's available.
  Stream<Reading> monitorDevice(String node, String device,
      {DateTime? startTime, DateTime? endTime}) {
    final entry = _nodes[node];

    if (entry != null) {
      final (_, sub) = entry;

      return sub
          .request(GMonitorDeviceReq((b) => b
            ..vars.device = device
            ..vars.range = _buildDateRange(startTime, endTime)))
          .where((response) => !response.loading && response.data != null)
          .map((response) => response.data!.monitorDevice)
          .map((data) => Reading.from(data.stamp, data.boolValue, data.intValue,
              data.floatValue, data.stringValue));
    } else {
      throw (Exception('$node is not known'));
    }
  }
}
