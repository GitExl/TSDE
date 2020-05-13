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
