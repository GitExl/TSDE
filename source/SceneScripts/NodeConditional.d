/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module SceneScripts.NodeConditional;

import std.string;

import SceneScripts.Node;
import SceneScripts.Parameter;

public class NodeConditional : Node {
    public Parameter lh;
    public Parameter rh;
    public Parameter operator;

    public override Node copy() {
        return new NodeConditional(this);
    }

    this(NodeConditional other) {
        super(other);

        lh = other.lh;
        rh = other.rh;
        operator = other.operator;
    }

    this(string name, Parameter lh, Parameter rh, Parameter op, int jumpTo) {
        if (op.type != ParameterType.OPERATOR) {
            throw new Exception("Conditional operator parameter is not of type OPERATOR.");
        }

        super(name);

        this.lh = lh;
        this.operator = op;
        this.rh = rh;
        this.jumpType = JumpType.BLOCK;
        this.jumpTo = jumpTo;
    }

    override public string toString() {
        string[] params;
        string[] comments;

        if (lh.comment) {
            comments ~= lh.comment;
        }
        if (rh.comment) {
            comments ~= rh.comment;
        }

        if (comments.length) {
            return format("%s (%s %s %s)  // %s", name, lh.toString(), operator.value, rh.toString(), join(comments, ", "));
        }
        return format("%s (%s %s %s)", name, lh.toString(), operator.value, rh.toString());
    }
}