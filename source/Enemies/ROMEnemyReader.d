module Enemies.ROMEnemyReader;

import std.json;
import std.stdio;
import std.string;

import List.ListReaderInterface;

import Enemies.Enemy;

import Items.ItemList;

import StringTables.StringTableList;

import ElementTypes;
import StatusEffects;
import EnemyTypes;
import StringTools;
import BinaryFile;

public class ROMEnemyReader : ListReaderInterface!Enemy {

    private JSONValue _config;
    private BinaryFile _rom;
    private ItemList _items;
    private StringTableList _strings;

    public this (JSONValue config, BinaryFile rom, ItemList items, StringTableList strings) {
        _config = config;
        _rom = rom;
        _items = items;
        _strings = strings;
    }

    public Enemy[] read() {
        immutable uint count = cast(uint)_config["enemies"]["count"].integer;
        immutable uint countSpecial = cast(uint)_config["enemies"]["countSpecial"].integer;
        immutable uint address = cast(uint)_config["enemies"]["address"].integer;
        immutable uint addressRewards = cast(uint)_config["enemies"]["addressRewards"].integer;
        immutable uint addressSpecial = cast(uint)_config["enemies"]["addressSpecial"].integer;
        immutable uint addressHideTargetWindow = cast(uint)_config["enemies"]["addressHideTargetWindow"].integer;
        immutable uint addressAttacks = cast(uint)_config["enemies"]["addressAttacks"].integer;
        immutable uint addressGraphics = cast(uint)_config["enemies"]["addressGraphics"].integer;

        Enemy[] enemies = new Enemy[count];
        
        _rom.setPosition(address);
        foreach (int index, ref Enemy enemy; enemies) {
            enemy.name = index < 251 ? _strings.get("enemy_names", index) : "";
            if (enemy.name.length) {
                enemy.key = format("%03d_%s", index, generateKeyFromName(enemy.name));
            } else {
                enemy.key = format("%03d_unnamed", index);
            }
            enemy.battleAI = enemy.key;

            enemy.health = _rom.read!ushort();
            enemy.level = _rom.read!ubyte();
            _rom.read!ubyte();

            enemy.immunities = getImmunities(_rom.read!ubyte());

            _rom.readBytes(3);
            
            enemy.stamina = _rom.read!ubyte();
            enemy.speed = _rom.read!ubyte();
            enemy.magic = _rom.read!ubyte();
            enemy.hit = _rom.read!ubyte();
            enemy.evade = _rom.read!ubyte();
            enemy.magicDefense = _rom.read!ubyte();
            enemy.attackIndex = _rom.read!ubyte();
            enemy.defense = _rom.read!ubyte();
            
            enemy.affinities[ElementType.LIGHTNING] = calcAffinity(_rom.read!ubyte());
            enemy.affinities[ElementType.SHADOW] = calcAffinity(_rom.read!ubyte());
            enemy.affinities[ElementType.WATER] = calcAffinity(_rom.read!ubyte());
            enemy.affinities[ElementType.FIRE] = calcAffinity(_rom.read!ubyte());

            enemy.techImmunities = cast(TechImmunityFlags)_rom.read!ubyte();  // TODO: use tech keys when available
            
            immutable ubyte flags = _rom.read!ubyte();
            enemy.flags = cast(EnemyFlags)(flags & 0x03);
            enemy.type = getEnemyType(flags);
            
            enemy.attack2Index = _rom.read!ubyte();
        }

        _rom.setPosition(addressRewards);
        foreach (ref Enemy enemy; enemies) {
            enemy.xp = _rom.read!ushort();
            enemy.gold = _rom.read!ushort();  
            
            auto items = _rom.readBytes(2);
            if (items[0]) {
                enemy.rewardItem = _items.getKeyByIndex(items[0]);
            }
            if (items[1]) {
                enemy.charmItem = _items.getKeyByIndex(items[1]);
            }

            enemy.techPoints = _rom.read!ubyte();
        }

        // Unknown values, some sort of tech\attack and some flags for it.
        _rom.setPosition(addressSpecial);
        for (int index = 0; index < countSpecial; index++) {
            immutable ushort enemyIndex = _rom.read!ushort();
            enemies[enemyIndex].special1 = _rom.read!ubyte();
            enemies[enemyIndex].special2 = _rom.read!ubyte();
            //writefln("%s: %d %d", enemies[index].key, enemies[index].special1, enemies[index].special2);
        }

        _rom.setPosition(addressHideTargetWindow);
        foreach (ref Enemy enemy; enemies) {
            enemy.hideTargetWindow = cast(bool)_rom.read!ubyte();
        }

        // Unknown, possibly attack-related data.
        _rom.setPosition(addressAttacks);
        foreach (ref Enemy enemy; enemies) {
            ubyte[12] values = _rom.readBytes(12);
            //writefln("%s: %d %d %d %d %d %d %d %d %d %d %d %d", enemy.key, values[0], values[1], values[2], values[3], values[4], values[5], values[6], values[7], values[8], values[9], values[10], values[11]);
        }

        _rom.setPosition(addressGraphics);
        foreach (ref Enemy enemy; enemies) {
            immutable ubyte[10] values = _rom.readBytes(10);

            enemy.sprite.packet = values[0];
            enemy.sprite.assembly = values[1];
            enemy.sprite.palette = values[2];
            enemy.sprite.animations = values[3];
            enemy.sprite.size = values[4] & 0x03;
            enemy.sprite.flags = cast(EnemySpriteFlags)(values[4] & 0xFC);
            enemy.sprite.originX = cast(byte)values[5];
            enemy.sprite.originY = cast(byte)values[6];
            enemy.sprite.unknown1 = values[7];
            enemy.sprite.unknown2 = values[8];
            enemy.sprite.unknown3 = values[9];
        }

        return enemies;
    }

    private static EnemyType getEnemyType(immutable ubyte flags) {
        if (flags & 0x04) {
            return EnemyType.DINOSAUR;
        } else if (flags & 0x08) {
            return EnemyType.MAGICAL;
        } else if (flags & 0x10) {
            return EnemyType.AQUATIC;
        } else if (flags & 0x20) {
            return EnemyType.HUMANOID;
        } else if (flags & 0x40) {
            return EnemyType.MECHANICAL;
        } else if (flags & 0x80) {
            return EnemyType.UNDEAD;
        }

        return EnemyType.NONE;
    }

    private static StatusEffect[] getImmunities(immutable ubyte flags) {
        StatusEffect[] immunities;

        if (flags & 0x01) {
            immunities ~= StatusEffect.BLIND;
        }
        if (flags & 0x02) {
            immunities ~= StatusEffect.SLEEP;
        }
        if (flags & 0x04) {
            immunities ~= StatusEffect.CONFUSE;
        }
        if (flags & 0x08) {
            immunities ~= StatusEffect.LOCK;
        }
        if (flags & 0x10) {
            immunities ~= StatusEffect.HP_DRAIN;
        }
        if (flags & 0x20) {
            immunities ~= StatusEffect.SLOW;
        }
        if (flags & 0x40) {
            immunities ~= StatusEffect.POISON;
        }
        if (flags & 0x80) {
            immunities ~= StatusEffect.STOP;
        }

        return immunities;
    }

    private static double calcAffinity(immutable ubyte value) {
        if (!(value & 0x7F)) {
            return 0.0;
        }

        immutable double output = 4.0 / (value & 0x7F);
        if (value & 0x80) {
            return -output;
        }
        return output;
    }
}