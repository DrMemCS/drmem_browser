import 'package:drmem_provider/drmem_provider.dart';
import 'package:drmem_browser/sheet/row.dart';

// This is the base class for all events that update the state of the sheet.

abstract class ModelEvent {
  const ModelEvent();
}

// Replace a row with the one contained in the message. The currently selected
// sheet is the one that gets modified.

class UpdateRow extends ModelEvent {
  final int index;
  final BaseRow newRow;

  const UpdateRow(this.index, this.newRow);
}

// Deletes the row, in the currently selected sheet, at the specified index.

class DeleteRow extends ModelEvent {
  final int index;

  const DeleteRow(this.index);
}

// Appends a row to the end of the currently selected sheet.

class AppendRow extends ModelEvent {
  final BaseRow newRow;

  const AppendRow(this.newRow);
}

// Moves a row found at `oldIndex` to `newIndex`. The currently selected sheet
// is the one that gets modified.

class MoveRow extends ModelEvent {
  final int oldIndex;
  final int newIndex;

  const MoveRow(this.oldIndex, this.newIndex);
}

// Changes the selected sheet. The application uses this to determine which
// sheet to display.

class SelectSheet extends ModelEvent {
  final String name;

  const SelectSheet(this.name);
}

// Renames the selected sheet.

class RenameSelectedSheet extends ModelEvent {
  final String newName;

  const RenameSelectedSheet(this.newName);
}

// Adds a new, empty sheet to the application's set of sheets.

class AddSheet extends ModelEvent {
  const AddSheet();
}

// Deletes the currently selected sheet from the application's set of sheets.

class DeleteSheet extends ModelEvent {
  const DeleteSheet();
}

// Adds node information to the application's list of nodes. If the node already
// exists, then it is updated.

class AddNode extends ModelEvent {
  final NodeInfo info;

  const AddNode(this.info);
}

// Marks the specified node as "inactive". The node will remain in the
// application's list of nodes, but it may get displayed differently because
// it's inactive.

class NodeInactive extends ModelEvent {
  final String name;

  const NodeInactive(this.name);
}

// Sets the default node. When new device rows are added to a sheet, this node
// will be automatically used for the device.

class SetDefaultNode extends ModelEvent {
  final String name;

  const SetDefaultNode(this.name);
}

// Generates a new client ID. DrMem needs to be configured to accept specific
// client IDs, so changing the application's ID will prevent it from using
// instances of DrMem until they've been configured properly.

class ResetClientId extends ModelEvent {
  const ResetClientId();
}
