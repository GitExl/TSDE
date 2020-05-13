/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module BattleScripts.ROMBattleScriptReader;

import std.json;
import std.string;

import List.ListReaderInterface;

import StringTables.StringTableList;

import Enemies.EnemyList;

import BattleScripts.BattleScript;
import BattleScripts.ConditionParser;
import BattleScripts.ParameterFactory;
import BattleScripts.ActionParser;

import BinaryFile;

public class ROMBattleScriptReader : ListReaderInterface!BattleScript {

    private JSONValue _config;
    private BinaryFile _rom;
    private EnemyList _enemies;

    private ConditionParser _conditionParser;
    private ActionParser _actionParser;

    public this (JSONValue config, BinaryFile rom, StringTableList strings, EnemyList enemies) {
        _config = config;
        _rom = rom;
        _enemies = enemies;

        ParameterFactory paramFactory = new ParameterFactory(strings, enemies);
        _conditionParser = new ConditionParser(paramFactory);
        _actionParser = new ActionParser(paramFactory);
    }

    public BattleScript[] read() {
        immutable uint address = cast(uint)_config["battleScripts"]["address"].integer;
        immutable uint count = cast(uint)_config["battleScripts"]["count"].integer;

        uint[] pointers = new uint[count];

        _rom.setPosition(address);
        foreach (ref uint pointer; pointers) {
            pointer = _rom.read!ushort() + 0x0C0000;
        }

        BattleScript[] scripts = new BattleScript[count];
        foreach (int index, ref BattleScript script; scripts) {
            _rom.setPosition(pointers[index]);
            
            script.key = _enemies.getKeyByIndex(index);

            // Normal triggers.
            while (1) {
                immutable ubyte value = _rom.peek!ubyte();
                if (value == 0xFF) {
                    _rom.read!ubyte();
                    break;
                }
                script.triggers ~= readTrigger();
            }

            // Triggers in response to being attacked.
            while (1) {
                immutable ubyte value = _rom.peek!ubyte();
                if (value == 0xFF) {
                    _rom.read!ubyte();
                    break;
                }
                script.attackTriggers ~= readTrigger();
            }
        }

        return scripts;
    }

    private Trigger readTrigger() {
        Trigger t;

        while (1) {
            immutable ubyte op = _rom.read!ubyte();
            if (op == 0xFE || op == 0xFF) {
                break;
            }
            t.conditions ~= _conditionParser.parse(op, _rom);
        }

        while (1) {
            immutable ubyte op = _rom.read!ubyte();
            if (op == 0xFE || op == 0xFF) {
                break;
            }
            t.actions ~= _actionParser.parse(op, _rom);
        }

        return t;
    }
}
