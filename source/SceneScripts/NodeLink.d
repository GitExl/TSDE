/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

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
