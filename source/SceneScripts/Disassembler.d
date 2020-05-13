module SceneScripts.Disassembler;

import std.stdio;
import std.string;
import std.conv;

import BinaryFile;

import SceneScripts.Parameter;
import SceneScripts.ParameterFactory;
import SceneScripts.Node;
import SceneScripts.NodeInstruction;
import SceneScripts.NodeConditional;

import StringTables.StringTableList;

private enum CallMode {
    CONTINUE,
    SYNC,
    WAIT
}

private enum Facing {
    UP = 0,
    DOWN = 1,
    LEFT = 2,
    RIGHT = 3,
}

private enum CopyTileFlags {
    LAYER1 = 0x01,
    LAYER2 = 0x02,
    LAYER3 = 0x04,
    LAYER1_PROPS = 0x08,
    UNKNOWN_10 = 0x10,
    UNKNOWN_20 = 0x20,
    ZPLANE = 0x40,
    WIND = 0x80
}

public enum ControlMode {
    SINGLE_INPUT,
    INFINITE,
}

private enum CollisionFlags {
    TILES = 0x01,
    PC = 0x02,
}

private enum PositioningFlags {
    TO_TILE = 0x01,
    TO_OBJECT = 0x02,
}

private enum DrawMode {
    DISABLED = 0,
    ENABLED = 1,
    HIDDEN = 2
}

private enum TextBoxPosition {
    AUTO = 0,
    TOP = 1,
    BOTTOM = 2
}

private enum ChangeLocationFlags {
    UNKNOWN1 = 0x01,
    UNKNOWN2 = 0x02,
    WAIT_VSYNC = 0x04,
}

private enum SpritePriorityFlags {
    UNKNOWN_04 = 0x01,
    UNKNOWN_08 = 0x02,
    UNKNOWN_40 = 0x04,
}

private enum SpritePriority {
    BELOW_BOTH_0 = 0,
    BELOW_BOTH_1 = 1,
    BELOW_L1_ABOVE_L2 = 2,
    ABOVE_BOTH = 3,
}

private enum ScrollLayerFlags {
    LAYER1 = 0x01,
    LAYER2 = 0x02,
    LAYER3 = 0x04,
}

private enum SolidityFlags {
    SOLID = 0x01,
    PUSHABLE = 0x02,
}

private enum ColorMode {
    ADD = 0,
    SUBTRACT = 1,
}

private enum ButtonFlags {
    DASH = 0x01,
    CONFIRM = 0x02,
    A = 0x04,
    B = 0x08,
    X = 0x10,
    Y = 0x20,
    L = 0x40,
    R = 0x80,
}

private enum BattleFlags {
    NO_WIN_POSE = 0x0001,
    MENU_BOTTOM = 0x0002,
    SMALL_ENEMIES = 0x0004,
    UNUSED_1 = 0x0008,
    PERSISTENT_ENEMIES = 0x0010,
    SCRIPTED = 0x0020,
    UNKNOWN_2 = 0x0040,
    NO_RUNNING = 0x0080,
    UNKNOWN_3 = 0x0100,
    UNKNOWN_4 = 0x0200,
    UNKNOWN_5 = 0x0400,
    UNKNOWN_6 = 0x0800,
    UNKNOWN_7 = 0x1000,
    NO_GAME_OVER = 0x2000,
    KEEP_MUSIC = 0x4000,
    AUTO_REGROUP = 0x8000,
}

private static immutable double SNES_REFRESH_RATE_NTSC = 60.098813897441;

public class Disassembler {
    private BinaryFile _data;
    private BinaryFile _rom;
    private string[string] _stringTableMap;
    private ParameterFactory _paramFactory;

    private bool _currentObjectIsNPC = false;
    private string _stringTable;

    public this(BinaryFile data, BinaryFile rom, string[string] stringTableMap, ParameterFactory paramFactory) {
        _data = data;
        _rom = rom;
        _stringTableMap = stringTableMap;
        _paramFactory = paramFactory;
    }

    public Node getNextNode() {
        const int address = _data.getPosition();
        Node node = disassemble();
        node.address = address;
        return node;
    }

    public Node disassemble() {
        const ubyte opCode = _data.read!ubyte();
        switch (opCode) {
            case 0x02, 0x03, 0x04:
                return opCallEvent(opCode);
            case 0x05, 0x06, 0x07:
                return opCallPCEvent(opCode);
            case 0x08:
                return new NodeInstruction("interactionEnabled", [
                    _paramFactory.create("enabled", ParameterType.BOOL, false)
                ]);
            case 0x09:
                return new NodeInstruction("interactionEnabled", [
                    _paramFactory.create("enabled", ParameterType.BOOL, true)
                ]);
            case 0x0A:
                return new NodeInstruction("disableObject", [
                    _paramFactory.create("object", ParameterType.OBJECT, _data.read!ubyte())
                ]);
            case 0x0B, 0x0C:
                return opEnableScriptProcessing(opCode);
            case 0x0F, 0x17, 0x1B, 0x1D:
            case 0x1E, 0x1F, 0x25, 0x26:
            case 0xA6, 0xA7:
                return opSetFacing(opCode);
            case 0xA9:
                return new NodeInstruction("facePC", [
                    _paramFactory.create("object", ParameterType.OBJECT, _data.read!ubyte())
                ]);
            case 0xA8:
                return new NodeInstruction("faceObject", [
                    _paramFactory.create("object", ParameterType.OBJECT, _data.read!ubyte())
                ]);
            case 0xB8:
                return opSetStringData();
            case 0x48, 0x49, 0x4C, 0x4D, 0x51, 0x52, 0x53, 0x54, 0x58, 0x59:
                return opCopy(opCode);
            case 0x75, 0x76, 0x77, 0x4A, 0x4B, 0x4E, 0x4F, 0x50, 0x56:
                return opStore(opCode);
            case 0x87:
                // Measured in 1/10th second, maybe. See soda guzzling contest code in scenescript 74.
                return new NodeInstruction("setExecutionSpeed", [
                    _paramFactory.create("speed", ParameterType.INTEGER, _data.read!ubyte())
                ]);
            case 0x24:
                return new NodeInstruction("loadPCFacing", [
                    _paramFactory.create("pc", ParameterType.INTEGER, _data.read!ubyte()),
                    _paramFactory.create("destination address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte())
                ]);
            case 0x22:
                return new NodeInstruction("loadPCPosition", [
                    _paramFactory.create("pc", ParameterType.INTEGER, _data.read!ubyte()),
                    _paramFactory.create("x destination address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                    _paramFactory.create("y destination address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte())
                ]);
            case 0xE4, 0xE5:
                return opCopyTiles(opCode);
            case 0xE3:
                return new NodeInstruction("explorationEnabled", [
                    _paramFactory.create("enabled", ParameterType.BOOL, _data.read!ubyte())
                ]);
            case 0x57, 0x5C, 0x62, 0x68, 0x6A, 0x6C, 0x6D, 0x80, 0x81:
                return opLoadPC(opCode);
            case 0x8B:
                return new NodeInstruction("setPositionTile", [
                    _paramFactory.create("x", ParameterType.INTEGER, _data.read!ubyte()),
                    _paramFactory.create("y", ParameterType.INTEGER, _data.read!ubyte())
                ]);
            case 0x8D:
                return new NodeInstruction("setPositionPixel", [
                    _paramFactory.create("x", ParameterType.FLOATING, cast(double)_data.read!ushort() / 16),
                    _paramFactory.create("y", ParameterType.FLOATING, cast(double)_data.read!ushort() / 16)
                ]);
            case 0xAF, 0xB0:
                return opAllowControl(opCode);
            case 0xAA, 0xAB, 0xB3, 0xB4, 0xB7:
                return opAnimate(opCode);
            case 0xAC:
                return new NodeInstruction("setFrame", [
                    _paramFactory.create("frame", ParameterType.INTEGER, _data.read!ubyte())
                ]);
            case 0x0D:
                return new NodeInstruction("setCollisionFlags", [
                    _paramFactory.flags!CollisionFlags("flags", cast(CollisionFlags)_data.read!ubyte())
                ]);
            case 0x0E:
                return new NodeInstruction("setPositioningFlags", [
                    _paramFactory.flags!PositioningFlags("flags", cast(PositioningFlags)_data.read!ubyte())
                ]);
            case 0x89:
                return new NodeInstruction("setSpeed", [
                    _paramFactory.create("speed", ParameterType.INTEGER, _data.read!ubyte())
                ]);
            case 0x8A:
                return new NodeInstruction("setSpeedFrom", [
                    _paramFactory.create("speed address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte())
                ]);
            case 0x96, 0xA0:
                return new NodeInstruction("walkTo", [
                    _paramFactory.create("x", ParameterType.INTEGER, _data.read!ubyte()),
                    _paramFactory.create("y", ParameterType.INTEGER, _data.read!ubyte()),
                    _paramFactory.create("animate", ParameterType.BOOL, (opCode == 0xA0)),
                ]);
            case 0x97:
                return new NodeInstruction("walkToLoad", [
                    _paramFactory.create("x address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                    _paramFactory.create("y address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                    _paramFactory.create("animated", ParameterType.BOOL, false)
                ]);
            case 0x7C, 0x7D, 0x7E, 0x90, 0x91:
                return opSetDrawMode(opCode);
            case 0xAE:
                return new NodeInstruction("animationReset");
            case 0xAD, 0xB9, 0xBA, 0xBC, 0xBD:
                return opPause(opCode);
            case 0x95, 0xB6, 0x8F:
                return opFollowPC(opCode);
            case 0x94, 0xB5:
                return opFollow(opCode);
            case 0xD9:
                return new NodeInstruction("partyMoveTo", [
                    _paramFactory.create("pc 1 x", ParameterType.INTEGER, _data.read!ubyte()),
                    _paramFactory.create("pc 1 y", ParameterType.INTEGER, _data.read!ubyte()),
                    _paramFactory.create("pc 2 x", ParameterType.INTEGER, _data.read!ubyte()),
                    _paramFactory.create("pc 2 y", ParameterType.INTEGER, _data.read!ubyte()),
                    _paramFactory.create("pc 3 x", ParameterType.INTEGER, _data.read!ubyte()),
                    _paramFactory.create("pc 3 y", ParameterType.INTEGER, _data.read!ubyte()),
                ]);
            case 0xC1, 0xC2, 0xBB:
                return opText(opCode);
            case 0xC0, 0xC3, 0xC4:
                return opDecision(opCode);
            case 0xDc, 0xDD, 0xDE, 0xDF, 0xE0, 0xE1:
                return opChangeLocation(opCode);
            case 0xE2:
                return new NodeInstruction("changeLocationFrom", [
                    _paramFactory.create("flags address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                    _paramFactory.create("location index address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                    _paramFactory.create("x address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                    _paramFactory.create("y address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte())
                ]);
            case 0x82:
                _currentObjectIsNPC = true;
                return new NodeInstruction("loadNPC", [
                    _paramFactory.create("npc", ParameterType.NPC, _data.read!ubyte())
                ]);
            case 0x8E:
                return opSetSpritePriority();
            case 0x9C, 0x9D, 0x92:
                return opVectorMove(opCode);
            case 0xE6:
                return opScrollLayers();
            case 0x5A:
                return new NodeInstruction("storylineSet", [
                    _paramFactory.create("value", ParameterType.INTEGER, _data.read!ubyte())
                ]);
            case 0x55:
                return new NodeInstruction("storylineLoad", [
                    _paramFactory.create("destination address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte())
                ]);
            case 0x84:
                return new NodeInstruction("setSolidity", [
                    _paramFactory.flags!SolidityFlags("flags", cast(SolidityFlags)_data.read!ubyte())
                ]);
            case 0xF1:
                return opColor();
            case 0xF3:
                return new NodeInstruction("waitForColor");
            case 0x88:
                return op88(opCode);
            case 0xFF:
                return opMode7(opCode);
            case 0xC8:
                return opDialog();
            case 0xF8:
                return new NodeInstruction("restoreHPMP");
            case 0xF9:
                return new NodeInstruction("restoreHP");
            case 0xFA:
                return new NodeInstruction("restoreMP");
            case 0xCA:
                return new NodeInstruction("itemAdd", [
                    _paramFactory.create("item", ParameterType.ITEM, _data.read!ubyte())
                ]);
            case 0xCB:
                return new NodeInstruction("itemRemove", [
                    _paramFactory.create("item", ParameterType.ITEM, _data.read!ubyte())
                ]);
            case 0xE7:
                return new NodeInstruction("scrollTo", [
                    _paramFactory.create("x", ParameterType.INTEGER, _data.read!ubyte()),
                    _paramFactory.create("y", ParameterType.INTEGER, _data.read!ubyte())
                ]);
            case 0xD8:
                return new NodeInstruction("battle", [
                    _paramFactory.flags!BattleFlags("flags", cast(BattleFlags)_data.read!ushort())
                ]);
            case 0x83:
                return opLoadEnemy();
            case 0x1C:
                return new NodeInstruction("resultLoad", [
                    _paramFactory.create("destination address", ParameterType.ADDRESS8_7F0000, _data.read!ushort())
                ]);
            case 0xFE:
                return opDrawGeometry();
            case 0xF0:
                return new NodeInstruction("darken", [
                    _paramFactory.create("amount", ParameterType.INTEGER, _data.read!ubyte())
                ]);
            case 0xF2:
                return new NodeInstruction("fadeOut");
            case 0x7A:
                return new NodeInstruction("jumpTo", [
                    _paramFactory.create("x", ParameterType.INTEGER, _data.read!ubyte()),
                    _paramFactory.create("y", ParameterType.INTEGER, _data.read!ubyte()),
                    _paramFactory.create("height", ParameterType.INTEGER, _data.read!ubyte())
                ]);
            case 0x2E:
                return opColorMath();
            case 0x71:
                return new NodeInstruction("increment8", [
                    _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte())
                ]);
            case 0x72:
                return new NodeInstruction("increment16", [
                    _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte())
                ]);
            case 0x73:
                return new NodeInstruction("decrement8", [
                    _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte())
                ]);
            case 0x74:
                return new NodeInstruction("decrement16", [
                    _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte())
                ]);
            case 0x19:
                return new NodeInstruction("resultLoad", [
                    _paramFactory.create("destination address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte())
                ]);
            case 0x8C:
                return new NodeInstruction("loadPositionPixel", [
                    _paramFactory.create("x address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                    _paramFactory.create("y address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte())
                ]);
            case 0xF4:
                return new NodeInstruction("screenShakeEnabled", [
                    _paramFactory.create("enabled", ParameterType.BOOL, _data.read!ubyte())
                ]);
            case 0x21:
                return new NodeInstruction("storeObjectPositionPixel", [
                    _paramFactory.create("object", ParameterType.OBJECT, _data.read!ubyte()),
                    _paramFactory.create("x address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                    _paramFactory.create("y address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                ]);
            case 0x7F:
                return new NodeInstruction("storeRandom", [
                    _paramFactory.create("destination address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte())
                ]);
            case 0x61:
                return new NodeInstruction("subLoadFrom8", [
                    _paramFactory.create("value address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                    _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte())
                ]);
            case 0x5E:
                return new NodeInstruction("addLoadFrom16", [
                    _paramFactory.create("value address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                    _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte())
                ]);
            case 0x5B:
                return new NodeInstruction("add8", [
                    _paramFactory.create("amount", ParameterType.INTEGER, _data.read!ubyte()),
                    _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte())
                ]);
            case 0x5F:
                return new NodeInstruction("sub8", [
                    _paramFactory.create("amount", ParameterType.INTEGER, _data.read!ubyte()),
                    _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte())
                ]);
            case 0x60:
                return new NodeInstruction("sub16", [
                    _paramFactory.create("amount", ParameterType.INTEGER, _data.read!ushort()),
                    _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte())
                ]);
            case 0x98:
                return new NodeInstruction("moveTowardsObject", [
                    _paramFactory.create("object", ParameterType.OBJECT, _data.read!ubyte()),
                    _paramFactory.create("distance", ParameterType.INTEGER, _data.read!ubyte())
                ]);
            case 0x9A:
                return new NodeInstruction("moveTowards", [
                    _paramFactory.create("x", ParameterType.INTEGER, _data.read!ubyte() * 10),
                    _paramFactory.create("y", ParameterType.INTEGER, _data.read!ubyte() * 10),
                    _paramFactory.create("distance", ParameterType.INTEGER, _data.read!ubyte())
                ]);
            case 0xD5:
                return new NodeInstruction("equip", [
                    _paramFactory.create("pc", ParameterType.PC, _data.read!ubyte()),
                    _paramFactory.create("item", ParameterType.ITEM, _data.read!ubyte())
                ]);
            case 0x20:
                return new NodeInstruction("storeFirstPC", [
                    _paramFactory.create("destination address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte())
                ]);
            case 0xCD:
                return new NodeInstruction("goldGive", [
                    _paramFactory.create("gold amount", ParameterType.INTEGER, _data.read!ushort())
                ]);
            case 0xCE:
                return new NodeInstruction("goldTake", [
                    _paramFactory.create("gold amount", ParameterType.INTEGER, _data.read!ushort())
                ]);
            case 0x29:
                return new NodeInstruction("loadASCIIText", [
                    _paramFactory.create("text index", ParameterType.INTEGER, _data.read!ubyte() - 0x80)
                ]);
            case 0x2C:
                return new NodeInstruction("unknown2C", [
                    _paramFactory.create("unknown", ParameterType.INTEGER, _data.read!ubyte()),
                    _paramFactory.create("unknown", ParameterType.INTEGER, _data.read!ubyte())
                ]);
            case 0x2A:
                return new NodeInstruction("unknown2A");
            case 0x2B:
                return new NodeInstruction("unknown2B");
            case 0x32:
                return new NodeInstruction("unknown32");
            case 0x2F:
                return new NodeInstruction("unknown2F", [
                    _paramFactory.create("unknown", ParameterType.INTEGER, _data.read!ubyte()),
                    _paramFactory.create("unknown", ParameterType.INTEGER, _data.read!ubyte())
                ]);
            case 0x33:
                return new NodeInstruction("setPalette", [
                    _paramFactory.create("palette", ParameterType.PALETTE, _data.read!ubyte())
                ]);
            case 0x99:
                return new NodeInstruction("moveTowardsPC", [
                    _paramFactory.create("pc", ParameterType.PC, _data.read!ubyte()),
                    _paramFactory.create("distance", ParameterType.INTEGER, _data.read!ubyte()),
                    _paramFactory.create("animated", ParameterType.BOOL, true)
                ]);
            case 0x9E:
                return new NodeInstruction("moveToObject", [
                    _paramFactory.create("object", ParameterType.OBJECT, _data.read!ubyte()),
                    _paramFactory.create("animated", ParameterType.BOOL, false)
                ]);
            case 0x9F:
                return new NodeInstruction("moveToPC", [
                    _paramFactory.create("pc", ParameterType.PC, _data.read!ubyte()),
                    _paramFactory.create("animated", ParameterType.BOOL, false)
                ]);
            case 0xC7:
                return new NodeInstruction("itemAddFrom", [
                    _paramFactory.create("address of item", ParameterType.ADDRESS8_7F0200, _data.read!ubyte())
                ]);
            case 0xA1:
                return new NodeInstruction("moveToAddress", [
                    _paramFactory.create("x", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                    _paramFactory.create("y", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                    _paramFactory.create("animated", ParameterType.BOOL, true)
                ]);
            case 0x47:
                return new NodeInstruction("animationLimit", [
                    _paramFactory.create("limit", ParameterType.INTEGER, _data.read!ubyte())
                ]);
            case 0x23:
                return new NodeInstruction("loadObjectFacing", [
                    _paramFactory.create("object", ParameterType.OBJECT, _data.read!ubyte()),
                    _paramFactory.create("destination address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte())
                ]);
            case 0xD7:
                return new NodeInstruction("itemAmountStore", [
                    _paramFactory.create("item", ParameterType.ITEM, _data.read!ubyte()),
                    _paramFactory.create("destination address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte())
                ]);

            // Input.
            case 0x2D, 0x30, 0x31, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3B, 0x3C, 0x3F, 0x40, 0x41, 0x42, 0x43, 0x44:
                return opCheckInput(opCode);

            // Flow control.
            case 0xB1:
                return new NodeInstruction("yield");
            case 0xB2:
                return new NodeInstruction("yieldIndefinite");
            case 0x00:
                return new NodeInstruction("end");
            case 0x10, 0x11:
                return opJump(opCode);

            // Party manipulation.
            case 0xD3:
                return new NodeInstruction("partyAddToActive", [
                    _paramFactory.create("pc", ParameterType.PC, _data.read!ubyte())
                ]);
            case 0xD4:
                return new NodeInstruction("partyMoveToReserve", [
                    _paramFactory.create("pc", ParameterType.PC, _data.read!ubyte())
                ]);
            case 0xDA:
                return new NodeInstruction("partyFollow");
            case 0xD1:
                return new NodeInstruction("partyRemove", [
                    _paramFactory.create("pc", ParameterType.PC, _data.read!ubyte())
                ]);
            case 0xD0:
                return new NodeInstruction("partyAddToReserve", [
                    _paramFactory.create("pc", ParameterType.PC, _data.read!ubyte())
                ]);
            case 0xD6:
                return new NodeInstruction("partyRemoveFromActive", [
                    _paramFactory.create("pc", ParameterType.PC, _data.read!ubyte())
                ]);

            // Sound\music
            case 0xE8:
                return opSoundPlay();
            case 0xEA:
                const ubyte track = _data.read!ubyte();
                if (track == 0xFF) {
                    return new NodeInstruction("musicStop");
                }
                return new NodeInstruction("musicPlay", [
                    _paramFactory.create("track", ParameterType.MUSIC, track)
                ]);
            case 0xEB:
                return opMusicVolume(opCode);
            case 0xEC:
                return opSoundCommand();
            case 0xEE:
                return new NodeInstruction("waitForMusicEnd");
            case 0xED:
                return new NodeInstruction("waitForSilence");

            // If
            case 0x12, 0x13, 0x14, 0x15, 0x16:
                return opIf(opCode);
            case 0x18:
                return new NodeConditional("if8",
                    _paramFactory.create("storyline", ParameterType.ADDRESS24, 0x7F0000),
                    _paramFactory.create("value", ParameterType.INTEGER, _data.read!ubyte()),
                    _paramFactory.create("operator", ParameterType.OPERATOR, cast(ubyte)Op.LESS_THEN_EQUALS),
                    _data.getPosition() + _data.read!ubyte()
                );
            case 0xD2:
                return new NodeConditional("ifPCActive",
                    _paramFactory.create("pc", ParameterType.PC, _data.read!ubyte()),
                    _paramFactory.create("active", ParameterType.BOOL, true),
                    _paramFactory.create("operator", ParameterType.OPERATOR, cast(ubyte)Op.EQUALS),
                    _data.getPosition() + _data.read!ubyte()
                );
            case 0x1A:
                return new NodeConditional("if8",
                    _paramFactory.create("result", ParameterType.ADDRESS24, 0x7F0A80),
                    _paramFactory.create("value", ParameterType.INTEGER, _data.read!ubyte()),
                    _paramFactory.create("operator", ParameterType.OPERATOR, cast(ubyte)Op.EQUALS),
                    _data.getPosition() + _data.read!ubyte()
                );
            case 0xCF:
                return new NodeConditional("ifRecruited",
                    _paramFactory.create("pc recruited", ParameterType.PC, _data.read!ubyte()),
                    _paramFactory.create("active", ParameterType.BOOL, true),
                    _paramFactory.create("operator", ParameterType.OPERATOR, cast(ubyte)Op.EQUALS),
                    _data.getPosition() + _data.read!ubyte()
                );
            case 0xC9:
                return new NodeConditional("ifHaveItem",
                    _paramFactory.create("item", ParameterType.ITEM, _data.read!ubyte()),
                    _paramFactory.create("have", ParameterType.BOOL, true),
                    _paramFactory.create("operator", ParameterType.OPERATOR, cast(ubyte)Op.EQUALS),
                    _data.getPosition() + _data.read!ubyte()
                );
            case 0x27:
                return new NodeConditional("ifObjectVisible",
                    _paramFactory.create("object", ParameterType.OBJECT, _data.read!ubyte()),
                    _paramFactory.create("visible", ParameterType.BOOL, true),
                    _paramFactory.create("operator", ParameterType.OPERATOR, cast(ubyte)Op.EQUALS),
                    _data.getPosition() + _data.read!ubyte()
                );
            case 0xCC:
                return new NodeConditional("if16",
                    _paramFactory.create("result", ParameterType.ADDRESS24, 0x7E2C53),
                    _paramFactory.create("value", ParameterType.INTEGER, _data.read!ushort()),
                    _paramFactory.create("operator", ParameterType.OPERATOR, cast(ubyte)Op.MORE_THAN_EQUALS),
                    _data.getPosition() + _data.read!ubyte()
                );
            case 0x28:
                return new NodeConditional("ifInBattleRange",
                    _paramFactory.create("object", ParameterType.OBJECT, _data.read!ubyte()),
                    _paramFactory.create("visible", ParameterType.BOOL, true),
                    _paramFactory.create("operator", ParameterType.OPERATOR, cast(ubyte)Op.EQUALS),
                    _data.getPosition() + _data.read!ubyte()
                );

            // Bit math
            case 0x63, 0x65:
                return opBitSet(opCode);
            case 0x64, 0x66:
                return opBitReset(opCode);
            case 0x67:
                return new NodeInstruction("bitResetMask", [
                    _paramFactory.create("mask", ParameterType.HEX_BYTE, _data.read!ubyte()),
                    _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                ]);
            case 0x6B:
                return new NodeInstruction("bitToggleMask", [
                    _paramFactory.create("mask", ParameterType.HEX_BYTE, _data.read!ubyte()),
                    _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                ]);
            case 0x69:
                return new NodeInstruction("bitSetMask", [
                    _paramFactory.create("mask", ParameterType.HEX_BYTE, _data.read!ubyte()),
                    _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                ]);
            case 0x6F:
                return new NodeInstruction("bitShiftDown", [
                    _paramFactory.create("shift", ParameterType.INTEGER, _data.read!ubyte()),
                    _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                ]);

            default:
                throw new Exception(format("Unknown opcode 0x%02X.", opCode));
        }
    }

    private Node opCallEvent(const ubyte opCode) {
        const ubyte obj = _data.read!ubyte();

        const ubyte param = _data.read!ubyte();
        const int priority = (param & 0xF0) >> 4;
        const int func = param & 0x0F;

        CallMode mode;
        if (opCode == 0x02) {
            mode = CallMode.CONTINUE;
        } else if (opCode == 0x03) {
            mode = CallMode.SYNC;
        } else if (opCode == 0x04) {
            mode = CallMode.WAIT;
        } else {
            throw new Exception(format("Invalid callEvent opcode 0x%02X.", opCode));
        }

        return new NodeInstruction("callEvent", [
            _paramFactory.create("object", ParameterType.OBJECT, obj),
            _paramFactory.create("function", ParameterType.INTEGER, func),
            _paramFactory.create("priority", ParameterType.INTEGER, priority),
            _paramFactory.enumerator!CallMode("mode", mode)
        ]);
    }

    private Node opCallPCEvent(const ubyte opCode) {
        const ubyte pc = _data.read!ubyte() / 2;

        const ubyte param = _data.read!ubyte();
        const int priority = (param & 0xF0) >> 4;
        const int func = param & 0x0F;

        CallMode mode;
        if (opCode == 0x05) {
            mode = CallMode.CONTINUE;
        } else if (opCode == 0x06) {
            mode = CallMode.SYNC;
        } else if (opCode == 0x07) {
            mode = CallMode.WAIT;
        } else {
            throw new Exception(format("Invalid callPCEvent opcode 0x%02X.", opCode));
        }

        return new NodeInstruction("callPCEvent", [
            _paramFactory.create("pc", ParameterType.INTEGER, pc),
            _paramFactory.create("function", ParameterType.INTEGER, func),
            _paramFactory.create("priority", ParameterType.INTEGER, priority),
            _paramFactory.enumerator!CallMode("mode", mode)
        ]);
    }

    private Node opEnableScriptProcessing(const ubyte opCode) {
        bool enable;
        if (opCode == 0x0B) {
            enable = false;
        } else if (opCode == 0x0C) {
            enable = true;
        } else {
            throw new Exception(format("Invalid enableScriptProcessing opcode 0x%02X.", opCode));
        }

        return new NodeInstruction("enableScriptProcessing", [
            _paramFactory.create("object", ParameterType.OBJECT, _data.read!ubyte()),
            _paramFactory.create("enable", ParameterType.BOOL, enable)
        ]);
    }

    private Node opSetFacing(const ubyte opCode) {
        if (opCode == 0x0F) {
            return new NodeInstruction("setFacing", [
                _paramFactory.enumerator!Facing("facing", Facing.UP)
            ]);
        } else if (opCode == 0x17) {
            return new NodeInstruction("setFacing", [
                _paramFactory.enumerator!Facing("facing", Facing.DOWN)
            ]);
        } else if (opCode == 0x1B) {
            return new NodeInstruction("setFacing", [
                _paramFactory.enumerator!Facing("facing", Facing.LEFT)
            ]);
        } else if (opCode == 0x1D) {
            return new NodeInstruction("setFacing", [
                _paramFactory.enumerator!Facing("facing", Facing.RIGHT)
            ]);
        }

        if (opCode == 0xA6) {
            return new NodeInstruction("setFacing", [
                _paramFactory.enumerator!Facing("facing", cast(Facing)_data.read!ubyte())
            ]);

        } else if (opCode == 0xA7) {
            return new NodeInstruction("setFacingLoad", [
                _paramFactory.create("source address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte())
            ]);
        }

        const ubyte obj = _data.read!ubyte();
        if (opCode == 0x1E) {
            return new NodeInstruction("setObjectFacing", [
                _paramFactory.create("object", ParameterType.OBJECT, obj),
                _paramFactory.enumerator!Facing("facing", Facing.UP)
            ]);
        } else if (opCode == 0x1F) {
            return new NodeInstruction("setObjectFacing", [
                _paramFactory.create("object", ParameterType.OBJECT, obj),
                _paramFactory.enumerator!Facing("facing", Facing.DOWN)
            ]);
        } else if (opCode == 0x25) {
            return new NodeInstruction("setObjectFacing", [
                _paramFactory.create("object", ParameterType.OBJECT, obj),
                _paramFactory.enumerator!Facing("facing", Facing.LEFT)
            ]);
        } else if (opCode == 0x26) {
            return new NodeInstruction("setObjectFacing", [
                _paramFactory.create("object", ParameterType.OBJECT, obj),
                _paramFactory.enumerator!Facing("facing", Facing.RIGHT)
            ]);
        }

        throw new Exception(format("Invalid setFacing opcode 0x%02X.", opCode));
    }

    private Node opJump(const ubyte opCode) {
        int address;

        if (opCode == 0x10) {
            address = _data.getPosition() + _data.read!ubyte();
        } else if (opCode == 0x11) {
            address = _data.getPosition() - _data.read!ubyte();
        } else {
            throw new Exception(format("Invalid jump opcode 0x%02X.", opCode));
        }

        return new NodeInstruction("jump", [
            _paramFactory.create("label", ParameterType.LABEL, address)
        ], JumpType.GOTO, address);
    }

    private Node opSetStringData() {
        const int offset = read24Bits() - 0xC00000;
        _stringTable = _stringTableMap[format("%06X", offset)];

        return new NodeInstruction("useStringTable", [
            _paramFactory.create("string table", ParameterType.STRING, _stringTable)
        ]);
    }

    private Node opCopy(const ubyte opCode) {
        int src;
        int dest;
        int length;

        if (opCode == 0x48) {
            src = read24Bits();
            if (src < 0x2000) {
                src += 0x7E0000;
            }
            dest = _data.read!ubyte() * 2 + 0x7F0200;
            length = 1;
        } else if (opCode == 0x49) {
            src = read24Bits();
            if (src < 0x2000) {
                src += 0x7E0000;
            }
            dest = _data.read!ubyte() * 2 + 0x7F0200;
            length = 2;

        } else if (opCode == 0x4C) {
            dest = read24Bits();
            if (dest < 0x2000) {
                dest += 0x7E0000;
            }
            src = _data.read!ubyte() * 2 + 0x7F0200;
            length = 1;
        } else if (opCode == 0x4D) {
            dest = read24Bits();
            if (dest < 0x2000) {
                dest += 0x7E0000;
            }
            src = _data.read!ubyte() * 2 + 0x7F0200;
            length = 2;

        } else if (opCode == 0x51) {
            src = _data.read!ubyte() * 2 + 0x7F0200;
            dest = _data.read!ubyte() * 2 + 0x7F0200;
            length = 1;
        } else if (opCode == 0x52) {
            src = _data.read!ubyte() * 2 + 0x7F0200;
            dest = _data.read!ubyte() * 2 + 0x7F0200;
            length = 2;

        } else if (opCode == 0x53) {
            src = _data.read!ushort() + 0x7F0000;
            dest = _data.read!ubyte() * 2 + 0x7F0200;
            length = 1;
        } else if (opCode == 0x54) {
            src = _data.read!ushort() + 0x7F0000;
            dest = _data.read!ubyte() * 2 + 0x7F0200;
            length = 2;

        } else if (opCode == 0x58) {
            src = _data.read!ubyte() * 2 + 0x7F0200;
            dest = _data.read!ushort() + 0x7F0000;
            length = 1;
        } else if (opCode == 0x59) {
            src = _data.read!ubyte() * 2 + 0x7F0200;
            dest = _data.read!ushort() + 0x7F0000;
            length = 2;

        } else {
            throw new Exception(format("Invalid copy opcode 0x%02X.", opCode));

        }

        return new NodeInstruction("copy", [
            _paramFactory.create("source address", ParameterType.ADDRESS24, src),
            _paramFactory.create("destination address", ParameterType.ADDRESS24, dest),
            _paramFactory.create("bytes", ParameterType.INTEGER, length)
        ]);
    }

    private Node opIf(const ubyte opCode) {
        if (opCode == 0x12) {
            return new NodeConditional("if8",
                _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                _paramFactory.create("value", ParameterType.INTEGER, _data.read!ubyte()),
                _paramFactory.create("operator", ParameterType.OPERATOR, _data.read!ubyte()),
                _data.getPosition() + _data.read!ubyte()
            );

        } else if (opCode == 0x13) {
            return new NodeConditional("if16",
                _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                _paramFactory.create("value", ParameterType.INTEGER, _data.read!ushort()),
                _paramFactory.create("operator", ParameterType.OPERATOR, _data.read!ubyte()),
                _data.getPosition() + _data.read!ubyte()
            );

        } else if (opCode == 0x14) {
            return new NodeConditional("if8",
                _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                _paramFactory.create("value address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                _paramFactory.create("operator", ParameterType.OPERATOR, _data.read!ubyte()),
                _data.getPosition() + _data.read!ubyte()
            );

        } else if (opCode == 0x15) {
            return new NodeConditional("if16",
                _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                _paramFactory.create("value address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                _paramFactory.create("operator", ParameterType.OPERATOR, _data.read!ubyte()),
                _data.getPosition() + _data.read!ubyte()
            );

        } else if (opCode == 0x16) {
            int address = _data.read!ubyte() + 0x7F0000;
            const ubyte value = _data.read!ubyte();
            ubyte op = _data.read!ubyte();
            if (op & 0x80) {
                address += 0x100;
                op -= 0x80;
            }

            return new NodeConditional("if8",
                _paramFactory.create("address", ParameterType.ADDRESS24, address),
                _paramFactory.create("value", ParameterType.INTEGER, value),
                _paramFactory.create("op", ParameterType.OPERATOR, op),
                _data.getPosition() + _data.read!ubyte()
            );

        }

        throw new Exception(format("Invalid if opcode 0x%02X.", opCode));
    }

    private Node opBitSet(const ubyte opCode) {
        if (opCode == 0x65) {
            ubyte bit = _data.read!ubyte();
            const bool local = cast(bool)(bit & 0x80);
            bit &= 0x7F;

            int address = _data.read!ubyte() + 0x7F0000;
            if (local) {
                address += 0x100;
            }

            return new NodeInstruction("bitSet", [
                _paramFactory.create("bit", ParameterType.INTEGER, bit),
                _paramFactory.create("address", ParameterType.ADDRESS24, address),
            ]);

        } else if (opCode == 0x63) {
            return new NodeInstruction("bitSet", [
                _paramFactory.create("bit", ParameterType.INTEGER, _data.read!ubyte()),
                _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
            ]);

        }

        throw new Exception(format("Invalid bitSet opcode 0x%02X.", opCode));
    }

    private Node opBitReset(const ubyte opCode) {
        if (opCode == 0x66) {
            ubyte bit = _data.read!ubyte();
            const bool local = cast(bool)(bit & 0x80);
            bit &= 0x7F;

            int address = _data.read!ubyte() + 0x7F0000;
            if (local) {
                address += 0x100;
            }

            return new NodeInstruction("bitReset", [
                _paramFactory.create("bit", ParameterType.INTEGER, bit),
                _paramFactory.create("address", ParameterType.ADDRESS24, address),
            ]);

        } else if (opCode == 0x64) {
            return new NodeInstruction("bitReset", [
                _paramFactory.create("bit", ParameterType.INTEGER, _data.read!ubyte()),
                _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
            ]);

        }

        throw new Exception(format("Invalid bitReset opcode 0x%02X.", opCode));
    }

    private Node opCopyTiles(const ubyte opCode) {
        const ubyte type = (opCode == 0xE5) ? 1 : 0;

        return new NodeInstruction("copyTiles", [
            _paramFactory.create("source left", ParameterType.INTEGER, _data.read!ubyte()),
            _paramFactory.create("source top", ParameterType.INTEGER, _data.read!ubyte()),
            _paramFactory.create("source right", ParameterType.INTEGER, _data.read!ubyte()),
            _paramFactory.create("source bottom", ParameterType.INTEGER, _data.read!ubyte()),
            _paramFactory.create("destination x", ParameterType.INTEGER, _data.read!ubyte()),
            _paramFactory.create("destination y", ParameterType.INTEGER, _data.read!ubyte()),
            _paramFactory.flags!CopyTileFlags("flags", cast(CopyTileFlags)_data.read!ubyte()),
            _paramFactory.create("type", ParameterType.INTEGER, type),
        ]);
    }

    private Node opStore(const ubyte opCode) {

        if (opCode == 0x75) {
            return new NodeInstruction("store8", [
                _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                _paramFactory.create("value", ParameterType.INTEGER, 0x01),
            ]);
        } else if (opCode == 0x76) {
            return new NodeInstruction("store16", [
                _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                _paramFactory.create("value", ParameterType.INTEGER, 0x0001),
            ]);
        } else if (opCode == 0x77) {
            return new NodeInstruction("store8", [
                _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                _paramFactory.create("value", ParameterType.INTEGER, 0x00),
            ]);

        } else if (opCode == 0x4A) {
            int address = read24Bits();
            if (address < 0x2000) {
                address += 0x7E0000;
            }
            return new NodeInstruction("store8", [
                _paramFactory.create("address", ParameterType.ADDRESS24, address),
                _paramFactory.create("value", ParameterType.INTEGER, _data.read!ubyte()),
            ]);
        } else if (opCode == 0x4B) {
            int address = read24Bits();
            if (address < 0x2000) {
                address += 0x7E0000;
            }
            return new NodeInstruction("store16", [
                _paramFactory.create("address", ParameterType.ADDRESS24, address),
                _paramFactory.create("values", ParameterType.INTEGER, _data.read!ushort()),
            ]);

        } else if (opCode == 0x4F) {
            const ubyte value = _data.read!ubyte();
            const ubyte address = _data.read!ubyte();
            return new NodeInstruction("store8", [
                _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, address),
                _paramFactory.create("value", ParameterType.INTEGER, value),
            ]);
        } else if (opCode == 0x50) {
            const ushort value = _data.read!ushort();
            const ubyte address = _data.read!ubyte();
            return new NodeInstruction("store16", [
                _paramFactory.create("address", ParameterType.ADDRESS8_7F0200, address),
                _paramFactory.create("value", ParameterType.INTEGER, value),
            ]);

        } else if (opCode == 0x56) {
            const ubyte value = _data.read!ubyte();
            const ushort address = _data.read!ushort();
            return new NodeInstruction("store8", [
                _paramFactory.create("address", ParameterType.ADDRESS8_7F0000, address),
                _paramFactory.create("value", ParameterType.INTEGER, value),
            ]);

        } else if (opCode == 0x4E) {
            const int dest = _data.read!ushort();
            const int bank = _data.read!ubyte();
            if (bank != 0x7F && bank != 0x7E) {
                throw new Exception("Invalid bank for store opcode 0x4E.");
            }
            const int address = bank * 0x10000 + dest;

            return new NodeInstruction("store", [
                _paramFactory.create("address", ParameterType.ADDRESS24, address),
                _paramFactory.data("values", _data.readBytes(_data.read!ushort() - 2)),
            ]);

        }

        throw new Exception(format("Invalid store opcode 0x%02X.", opCode));
    }

    private Node opLoadPC(const ubyte opCode) {
        ubyte pc;
        bool ifInParty;

        _currentObjectIsNPC = false;

        if (opCode == 0x57) {
            pc = 0;
            ifInParty = true;
        } else if (opCode == 0x5C) {
            pc = 1;
            ifInParty = true;
        } else if (opCode == 0x62) {
            pc = 2;
            ifInParty = true;
        } else if (opCode == 0x68) {
            pc = 3;
            ifInParty = true;
        } else if (opCode == 0x6A) {
            pc = 4;
            ifInParty = true;
        } else if (opCode == 0x6C) {
            pc = 5;
            ifInParty = true;
        } else if (opCode == 0x6D) {
            pc = 6;
            ifInParty = true;
        } else if (opCode == 0x80) {
            pc = _data.read!ubyte();
            ifInParty = true;
        } else if (opCode == 0x81) {
            pc = _data.read!ubyte();
            ifInParty = false;
        } else {
            throw new Exception(format("Invalid loadPC opcode 0x%02X.", opCode));
        }

        if (pc > 6) {
            throw new Exception(format("Invalid PC index %d.", pc));
        }

        return new NodeInstruction("loadPC", [
            _paramFactory.create("pc", ParameterType.PC, pc),
            _paramFactory.create("only if in party", ParameterType.BOOL, ifInParty)
        ]);
    }

    private Node opAllowControl(const ubyte opCode) {
        ControlMode mode;
        if (opCode == 0xAF) {
            mode = ControlMode.SINGLE_INPUT;
        } else if (opCode == 0xB0) {
            mode = ControlMode.INFINITE;
        } else {
            throw new Exception(format("Invalid allowControl opcode 0x%02X.", opCode));
        }

        return new NodeInstruction("allowControl", [
            _paramFactory.enumerator!ControlMode("duration", mode)
        ]);
    }

    private Node opAnimate(const ubyte opCode) {
        int animation;
        int loopCount;

        if (opCode == 0xAA) {
            animation = _data.read!ubyte();
            loopCount = -1;
        } else if (opCode == 0xAB) {
            animation = _data.read!ubyte();
            loopCount = 0;
        } else if (opCode == 0xB3) {
            animation = 0;
            loopCount = 0;
        } else if (opCode == 0xB4) {
            animation = 1;
            loopCount = 0;
        } else if (opCode == 0xB7) {
            animation = _data.read!ubyte();
            loopCount = _data.read!ubyte();
        } else {
            throw new Exception(format("Invalid animate opcode 0x%02X.", opCode));
        }

        return new NodeInstruction("animate", [
            _paramFactory.create("animation", ParameterType.INTEGER, animation),
            _paramFactory.create("loop count", ParameterType.INTEGER, loopCount),
        ]);
    }

    private Node opSetDrawMode(const ubyte opCode) {
        if (opCode == 0x7C) {
            return new NodeInstruction("setObjectDrawMode", [
                _paramFactory.create("object", ParameterType.OBJECT, _data.read!ubyte()),
                _paramFactory.enumerator("draw mode", DrawMode.ENABLED),
            ]);
        } else if (opCode == 0x7D) {
            return new NodeInstruction("setObjectDrawMode", [
                _paramFactory.create("object", ParameterType.OBJECT, _data.read!ubyte()),
                _paramFactory.enumerator("draw mode", DrawMode.DISABLED),
            ]);
        } else if (opCode == 0x7E) {
            return new NodeInstruction("setDrawMode", [
                _paramFactory.enumerator("draw mode", DrawMode.HIDDEN),
            ]);
        } else if (opCode == 0x90) {
            return new NodeInstruction("setDrawMode", [
                _paramFactory.enumerator("draw mode", DrawMode.ENABLED),
            ]);
        } else if (opCode == 0x91) {
            return new NodeInstruction("setDrawMode", [
                _paramFactory.enumerator("draw mode", DrawMode.DISABLED),
            ]);
        }

        throw new Exception(format("Invalid setDrawMode opcode 0x%02X.", opCode));
    }

    private Node opPause(const ubyte opCode) {
        double time = 0.0;

        if (opCode == 0xAD) {
            if (_currentObjectIsNPC) {
                time = (1.0 / 16.0) * _data.read!ubyte();
            } else {
                time = (1.0 / 64.0) * _data.read!ubyte();
            }
        } else if (opCode == 0xB9) {
            time = 0.25;
        } else if (opCode == 0xBA) {
            time = 0.5;
        } else if (opCode == 0xBC) {
            time = 1.0;
        } else if (opCode == 0xBD) {
            time = 2.0;
        } else {
            throw new Exception(format("Invalid pause opcode 0x%02X.", opCode));
        }

        return new NodeInstruction("pause", [
            _paramFactory.create("duration", ParameterType.FLOATING, time)
        ]);
    }

    private Node opFollowPC(const ubyte opCode) {
        bool repeat = true;
        bool keepFacing = false;

        if (opCode == 0x95) {
            repeat = false;
        } else if (opCode == 0xB6) {
            repeat = true;
        } else if (opCode == 0x8F) {
            repeat = false;
            keepFacing = true;
        } else {
            throw new Exception(format("invalid followPC opcode 0x%02X.", opCode));
        }

        return new NodeInstruction("followPC", [
            _paramFactory.create("pc", ParameterType.INTEGER, _data.read!ubyte()),
            _paramFactory.create("keep current facing", ParameterType.BOOL, keepFacing),
            _paramFactory.create("repeat", ParameterType.BOOL, repeat)
        ]);
    }

    private Node opFollow(const ubyte opCode) {
        bool repeat = true;

        if (opCode == 0x94) {
            repeat = false;
        } else if (opCode == 0xB5) {
            repeat = true;
        } else {
            throw new Exception(format("Invalid follow opcode 0x%02X.", opCode));
        }

        return new NodeInstruction("followObject", [
            _paramFactory.create("object", ParameterType.OBJECT, _data.read!ubyte()),
            _paramFactory.create("keep current facing", ParameterType.BOOL, false),
            _paramFactory.create("repeat", ParameterType.BOOL, repeat)
        ]);
    }

    private Node opText(const ubyte opCode) {
        TextBoxPosition position;
        if (opCode == 0xC1) {
            position = TextBoxPosition.TOP;
        } else if (opCode == 0xC2) {
            position = TextBoxPosition.BOTTOM;
        } else if (opCode == 0xBB) {
            position = TextBoxPosition.AUTO;
        } else {
            throw new Exception(format("Invalid text opcode 0x%02X.", opCode));
        }

        return new NodeInstruction("text", [
            _paramFactory.text("text", _stringTable, _data.read!ubyte()),
            _paramFactory.enumerator!TextBoxPosition("position", position)
        ]);
    }

    private Node opDecision(const ubyte opCode) {
        const ubyte stringIndex = _data.read!ubyte();
        const ubyte lines = _data.read!ubyte();
        const int first = (lines & 0x0C) >> 2;
        const int last = lines & 0x03;

        TextBoxPosition position;
        if (opCode == 0xC3) {
            position = TextBoxPosition.TOP;
        } else if (opCode == 0xC4) {
            position = TextBoxPosition.BOTTOM;
        } else if (opCode == 0xC0) {
            position = TextBoxPosition.AUTO;
        } else {
            throw new Exception(format("Invalid decision opcode 0x%02X.", opCode));
        }

        return new NodeInstruction("decision", [
            _paramFactory.text("text", _stringTable, stringIndex),
            _paramFactory.enumerator!TextBoxPosition("position", position),
            _paramFactory.create("first decision line", ParameterType.INTEGER, first),
            _paramFactory.create("last decision line", ParameterType.INTEGER, last)
        ]);
    }

    private Node opChangeLocation(const ubyte opCode) {
        ChangeLocationFlags flags;

        const ushort params = _data.read!ushort();
        const ushort locationIndex = params & 0x01FF;
        const Facing facing = cast(Facing)((params & 0x0600) >> 9);
        if (params & 0x1800) {
            flags |= ChangeLocationFlags.UNKNOWN1;
        }
        if (params & 0x8000) {
            flags |= ChangeLocationFlags.UNKNOWN2;
        }

        const int x = _data.read!ubyte();
        const int y = _data.read!ubyte();

        int type;
        if (opCode == 0xDC) {
            type = 0;
        } else if (opCode == 0xDD) {
            type = 1;
        } else if (opCode == 0xDE) {
            type = 2;
        } else if (opCode == 0xDF) {
            type = 3;
        } else if (opCode == 0xE0) {
            type = 4;
        } else if (opCode == 0xE1) {
            type = 5;
            flags |= ChangeLocationFlags.WAIT_VSYNC;
        } else if (opCode == 0xE2) {
            type = 4;
        } else {
            throw new Exception(format("Invalid changeLocation opcode 0x%02X.", opCode));
        }

        return new NodeInstruction("changeLocation", [
            _paramFactory.create("location", ParameterType.LOCATION, locationIndex),
            _paramFactory.create("x", ParameterType.INTEGER, x),
            _paramFactory.create("y", ParameterType.INTEGER, y),
            _paramFactory.enumerator!Facing("facing", facing),
            _paramFactory.flags!ChangeLocationFlags("flags", flags),
            _paramFactory.create("type", ParameterType.INTEGER, type)
        ]);
    }

    private Node opSetSpritePriority() {
        SpritePriorityFlags flags;

        const ubyte value = _data.read!ubyte();
        if (value & 0x04) {
            flags |= SpritePriorityFlags.UNKNOWN_04;
        }
        if (value & 0x08) {
            flags |= SpritePriorityFlags.UNKNOWN_08;
        }
        if (value & 0x40) {
            flags |= SpritePriorityFlags.UNKNOWN_40;
        }

        const SpritePriority priorityTop = cast(SpritePriority)((value & 0x30) >> 4);
        const SpritePriority priorityBottom = cast(SpritePriority)(value & 0x03);
        const int mode = (value & 0x80) >> 7;

        return new NodeInstruction("setSpritePriority", [
            _paramFactory.enumerator!SpritePriority("top priority", priorityTop),
            _paramFactory.enumerator!SpritePriority("bottom priority", priorityBottom),
            _paramFactory.flags!SpritePriorityFlags("flags", flags),
            _paramFactory.create("mode", ParameterType.INTEGER, mode)
        ]);
    }

    private Node opVectorMove(const ubyte opCode) {
        if (opCode == 0x9D) {
            return new NodeInstruction("vectorMoveFrom", [
                _paramFactory.create("direction address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte()),
                _paramFactory.create("magnitude address", ParameterType.ADDRESS8_7F0200, _data.read!ubyte())
            ]);
        }

        double direction;
        int magnitude;
        bool changeFacing;

        if (opCode == 0x92) {
            direction = cast(double)_data.read!ubyte() * (360.0 / 256.0);
            magnitude = _data.read!ubyte();
            changeFacing = true;
        } else if (opCode == 0x9C) {
            direction = cast(double)_data.read!ubyte() * (360.0 / 256.0);
            magnitude = _data.read!ubyte();
            changeFacing = false;
        } else {
            throw new Exception(format("Invalid vectorMove opcode 0x%02X.", opCode));
        }

        return new NodeInstruction("vectorMove", [
            _paramFactory.create("direction", ParameterType.FLOATING, direction),
            _paramFactory.create("magnitude", ParameterType.INTEGER, magnitude),
            _paramFactory.create("change facing", ParameterType.BOOL, changeFacing),
        ]);
    }

    private Node opMusicVolume(const ubyte opCode) {
        const int speed = _data.read!ubyte();
        const int volume = _data.read!ubyte();

        // TODO: what is speed measured in?

        if (volume == 0xFF) {
            return new NodeInstruction("musicVolumeReset", [
                _paramFactory.create("speed \\ duration?", ParameterType.INTEGER, speed)
            ]);
        }

        return new NodeInstruction("musicVolume", [
            _paramFactory.create("speed \\ duration?", ParameterType.INTEGER, speed),
            _paramFactory.create("volume", ParameterType.INTEGER, volume)
        ]);
    }

    private Node opScrollLayers() {
        const int x = _data.read!byte() * 5;
        const int y = _data.read!byte() * 5;
        const ScrollLayerFlags flags = cast(ScrollLayerFlags)_data.read!ubyte();

        // Duration is measured in frames.
        const double duration = cast(double)_data.read!ubyte() * (1.0 / SNES_REFRESH_RATE_NTSC);

        return new NodeInstruction("scrollLayersTo", [
            _paramFactory.create("x", ParameterType.INTEGER, x),
            _paramFactory.create("y", ParameterType.INTEGER, y),
            _paramFactory.create("duration", ParameterType.FLOATING, duration),
            _paramFactory.flags!ScrollLayerFlags("flags", flags)
        ]);
    }

    private Node opColor() {
        const ubyte color = _data.read!ubyte();
        if (!color) {
            return new NodeInstruction("colorReset");
        }

        const double b = ((color & 0x80) >> 7) * 1.0;
        const double g = ((color & 0x40) >> 6) * 1.0;
        const double r = ((color & 0x20) >> 5) * 1.0;
        const double intensity = cast(double)(color & 0x1F) * (1.0 / 31.0);

        const ubyte params = _data.read!ubyte();
        const ColorMode mode = cast(ColorMode)(params & 0x80);
        const double duration = cast(double)(params & 0x7F) * 0.0625;   // TODO: is measured in 1 / 16?

        return new NodeInstruction("colorSet", [
            _paramFactory.create("red", ParameterType.FLOATING, r),
            _paramFactory.create("green", ParameterType.FLOATING, g),
            _paramFactory.create("blue", ParameterType.FLOATING, b),
            _paramFactory.create("intensity", ParameterType.FLOATING, intensity),
            _paramFactory.enumerator!ColorMode("mode", mode),
            _paramFactory.create("duration", ParameterType.FLOATING, duration)
        ]);
    }

    private Node op88(const ubyte opCode) {
        ubyte param = _data.read!ubyte();

        if (param == 0x00) {
            return new NodeInstruction("paletteReset");

        // TODO: Unknown
        } else if (param == 0x20) {
            const ubyte value = _data.read!ubyte();
            const ubyte nibbles = _data.read!ubyte();
            return new NodeInstruction("unknownGraphicsSetup20", [
                _paramFactory.create("value", ParameterType.INTEGER, value),
                _paramFactory.create("nibble 1", ParameterType.INTEGER, nibbles& 0x0F),
                _paramFactory.create("nibble 2", ParameterType.INTEGER, (nibbles & 0x0F) >> 4)
            ]);

        // TODO: Unknown
        } else if (param == 0x30) {
            const ubyte value = _data.read!ubyte();
            const ubyte nibbles = _data.read!ubyte();
            return new NodeInstruction("unknownGraphicsSetup30", [
                _paramFactory.create("value", ParameterType.INTEGER, value),
                _paramFactory.create("nibble 1", ParameterType.INTEGER, nibbles& 0x0F),
                _paramFactory.create("nibble 2", ParameterType.INTEGER, (nibbles & 0x0F) >> 4)
            ]);

        // TODO: Unknown
        } else if (param >= 0x40 && param <= 0x5F) {
            const ubyte nibbles = _data.read!ubyte();
            const ubyte value1 = _data.read!ubyte();
            const ubyte value2 = _data.read!ubyte();
            return new NodeInstruction("unknownGraphicsSetup405F", [
                _paramFactory.create("parameter", ParameterType.INTEGER, param),
                _paramFactory.create("nibble 1", ParameterType.INTEGER, nibbles& 0x0F),
                _paramFactory.create("nibble 2", ParameterType.INTEGER, (nibbles & 0x0F) >> 4),
                _paramFactory.create("value 1", ParameterType.INTEGER, value1),
                _paramFactory.create("value 2", ParameterType.INTEGER, value2)
            ]);

        } else if (param >= 0x80 && param <= 0x8F) {
            const ubyte startColor = param & 0x0F;
            return new NodeInstruction("paletteSet", [
                _paramFactory.create("start index", ParameterType.INTEGER, param & 0x0F),
                _paramFactory.data("data", _data.readBytes(_data.read!ushort() - 2))
            ]);
        }

        throw new Exception(format("Unknown 0x88 opcode 0x%02X.", opCode));
    }

    private Node opMode7(const ubyte opCode) {
        const ubyte command = _data.read!ubyte();

        // TODO: use info from https://www.*compendium.com/Forums/index.php?topic=13221.0
        //
        //Credit data: Mostly ASCII, somewhat redundant. Three control codes, plus special routines for 0x20 (space character).

        //Mode 7 event command:
        //00-7F: Opens Mode 7 packet at 0x031313
        //80-8F: Wormhole scenes. 80, 81, 82, and 83 are definitely unique. 84-8F are duplicates of 83.
        //90-A3: Special purpose commands. Partial list in editor. A0-A3 trigger the Color Crash event command.
        //A4-FF: Invalid, will likely crash.

        //Mode 7 Scenes (from packet):
        //80: Unknown Flag, can't be set normally. If set in the event command, will open a wormhole instead.
        //40: Unknown Flag, mostly seen in load screen events. Definitely seems responsible for the race's demo mode.
        //20: Unknown Flag.
        //10: Unused flag. Setting will cause the command to crash.

        //00: Race with boosts.
        //...
        //09: Race with rotation.
        //0A: Fireworks.
        //0B: Fireworks. Specific settings change based on which one is loaded.
        //0C: Ending Credits
        //0D: Ending Credits (fast)
        //0E: Fireworks, invalid. Will crash.
        //0F: Fireworks, invalid. Will crash.

        //I haven't confirmed 1-8 yet, but at this point I'm assuming notes are accurate, except for a value of 00.

        if (command == 0x90) {
            return new NodeInstruction("mode7Portal", [
                _paramFactory.create("x", ParameterType.INTEGER, _data.read!ubyte()),
                _paramFactory.create("y", ParameterType.INTEGER, _data.read!ubyte()),
                _paramFactory.create("radius", ParameterType.INTEGER, _data.read!ubyte())
            ]);

        } else if (command == 0x97) {
            return new NodeInstruction("mode797", [
                _paramFactory.create("unknown 1", ParameterType.INTEGER, _data.read!ubyte()),
                _paramFactory.create("unknown 2", ParameterType.INTEGER, _data.read!ubyte()),
                _paramFactory.create("unknown 3", ParameterType.INTEGER, _data.read!ubyte())
            ]);

        } else if (command >= 0x00 && command <= 0x8F) {
            return new NodeInstruction("mode7Scene", [
                _paramFactory.create("scene", ParameterType.INTEGER, command),
            ]);

        } else if ((command >= 0x91 && command <= 0x95) || (command >= 0x98 && command <= 0xA3)) {
            return new NodeInstruction("mode7SpecialPurpose", [
                _paramFactory.create("unknown", ParameterType.INTEGER, command),
            ]);

        } else if (command == 0x96) {
            return new NodeInstruction("reset");

        }

        throw new Exception(format("Unknown mode7 command 0x%02X.", command));
    }

    private Node opDialog() {
        const ubyte dialog = _data.read!ubyte();

        // TODO: what is the meaning of 0x40 set for save or load?

        if (dialog >= 0x80 && dialog <= 0xBF) {
            return new NodeInstruction("dialogShop", [
                _paramFactory.create("shop", ParameterType.SHOP, cast(ubyte)(dialog - 0x80))
            ]);

        } else if (dialog >= 0xC0 && dialog <= 0xC7) {
            return new NodeInstruction("dialogName", [
                _paramFactory.create("pc", ParameterType.PC, cast(ubyte)(dialog - 0xC0))
            ]);

        } else if (dialog == 0) {
            return new NodeInstruction("dialogCharacterReplace");

        } else if (dialog == 1 || dialog == 0x41) {
            return new NodeInstruction("dialogLoad");

        } else if (dialog == 2 || dialog == 0x40) {
            return new NodeInstruction("dialogSave");

        }

        throw new Exception(format("Unknown dialog opcode dialog 0x%02X.", dialog));
    }

    private Node opSoundPlay() {
        const ubyte effect = _data.read!ubyte();
        if (effect == 0xFF) {
            return new NodeInstruction("soundStop");
        }

        return new NodeInstruction("soundPlay", [
            _paramFactory.create("sound", ParameterType.SOUND_EFFECT, effect),
            _paramFactory.create("pan", ParameterType.FLOATING, 0.0)
        ]);
    }

    private Node opSoundCommand() {
        const ubyte command = _data.read!ubyte();

        switch (command) {
            case 0x11:
                const ubyte track = _data.read!ubyte();
                _data.skip(1);
                return new NodeInstruction("musicPlay", [
                    _paramFactory.create("track", ParameterType.MUSIC, track)
                ]);

            case 0x14:
                const ubyte track = _data.read!ubyte();
                _data.skip(1);
                return new NodeInstruction("musicInterruptPlay", [
                    _paramFactory.create("track", ParameterType.MUSIC, track)
                ]);

            case 0x18, 0x19:
                const ubyte effect = _data.read!ubyte();
                const double pan = (cast(double)_data.read!ubyte() * (1.0 / 127.0)) - 1.0;

                if (effect == 0xFF) {
                    return new NodeInstruction("soundEndLoop");
                }

                return new NodeInstruction("soundPlay", [
                    _paramFactory.create("sound", ParameterType.SOUND_EFFECT, effect),
                    _paramFactory.create("pan", ParameterType.FLOATING, pan)
                ]);

            case 0x82:
                // TODO: Is duration correct?
                const double duration = cast(double)_data.read!ubyte() * (1.0 / 15.0);
                const double volume = cast(double)_data.read!ubyte() * (1.0 / 255.0);

                return new NodeInstruction("soundVolumeSlide", [
                    _paramFactory.create("duration", ParameterType.FLOATING, duration),
                    _paramFactory.create("volume", ParameterType.FLOATING, volume)
                ]);

            case 0x83:
                return new NodeInstruction("soundUnknown83", [
                    _paramFactory.create("unknown", ParameterType.INTEGER, _data.read!ubyte()),
                    _paramFactory.create("unknown", ParameterType.INTEGER, _data.read!ubyte())
                ]);

            case 0x85, 0x86:
                // TODO: Is duration correct?
                const double duration = cast(double)_data.read!ubyte() * (1.0 / 15.0);
                const double tempo = (cast(double)_data.read!byte() * (1.0 / 127.0)) - 1.0;
                return new NodeInstruction("musicTempoSlide", [
                    _paramFactory.create("duration", ParameterType.FLOATING, duration),
                    _paramFactory.create("tempo", ParameterType.FLOATING, tempo)
                ]);

            case 0x88:
                _data.skip(2);
                return new NodeInstruction("musicChangeState");

            case 0xF0:
                _data.skip(2);
                return new NodeInstruction("musicSilence");

            case 0xF2:
                _data.skip(2);
                return new NodeInstruction("soundSilence");

            default:
                throw new Exception(format("Unknown sound command 0x%02X.", command));
        }
    }

    private Node opCheckInput(const ubyte opCode) {
        const int jumpTo = _data.getPosition() + _data.read!ubyte();

        ButtonFlags buttonFlags;
        bool sinceLast = false;

        switch (opCode) {
            case 0x2D: buttonFlags = cast(ButtonFlags)0xFF; break;
            case 0x30: buttonFlags = ButtonFlags.DASH; break;
            case 0x31: buttonFlags = ButtonFlags.CONFIRM; break;
            case 0x34: buttonFlags = ButtonFlags.A; break;
            case 0x35: buttonFlags = ButtonFlags.B; break;
            case 0x36: buttonFlags = ButtonFlags.X; break;
            case 0x37: buttonFlags = ButtonFlags.Y; break;
            case 0x38: buttonFlags = ButtonFlags.L; break;
            case 0x39: buttonFlags = ButtonFlags.R; break;
            case 0x3B: buttonFlags = ButtonFlags.DASH; sinceLast = true; break;
            case 0x3C: buttonFlags = ButtonFlags.CONFIRM; sinceLast = true; break;
            case 0x3F: buttonFlags = ButtonFlags.A; sinceLast = true; break;
            case 0x40: buttonFlags = ButtonFlags.B; sinceLast = true; break;
            case 0x41: buttonFlags = ButtonFlags.X; sinceLast = true; break;
            case 0x42: buttonFlags = ButtonFlags.Y; sinceLast = true; break;
            case 0x43: buttonFlags = ButtonFlags.L; sinceLast = true; break;
            case 0x44: buttonFlags = ButtonFlags.R; sinceLast = true; break;
            default:
                throw new Exception(format("Invalid ifInput opcode 0x%02X.", opCode));
        }

        return new NodeInstruction("ifInput", [
            _paramFactory.flags!ButtonFlags("buttons", buttonFlags),
            _paramFactory.create("since last check", ParameterType.BOOL, sinceLast),
        ], JumpType.BLOCK, jumpTo);
    }

    private Node opLoadEnemy() {
        _currentObjectIsNPC = true;

        const ubyte enemy = _data.read!ubyte();
        const ubyte value = _data.read!ubyte();
        const int targetIndex = value & 0x7F;
        const bool isStatic = !!(value & 0x80);

        return new NodeInstruction("loadEnemy", [
            _paramFactory.create("enemy", ParameterType.ENEMY, enemy),
            _paramFactory.create("target index", ParameterType.INTEGER, targetIndex),
            _paramFactory.create("static", ParameterType.BOOL, isStatic)
        ]);
    }

    private Node opDrawGeometry() {
        const ubyte unknown = _data.read!ubyte();

        const ubyte x1src = _data.read!ubyte();
        const ubyte x1dest = _data.read!ubyte();
        const ubyte y1src = _data.read!ubyte();
        const ubyte y1dest = _data.read!ubyte();
        const ubyte x2src = _data.read!ubyte();
        const ubyte x2dest = _data.read!ubyte();
        const ubyte y2src = _data.read!ubyte();
        const ubyte y2dest = _data.read!ubyte();
        const ubyte x3src = _data.read!ubyte();
        const ubyte x3dest = _data.read!ubyte();
        const ubyte y3src = _data.read!ubyte();
        const ubyte y3dest = _data.read!ubyte();
        const ubyte x4src = _data.read!ubyte();
        const ubyte x4dest = _data.read!ubyte();
        const ubyte y4src = _data.read!ubyte();
        const ubyte y4dest = _data.read!ubyte();

        return new NodeInstruction("drawGeometry", [
            _paramFactory.create("x1 source", ParameterType.INTEGER, x1src),
            _paramFactory.create("y1 source", ParameterType.INTEGER, y1src),
            _paramFactory.create("x1 destination", ParameterType.INTEGER, x1src),
            _paramFactory.create("y1 destination", ParameterType.INTEGER, y1src),
            _paramFactory.create("x2 source", ParameterType.INTEGER, x2src),
            _paramFactory.create("y2 source", ParameterType.INTEGER, y2src),
            _paramFactory.create("x2 destination", ParameterType.INTEGER, x2src),
            _paramFactory.create("y2 destination", ParameterType.INTEGER, y2src),
            _paramFactory.create("x3 source", ParameterType.INTEGER, x3src),
            _paramFactory.create("y3 source", ParameterType.INTEGER, y3src),
            _paramFactory.create("x3 destination", ParameterType.INTEGER, x3src),
            _paramFactory.create("y3 destination", ParameterType.INTEGER, y3src),
            _paramFactory.create("x4 source", ParameterType.INTEGER, x4src),
            _paramFactory.create("y4 source", ParameterType.INTEGER, y4src),
            _paramFactory.create("x4 destination", ParameterType.INTEGER, x4src),
            _paramFactory.create("y4 destination", ParameterType.INTEGER, y4src),
            _paramFactory.create("unknown", ParameterType.INTEGER, unknown)
        ]);
    }

    private Node opColorMath() {
        const ubyte mode = _data.read!ubyte();

        // Palette change.
        if (mode & 0x40) {
            const ColorMode colorMode = (mode & 0x50) ? ColorMode.ADD : ColorMode.SUBTRACT;

            const double b = ((mode & 0x4) >> 2) * 1.0;
            const double g = ((mode & 0x2) >> 1) * 1.0;
            const double r = ((mode & 0x1) >> 0) * 1.0;

            const ubyte startColor = _data.read!ubyte();
            const ubyte colorCount = _data.read!ubyte();

            const ubyte intensity = _data.read!ubyte();
            const double intensityEnd = cast(double)(intensity & 0xF) * (1.0 / 15.0);
            const double intensityStart = cast(double)((intensity & 0xF0) >> 4) * (1.0 / 15.0);

            // TODO: what is duration?
            const ubyte duration = _data.read!ubyte();

            return new NodeInstruction("paletteFade", [
                _paramFactory.create("red", ParameterType.FLOATING, r),
                _paramFactory.create("green", ParameterType.FLOATING, g),
                _paramFactory.create("blue", ParameterType.FLOATING, b),
                _paramFactory.enumerator!ColorMode("mode", colorMode),
                _paramFactory.create("start color", ParameterType.INTEGER, startColor),
                _paramFactory.create("color count", ParameterType.INTEGER, colorCount),
                _paramFactory.create("intensity start", ParameterType.FLOATING, intensityStart),
                _paramFactory.create("intensity end", ParameterType.FLOATING, intensityEnd),
                _paramFactory.create("duration", ParameterType.INTEGER, duration)
            ]);

            // Palette set.
        } else if (mode & 0x80) {
            const ubyte value = _data.read!ubyte();
            const ubyte startColor = value & 0xF;
            const ubyte palette = (value & 0xF0) >> 4;

            return new NodeInstruction("paletteSet", [
                _paramFactory.create("palette", ParameterType.PALETTE, palette),
                _paramFactory.create("start color", ParameterType.INTEGER, startColor),
                _paramFactory.data("data", _data.readBytes(_data.read!ushort() - 2))
            ]);

        } else {
            throw new Exception(format("Invalid colorMath mode 0x%02X.", mode));

        }
    }

    private uint read24Bits() {
        return _data.read!ubyte() + (_data.read!ubyte() << 8) + (_data.read!ubyte() << 16);
    }
}

