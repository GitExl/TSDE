/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module SceneScripts.Decompiler;

import std.string;
import std.json;

import SceneScripts.SceneScript;
import SceneScripts.Node;
import SceneScripts.NodeObject;
import SceneScripts.NodeFunction;
import SceneScripts.NodeLink;
import SceneScripts.NodeInstruction;
import SceneScripts.Disassembler;
import SceneScripts.ParameterFactory;

import StringTables.StringTableList;

import Enemies.EnemyList;

import Items.ItemList;

import Palettes.PaletteList;

import Scenes.SceneList;

import BinaryFile;

public class Decompiler {

    private string[string] _stringTableMap;
    private StringTableList _strings;
    private EnemyList _enemies;
    private ItemList _items;
    private PaletteList _palettes;
    private SceneList _scenes;
    private JSONValue musicNames;
    private ParameterFactory _paramFactory;

    public this(string[string] stringTableMap, StringTableList strings, EnemyList enemies, ItemList items, PaletteList palettes, SceneList scenes,
                JSONValue musicNames, JSONValue soundNames, JSONValue shopNames, JSONValue pcNames, JSONValue npcNames) {
        _stringTableMap = stringTableMap;
        _strings = strings;
        _enemies = enemies;
        _items = items;
        _palettes = palettes;
        _scenes = scenes;
        _paramFactory = new ParameterFactory(_strings, _enemies, _items, _palettes, _scenes, musicNames, soundNames, shopNames, pcNames, npcNames);
    }

    public SceneScript decompile(BinaryFile rom) {
        SceneScript script;

        const ubyte objectCount = rom.read!ubyte();
        script.objects.length = objectCount;
        
        // Read pointers to objects.
        const int headerSize = objectCount * 32;
        foreach (ref SceneObject object; script.objects) {
            object.name = "object";

            foreach (ref uint pointer; object.pointers) {
                pointer = rom.read!ushort() - headerSize;
            }
        }

        // Read raw opcode data following the header.
        const int dataLength = rom.size - rom.getPosition();
        ubyte[] opcodeData = rom.readBytes(dataLength);
        BinaryFile scriptData = new BinaryFile(opcodeData);

        Disassembler disassembler = new Disassembler(scriptData, rom, _stringTableMap, _paramFactory);

        Node[] nodes;
        int[int] nodeIndexByAddress;
        int[string] objectNames;
        
        // Disassemble all instructions at once.
        while (scriptData.getPosition() < scriptData.size) {
            Node node = disassembler.getNextNode();
            nodeIndexByAddress[node.address] = nodes.length;
            nodes ~= node;
        }

        // Generate labels for all goto type jumps.
        foreach (Node node; nodes) {
            if (node.jumpType == JumpType.GOTO) {
                script.labels[node.jumpTo] = format("label_%04X", node.jumpTo);
            }
        }

        // TODO: address => variable replacements

        foreach (const int objectIndex, ref SceneObject object; script.objects) {
            object.root = new NodeObject(object.name);

            int previousAddress = -1;
            foreach (const int pointerIndex, const int startAddress; object.pointers) {

                // Functions that start at the same location as the previous one
                // do not have any instructions.
                if (startAddress == previousAddress) {
                    previousAddress = startAddress;
                    continue;
                }

                // The last function in the last object could end up pointing beyond the data address range.
                if (startAddress >= scriptData.size) {
                    continue;
                }

                if (!(startAddress in nodeIndexByAddress)) {
                    throw new Exception(format("Cannot find instruction for object %d, function %d, start address 0x%04X.", objectIndex, pointerIndex, startAddress));
                }
                const int startNode = nodeIndexByAddress[startAddress];

                string funcName = getFuncNameForIndex(pointerIndex);

                // Detect linked functions which point to functions in a previous object.
                if (startAddress < object.pointers[0]) {
                    string linkName = getObjFuncNameForAddress(script.objects, startAddress);
                    NodeLink link = new NodeLink(funcName, linkName);
                    object.root.children ~= link;
                    continue;
                }
                
                NodeFunction func = new NodeFunction(funcName);
                object.root.children ~= func;

                // Determine the ending address to stop copying instructions at.
                // We search through all pointers to find the first one that is
                // right after the start address. This is needed because some
                // pointers are reused from other objects, thus pointing to a previous
                // address.
                int endAddress = 0;
                int endObjectIndex = 0;
                int endPointerIndex = 0;
                while (endAddress <= startAddress) {
                    endPointerIndex++;
                    if (endPointerIndex == script.objects[endObjectIndex].pointers.length) {

                        endObjectIndex++;
                        endPointerIndex = 0;
                        if (endObjectIndex == script.objects.length) {
                            endAddress = scriptData.size;
                            break;
                        }                            
                    }

                    endAddress = script.objects[endObjectIndex].pointers[endPointerIndex];    
                }

                // Add nodes between the function start and end, and do some processing on them.
                func.addChildren(nodes, startNode, endAddress);
                func.processBlocks();

                previousAddress = startAddress;
            }

            // Determine object name from some opcodes that load sprites.
            string determinedName = this.determineObjectName(object.name, object.root);
            if (determinedName in objectNames) {
                objectNames[determinedName] += 1;
                object.name = format("%s_%d", determinedName, objectNames[determinedName]);                
            } else {
                objectNames[determinedName] = 1;
                object.name = determinedName;
            }

            NodeObject obj = cast(NodeObject)object.root;
            obj.name = object.name;
        }

        return script;
    }

    private string determineObjectName(string currentName, Node node) {
        NodeInstruction ins = cast(NodeInstruction)node;
        if (ins !is null && ins.parameters.length >= 1) {
            if (node.name == "loadNPC") {
                return ins.parameters[0].value;
            } else if (node.name == "loadPC") {
                return ins.parameters[0].value;
            } else if (node.name == "loadEnemy") {
                return ins.parameters[0].value;
            }
        }

        foreach (Node childNode; node.children) {
            currentName = this.determineObjectName(currentName, childNode);
        }

        return currentName;
    }

    private string getFuncNameForIndex(int index) {
        if (index == 0) {
            return "init";
        } else if (index == 1) {
            return "activate";
        } else if (index == 2) {
            return "touch";
        }
        
        return format("misc%02d", index - 3);
    }

    private string getObjFuncNameForAddress(SceneObject[] objects, int startAddress) {
        foreach (SceneObject object; objects) {
            foreach (int pointerIndex, address; object.pointers) {
                if (address == startAddress) {
                    return format("%s.%s", object.name, getFuncNameForIndex(pointerIndex));
                }
            }
        }

        return "NULL";
    }
}
