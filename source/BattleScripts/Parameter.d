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
