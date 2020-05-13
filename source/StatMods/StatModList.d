/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module StatMods.StatModList;

import List.ListInterface;
import List.ListReaderInterface;
import List.ListWriterInterface;

import StatMods.StatMod;

public class StatModList : ListInterface!StatMod {

    private StatMod[] _statMods;

    public void readWith(ListReaderInterface!StatMod reader) {
        _statMods = reader.read();
    }

    public void writeWith(ListWriterInterface!StatMod writer) {
        writer.write(_statMods);
    }

    public string getKeyByIndex(immutable int index) {
        return _statMods[index].key;
    }

}
