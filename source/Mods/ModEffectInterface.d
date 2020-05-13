module Mods.ModEffectInterface;

import std.json;

public interface ModEffectInterface {
    public const string name();
    public const string description();
    public const JSONValue serialize();
}
