module Mods.ModConditions;

import std.conv;
import std.format;
import std.json;

import Mods.ModConditionInterface;

import EnemyTypes;

public class ModConditionEnemyType : ModConditionInterface {
    private EnemyType _type;

    public this(immutable EnemyType type) {
        _type = type;
    }

    public const string name() {
        return "enemyType";
    }

    public const string description() {
        return format("enemy is %s", cast(string)_type);
    }

    public const JSONValue serialize() {
        return JSONValue(to!string(_type));
    }
}

public class ModConditionSightScopeRelicFail : ModConditionInterface {
    public const string name() {
        return "sightScopeRelicFail";
    }

    public const string description() {
        return "Sight Scope or Relic fails";
    }

    public const JSONValue serialize() {
        return JSONValue(true);
    }
}

public class ModConditionBossDeath : ModConditionInterface {
    public const string name() {
        return "bossDeath";
    }

    public const string description() {
        return "boss dies";
    }

    public const JSONValue serialize() {
        return JSONValue(true);
    }
}
