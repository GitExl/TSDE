module Mods.ModConditionInterface;

import std.json;

public interface ModConditionInterface {
    public const string name();
    public const string description();
    public const JSONValue serialize();
}