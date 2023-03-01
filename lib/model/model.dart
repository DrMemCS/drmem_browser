import 'package:bloc/bloc.dart';
import 'package:drmem_browser/sheet/sheet.dart';
import 'page_events.dart';

// Defines the page's data model and handles events to modify it.

class PageModel extends Bloc<PageEvent, List<BaseRow>> {
  // Dummy default data used for testing. This will be deleted in the final
  // product.

  static List<BaseRow> dummyDefaults = <BaseRow>[
    CommentRow("This is a comment.\n\nCan we insert newlines?"),
    const DeviceRow("demo-timer:output", false),
    const DeviceRow("demo-timer:enable", true),
    const EmptyRow(),
    CommentRow("Here's another comment."),
    const PlotRow(),
  ];

  // Constructor.

  PageModel() : super([]) {
    on<UpdateRow>(_updateRow);
    on<InsertBeforeRow>(_insertBeforeRow);
    on<InsertAfterRow>(_insertAfterRow);
    on<DeleteRow>(_deleteRow);
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

  // This handles the event that inserts a new row. The sender will specify the
  // relative node to use. The UI will prevent this message from being sent if
  // the list is empty.

  void _insertBeforeRow(InsertBeforeRow event, Emitter<List<BaseRow>> emit) {
    // If the index is in range, insert the new row before it.

    if (event.index >= 0 && event.index < state.length) {
      var newState = state.toList();

      newState.insert(event.index, event.newRow);
      emit(newState);
    }
  }

  // This handles the event that inserts a new row after another. The sender
  // will specify the relative node to use. The UI will prevent this message
  // from being sent if the list is empty.

  void _insertAfterRow(InsertAfterRow event, Emitter<List<BaseRow>> emit) {
    // If the index is in range, insert the new row before it.

    if (event.index >= 0 && event.index < state.length) {
      var newState = state.toList();

      newState.insert(event.index + 1, event.newRow);
      emit(newState);
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
