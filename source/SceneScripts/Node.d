module SceneScripts.Node;

import std.stdio;
import std.array;
import std.algorithm;

public enum JumpType {
    NONE,
    BLOCK,
    GOTO,
}

public abstract class Node {
    public string name;
    public JumpType jumpType;
    public int jumpTo;
    public int address;
    public Node[] children;

    public abstract Node copy();

    this(Node other) {
        name = other.name;
        jumpType = other.jumpType;
        jumpTo = other.jumpTo;
        address = other.address;

        children.length = other.children.length;
        foreach (int index, Node child; other.children) {
            children[index] = other.children[index].copy();
        }
    }

    this(string newName) {
        this.name = newName;
    }

    public int addChildren(Node[] nodes, int startNode, int endAddress) {
        int currentNode = startNode;

        Node node = nodes[currentNode];
        while (node.address < endAddress) {
            children ~= node.copy();

            currentNode++;
            if (currentNode >= nodes.length) {
                break;
            }
            node = nodes[currentNode];
        }

        return currentNode;
    }

    public void output(File file, string[uint] labels, const int indent) {
        if (address in labels) {
            file.writeln();
            file.writefln("%s%s:", "  ".replicate(max(0, indent)), labels[address]);
        }
        file.writef("%s%s", "  ".replicate(indent), toString());

        if (children.length) {
            file.writeln(" {");
            foreach (Node childNode; children) {
                childNode.output(file, labels, indent + 1);
            }
            file.writeln("  ".replicate(indent), "}");
            if (!jumpTo) {
                file.writeln();
            }
        } else {
            file.writeln();
        }
    }

    public void processBlocks() {
        Node[] newNodes;

        for (int index = 0; index < children.length; index++) {
            Node node = children[index].copy();
            if (node.jumpType == JumpType.BLOCK) {
                index = node.addChildren(children, index + 1, node.jumpTo) - 1;
                node.processBlocks();
            }

            newNodes ~= node;
        }

        children = newNodes;
    }
}
