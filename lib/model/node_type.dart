const String PN_URL = "https://rpc.idena.dev";
const String PN_ADDRESS = "(public node)";

const int SHARED_NODE = 1;
const int NORMAL_LOCAL_NODE = 2;
const int NORMAL_VPS_NODE = 3;
const int PUBLIC_NODE = 4;
const int DEMO_NODE = 5;
const int UNKOWN_NODE = 0;

class NodeType {
  NodeType({this.type, this.label});
  int? type;
  String? label;
}
