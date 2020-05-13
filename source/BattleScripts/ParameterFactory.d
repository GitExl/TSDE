/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module BattleScripts.ParameterFactory;

import std.stdio;
import std.string;
import std.conv;

import StringTables.StringTableList;

import Enemies.EnemyList;

import BattleScripts.Parameter;
import BattleScripts.TargetParser;
import BattleScripts.StatParser;

public class ParameterFactory {

    private StringTableList _strings;
    private EnemyList _enemies;

    public this(StringTableList strings, EnemyList enemies) {
        _strings = strings;
        _enemies = enemies;
    }

    public Parameter op(Op op) {
        return Parameter("op", ParameterType.OP, op);
    }

    public Parameter create(immutable string name, immutable ParameterType type, immutable ubyte value) {
        Parameter param;
        param.name = name;
        param.type = type;

        switch (type) {
            case ParameterType.INTEGER:
                param.value = format("%d", value);
                break;
            case ParameterType.INTEGER_HEX:
                param.value = format("0x%02X", value);
                break;
            case ParameterType.BOOL:
                param.value = format("%s", !!value);
                break;
            case ParameterType.STAT:
                param.value = format("stat:%s", parseStatByte(value));
                break;
            case ParameterType.TARGET:
                param.value = format("target:%s", parseTargetByte(value));
                break;
            case ParameterType.STATUS:
                param.value = format("status:0x%02X", value);
                break;
            case ParameterType.TECH:
                param.value = format("tech:%d", value);
                break;
            case ParameterType.ENEMY:
                param.value = format("%s", _enemies.getKeyByIndex(value));
                break;
            case ParameterType.MESSAGE:
                if (!value) {
                    param.value = "null";
                } else {
                    param.value = format("string:battle:%s", value - 1);
                    param.comment = format("\"%s\"", _strings.get("battle", value - 1));
                }
                break;
            default:
                throw new Exception(format("ubyte values cannot be interpreted as %s.", to!string(type)));
        }

        return param;
    }

    public Parameter create(immutable string name, immutable ParameterType type, immutable int value) {
        Parameter param;
        param.name = name;
        param.type = type;

        switch (type) {
            case ParameterType.INTEGER:
                param.value = format("%d", value);
                break;
            case ParameterType.INTEGER_HEX:
                param.value = format("0x%2X", value);
                break;
            case ParameterType.BOOL:
                param.value = format("%s", !!value);
                break;
            default:
                throw new Exception(format("int values cannot be interpreted as %s.", to!string(type)));
        }

        return param;
    }

    public Parameter create(immutable string name, immutable ParameterType type, immutable string value) {
        Parameter param;
        param.name = name;
        param.type = type;

        switch (type) {
            case ParameterType.OP:
            case ParameterType.STRING:
                param.value = value;
                break;
            default:
                throw new Exception(format("string values cannot be interpreted as %s.", to!string(type)));
        }
        
        return param;
    }

    public Parameter create(immutable string name, immutable ParameterType type, immutable bool value) {
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

    public Parameter create(immutable string name, immutable ParameterType type, immutable ushort value) {
        Parameter param;
        param.name = name;
        param.type = type;

        switch (type) {
            case ParameterType.INTEGER:
                param.value = format("%d", value);
                break;
            case ParameterType.INTEGER_HEX:
                param.value = format("0x%0002X", value);
                break;
            case ParameterType.BOOL:
                param.value = format("%s", !!value);
                break;
            default:
                throw new Exception(format("ushort values cannot be interpreted as %s.", to!string(type)));
        }
        
        return param;
    }

    public Parameter create(immutable string name, immutable ParameterType type, immutable double value) {
        Parameter param;
        param.name = name;
        param.type = type;

        switch (type) {
            case ParameterType.FLOAT:
                param.value = format("%.06f", value);
                break;
            default:
                throw new Exception(format("double values cannot be interpreted as %s.", to!string(type)));
        }
        
        return param;
    }
    
    public Parameter create(immutable string name, immutable ParameterType type, string[] value) {
        Parameter param;
        param.name = name;
        param.type = type;

        switch (type) {
            case ParameterType.ARRAY_STRING:
                param.value = join(value, ", ");
                break;
            default:
                throw new Exception(format("string array values cannot be interpreted as %s.", to!string(type)));
        }
        
        return param;
    }

}