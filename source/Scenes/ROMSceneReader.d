/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module Scenes.ROMSceneReader;

import std.json;
import std.stdio;
import std.string;
import std.algorithm;

import Scenes.Scene;

import List.ListReaderInterface;

import Items.ItemList;

import StringTools;
import JSONTools;
import BinaryFile;

public class ROMSceneReader : ListReaderInterface!Scene {

    private JSONValue _config;
    private BinaryFile _rom;
    private ItemList _items;
    private JSONValue _names;

    public this(JSONValue config, BinaryFile rom, ItemList items) {
        _config = config;
        _rom = rom;
        _items = items;
    }

    public Scene[] read() {
        immutable uint sceneCount = cast(uint)_config["scenes"]["count"].integer;
        _names = loadStubbedJSONNames(_config["scenes"]["names"].str, "scene", sceneCount, false);

        Scene[] scenes = readScenes(sceneCount);
        readExits(scenes);
        readChests(scenes);
        return scenes;
    }

    private Scene[] readScenes(immutable uint count) {
        Scene[] scenes = new Scene[count];

        immutable uint address = cast(uint)_config["scenes"]["addressScenes"].integer;
        _rom.setPosition(address);
        foreach (int index, ref Scene scene; scenes) {
            scene = readScene(index);
        }

        return scenes;
    }

    private Scene readScene(immutable uint index ) {
        Scene scene;

        scene.name = _names[index].str;
        scene.key = format("%03d_%s", index, generateKeyFromName(scene.name));

        scene.music = _rom.read!ubyte();
        scene.tileset12 = _rom.read!ubyte();
        scene.tileset3 = _rom.read!ubyte();
        scene.palette = _rom.read!ubyte();
        scene.map = _rom.read!ushort();

        _rom.read!ushort();

        scene.script = _rom.read!ushort();
        scene.left = _rom.read!ubyte();
        scene.top = _rom.read!ubyte();
        scene.right = _rom.read!ubyte();
        scene.bottom = _rom.read!ubyte();

        return scene;
    }

    private void readExits(Scene[] scenes) {
        immutable uint address = cast(uint)_config["scenes"]["addressExits"].integer;
        immutable uint bank = address & 0xFF0000;
        _rom.setPosition(address);

        // One pointer for each scene, with an extra one to determine the last scene's end.
        int first = int.max;
        int last = int.min;
        uint[] pointers = new uint[scenes.length + 1];
        foreach (ref uint pointer; pointers) {
            pointer = bank + _rom.read!ushort();
            first = min(pointer, first);
            last = max(pointer, last);
        }
        const int count = (last - first) / 7;

        _rom.setPosition(first);
        SceneExit[] exits = new SceneExit[count];
        foreach (ref SceneExit exit; exits) {
            exit = readExit(scenes);
        }

        assignSceneExits(scenes, exits, pointers, first);
    }

    private SceneExit readExit(Scene[] scenes) {
        SceneExit exit;

        exit.x = _rom.read!ubyte() * 16;
        exit.y = _rom.read!ubyte() * 16;

        const ubyte size = _rom.read!ubyte();
        if (size & 0x80) {
            exit.width = 16;
            exit.height = ((size & 0x7F) + 1) * 16;
        } else {
            exit.width = ((size & 0x7F) + 1) * 16;
            exit.height = 16;
        }
        
        const ushort v0 = _rom.read!ushort();
        exit.destination = scenes[v0 & 0x1FF].key;
        
        const ubyte v1 = (v0 >> 9) & 0x3;
        switch (v1) {
            case 0: exit.facing = SceneExitFacing.UP; break;
            case 1: exit.facing = SceneExitFacing.DOWN; break;
            case 2: exit.facing = SceneExitFacing.LEFT; break;
            case 3: exit.facing = SceneExitFacing.RIGHT; break;
            default:
                throw new Exception("Unkown exit facing.");
        }

        const ubyte v2 = (v0 >> 11) & 0x3;
        if (v2 & 0x1) {
            exit.destinationX = -8;
        }
        if (v2 & 0x2) {
            exit.destinationY = -8;
        }

        exit.destinationX += _rom.read!ubyte() * 16;
        exit.destinationY += _rom.read!ubyte() * 16;

        return exit;
    }

    private void assignSceneExits(Scene[] scenes, SceneExit[] exits, uint[] pointers, immutable uint first) {
        int pointer;
        int endPointer;

        for (int index = 0; index < scenes.length; index++) {
            pointer = pointers[index];
            endPointer = pointers[index + 1];

            while (pointer < endPointer) {
                const int exitIndex = cast(int)((pointer - first) / 7);
                scenes[index].exits ~= exits[exitIndex];
                pointer += 7;
            }
        }
    }

    private void readChests(Scene[] scenes) {
        immutable uint address = cast(uint)_config["scenes"]["addressChests"].integer;
        immutable uint bank = address & 0xFF0000;
        _rom.setPosition(address);

        // One pointer for each scene, with an extra one to determine the last scene's end.
        int first = int.max;
        int last = int.min;
        uint[] pointers = new uint[scenes.length + 1];
        foreach (ref uint pointer; pointers) {
            pointer = bank + _rom.read!ushort();
            first = min(pointer, first);
            last = max(pointer, last);
        }
        const int count = (last - first) / 4;

        SceneChest[] chests = new SceneChest[count];
        _rom.setPosition(first);
        foreach (ref SceneChest chest; chests) {
            chest = readChest();
        }

        assignSceneChests(scenes, chests, pointers, first);
    }

    private SceneChest readChest() {
        SceneChest chest;

        chest.x = _rom.read!ubyte();
        chest.y = _rom.read!ubyte();
        
        const ushort contents = _rom.read!ushort();
        if (chest.x == 0 && chest.y == 0) {
            chest.pointer = contents;
        } else if (contents & 0x8000) {
            chest.gold = (contents & 0x3FFF) * 2;
        } else if (!(contents & 0x4000)) {
            chest.item = _items.getKeyByIndex(contents & 0x3FFF);
        }

        return chest;
    }

    private void assignSceneChests(Scene[] scenes, SceneChest[] chests, uint[] pointers, uint first) {
        int pointer;
        int endPointer;

        for (int index = 0; index < scenes.length; index++) {
            pointer = pointers[index];
            endPointer = pointers[index + 1];

            while (pointer < endPointer) {
                const int chestIndex = cast(int)((pointer - first) / 4);
                if (chests[chestIndex].x == 0 && chests[chestIndex].y == 0) {
                    scenes[index].chestPointer = scenes[chests[chestIndex].pointer].key;
                } else {
                    scenes[index].chests ~= chests[chestIndex];
                }
                pointer += 4;
            }
        }
    }

}
