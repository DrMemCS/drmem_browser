import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:drmem_browser/sheet/sheet.dart';
import 'model_events.dart';

// Holds the configuration for one sheet of parameters.

class PageConfig {
  final List<BaseRow> _content = [];

  List<BaseRow> get rows => _content;

  void appendRow(BaseRow row) => _content.add(row);

  void moveRow(int oIdx, int nIdx) {
    if (oIdx >= 0 &&
        oIdx < _content.length &&
        nIdx >= 0 &&
        nIdx < _content.length) {
      final newIndex = oIdx < nIdx ? nIdx - 1 : nIdx;
      final BaseRow element = _content.removeAt(oIdx);

      _content.insert(newIndex, element);
    }
  }

  void removeRow(int index) {
    if (index >= 0 && index < _content.length) {
      _content.removeAt(index);
    }
  }

  void updateRow(int index, BaseRow row) {
    if (index >= 0 && index < _content.length) {
      _content[index] = row;
    } else {
      _content.add(row);
    }
  }
}

// Holds the state of the app's data model. This model consists of the set of
// DrMem nodes we know about and our local database of sheets that were
// configured. It also keeps track of the last sheet that was selected.

class AppState {
  UniqueKey id = UniqueKey();
  String selectedSheet;
  final Map<String, PageConfig> _sheets;

  AppState(this.selectedSheet, this._sheets);

  AppState.withMyData()
      : _sheets = {},
        selectedSheet = "" {
    var pc = PageConfig();

    pc.appendRow(DeviceRow("sump:state", label: "Active", key: UniqueKey()));
    pc.appendRow(DeviceRow("sump:duty", label: "Duty Cycle", key: UniqueKey()));
    pc.appendRow(DeviceRow("sump:in-flow", label: "In-Flow", key: UniqueKey()));
    pc.appendRow(
        DeviceRow("sump:duration", label: "Off-Time", key: UniqueKey()));
    pc.appendRow(EmptyRow(key: UniqueKey()));
    pc.appendRow(DeviceRow("weather:precip-rate",
        label: "Rainfall Rate", key: UniqueKey()));
    pc.appendRow(DeviceRow("weather:precip-total",
        label: "Rainfall Total", key: UniqueKey()));

    _sheets["Sump Status"] = pc;

    pc = PageConfig();

    pc.appendRow(DeviceRow("weather:temperature", key: UniqueKey()));
    pc.appendRow(DeviceRow("weather:dewpoint", key: UniqueKey()));
    pc.appendRow(DeviceRow("weather:wind-chill", key: UniqueKey()));
    pc.appendRow(DeviceRow("weather:solar-rad", key: UniqueKey()));
    pc.appendRow(DeviceRow("weather:precip-rate", key: UniqueKey()));
    pc.appendRow(DeviceRow("weather:precip-total", key: UniqueKey()));

    _sheets["Weather Info"] = pc;

    selectedSheet = "Sump Status";
  }

  List<String> get sheetNames =>
      _sheets.isNotEmpty ? _sheets.keys.toList() : ["Untitled"];

  // Returns the page that's currently selected. If `selectedSheet` refers to a
  // non-existent entry, return an empty sheet.

  PageConfig get selected => _sheets[selectedSheet] ?? PageConfig();
}

// Defines the page's data model and handles events to modify it.

class Model extends Bloc<ModelEvent, AppState> {
  Model() : super(AppState.withMyData()) {
    on<AppendRow>(_appendRow);
    on<DeleteRow>(_deleteRow);
    on<UpdateRow>(_updateRow);
    on<MoveRow>(_moveRow);
    on<SelectSheet>(_selectSheet);
    on<RenameSelectedSheet>(_renameSelectedSheet);
    on<AddSheet>(_addSheet);
  }

  // Adds a new row to the end of the currently selected sheet.

  void _appendRow(AppendRow event, Emitter<AppState> emit) {
    AppState tmp = AppState.init(state.selectedSheet, state._sheets);

    tmp._sheets[tmp.selectedSheet]!.appendRow(event.newRow);
    developer.log("new state: ${tmp.selected.content}");
    emit(tmp);
  }

  // Removes the row specified by the index from the currently selected sheet.

  void _deleteRow(DeleteRow event, Emitter<AppState> emit) {
    AppState tmp = AppState.init(state.selectedSheet, state._sheets);

    tmp._sheets[tmp.selectedSheet]!.removeRow(event.index);
    emit(tmp);
  }

  // This event is received when a child widget wants to change the type of a
  // row. This also needs to handle the case when the list of rows is empty.

  void _updateRow(UpdateRow event, Emitter<AppState> emit) {
    AppState tmp = AppState.init(state.selectedSheet, state._sheets);

    tmp._sheets[tmp.selectedSheet]!.updateRow(event.index, event.newRow);
    emit(tmp);
  }

  void _moveRow(MoveRow event, Emitter<AppState> emit) {
    AppState tmp = AppState.init(state.selectedSheet, state._sheets);

    tmp._sheets[tmp.selectedSheet]!.moveRow(event.oldIndex, event.newIndex);
    emit(tmp);
  }

  void _selectSheet(SelectSheet event, Emitter<AppState> emit) {
    AppState tmp = AppState.init(state.selectedSheet, state._sheets);

    if (!tmp._sheets.containsKey(event.name)) {
      tmp._sheets[event.name] = PageConfig();
    }
    tmp.selectedSheet = event.name;
    emit(tmp);
  }

  void _renameSelectedSheet(RenameSelectedSheet event, Emitter<AppState> emit) {
    AppState tmp = AppState.init(state.selectedSheet, state._sheets);

    // If the new name doesn't exist, then we can proceed. If it does exist,
    // we ignore the request.
    //
    // TODO: We should report the error.

    if (!tmp._sheets.containsKey(event.newName)) {
      PageConfig conf = tmp._sheets.remove(tmp.selectedSheet)!;

      tmp.selectedSheet = event.newName;
      tmp._sheets[event.newName] = conf;
      emit(tmp);
    } else {
      developer.log("can't rename sheet ... ${event.newName} already exists");
    }
  }

  // Adds a new, empty sheet to the application state. The title will be of
  // the form "Untitled#", where the number will be determined based on the
  // availability.

  void _addSheet(AddSheet event, Emitter<AppState> emit) {
    AppState tmp = AppState.init(state.selectedSheet, state._sheets);

    tmp.selectedSheet = tmp.nextUntitled();
    tmp._sheets[tmp.selectedSheet] = PageConfig();
    emit(tmp);
  }
}
