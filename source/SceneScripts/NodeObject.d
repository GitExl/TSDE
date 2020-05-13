module SceneScripts.NodeObject;

import std.string;

import SceneScripts.Node;

public class NodeObject : Node {
    this(NodeObject other) {
        super(other);
    }

    public override Node copy() {
        return new NodeObject(this);
    }

    this(string newName) {
        super(newName);
    }

    override public string toString() {
        return format("obj %s", name);
    }
}