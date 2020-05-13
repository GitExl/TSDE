/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module SceneScripts.SceneScriptList;

import List.ListInterface;
import List.ListReaderInterface;
import List.ListWriterInterface;

import SceneScripts.SceneScript;

public class SceneScriptList : ListInterface!SceneScript {

    private SceneScript[] _scripts;

    public void readWith(ListReaderInterface!SceneScript reader) {
        _scripts = reader.read();
    }

    public void writeWith(ListWriterInterface!SceneScript writer) {
        writer.write(_scripts);
    }

    public string getKeyByIndex(immutable int index) {
        return _scripts[index].key;
    }

}
