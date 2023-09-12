// Holds information about DrMem nodes.

class NodeInfo {
  final String name;
  final String version;
  final String location;
  final String host;
  final int port;
  final DateTime bootTime;
  final String queries;
  final String mutations;
  final String subscriptions;
  bool active;

  NodeInfo(
      {required this.name,
      required this.version,
      required this.location,
      required this.host,
      required this.port,
      required this.bootTime,
      required this.queries,
      required this.mutations,
      required this.subscriptions})
      : active = false;

  Map<String, dynamic>? toJson() => {
        'name': name,
        'version': version,
        'location': location,
        'host': host,
        'port': port,
        'bootTime': bootTime,
        'queries': queries,
        'mutations': mutations,
        'subscriptions': subscriptions
      };

  static NodeInfo? fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'name': String name,
          'version': String version,
          'location': String location,
          'host': String host,
          'port': int port,
          'bootTime': DateTime bootTime,
          'queries': String queries,
          'mutations': String mutations,
          'subscriptions': String subscriptions
        }) {
      return NodeInfo(
          name: name,
          version: version,
          location: location,
          host: host,
          port: port,
          bootTime: bootTime,
          queries: queries,
          mutations: mutations,
          subscriptions: subscriptions);
    }
    return null;
  }
}
