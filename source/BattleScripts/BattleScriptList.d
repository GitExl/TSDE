/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module BattleScripts.BattleScriptList;

import List.ListInterface;
import List.ListReaderInterface;
import List.ListWriterInterface;

import BattleScripts.BattleScript;

public class BattleScriptList : ListInterface!BattleScript {

    private BattleScript[] _ai;

    public void readWith(ListReaderInterface!BattleScript reader) {
        _ai = reader.read();
    }

    public void writeWith(ListWriterInterface!BattleScript writer) {
        writer.write(_ai);
    }

    public string getKeyByIndex(immutable int index) {
        return _ai[index].key;
    }

}
