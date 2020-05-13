/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module JSONTools;

import std.string;
import std.file;
import std.json;

public JSONValue loadJSON(immutable string filename) {
    return parseJSON(cast(char[])read(filename));
}

public JSONValue[] loadStubbedJSONNames(immutable string filename, immutable string stubName, immutable uint count, immutable bool numbered) {
    if (!exists(filename)) {
        JSONValue[] names = new JSONValue[count];
        foreach (int index, ref JSONValue name; names) {
            if (numbered) {
                name = JSONValue(format("%s_%03d", stubName, index));
            } else {
                name = JSONValue(stubName);
            }
        }
        return names;
    }

    return parseJSON(cast(char[])read(filename)).array;
}
