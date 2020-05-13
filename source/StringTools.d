/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module StringTools;

import std.string;

public string generateKeyFromName(string key) {
    return key.strip().toLower()
        .replace(":", "")
        .replace("{", "_")
        .replace("}", "_")
        .replace("(", "")
        .replace(")", "")
        .replace(".", "")
        .replace("?", "")
        .replace(" ", "_")
        .replace("'", "")
        .replace("/", "_")
        .replace("-", "")
        .replace("__", "_");
}
