module SceneScripts.NodeInstruction;

import std.string;

import SceneScripts.Node;
import SceneScripts.Parameter;

public class NodeInstruction : Node {
    public Parameter[] parameters;

    this(NodeInstruction other) {
        super(other);

        parameters.length = other.parameters.length;
        foreach (int index, Parameter parameter; other.parameters) {
            parameters[index] = other.parameters[index];
        }
    }

    public override Node copy() {
        return new NodeInstruction(this);
    }

    this(string newName) {
        super(newName);
    }

    this(string newName, Parameter[] parameters) {
        super(newName);

        this.parameters = parameters;
    }

    this(string newName, Parameter[] parameters, JumpType jumpType, int jumpTo) {
        super(newName);

        this.parameters = parameters;
        this.jumpType = jumpType;
        this.jumpTo = jumpTo;
    }

    override public string toString() {
        string[] params;
        string[] comments;
        foreach (ref Parameter param; parameters) {
            params ~= param.toString();
            if (param.comment) {
                comments ~= param.comment;
            }
        }

        if (comments.length) {
            return format("%s(%s);  // %s", name, join(params, ", "), join(comments, ", "));
        }
        return format("%s(%s);", name, join(params, ", "));
    }
}
