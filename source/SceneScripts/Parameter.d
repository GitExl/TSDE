/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module SceneScripts.Parameter;

import std.string;

public enum ParameterType : ubyte {
    INTEGER,
    FLOATING,
    BOOL,
    STRING,
    ADDRESS8_7F0200,
    ADDRESS8_7F0000,
    ADDRESS16,
    ADDRESS24,
    HEX_BYTE,
    PC,
    OBJECT,
    NPC,
    ENEMY,
    ITEM,
    LOCATION,
    SHOP,
    MUSIC,
    SOUND_EFFECT,
    PALETTE,
    VOLUME,
    PAN,
    ENUM,
    OPERATOR,
    FLAGS,
    DATA,
    LABEL,
    STRING_INDEX,
    OBJECT_FUNCTION,
}

public struct Parameter {
    ParameterType type;
    string name;
    string value;
    string comment;
    uint addressValue;

    public string toString() {
        if (this.type == ParameterType.STRING || this.type == ParameterType.NPC ||
            this.type == ParameterType.PC || this.type == ParameterType.LOCATION) {
            return format("\"%s\"", this.value);
        }

        return this.value;
    }

}
