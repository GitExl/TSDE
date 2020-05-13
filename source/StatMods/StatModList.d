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
