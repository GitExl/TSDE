module Mods.JSONModWriter;

import std.json;
import std.stdio;
import std.string;
import std.file;

import List.ListWriterInterface;

import Mods.Mod;
import Mods.ModEffectInterface;
import Mods.ModConditionInterface;

public class JSONModWriter : ListWriterInterface!Mod {

    private string _outputPath;

    public this(immutable string outputPath) {
        _outputPath = outputPath;
    }

    public void write(const Mod[] mods) {
        mkdirRecurse(_outputPath);
        foreach (const Mod mod; mods) {
            JSONValue json = serialize(mod);
            File file = File(format("%s/%s.json", _outputPath, mod.key), "w");
            file.writeln(json.toJSON(true));
            file.close();    
        }
    }

    public JSONValue serialize(const Mod mod) {
        JSONValue value;

        value["name"] = mod.name;

        if (mod.conditions.length) {
            value["conditions"] = serializeConditions(mod.conditions);
        }
        if (mod.effects.length) {
            value["effects"] = serializeEffects(mod.effects);
        }

        return value;
    }

    private JSONValue serializeConditions(const ModConditionInterface[] effects) {
        JSONValue value;

        foreach (const ModConditionInterface condition; effects) {
            value[condition.name()] = condition.serialize();
        }

        return value;
    }

    private JSONValue serializeEffects(const ModEffectInterface[] effects) {
        JSONValue value;

        foreach (const ModEffectInterface effect; effects) {
            value[effect.name()] = effect.serialize();
        }

        return value;
    }

}
