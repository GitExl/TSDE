module SceneScripts.SceneScript;

import SceneScripts.Node;

public struct SceneObject {
    string name;
    uint[16] pointers;
    Node root;

    this(string name) {
        this.name = name;
    }
}

public struct SceneScript {
    string key;
    SceneObject[] objects;
    string[uint] labels;
}
