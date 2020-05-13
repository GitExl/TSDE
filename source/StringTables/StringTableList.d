/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module StringTables.StringTableList;

import List.ListInterface;
import List.ListReaderInterface;
import List.ListWriterInterface;

import StringTables.StringTable;

public class StringTableList : ListInterface!StringTable {

    private StringTable[] _tables;
    private uint[string] _tablesByKey;

    public void readWith(ListReaderInterface!StringTable reader) {
        _tables = reader.read();
        index();
    }

    public void writeWith(ListWriterInterface!StringTable writer) {
        writer.write(_tables);
    }

    public string getKeyByIndex(immutable int index) {
        return _tables[index].key;
    }

    public string get(immutable string key, immutable uint index) {
        return _tables[_tablesByKey[key]].get(index);
    }

    private void index() {
        _tablesByKey.clear();
        foreach (int index, StringTable table; _tables) {
            _tablesByKey[table.key] = index;
        }
    }

}
