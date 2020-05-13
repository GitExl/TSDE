module SceneScripts.NodeLink;

import std.string;

import SceneScripts.Node;

public class NodeLink : Node {
    public string linkName;

    this(NodeLink other) {
        super(other);

        linkName = other.linkName;
    }

    public override Node copy() {
        return new NodeLink(this);
    }

    this(string newName, string linkName) {
        super(newName);

        this.linkName = linkName;
    }

    override public string toString() {
        return format("func %s = %s;\n", name, linkName);
    }
}
