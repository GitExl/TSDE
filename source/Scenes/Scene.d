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
