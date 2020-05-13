module Enemies.EnemyList;

import List.ListInterface;
import List.ListReaderInterface;
import List.ListWriterInterface;

import Enemies.Enemy;

public class EnemyList : ListInterface!Enemy {

    private Enemy[] _enemies;

    public void readWith(ListReaderInterface!Enemy reader) {
        _enemies = reader.read();
    }

    public void writeWith(ListWriterInterface!Enemy writer) {
        writer.write(_enemies);
    }

    public Enemy getByIndex(immutable int index) {
        return _enemies[index];
    }

    public string getKeyByIndex(immutable int index) {
        return _enemies[index].key;
    }

}
