module StringTables.StringTable;

public struct StringTable {
    string key;
    string[] strings;

    public string get(immutable uint index) {
        if (index >= strings.length) {
            return "INVALID";
        }
        return strings[index];
    }
}
