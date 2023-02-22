# DrMem Browser

A browser to interact with a DrMem node.

## Getting Started

This project was built using VSCode.

NOTE: This is a new project and currently doesn't do much. This README will be updated as new features are added.

- Listens to mDNS annoucements for instances of DrMem and adds them to a ListView which some information obtained from the annoucement. Selecting an instance will take you to another screen which shows node details.
  - The details page uses GraphQL to query the node as to what drivers are installed.

Before the project can be built, the GraphQL files need to be processed. This can be done with the command:

```shell
$ flutter pub run build_runner build --delete-conflicting-outputs
```
