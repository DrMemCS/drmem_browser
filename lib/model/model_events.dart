import 'package:drmem_browser/sheet/sheet.dart';

// This is the base class for all events that update the state of the page.

abstract class ModelEvent {
  const ModelEvent();
}

// For this event, we're replacing a row with the one contained in the message.

class UpdateRow extends ModelEvent {
  final int index;
  final BaseRow newRow;

  const UpdateRow(this.index, this.newRow);
}

// For this event, we're inserting a row before the row specified by the index.

class InsertBeforeRow extends ModelEvent {
  final int index;
  final BaseRow newRow;

  const InsertBeforeRow(this.index, this.newRow);
}

// For this event, we're inserting a row after the row specified by the index.

class InsertAfterRow extends ModelEvent {
  final int index;
  final BaseRow newRow;

  const InsertAfterRow(this.index, this.newRow);
}

// For this event, we're inserting a row after the row specified by the index.

class DeleteRow extends ModelEvent {
  final int index;

  const DeleteRow(this.index);
}

class MoveRow extends ModelEvent {
  final int oldIndex;
  final int newIndex;

  const MoveRow(this.oldIndex, this.newIndex);
}
