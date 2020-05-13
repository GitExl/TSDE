module SceneScripts.ParameterFactory;

import std.conv;
import std.string;
import std.json;

import SceneScripts.Parameter;

import StringTables.StringTableList;

import Enemies.EnemyList;

import Items.ItemList;

import Palettes.PaletteList;

import Scenes.SceneList;

import ArrayTools;
import StringTools;

public enum Op : ubyte {
    EQUALS,
    NOT_EQUALS,
    MORE_THAN,
    LESS_THAN,
    MORE_THAN_EQUALS,
    LESS_THEN_EQUALS,
    AND,
    OR,
}

public class ParameterFactory {

    private StringTableList _strings;
    private EnemyList _enemies;
    private ItemList _items;
    private PaletteList _palettes;
    private SceneList _scenes;

    private JSONValue _musicNames;
    private JSONValue _soundNames;
    private JSONValue _shopNames;
    private JSONValue _pcNames;
    private JSONValue _npcNames;

    public this(StringTableList strings, EnemyList enemies, ItemList items, PaletteList palettes, SceneList scenes,
                JSONValue musicNames, JSONValue soundNames, JSONValue shopNames, JSONValue pcNames, JSONValue npcNames) {
        _strings = strings;
        _enemies = enemies;
        _items = items;
        _palettes = palettes;
        _scenes = scenes;

        _musicNames = musicNames;
        _soundNames = soundNames;
        _shopNames = shopNames;
        _pcNames = pcNames;
        _npcNames = npcNames;
    }

    public Parameter enumerator(T)(string name, T value) {
        Parameter param;
        param.type = ParameterType.ENUM;
        param.name = name;
        param.value = T.stringof ~ "." ~ to!string(value);

        return param;
    }

    public Parameter flags(T)(string name, T value) {
        Parameter param;
        param.type = ParameterType.FLAGS;
        param.name = name;
        param.value = flagStringArrayBool!T(value);

        return param;
    }

    public Parameter data(string name, ubyte[] values) {
        Parameter param;
        param.type = ParameterType.DATA;
        param.name = name;
        param.value = printableDataArray(values);

        return param;
    }

    public Parameter text(string name, string table, int index) {
        Parameter param;
        param.type = ParameterType.STRING_INDEX;
        param.name = name;
        param.value = format("%d", index);
        param.comment = _strings.get(table, index);
        
        return param;
    }

    public Parameter objectFunction(string name, string objectName, string funcName) {
        Parameter param;
        param.type = ParameterType.OBJECT_FUNCTION;
        param.name = name;
        param.value = format("%s.%s", objectName, funcName);

        return param;
    }

    public Parameter create(string name, ParameterType type, ubyte value) {
        Parameter param;
        param.name = name;
        param.type = type;

        switch (type) {
            case ParameterType.INTEGER:
                param.value = format("%d", value);
                break;
            case ParameterType.HEX_BYTE:
                param.value = format("0x%02X", value);
                break;
            case ParameterType.PC:
                param.value = generateKeyFromName(_pcNames[value].str);
                param.comment = _pcNames[value].str;
                break;
            case ParameterType.OBJECT:
                param.value = format("%d", value / 2);
                break;
            case ParameterType.MUSIC:
                param.value = generateKeyFromName(_musicNames[value].str);
                param.comment = _musicNames[value].str;
                break;
            case ParameterType.SOUND_EFFECT:
                param.value = generateKeyFromName(_soundNames[value].str);
                param.comment = _soundNames[value].str;
                break;
            case ParameterType.ENEMY:
                param.value = _enemies.getKeyByIndex(value);
                param.comment = _enemies.getByIndex(value).name;
                break;
            case ParameterType.ITEM:
                param.value = _items.getKeyByIndex(value);
                param.comment = _items.getByIndex(value).name;
                break;
            case ParameterType.NPC:
                param.value = generateKeyFromName(_npcNames[value].str);
                param.comment = _npcNames[value].str;
                break;
            case ParameterType.SHOP:
                param.value = generateKeyFromName(_shopNames[value].str);
                param.comment = _shopNames[value].str;
                break;
            case ParameterType.PALETTE:
                param.value = _palettes.getKeyByIndex(value);
                break;
            case ParameterType.ADDRESS8_7F0200:
                param.addressValue = value * 2 + 0x7F0200;
                param.value = format("0x%06X", param.addressValue);
                break;
            case ParameterType.ADDRESS8_7F0000:
                param.addressValue = value + 0x7F0000;
                param.value = format("0x%06X", param.addressValue);
                break;
            case ParameterType.BOOL:
                param.value = format("%s", !!value);
                break;
            case ParameterType.OPERATOR:
                switch (value) {
                    case Op.EQUALS: param.value = "=="; break;
                    case Op.NOT_EQUALS: param.value = "!="; break;
                    case Op.MORE_THAN: param.value = ">"; break;
                    case Op.LESS_THAN: param.value = "<"; break;
                    case Op.MORE_THAN_EQUALS: param.value = ">="; break;
                    case Op.LESS_THEN_EQUALS: param.value = "<="; break;
                    case Op.AND: param.value = "&"; break;
                    case Op.OR: param.value = "|"; break;
                    default:
                        throw new Exception(format("Unknown operator %d.", value));
                }
                break;
            case ParameterType.VOLUME:
                param.value = format("%.02f", cast(double)value * 0.003921568627451);
                break;
            case ParameterType.PAN:
                param.value = format("%.02f", (cast(double)value * 0.007843137254902) - 1.0);
                break;
            default:
                throw new Exception(format("ubyte values cannot be interpreted as %s.", to!string(type)));
        }

        return param;
    }

    public Parameter create(string name, ParameterType type, int value) {
        Parameter param;
        param.name = name;
        param.type = type;

        switch (type) {
            case ParameterType.INTEGER:
                param.value = format("%d", value);
                break;
            case ParameterType.ADDRESS16:
                param.value = format("0x%04X", value);
                break;
            case ParameterType.ADDRESS24:
                param.addressValue = value;
                param.value = format("0x%06X", value);
                break;
            case ParameterType.LABEL:
                param.addressValue = value;
                param.value = format("label_%04X", value);
                break;
            default:
                throw new Exception(format("int values cannot be interpreted as %s.", to!string(type)));
        }

        return param;
    }

    public Parameter create(string name, ParameterType type, string value) {
        Parameter param;
        param.name = name;
        param.type = type;

        switch (type) {
            case ParameterType.STRING:
                param.value = value;
                break;
            default:
                throw new Exception(format("string values cannot be interpreted as %s.", to!string(type)));
        }

        return param;
    }

    public Parameter create(string name, ParameterType type, bool value) {
        Parameter param;
        param.name = name;
        param.type = type;

        switch (type) {
            case ParameterType.BOOL:
                param.value = format("%s", value);
                break;
            default:
                throw new Exception(format("bool values cannot be interpreted as %s.", to!string(type)));
        }

        return param;
    }

    public Parameter create(string name, ParameterType type, ushort value) {
        Parameter param;
        param.name = name;
        param.type = type;

        switch (type) {
            case ParameterType.INTEGER:
                param.value = format("%d", value);
                break;
            case ParameterType.LOCATION:
                param.value = _scenes.getKeyByIndex(value);
                param.comment = _scenes.getByIndex(value).name;
                break;
            case ParameterType.ADDRESS8_7F0000:
                param.addressValue = value + 0x7F0000;
                param.value = format("0x%06X", param.addressValue);
                break;
            default:
                throw new Exception(format("ushort values cannot be interpreted as %s.", to!string(type)));
        }

        return param;
    }

    public Parameter create(string name, ParameterType type, double value) {
        Parameter param;
        param.name = name;
        param.type = type;

        switch (type) {
            case ParameterType.FLOATING:
                param.value = format("%.03f", value);
                break;
            default:
                throw new Exception(format("double values cannot be interpreted as %s.", to!string(type)));
        }

        return param;
    }
}
