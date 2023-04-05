import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:drmem_browser/sheet/sheet.dart';
import 'model_events.dart';

// Defines the page's data model and handles events to modify it.

class PageModel extends Bloc<ModelEvent, List<BaseRow>> {
  // Dummy default data used for testing. This will be deleted in the final
  // product.

  static List<BaseRow> dummyDefaults = <BaseRow>[
    CommentRow("This is a comment.\n\nCan we insert newlines?",
        key: UniqueKey()),
    DeviceRow("demo-timer:output", key: UniqueKey()),
    DeviceRow("demo-timer:enable", key: UniqueKey()),
    EmptyRow(key: UniqueKey()),
    CommentRow("Here's another comment.", key: UniqueKey()),
    PlotRow(key: UniqueKey()),
  ];

  // Constructor.

  PageModel() : super([]) {
    on<UpdateRow>(_updateRow);
    on<AppendRow>(_appendRow);
    on<DeleteRow>(_deleteRow);
    on<MoveRow>(_moveRow);
  }

  void _moveRow(MoveRow event, Emitter<List<BaseRow>> emit) {
    var newState = state.toList();

    final newIndex =
        event.oldIndex < event.newIndex ? event.newIndex - 1 : event.newIndex;
    final BaseRow element = newState.removeAt(event.oldIndex);

    newState.insert(newIndex, element);
    emit(newState);
  }

  void _appendRow(AppendRow event, Emitter<List<BaseRow>> emit) {
    var newState = state.toList();

    newState.add(event.newRow);
    emit(newState);
  }

  // This event is received when a child widget wants to change the type of a
  // row. This also needs to handle the case when the list of rows is empty.

  void _updateRow(UpdateRow event, Emitter<List<BaseRow>> emit) {
    // If the index is in range, replace the corresponding enry with the new
    // row in the event.

    if (event.index >= 0 && event.index < state.length) {
      var newState = state.toList();

      newState[event.index] = event.newRow;
      emit(newState);
    }

    // If the list is empty and the index is 0, then make a singleton list.

    else if (event.index == 0 && state.isEmpty) {
      emit([event.newRow]);
    }
  }

  void _deleteRow(DeleteRow event, Emitter<List<BaseRow>> emit) {
    // If the index is in range, delete row.

    if (event.index >= 0 && event.index < state.length) {
      var newState = state.toList();

      newState.removeAt(event.index);
      emit(newState);
    }
  }

  get isNotEmpty => state.isNotEmpty;
}
