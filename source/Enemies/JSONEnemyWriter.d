/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module Enemies.JSONEnemyWriter;

import std.string;
import std.json;
import std.stdio;
import std.conv;
import std.file;

import List.ListWriterInterface;

import Enemies.Enemy;

import StatusEffects;
import ElementTypes;

import ArrayTools;

public class JSONEnemyWriter : ListWriterInterface!Enemy {

    private string _outputPath;

    public this(immutable string outputPath) {
        _outputPath = outputPath;
    }

    public void write(const Enemy[] enemies) {
        mkdirRecurse(_outputPath);
        foreach (const Enemy enemy; enemies) {
            JSONValue json = serialize(enemy);
            File file = File(format("%s/%s.json", _outputPath, enemy.key), "w");
            file.writeln(json.toJSON(true));
            file.close();    
        }
    }

    public JSONValue serialize(const Enemy enemy) {
        JSONValue value;

        value["name"] = enemy.name;
        value["health"] = enemy.health;
        value["attackIndex"] = enemy.attackIndex;
        value["attack2Index"] = enemy.attack2Index;
        value["hideTargetWindow"] = enemy.hideTargetWindow;
        value["battleAI"] = enemy.battleAI;
        value["type"] = to!string(enemy.type);

        if (enemy.charmItem) {
            value["charmItem"] = enemy.charmItem; 
        }

        value["special1"] = enemy.special1;
        value["special2"] = enemy.special2;
        
        value["stats"] = serializeStats(enemy);
        value["rewards"] = serializeRewards(enemy);
        value["sprite"] = serializeSprite(enemy);

        if (enemy.immunities.length) {
            value["statusImmunities"] = enumStringKeys!StatusEffect(enemy.immunities);
        }
        if (enemy.techImmunities) {
            value["techImmunities"] = flagStringArray!TechImmunityFlags(enemy.techImmunities);       
        }
        if (enemy.flags) {
            value["flags"] = flagStringArray!EnemyFlags(enemy.flags);
        }
        
        double[string] affinityStrings;
        foreach (ElementType elementType, double affinityValue; enemy.affinities) {
            affinityStrings[to!string(elementType)] = affinityValue;
        }
        value["affinities"] = affinityStrings;

        return value;
    }

    private JSONValue serializeStats(const Enemy enemy) {
        JSONValue stats;

        stats["level"] = enemy.level;
        stats["speed"] = enemy.speed;
        stats["magic"] = enemy.magic;
        stats["hit"] = enemy.hit;
        stats["stamina"] = enemy.stamina;
        stats["defense"] = enemy.defense;
        stats["magicDefense"] = enemy.magicDefense;
        stats["evade"] = enemy.evade;
        
        return stats;
    }

    private JSONValue serializeRewards(const Enemy enemy) {
        JSONValue rewards;

        rewards["xp"] = enemy.xp;
        rewards["gold"] = enemy.gold;
        rewards["techPoints"] = enemy.techPoints;
        if (enemy.rewardItem) {
            rewards["item"] = enemy.rewardItem;
        }

        return rewards;
    }

    private JSONValue serializeSprite(const Enemy enemy) {
        JSONValue sprite;

        sprite["packet"] = enemy.sprite.packet;
        sprite["assembly"] = enemy.sprite.assembly;
        sprite["palette"] = enemy.sprite.palette;
        sprite["animations"] = enemy.sprite.animations;
        sprite["size"] = enemy.sprite.size;
        sprite["originX"] = enemy.sprite.originX;
        sprite["originY"] = enemy.sprite.originY;
        if (enemy.sprite.flags) {
            sprite["flags"] = flagStringArray!EnemySpriteFlags(enemy.sprite.flags);
        }
        
        return sprite;
    }

}