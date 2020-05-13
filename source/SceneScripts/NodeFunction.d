/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

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