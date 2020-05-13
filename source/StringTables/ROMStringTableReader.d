module StringTables.ROMStringTableReader;

import std.json;
import std.string;

import List.ListReaderInterface;

import StringTables.StringTable;
import StringTables.HuffmanDictionary;

import BinaryFile;

private static immutable string[] FONT_8_MAP = [
    "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶",
    "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶",
    "{blade}", "{bow}", "{gun}", "{arm}", "{sword}", "{fist}", "{scythe}", "{helm}", "{armor}", "{ring}", "{H}", "{M}", "{P}", ":", "{shield}", "{star}",
    "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶",
    "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶",
    "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "{left}", "{right}", "(", ")", ":",
    "{hand1}", "{hand2}", "{hand3}", "{hand4}", "{H}", "{M}", "{P}", "{hp0}", "{hp1}", "{hp2}", "{hp3}", "{hp4}", "{hp5}", "{hp6}", "{hp7}", "{hp8}",
    "¶", "¶", "°", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "{D}", "{Z}", "{up}",
    "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶",
    "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶", "¶",
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P",
    "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f",
    "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v",
    "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "!", "?",
    "/", "“", "”", ":", "&", "(", ")", "'", ".", ",", "=", "-", "+", "%", "#", " ",
    "°", "{A}", "#", "#", "{L}", "{R}", "{H}", "{M}", "{P}", "̖", "{corner}", "(", ")", "¶", "¶", " "
];

public class ROMStringTableReader : ListReaderInterface!StringTable {

    private JSONValue _config;
    private BinaryFile _rom;

    public this (JSONValue config, BinaryFile rom) {
        _config = config;
        _rom = rom;
    }

    public StringTable[] read() {
        immutable uint dictSize = cast(uint)_config["dictionary"]["size"].integer;
        immutable uint dictAddress = cast(uint)_config["dictionary"]["address"].integer;
        HuffmanDictionary dictionary = new HuffmanDictionary(_rom, dictAddress, dictSize);

        StringTable[] tables;

        foreach (string key, JSONValue tableConfig; _config["strings"].object) {
            StringTable table;
            table.key = key;

            immutable uint address = cast(uint)tableConfig["address"].integer;
            immutable uint count = cast(uint)tableConfig["count"].integer;
            immutable bool isHuffman = "huffman" in tableConfig ? tableConfig["huffman"].boolean : false;

            _rom.setPosition(address);
            if (isHuffman) {
                table.strings = readHuffmanStrings(dictionary, count);
            } else {
                immutable uint size = cast(uint)tableConfig["size"].integer;
                table.strings = readStrings(count, size);
            }

            tables ~= table;
        }

        return tables;
    }

    private string[] readHuffmanStrings(HuffmanDictionary dict, immutable uint count) {
        immutable uint bank = _rom.getPosition() & 0xFF0000;
        
        uint[] offsets = new uint[count];
        foreach (ref uint offset; offsets) {
            offset = _rom.read!ushort() + bank;
        }

        string[] strings = new string[count];
        foreach (int index, const int offset; offsets) {
            _rom.setPosition(offset);
            strings[index] = dict.readString(_rom);
        }

        return strings;
    }

    private string[] readStrings(immutable uint count, immutable uint size) {
        string[] strings = new string[count];

        foreach (ref string str; strings) {
            ubyte[] data = _rom.readBytes(size);

            string[] parts;
            foreach (immutable ubyte value; data) {
                parts ~= FONT_8_MAP[value];
            }
            str = parts.join().strip();
        }

        return strings;
    }
}
