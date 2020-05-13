module StatMods.JSONStatModWriter;

import std.string;
import std.json;
import std.stdio;
import std.conv;
import std.file;

import List.ListWriterInterface;

import StatMods.StatMod;

import Stats;

public class JSONStatModWriter : ListWriterInterface!StatMod {

    private string _outputPath;

    public this(immutable string outputPath) {
        _outputPath = outputPath;
    }

    public void write(const StatMod[] statMods) {
        mkdirRecurse(_outputPath);
        foreach (const StatMod statMod; statMods) {
            JSONValue json = serialize(statMod);
            File file = File(format("%s/%s.json", _outputPath, statMod.key), "w");
            file.writeln(json.toJSON(true));
            file.close();    
        }
    }

    public JSONValue serialize(const StatMod statMod) {
        JSONValue value;

        value["name"] = statMod.name;
        
        if (statMod.mods.length) {
            JSONValue mods;
            foreach (Stat stat, int modValue; statMod.mods) {
                mods[to!string(stat)] = modValue;
            }   
            value["mods"] = mods;
        }

        return value;
    }

}