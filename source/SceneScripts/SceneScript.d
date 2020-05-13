/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

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
