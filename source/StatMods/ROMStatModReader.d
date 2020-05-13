module StatMods.ROMStatModReader;

import std.json;
import std.string;

import List.ListReaderInterface;

import StatMods.StatMod;

import Stats;
import BinaryFile;

public class ROMStatModReader : ListReaderInterface!StatMod {

    private JSONValue _config;
    private BinaryFile _rom;

    public this (JSONValue config, BinaryFile rom) {
        _config = config;
        _rom = rom;
    }

    public StatMod[] read() {
        immutable uint count = cast(uint)_config["statMods"]["count"].integer;
        immutable uint address = cast(uint)_config["statMods"]["address"].integer;

        StatMod[] statMods = new StatMod[count];
        
        _rom.setPosition(address);
        foreach (int index, ref StatMod statMod; statMods) {
            immutable ubyte flags = _rom.read!ubyte();
            immutable byte value = _rom.read!byte();

            if (flags & 0x01) {
                throw new Exception("Unknown stat mod flag 0x01.");
            }
            if (flags & 0x02) {
                statMod.mods[Stat.MAGIC_DEFENSE] = value;
            }
            if (flags & 0x04) {
                statMod.mods[Stat.MAGIC] = value;
            }
            if (flags & 0x10) {
                statMod.mods[Stat.ATTACK] = value;
            }
            if (flags & 0x20) {
                statMod.mods[Stat.STAMINA] = value;
            }
            if (flags & 0x40) {
                statMod.mods[Stat.SPEED] = value;
            }
            if (flags & 0x80) {
                statMod.mods[Stat.POWER] = value;
            }

            string[] nameParts;
            foreach (Stat stat, int modValue; statMod.mods) {
                nameParts ~= format("%s %s%d", cast(string)stat, modValue < 0 ? "-" : "+", modValue);
            }
            statMod.name = nameParts.join(", ");
            statMod.key = format("%03d_statmod", index);
        }

        return statMods;
    }
}
