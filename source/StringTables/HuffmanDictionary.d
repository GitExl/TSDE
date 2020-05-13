module StringTables.HuffmanDictionary;

import std.string;
import std.conv;

import BinaryFile;

public class HuffmanDictionary {

    private static immutable uint DICTIONARY_LENGTH = 0x9F;

    private string[] _words;

    public this(BinaryFile data, const uint offset, const uint size) {
        data.setPosition(offset);

        uint[] pointers = new uint[size];
        foreach (ref uint pointer; pointers) {
            pointer = data.read!ushort() + (offset & 0xFF0000);
        }

        _words = new string[size];
        foreach (const uint index, ref string word; _words) {
            data.setPosition(pointers[index]);
            const ubyte length = data.read!ubyte();
            word = readWord(data, length);
        }
    }

    public string readString(BinaryFile data) {
        string[] parts;

        while (1) {
            const ubyte code = data.read!ubyte();

            // Strings end on a NULL character, or a delay special character with it's parameter set to 0.
            if (!code || (code == 0x03 && data.peek!ubyte() == 0x00)) {
                break;
            } else if (code == 1) {
                parts ~= readChar(0x100 + data.read!ubyte());
            } else if (code == 2) {
                parts ~= readChar(0x200 + data.read!ubyte());
            } else if (code >= 0x21 && code <= DICTIONARY_LENGTH) {
                parts ~= _words[code - 0x21];
            } else if (code > DICTIONARY_LENGTH) {
                parts ~= readChar(code);
            } else {
                parts ~= readSpecialChar(code, data);
            }
        }

        return parts.join("");
    }

    private static string readWord(BinaryFile data, immutable ubyte length) {
        string[] parts;

        for (int offset = 0; offset < length; offset++) {
            const ubyte code = data.read!ubyte();
            if (!code) {
                break;
            } else if (code == 1) {
                parts ~= readChar(0x100 + data.read!ubyte());
            } else if (code == 2) {
                parts ~= readChar(0x200 + data.read!ubyte());
            } else if (code >= DICTIONARY_LENGTH) {
                parts ~= readChar(code);
            } else {
                parts ~= readSpecialChar(code, data);
            }
        }

        return parts.join("");
    }

    private static string readChar(immutable uint code) {
        if (code >= 0xA0 && code <= 0xB9) {
            return to!string(cast(char)('A' + (code - 0xA0)));
        } else if (code >= 0xBA && code <= 0xD3) {
            return to!string(cast(char)('a' + (code - 0xBA)));
        } else if (code >= 0xD4 && code <= 0xDD) {
            return to!string(cast(char)('0' + (code - 0xD4)));
        } else {
            switch (code) {
                case 0xDE: return "!";
                case 0xDF: return "?";
                case 0xE0: return "/";
                case 0xE1: return "“";
                case 0xE2: return "”";
                case 0xE3: return ":";
                case 0xE4: return "&";
                case 0xE5: return "(";
                case 0xE6: return ")";
                case 0xE7: return "'";
                case 0xE8: return ".";
                case 0xE9: return ",";
                case 0xEA: return "=";
                case 0xEB: return "-";
                case 0xEC: return "+";
                case 0xED: return "%";
                case 0xEE: return "{note}";
                case 0xEF: return " ";
                case 0xF0: return "{heart}";
                case 0xF1: return "...";
                case 0xF2: return "{infinity}";
                case 0xF3: return "#";
                default: return format("{UNKNOWNCHAR_0x%02X}", code);
            }
        }
    }

    private static string readSpecialChar(immutable uint code, BinaryFile data) {
        switch (code) {
            case 0x03: return format("{delay,%d}", data.read!ubyte());
            case 0x05: return " ";
            case 0x06: return "{line break}";
            case 0x07: return "{stop}";
            case 0x08: return "{stop line break}";
            case 0x09: return "{instant line break}";
            case 0x0A: return "{instant page break}";
            case 0x0B: return "{full break}";
            case 0x0C: return "{page break}";
            case 0x0D: return "{result 8bits}";
            case 0x0E: return "{result 16bits}";
            case 0x0F: return "{result 24bits}";
            case 0x11: return "{spch 11}";  // TODO, displays previous substring?
            case 0x12: return format("{tech,%d}", data.read!ubyte());
            case 0x13: return "{pc1name}";
            case 0x14: return "{pc2name}";
            case 0x15: return "{pc3name}";
            case 0x16: return "{pc4name}";
            case 0x17: return "{pc5name}";
            case 0x18: return "{pc6name}";
            case 0x19: return "{pc7name}";
            case 0x1A: return "{pc1nickname}";
            case 0x1B: return "{pc1}";
            case 0x1C: return "{pc2}";
            case 0x1D: return "{pc3}";
            case 0x1E: return "{queenName}";
            case 0x1F: return "{result item}";
            case 0x20: return "{hovercraftName}";
            default: return "{UNKNOWNSPECIAL}";
        }
    }
}