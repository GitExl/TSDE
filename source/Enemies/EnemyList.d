/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

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
