/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module Maps.MapList;

import List.ListInterface;
import List.ListReaderInterface;
import List.ListWriterInterface;

import Maps.Map;

public class MapList : ListInterface!Map {

    private Map[] _maps;

    public void readWith(ListReaderInterface!Map reader) {
        _maps = reader.read();
    }

    public void writeWith(ListWriterInterface!Map writer) {
        writer.write(_maps);
    }

    public string getKeyByIndex(immutable int index) {
        return _maps[index].key;
    }

}
