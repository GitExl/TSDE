module SceneScripts.NodeFunction;

import std.string;

import SceneScripts.Node;

public class NodeFunction : Node {
    this(NodeFunction other) {
        super(other);
    }

    public override Node copy() {
        return new NodeFunction(this);
    }

    this(string newName) {
        super(newName);
    }

    override public string toString() {
        return format("func %s", name);
    }
}