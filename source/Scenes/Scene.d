/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module Scenes.Scene;

public enum SceneExitFacing : ubyte {
    UP,
    DOWN,
    LEFT,
    RIGHT,
}

public struct SceneExit {
    int x;
    int y;
    ushort width;
    ushort height;
    string destination;
    SceneExitFacing facing;
    int destinationX;
    int destinationY;
}

public struct SceneChest {
    ushort x;
    ushort y;
    uint gold;
    string item;
    uint pointer;
}

public struct Scene {
    string key;
    string name;

    ubyte music;

    ubyte tileset12;
    ubyte tileset3;
    ubyte palette;

    short left;
    short top;
    short right;
    short bottom;
    
    ushort map;
    ushort script;
    
    SceneChest[] chests;
    string chestPointer;

    SceneExit[] exits;
}
