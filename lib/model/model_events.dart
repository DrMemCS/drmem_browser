import 'package:drmem_browser/sheet/sheet.dart';

// This is the base class for all events that update the state of the page.

abstract class ModelEvent {}

// For this event, we're replacing a row with the one contained in the message.

class UpdateRow extends ModelEvent {
  final int index;
  final BaseRow newRow;

  UpdateRow(this.index, this.newRow);
}

// For this event, we're inserting a row before the row specified by the index.

class InsertBeforeRow extends ModelEvent {
  final int index;
  final BaseRow newRow;

  InsertBeforeRow(this.index, this.newRow);
}

// For this event, we're inserting a row after the row specified by the index.

class InsertAfterRow extends ModelEvent {
  final int index;
  final BaseRow newRow;

  InsertAfterRow(this.index, this.newRow);
}

// For this event, we're inserting a row after the row specified by the index.

class DeleteRow extends ModelEvent {
  final int index;

  DeleteRow(this.index);
}
