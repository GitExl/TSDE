module Scenes.JSONSceneWriter;

import std.string;
import std.stdio;
import std.json;
import std.conv;
import std.file;

import List.ListWriterInterface;

import Scenes.Scene;

public class JSONSceneWriter : ListWriterInterface!Scene {

    private string _outputPath;

    public this(immutable string outputPath) {
        _outputPath = outputPath;
    }

    public void write(const Scene[] scenes) {
        mkdirRecurse(_outputPath);
        foreach (const Scene scene; scenes) {
            JSONValue json = serialize(scene);
            File file = File(format("%s/%s.json", _outputPath, scene.key), "w");
            file.writeln(json.toJSON(true));
            file.close();    
        }
    }

    public JSONValue serialize(const Scene scene) {
        JSONValue value;

        value["name"] = scene.name;
        value["tilesetL12"] = scene.tileset12;
        value["palette"] = scene.palette;
        value["map"] = scene.map;
        value["script"] = scene.script;
        if (scene.chestPointer) {
            value["chestPointer"] = scene.chestPointer;
        }

        JSONValue mapArea;
        mapArea["left"] = scene.left;
        mapArea["top"] = scene.top;
        mapArea["right"] = scene.right;
        mapArea["bottom"] = scene.bottom;
        value["mapArea"] = mapArea;

        if (scene.music != 0xFF) {
            value["music"] = scene.music;
        }
        if (scene.tileset3 != 0xFF) {
            value["tilesetL3"] = scene.tileset3;
        }

        if (scene.chests.length) {
            JSONValue[] chests;
            foreach (SceneChest chest; scene.chests) {
                chests ~= serializeChest(chest);
            }
            value["chests"] = chests;
        }

        if (scene.exits.length) {
            JSONValue[] exits;
            foreach (SceneExit exit; scene.exits) {
                exits ~= serializeExit(exit);
            }
            value["exits"] = exits;
        }

        return value;
    }

    private JSONValue serializeExit(const SceneExit exit) {
        JSONValue value;

        value["x"] = exit.x;
        value["y"] = exit.y;
        value["width"] = exit.width;
        value["height"] = exit.height;
        value["destination"] = exit.destination;
        value["facing"] = to!string(exit.facing);
        value["destinationX"] = exit.destinationX;
        value["destinationY"] = exit.destinationY;

        return value;
    }

    private JSONValue serializeChest(const SceneChest chest) {
        JSONValue value;

        value["x"] = chest.x;
        value["y"] = chest.y;
        if (chest.item) {
            value["item"] = chest.item;
        }
        if (chest.gold) {
            value["gold"] = chest.gold;
        }

        return value;
    }

}