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
