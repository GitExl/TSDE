/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module SceneScripts.ROMSceneScriptReader;

import std.json;
import std.string;

import List.ListReaderInterface;

import SceneScripts.SceneScript;
import SceneScripts.Decompiler;

import StringTables.StringTableList;

import Enemies.EnemyList;

import Items.ItemList;

import Palettes.PaletteList;

import Scenes.SceneList;

import JSONTools;
import BinaryFile;
import Decompress;

public class ROMSceneScriptReader : ListReaderInterface!SceneScript {

    private JSONValue _config;
    private BinaryFile _rom;
    private StringTableList _strings;
    private EnemyList _enemies;
    private ItemList _items;
    private PaletteList _palettes;
    private SceneList _scenes;

    public this (JSONValue config, BinaryFile rom, StringTableList strings, EnemyList enemies, ItemList items, PaletteList palettes, SceneList scenes) {
        _config = config;
        _rom = rom;
        _strings = strings;
        _enemies = enemies;
        _items = items;
        _palettes = palettes;
        _scenes = scenes;
    }

    public SceneScript[] read() {
        immutable uint count = cast(uint)_config["sceneScripts"]["count"].integer;
        immutable uint address = cast(uint)_config["sceneScripts"]["address"].integer;

        string[string] stringTableMap;
        foreach (string key, JSONValue value; _config["sceneScripts"]["stringTableMap"].object) {
            stringTableMap[key] = value.str;
        }

        JSONValue musicNames = loadStubbedJSONNames(_config["music"]["names"].str, "music", 84, true);
        JSONValue soundNames = loadStubbedJSONNames(_config["sounds"]["names"].str, "sound", 256, true);
        JSONValue shopNames = loadStubbedJSONNames(_config["shops"]["names"].str, "shop", 24, true);
        JSONValue pcNames = loadStubbedJSONNames(_config["pcs"]["names"].str, "pc", 8, true);
        JSONValue npcNames = loadStubbedJSONNames(_config["npcs"]["names"].str, "npc", 256, true);
        Decompiler decompiler = new Decompiler(stringTableMap, _strings, _enemies, _items, _palettes, _scenes,
                                               musicNames, soundNames, shopNames, pcNames, npcNames);

        _rom.setPosition(address);
        int[int] usedAddresses;

        uint[] pointers = new uint[count];
        foreach (ref uint pointer; pointers) {
            pointer = _rom.read!ushort();
            const ubyte bank = _rom.read!ubyte();
            if (bank) {
                pointer = 0x10000 * (bank - 0xC0) + pointer;
            }
        }

        SceneScript[] scripts = new SceneScript[count];

        _rom.setPosition(address);
        foreach (int index, ref SceneScript script; scripts) {
            if (!pointers[index]) {
                script.key = format("%03d_null", index);
                continue;
            }

            ubyte[] data = decompressScript(pointers[index]);
            if (data.length) {
                BinaryFile binaryData = new BinaryFile(data);
                script = decompiler.decompile(binaryData);
                script.key = format("%03d_scenescript", index);
            } else {
                script.key = format("%03d_empty", index);
            }
        }

        return scripts;
    }

    private ubyte[] decompressScript(immutable uint address) {
        ubyte[] decompressed = new ubyte[0x2000];
        const uint length = decompressLZ(_rom.array, decompressed, address);
        decompressed.length = length;
        return decompressed;
    }

}
