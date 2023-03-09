# DrMem Browser

A browser to interact with a DrMem node.

## Getting Started

This project was built using VSCode.

NOTE: This is a new project and currently doesn't do much. This README will be updated as new features are added.

- Listens to mDNS annoucements for instances of DrMem and adds them to a ListView which some information obtained from the annoucement. Selecting an instance will take you to another screen which shows node details.
  - The details page uses GraphQL to query the node as to what drivers are installed.
- The "Sheets" tab takes you to a page where you can add rows. There are 4 row types: Divider, Comment, Device, and Chart. The first three are implemented.

Before the project can be built, the GraphQL files need to be processed. This can be done with the command:

```shell
$ flutter pub run build_runner build --delete-conflicting-outputs
```

## TO-DO List

These are the improvements that need to be made, along with a few buggy features:

- [ ] Create a "Widget" that defines the GraphQL API. Use the approach done by Bloc in which the `BuildContext` gains a field; in our case, a `drmem` field that has methods that use the GraphQL API.
  - [ ] This widget should be extracted and packaged so that other developers can make their own Flutter apps that talk to DrMem.
- [ ] Display all the devices defined by the node (in the node details page.)
- [ ] Needs to monitor when it goes in and out of the background. As it transits throw these states, it must:
  - [ ] Shutdown and restore the mDNS service.
  - [ ] Shutdown and restore GraphQL subscriptions.
- [ ] Merge the Edit/Runner Sheet views. By default we're in runner view.
  - [ ] Floating button to add row.
  - [ ] Tap and hold will allow one to drag a row to change the position.
  - [ ] Double tap puts the row in edit mode.
- [ ] Add controls to add/delete sheets.
- [ ] Sheets need to be added to persistent storage.
- [ ] Implement the Plot Row type.
  - [ ] Displaying plots
  - [ ] Editing plot configuration
  - [ ] Should support strip plots (numeric device(s) vs. time), logic plots (boolean device(s) vs.time), and X-Y (numeric device(s) vs. numeric device)
- [ ] Need to verify that all error handling is done correctly (re: GraphQL connections)
- [ ] Add unit tests
- [X] Add a GitHib workflow to build and test before merging pull requests
- [ ] Finish the third tab, "Logic"