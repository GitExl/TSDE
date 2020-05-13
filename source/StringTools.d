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
