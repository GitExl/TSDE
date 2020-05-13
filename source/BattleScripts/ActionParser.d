module BattleScripts.ActionParser;

import std.string;

import BinaryFile;

import BattleScripts.BattleScript;
import BattleScripts.Parameter;
import BattleScripts.ParameterFactory;

public class ActionParser {

    private ParameterFactory _paramFactory;

    public this(ParameterFactory paramFactory) {
        _paramFactory = paramFactory;
    }

    public Action parse(immutable ubyte op, BinaryFile data) {
        switch (op) {
            case 0x00: return opWanderMode(data);
            case 0x01: return opAttackMode(data);
            case 0x02: return opTechMode(data);
            case 0x04: return opRandom(data);
            case 0x07: return opChangeIntoMonster(data);
            case 0x0A: return opRunAway(data);
            case 0x0B: return opStatSet(data);
            case 0x0C: return opStatAdd(data);
            case 0x0D: return opChangeState(data);
            case 0x0F: return opMessage(data);
            case 0x10: return opReviveSupport(data);
            case 0x11: return opStatSetMulti(data);
            case 0x12: return opStatSetMultiSpecial(data);
            case 0x14: return opStatAddMulti(data);
            case 0x15: return opStatAddMultiSpecial(data);
            case 0x16: return opStatSetMultiTech(data);

            default:
                throw new Exception(format("Unknown action opcode 0x%02X", op));
        }
    }

    private Action opWanderMode(BinaryFile data) {
        data.read!ubyte();

        return Action(
            "wander",
            _paramFactory.create("target", ParameterType.TARGET, data.read!ubyte()),
            _paramFactory.create("wander type", ParameterType.INTEGER, data.read!ubyte())
        );
    }

    private Action opAttackMode(BinaryFile data) {
        return Action(
            "attack",
            _paramFactory.create("attack index", ParameterType.INTEGER, data.read!ubyte()),
            _paramFactory.create("target", ParameterType.TARGET, data.read!ubyte()),
            _paramFactory.create("unknown", ParameterType.INTEGER, data.read!ubyte())
        );
    }

    private Action opTechMode(BinaryFile data) {
        return Action(
            "tech",
            _paramFactory.create("tech", ParameterType.TECH, data.read!ubyte()),
            _paramFactory.create("target", ParameterType.TARGET, data.read!ubyte()),
            _paramFactory.create("unknown", ParameterType.INTEGER, data.read!ubyte()),
            _paramFactory.create("unknown", ParameterType.INTEGER, data.read!ubyte()),
            _paramFactory.create("message", ParameterType.MESSAGE, data.read!ubyte())
        );
    }

    private Action opRandom(BinaryFile data) {
        return Action("random");
    }

    private Action opChangeIntoMonster(BinaryFile data) {
        return Action(
            "changeInto",
            _paramFactory.create("enemy", ParameterType.ENEMY, data.read!ubyte()),
            _paramFactory.create("tech", ParameterType.TECH, data.read!ubyte()),
            _paramFactory.create("unknown flag", ParameterType.INTEGER, data.read!ubyte())
        );
    }

    private Action opRunAway(BinaryFile data) {
        return Action(
            "run",
            _paramFactory.create("tech", ParameterType.TECH, data.read!ubyte()),
            _paramFactory.create("message", ParameterType.MESSAGE, data.read!ubyte())
        );
    }

    private Action opStatSet(BinaryFile data) {
        immutable ubyte[4] values = data.readBytes(4);

        if (values[2]) {
            return Action(
                "statOr",
                _paramFactory.create("stat", ParameterType.STAT, values[0]),
                _paramFactory.create("value", ParameterType.INTEGER, values[1]),
                _paramFactory.create("message", ParameterType.MESSAGE, values[3])
            );
        }

        return Action(
            "statSet",
            _paramFactory.create("stat", ParameterType.STAT, values[0]),
            _paramFactory.create("value", ParameterType.INTEGER, values[1]),
            _paramFactory.create("message", ParameterType.MESSAGE, values[3])
        );
    }

    private Action opStatAdd(BinaryFile data) {
        return Action(
            "statAdd",
            _paramFactory.create("stat", ParameterType.STAT, data.read!ubyte()),
            _paramFactory.create("value", ParameterType.INTEGER, cast(int)data.read!byte()),
            _paramFactory.create("message", ParameterType.MESSAGE, data.read!ubyte())
        );
    }

    private Action opChangeState(BinaryFile data) {
        return Action(
            "setAnimation",
            _paramFactory.create("animation?", ParameterType.INTEGER, data.read!ubyte()),
            _paramFactory.create("message", ParameterType.MESSAGE, data.read!ubyte())
        );
    }

    private Action opMessage(BinaryFile data) {
        return Action(
            "message",
            _paramFactory.create("message", ParameterType.MESSAGE, data.read!ubyte())
        );
    }

    private Action opReviveSupport(BinaryFile data) {
        return Action(
            "reviveSupport",
            _paramFactory.create("unknown", ParameterType.INTEGER, data.read!ubyte()),
            _paramFactory.create("animation?", ParameterType.INTEGER, data.read!ubyte()),
            _paramFactory.create("message", ParameterType.MESSAGE, data.read!ubyte())
        );
    }

    private Action opStatSetMulti(BinaryFile data) {
        return Action(
            "statSetMulti",
            _paramFactory.create("stat", ParameterType.STAT, data.read!ubyte()),
            _paramFactory.create("value", ParameterType.INTEGER, data.read!ubyte()),
            _paramFactory.create("stat", ParameterType.STAT, data.read!ubyte()),
            _paramFactory.create("value", ParameterType.INTEGER, data.read!ubyte()),
            _paramFactory.create("stat", ParameterType.STAT, data.read!ubyte()),
            _paramFactory.create("value", ParameterType.INTEGER, data.read!ubyte()),
            _paramFactory.create("stat", ParameterType.STAT, data.read!ubyte()),
            _paramFactory.create("value", ParameterType.INTEGER, data.read!ubyte()),
            _paramFactory.create("message", ParameterType.MESSAGE, data.read!ubyte())
        );
    }

    private Action opStatSetMultiSpecial(BinaryFile data) {
        immutable ubyte[15] values = data.readBytes(15);

        return Action(
            "techStatAddMulti",
            _paramFactory.create("tech", ParameterType.TECH, values[0]),
            _paramFactory.create("target", ParameterType.TARGET, values[1]),
            _paramFactory.create("stat", ParameterType.STAT, values[4]),
            _paramFactory.create("value", ParameterType.INTEGER, cast(byte)values[5]),
            _paramFactory.create("stat", ParameterType.STAT, values[6]),
            _paramFactory.create("value", ParameterType.INTEGER, cast(byte)values[7]),
            _paramFactory.create("stat", ParameterType.STAT, values[8]),
            _paramFactory.create("value", ParameterType.INTEGER, cast(byte)values[9]),
            _paramFactory.create("stat", ParameterType.STAT, values[10]),
            _paramFactory.create("value", ParameterType.INTEGER, cast(byte)values[11]),
            _paramFactory.create("stat", ParameterType.STAT, values[12]),
            _paramFactory.create("value", ParameterType.INTEGER, cast(byte)values[13]),
            _paramFactory.create("message", ParameterType.MESSAGE, values[14])
        );
    }

    private Action opStatAddMulti(BinaryFile data) {
        return Action(
            "statAddMulti",
            _paramFactory.create("stat", ParameterType.STAT, data.read!ubyte()),
            _paramFactory.create("value", ParameterType.INTEGER, cast(int)data.read!byte()),
            _paramFactory.create("stat", ParameterType.STAT, data.read!ubyte()),
            _paramFactory.create("value", ParameterType.INTEGER, cast(int)data.read!byte()),
            _paramFactory.create("stat", ParameterType.STAT, data.read!ubyte()),
            _paramFactory.create("value", ParameterType.INTEGER, cast(int)data.read!byte()),
            _paramFactory.create("stat", ParameterType.STAT, data.read!ubyte()),
            _paramFactory.create("value", ParameterType.INTEGER, cast(int)data.read!byte()),
            _paramFactory.create("message", ParameterType.MESSAGE, data.read!ubyte())
        );
    }

    // Only used by enemy 190.
    private Action opStatAddMultiSpecial(BinaryFile data) {
        immutable ubyte[15] values = data.readBytes(15);

        return Action(
            "techStatAddMultiAlternate",
            _paramFactory.create("tech", ParameterType.TECH, values[0]),
            _paramFactory.create("target", ParameterType.TARGET, values[1]),
            _paramFactory.create("stat", ParameterType.STAT, values[4]),
            _paramFactory.create("value", ParameterType.INTEGER, cast(byte)values[5]),
            _paramFactory.create("stat", ParameterType.STAT, values[6]),
            _paramFactory.create("value", ParameterType.INTEGER, cast(byte)values[7]),
            _paramFactory.create("stat", ParameterType.STAT, values[8]),
            _paramFactory.create("value", ParameterType.INTEGER, cast(byte)values[9]),
            _paramFactory.create("stat", ParameterType.STAT, values[10]),
            _paramFactory.create("value", ParameterType.INTEGER, cast(byte)values[11]),
            _paramFactory.create("stat", ParameterType.STAT, values[12]),
            _paramFactory.create("value", ParameterType.INTEGER, cast(byte)values[13]),
            _paramFactory.create("message", ParameterType.MESSAGE, values[14])
        );
    }

    // Unsure if the first two parameters are correct. Only used by enemy 239, related but possibly unused.
    private Action opStatSetMultiTech(BinaryFile data) {
        return Action(
            "techStatAddMultiShort",
            _paramFactory.create("unknown", ParameterType.INTEGER, data.read!ubyte()),
            _paramFactory.create("tech", ParameterType.TECH, data.read!ubyte()),
            _paramFactory.create("stat", ParameterType.STAT, data.read!ubyte()),
            _paramFactory.create("value", ParameterType.INTEGER, cast(int)data.read!byte()),
            _paramFactory.create("stat", ParameterType.STAT, data.read!ubyte()),
            _paramFactory.create("value", ParameterType.INTEGER, cast(int)data.read!byte()),
            _paramFactory.create("stat", ParameterType.STAT, data.read!ubyte()),
            _paramFactory.create("value", ParameterType.INTEGER, cast(int)data.read!byte()),
            _paramFactory.create("stat", ParameterType.STAT, data.read!ubyte()),
            _paramFactory.create("value", ParameterType.INTEGER, cast(int)data.read!byte()),
            _paramFactory.create("message", ParameterType.MESSAGE, data.read!ubyte())
        );
    }
}