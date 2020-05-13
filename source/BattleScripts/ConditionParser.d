module BattleScripts.ConditionParser;

import std.stdio;
import std.string;
import std.json;
import std.array;

import BinaryFile;

import BattleScripts.BattleScript;
import BattleScripts.ParameterFactory;
import BattleScripts.Parameter;
import BattleScripts.TargetParser;

public class ConditionParser {

    private ParameterFactory _paramFactory;

    public this(ParameterFactory paramFactory) {
        _paramFactory = paramFactory;
    }

    public Condition parse(immutable ubyte op, BinaryFile data) {
        ubyte[3] args = data.readBytes(3);

        switch (op) {
            case 0x00, 0x16, 0x19:
                return Condition("always");

            case 0x01: return opHalfHealth(args);
            case 0x02: return opTargetStatus(args);
            case 0x03: return opTargetMoved(args);
            case 0x04: return opEnemyAlive(args);
            case 0x05: return opEnemiesAlive(args);
            case 0x07: return opCustomMode(args);
            case 0x08: return opHealthBelow(args);
            case 0x09: return opStatBelow(args);
            case 0x0B: return opStatBelowOrEqual(args);
            case 0x0C: return opInsideRadius32(args);
            case 0x10: return opScreenCheck(args);
            case 0x11: return opTechElementCheck(args);
            case 0x12: return opTechCheck(args);
            case 0x13: return opAttackerType(args);
            case 0x15: return opAttackElement(args);           
            case 0x17: return opRandomChance(args);
            case 0x1A: return opIdenticalMonsterCount(args);
            case 0x1B: return opPlayerCount(args);
            case 0x1F: return opInsideRadius48(args);
            case 0x20: return opFinalAttack(args);
            case 0x18, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28:
                return opCheckStat(args);

            // Unused by game.
            case 0x0A: return opStatBitsSet(args);
            case 0x06: return opFrameCounter(args);
            case 0x0D: return opXDistance(args);
            case 0x0E: return opDistanceUnknown1(args);
            case 0x0F: return opDistanceUnknown2(args);
            case 0x14: return opAttackerStat(args);
            case 0x1C: return opPlayerPresence(args);
            case 0x1D: return opTargetAlive(args);
            case 0x1E: return opFailure(args);
            case 0x22: return opUnknownCompare(args);

            default:
                throw new Exception(format("Unknown condition with opcode 0x%02X, arguments 0x%02X, 0x%02X, 0x%02X", op, args[0], args[1], args[2]));
        }
    }

    // healthPercent(target) < 50
    private Condition opHalfHealth(immutable ubyte[3] data) {
        return Condition(
            "healthPercent",
            [_paramFactory.create("target", ParameterType.TARGET, data[0])],
            _paramFactory.op(Op.LESS_THAN),
            _paramFactory.create("value", ParameterType.FLOAT, 0.5)
        );
    }

    // status(player) == status
    // status(enemy) == status
    private Condition opTargetStatus(immutable ubyte[3] data) {
        if (data[0] == 0) {
            return Condition(
                "status",
                [_paramFactory.create("target", ParameterType.TARGET, cast(ubyte)(0x30 + data[1]))],
                _paramFactory.op(Op.EQUALS),
                _paramFactory.create("status", ParameterType.STATUS, data[2])
            );
        }

        return Condition(
            "enemyStatus",
            [_paramFactory.create("target", ParameterType.INTEGER, data[1])],
            _paramFactory.op(Op.EQUALS),
            _paramFactory.create("status", ParameterType.STATUS, data[2])
        );
    }

    // movedByUnits(target) >= units
    private Condition opTargetMoved(immutable ubyte[3] data) {
        return Condition(
            "movedByUnits",
            [_paramFactory.create("target", ParameterType.TARGET, data[0])],
            _paramFactory.op(Op.MORE_THAN_EQUALS),
            _paramFactory.create("units", ParameterType.INTEGER, data[1])
        );
    }

    // enemiesOfTypeAlive("mammon-machine") == 0
    // enemiesOfTypeAlive("mammon-machine") > 0
    private Condition opEnemyAlive(immutable ubyte[3] data) {
        if (data[2]) {
            return Condition(
                "enemiesOfTypeAlive",
                [_paramFactory.create("enemy", ParameterType.ENEMY, data[1])],
                _paramFactory.op(Op.EQUALS),
                _paramFactory.create("count", ParameterType.INTEGER, 0)
            );
        }

        return Condition(
            "enemiesOfTypeAlive",
            [_paramFactory.create("enemy", ParameterType.ENEMY, data[1])],
            _paramFactory.op(Op.MORE_THAN),
            _paramFactory.create("count", ParameterType.INTEGER, 0)
        );
    }

    // enemiesAlive <= 1
    private Condition opEnemiesAlive(immutable ubyte[3] data) {
        return Condition(
            "enemiesAlive",
            [],
            _paramFactory.op(Op.LESS_THAN_EQUALS),
            _paramFactory.create("count", ParameterType.INTEGER, data[0])
        );
    }

    // animation >= 1
    private Condition opCustomMode(immutable ubyte[3] data) {
        Op op;
        switch (data[1]) {
            case 0: op = Op.MORE_THAN_EQUALS; break;
            case 1: op = Op.LESS_THAN_EQUALS; break;
            default:
                throw new Exception(format("Unknown animation mode op %d.", data[1]));
        }

        return Condition(
            "animation",
            [],
            _paramFactory.op(op),
            _paramFactory.create("animation", ParameterType.INTEGER, data[0])
        );
    }

    // health(target) < 100
    private Condition opHealthBelow(immutable ubyte[3] data) {
        immutable uint value = data[1] + (data[2] << 8);
        return Condition(
            "health",
            [_paramFactory.create("target", ParameterType.TARGET, data[0])],
            _paramFactory.op(Op.LESS_THAN),
            _paramFactory.create("health", ParameterType.INTEGER, value)
        );
    }

    // stat(target, stat) < 50
    private Condition opStatBelow(immutable ubyte[3] data) {
        return Condition(
            "stat",
            [
                _paramFactory.create("target", ParameterType.TARGET, data[0]),
                _paramFactory.create("stat", ParameterType.STAT, data[1]),
            ],
            _paramFactory.op(Op.LESS_THAN),
            _paramFactory.create("value", ParameterType.INTEGER, data[2])
        );
    }

    // stat(target, stat) <=
    private Condition opStatBelowOrEqual(immutable ubyte[3] data) {
        return Condition(
            "stat",
            [
                _paramFactory.create("target", ParameterType.TARGET, data[0]),
                _paramFactory.create("stat", ParameterType.STAT, data[1]),
            ],
            _paramFactory.op(Op.LESS_THAN_EQUALS),
            _paramFactory.create("value", ParameterType.INTEGER, data[2])
        );
    }

    // distanceTo(target) <= 32
    private Condition opInsideRadius32(immutable ubyte[3] data) {
        Op op = Op.LESS_THAN;
        if (data[1]) {
            op = Op.MORE_THAN_EQUALS;
        }

        return Condition(
            "distanceTo",
            [_paramFactory.create("target", ParameterType.TARGET, data[0])],
            _paramFactory.op(op),
            _paramFactory.create("distance", ParameterType.INTEGER, 32)
        );
    }

    // screenPosition(target) x <= 10 && y <= 10
    private Condition opScreenCheck(immutable ubyte[3] data) {
        immutable ubyte vertical = data[1];
        immutable ubyte horizontal = data[2];
        
        Op opV = vertical ? Op.MORE_THAN_EQUALS : Op.LESS_THAN;
        immutable int valueV = 128;

        immutable Op opH = horizontal ? Op.LESS_THAN : Op.MORE_THAN_EQUALS;
        immutable int valueH = horizontal ? 80 : 176;

        return Condition(
            "screenPosition",
            [_paramFactory.create("target", ParameterType.TARGET, TargetType.ENEMY_SELF)],
            _paramFactory.create("x", ParameterType.STRING, "x"),
            _paramFactory.op(opH),
            _paramFactory.create("value", ParameterType.INTEGER, valueH),

            _paramFactory.op(Op.AND),

            _paramFactory.create("y", ParameterType.STRING, "y"),
            _paramFactory.op(opV),
            _paramFactory.create("value", ParameterType.INTEGER, valueV),
        );
    }

    // lastHitTechSource == player
    private Condition opTechElementCheck(immutable ubyte[3] data) {
        return Condition(
            "lastHitTechSource",
            [],
            _paramFactory.op(data[2] ? Op.NOT_EQUALS : Op.EQUALS),
            _paramFactory.create("source", ParameterType.STRING, data[0] ? "enemy" : "player")
        );
    }

    // lastHitTechSource == player && lastHitTech == 45
    private Condition opTechCheck(immutable ubyte[3] data) {
        return Condition(
            "lastHitTechSourceAndTech",
            [],
            _paramFactory.op(data[2] ? Op.NOT_EQUALS : Op.EQUALS),
            _paramFactory.create("source", ParameterType.STRING, data[0] ? "enemy" : "player"),
            _paramFactory.create("tech", ParameterType.TECH, data[1])
        );
    }

    // lastHitSource == player
    private Condition opAttackerType(immutable ubyte[3] data) {
        return Condition(
            "lastHitSource",
            [],
            _paramFactory.op(data[2] ? Op.EQUALS : Op.NOT_EQUALS),
            _paramFactory.create("type", ParameterType.STRING, data[0] ? "enemy" : "player"),
        );
    }  

    // attackType == element_shadow
    private Condition opAttackElement(immutable ubyte[3] data) {
        string[] elements;
        if (data[0] & 0x01) {
            throw new Exception("Unknown element type flag 0x01");
        }
        if (data[0] & 0x02) {
            elements ~= "magical";
        }
        if (data[0] & 0x04) {
            elements ~= "physical";
        }
        if (data[0] & 0x08) {
            throw new Exception("Unknown element type flag 0x08");
        }
        if (data[0] & 0x10) {
            elements ~= "element_fire";
        }
        if (data[0] & 0x20) {
            elements ~= "element_water";
        }
        if (data[0] & 0x40) {
            elements ~= "element_shadow";
        }
        if (data[0] & 0x80) {
            elements ~= "element_lightning";
        }
        
        return Condition(
            "attackType",
            [],
            _paramFactory.op(data[2] ? Op.NOT_EQUALS : Op.EQUALS),
            _paramFactory.create("types", ParameterType.ARRAY_STRING, elements)
        );
    }

    // random(0.5)
    private Condition opRandomChance(immutable ubyte[3] data) {
        return Condition(
            "random",
            [],
            _paramFactory.create("chance", ParameterType.FLOAT, cast(double)data[0] / 256.0)
        );
    }

    // stat(target, stat) == 10
    private Condition opCheckStat(immutable ubyte[3] data) {
        return Condition(
            "stat",
            [
                _paramFactory.create("target", ParameterType.TARGET, data[1]),
                _paramFactory.create("stat", ParameterType.STAT, data[2]),
            ],
            _paramFactory.op(Op.EQUALS),
            _paramFactory.create("value", ParameterType.INTEGER, data[0])
        );
    }

    // enemyTypeCount("mammon-machine") == 1
    // enemyTypeCount("mammon-machine") > 1
    private Condition opIdenticalMonsterCount(immutable ubyte[3] data) {
        if (data[1] == 0) {
            return Condition(
                "enemyTypeCount",
                [_paramFactory.create("enemy", ParameterType.ENEMY, data[0])],
                _paramFactory.op(Op.EQUALS),
                _paramFactory.create("value", ParameterType.INTEGER, 1)
            );    
        }

        return Condition(
            "enemyTypeCount",
            [_paramFactory.create("enemy", ParameterType.ENEMY, data[0])],
            _paramFactory.op(Op.MORE_THAN),
            _paramFactory.create("value", ParameterType.INTEGER, 1)
        );
    }

    // playersAlive >= 2
    private Condition opPlayerCount(immutable ubyte[3] data) {
        return Condition(
            "playersAlive",
            [],
            _paramFactory.op(Op.LESS_THAN_EQUALS),
            _paramFactory.create("amount", ParameterType.INTEGER, data[1] + 1)
        );
    }

    // distanceTo(target) >= 48
    private Condition opInsideRadius48(immutable ubyte[3] data) {
        return Condition(
            "distanceTo",
            [_paramFactory.create("target", ParameterType.TARGET, data[0])],
            _paramFactory.op(data[1] ? Op.MORE_THAN_EQUALS : Op.LESS_THAN),
            _paramFactory.create("distance", ParameterType.INTEGER, 48)
        );
    }

    // isFinalAttack()
    private Condition opFinalAttack(immutable ubyte[3] data) {
        return Condition("isFinalAttack");
    }

    // Unused.
    private Condition opFailure(immutable ubyte[3] data) {
        return Condition("setFailure");
    }

    // Unused.
    private Condition opUnknownCompare(immutable ubyte[3] data) {
        return Condition(
            "compareUnknown",
            [_paramFactory.create("target", ParameterType.TARGET, data[0])],
            _paramFactory.op(data[2] ? Op.MORE_THAN_EQUALS : Op.LESS_THAN),
            _paramFactory.create("unknown", ParameterType.INTEGER, data[1]),
        );
    }

    // Unused.
    private Condition opStatBitsSet(immutable ubyte[3] data) {
        return Condition(
            "statBits",
            [_paramFactory.create("target", ParameterType.TARGET, data[0])],
            _paramFactory.create("stat bits", ParameterType.INTEGER, data[1]),
            _paramFactory.op(Op.BIT_AND),
            _paramFactory.create("bitmask", ParameterType.INTEGER_HEX, data[2])
        );
    }

    // Unused.
    private Condition opFrameCounter(immutable ubyte[3] data) {
        immutable uint value = data[0] + (data[1] << 8) + (data[2] << 16);
        return Condition(
            "battleFrameCounter",
            [],
            _paramFactory.op(Op.MORE_THAN_EQUALS),
            _paramFactory.create("frame", ParameterType.INTEGER, value)
        );
    }

    // Unused.
    private Condition opXDistance(immutable ubyte[3] data) {
        Op op = Op.MORE_THAN;
        if (data[1]) {
            op = Op.LESS_THAN_EQUALS;
        }

        return Condition(
            "xDistanceTo",
            [_paramFactory.create("target", ParameterType.TARGET, data[0])],
            _paramFactory.op(op),
            _paramFactory.create("distance", ParameterType.INTEGER, 32)
        );
    }

    // Unused.
    private Condition opDistanceUnknown1(immutable ubyte[3] data) {
        return Condition(
            "distanceCheckUnknown1",
            [_paramFactory.create("target", ParameterType.TARGET, data[0])],
            _paramFactory.create("unknown", ParameterType.INTEGER, data[1]),
            _paramFactory.create("unknown", ParameterType.INTEGER, data[2])
        );
    }

    // Unused.
    private Condition opDistanceUnknown2(immutable ubyte[3] data) {
        return Condition(
            "distanceCheckUnknown2",
            [_paramFactory.create("target", ParameterType.TARGET, data[0])],
            _paramFactory.create("unknown", ParameterType.INTEGER, data[1]),
            _paramFactory.create("unknown", ParameterType.INTEGER, data[2])
        );
    }

    // Unused.
    private Condition opAttackerStat(immutable ubyte[3] data) {
        return Condition(
            "unknownAttackerCheck",
            [],
            _paramFactory.create("value", ParameterType.INTEGER, data[0]),
            _paramFactory.create("mode", ParameterType.INTEGER, data[1]),
            _paramFactory.op(data[2] ? Op.NOT_EQUALS : Op.EQUALS)
        );
    }  

    // Unused.
    private Condition opPlayerPresence(immutable ubyte[3] data) {
        return Condition(
            "playerStatus",
            [_paramFactory.create("target", ParameterType.TARGET, data[0])],
            _paramFactory.create("absent", ParameterType.BOOL, !!data[1]),
            _paramFactory.create("dead", ParameterType.BOOL, !!data[2]),
        );
    }

    // Unused.
    private Condition opTargetAlive(immutable ubyte[3] data) {
        return Condition(
            "isAlive",
            [_paramFactory.create("target", ParameterType.TARGET, data[0])],
            _paramFactory.create("isAlive", ParameterType.BOOL, !!data[2])
        );
    }

}
