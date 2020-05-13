/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module Mods.ModList;

import List.ListInterface;
import List.ListReaderInterface;
import List.ListWriterInterface;

import Mods.Mod;

public class ModList : ListInterface!Mod {

    private Mod[] _mods;

    public void readWith(ListReaderInterface!Mod reader) {
        _mods = reader.read();
    }

    public void writeWith(ListWriterInterface!Mod writer) {
        writer.write(_mods);
    }

    public string getKeyByIndex(immutable int index) {
        return _mods[index].key;
    }

}
