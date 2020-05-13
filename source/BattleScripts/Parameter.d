/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module BattleScripts.Parameter;

public enum ParameterType : int {
    INTEGER,
    INTEGER_HEX,
    FLOAT,
    BOOL,
    STRING,
    OP,
    STAT,
    TARGET,
    STATUS,
    TECH,
    ARRAY_STRING,
    ENEMY,
    MESSAGE,
}

public enum Op : string {
    EQUALS = "==",
    NOT_EQUALS = "!=",
    MORE_THAN = ">",
    LESS_THAN = "<",
    MORE_THAN_EQUALS = ">=",
    LESS_THAN_EQUALS = "<=",
    BIT_AND = "&",
    BIT_OR = "|",
    AND = "&&",
    OR = "||"
}

public struct Parameter {
    string name;
    ParameterType type;
    string value;
    string comment;
}
