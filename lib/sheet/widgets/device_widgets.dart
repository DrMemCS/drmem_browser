import 'package:drmem_browser/sheet/widgets/data_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drmem_provider/drmem_provider.dart';

import 'package:drmem_browser/model/model_events.dart';
import 'package:drmem_browser/model/model.dart';
import 'package:drmem_browser/sheet/row.dart';

enum _DeviceModelAspect { label, name, units, settable, reading }

// This is an `InheritedModel` widget which holds the latest information
// associated with a device. Widgets downstream can register for apects and
// will get updated when their field of interest changes.

class _DeviceModel extends InheritedModel<_DeviceModelAspect> {
  final bool settable;
  final String label;
  final Device device;
  final String? units;
  final (DateTime, DevValue)? reading;

  const _DeviceModel(
      {required this.label,
      required this.device,
      this.settable = false,
      this.units,
      this.reading,
      required super.child});

  @override
  bool updateShouldNotify(covariant _DeviceModel oldWidget) =>
      settable != oldWidget.settable ||
      label != oldWidget.label ||
      device != oldWidget.device ||
      units != oldWidget.units ||
      reading != oldWidget.reading;

  @override
  bool updateShouldNotifyDependent(
          covariant _DeviceModel oldWidget, Set<_DeviceModelAspect> deps) =>
      (settable != oldWidget.settable &&
          deps.contains(_DeviceModelAspect.settable)) ||
      (label != oldWidget.label && deps.contains(_DeviceModelAspect.label)) ||
      (device != oldWidget.device && deps.contains(_DeviceModelAspect.name)) ||
      (units != oldWidget.units && deps.contains(_DeviceModelAspect.units)) ||
      (reading != oldWidget.reading &&
          deps.contains(_DeviceModelAspect.reading));
}

// Creates a widget that displays a row of information for a DrMem device.

class DeviceWidget extends StatelessWidget {
  final Stream<_DeviceModel>? Function(BuildContext) _builder;

  // The constructor simply builds a function that is used to set up the stream
  // of readings from a device.

  DeviceWidget({String? label, required Device device, super.key})
      : _builder = _buildStream(label: label, device: device);

  // This private, helper method builds a closure which creates a stream that
  // returns `_DeviceModel` widgets. This allows the `DeviceWidget` to be
  // a `StatelessWidget` since all the updates are returned by the stream.

  static Stream<_DeviceModel>? Function(BuildContext) _buildStream(
      {String? label, required Device device}) {
    final cookedLabel = label ?? device.name;

    return (BuildContext context) async* {
      try {
        // First, get device information from the node. This will tell us
        // whether the device is settable and also provide the units, if any.

        final di = await DrMem.getDeviceInfo(context, device: device);

        // If the query returns one instance of device information, we're good.

        if (di
            case [DeviceInfo(settable: bool settable, units: String? units)]) {
          // Yield the first InheritedModel. In this case, all fields except
          // the reading field is complete.

          yield _DeviceModel(
              label: cookedLabel,
              device: device,
              units: units,
              settable: settable,
              child: const _DeviceRowWrapper());

          // If the widget is still mounted in the tree, stream the readings
          // of the device.

          if (context.mounted) {
            yield* DrMem.monitorDevice(context, device).map((event) =>
                _DeviceModel(
                    label: cookedLabel,
                    device: device,
                    units: units,
                    settable: settable,
                    reading: (event.stamp, event.value),
                    child: const _DeviceRowWrapper()));
          }
        } else {
          throw Exception("bad device ${device.name}@${device.node}");
        }
      } catch (ex) {
        // ignore: use_build_context_synchronously
        displayError(context, ex.toString());
      }
    };
  }

  static _DeviceModel _of(BuildContext context, _DeviceModelAspect aspect) =>
      InheritedModel.inheritFrom<_DeviceModel>(context, aspect: aspect)!;

  static String? getUnits(BuildContext context) =>
      _of(context, _DeviceModelAspect.units).units;

  static String getLabel(BuildContext context) =>
      _of(context, _DeviceModelAspect.label).label;

  static bool getSettable(BuildContext context) =>
      _of(context, _DeviceModelAspect.settable).settable;

  static Device getDevice(BuildContext context) =>
      _of(context, _DeviceModelAspect.label).device;

  static DateTime? getTimestamp(BuildContext context) =>
      _of(context, _DeviceModelAspect.reading).reading?.$1;

  static DevValue? getReading(BuildContext context) =>
      _of(context, _DeviceModelAspect.reading).reading?.$2;

  @override
  Widget build(BuildContext context) => StreamBuilder(
      stream: _builder(context),
      builder: (context, snapshot) =>
          snapshot.hasData ? snapshot.data! : Container());
}

// Private widget which builds a device row. This row should be a descendant of
// a `_DeviceModel` because it uses widgets that display updating field of a
// device model.

class _DeviceRowWrapper extends StatefulWidget {
  const _DeviceRowWrapper();

  @override
  _DeviceRowWrapperState createState() => _DeviceRowWrapperState();
}

class _DeviceRowWrapperState extends State<_DeviceRowWrapper> {
  bool _expand = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData td = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _expand = !_expand),
                child: Text(
                  DeviceWidget.getLabel(context),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: td.colorScheme.primary),
                ),
              ),
            ),
            const DataWidget(),
          ],
        ),
        if (_expand) const Text("show the timestamp"),
      ],
    );
  }
}

class DeviceEditor extends StatefulWidget {
  final int _idx;
  final Device _device;
  final String _label;

  const DeviceEditor(this._idx, this._device, {String? label, super.key})
      : _label = label ?? "";

  @override
  State<DeviceEditor> createState() => _DeviceEditorState();
}

class _DeviceEditorState extends State<DeviceEditor> {
  late final TextEditingController ctrlDevice;
  late final TextEditingController ctrlLabel;
  final RegExp re = RegExp(r'^[-:\w\d]*$');

  @override
  void initState() {
    ctrlDevice = TextEditingController(text: widget._device.name);
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
  Widget build(BuildContext context) => Expanded(
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
                    decoration: getTextFieldDecoration(context, "Device name"),
                    controller: ctrlDevice,
                    onSubmitted: (value) => context.read<Model>().add(
                          UpdateRow(
                              widget._idx,
                              DeviceRow(Device(name: value, node: "rpi4"),
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
                      getTextFieldDecoration(context, "Label (optional)"),
                  controller: ctrlLabel,
                  onSubmitted: (value) => context.read<Model>().add(
                        UpdateRow(
                            widget._idx,
                            DeviceRow(Device(name: ctrlDevice.text),
                                label: value, key: UniqueKey())),
                      )),
            ),
          ],
        ),
      );
}
