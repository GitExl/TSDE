/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module ArrayTools;

import std.conv;
import std.traits;
import std.array;
import std.string;

public string[] flagStringArray(T)(immutable uint bits) {
    string[] flagStrings;

    foreach (flag; EnumMembers!T) {
        if (bits & flag) {
            flagStrings ~= to!string(flag);
        }
    }

    return flagStrings;
}

public string flagStringArrayBool(T)(uint bits) {
    string[] flagStrings;

    foreach (flag; EnumMembers!T) {
        if (bits & flag) {
            flagStrings ~= T.stringof ~ "." ~ to!string(flag);
        }
    }

    if (!flagStrings.length) {
        flagStrings ~= "0";
    }

    return join(flagStrings, " | ");
}

public string[] enumStringKeys(T)(const T[] items) {
    string[] strings;

    foreach (item; items) {
        strings ~= to!string(item);
    }

    return strings;
}

public string[] enumStringValues(T)(const T[] items) {
    string[] strings;

    foreach (item; items) {
        strings ~= cast(string)item;
    }

    return strings;
}

public string printableDataArray(ubyte[] data) {
    string[] printable;
    foreach (ref ubyte value; data) {
        printable ~= format("0x%02X", value);
    }
    return "{" ~ join(printable, ", ") ~ "}";
}