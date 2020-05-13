module Game;

import std.stdio;
import std.json;

import StringTables.StringTableList;
import StringTables.ROMStringTableReader;
import StringTables.TextStringTableWriter;

import Mods.ModList;
import Mods.ROMModReader;
import Mods.JSONModWriter;

import StatMods.StatModList;
import StatMods.ROMStatModReader;
import StatMods.JSONStatModWriter;

import Items.ItemList;
import Items.ROMItemReader;
import Items.JSONItemWriter;

import Enemies.EnemyList;
import Enemies.ROMEnemyReader;
import Enemies.JSONEnemyWriter;

import Scenes.SceneList;
import Scenes.ROMSceneReader;
import Scenes.JSONSceneWriter;

import Palettes.PaletteList;
import Palettes.ROMPaletteReader;
import Palettes.ACTPaletteWriter;

import BattleScripts.BattleScriptList;
import BattleScripts.ROMBattleScriptReader;
import BattleScripts.TextBattleScriptWriter;

import SceneScripts.SceneScriptList;
import SceneScripts.ROMSceneScriptReader;
import SceneScripts.TextSceneScriptWriter;

import TileSets.TileSetList;
import TileSets.ROMTileSetReader;
import TileSets.JSONTileSetWriter;

import Maps.MapList;
import Maps.ROMMapReader;
import Maps.JSONMapWriter;

import Graphics.GraphicsList;
import Graphics.ROMGraphicsReader;
import Graphics.BMPGraphicsWriter;

import BinaryFile;

public class Game {

    private StringTableList _strings;
    private ModList _mods;
    private PaletteList _palettes;
    private StatModList _statMods;
    private ItemList _items;
    private EnemyList _enemies;
    private BattleScriptList _battleScripts;
    private SceneScriptList _sceneScripts;
    private TileSetList _tileSets;
    private MapList _maps;
    private GraphicsList _graphics;
    private SceneList _scenes;

    public void readFromROM(BinaryFile rom, JSONValue config) {
        writeln("Reading strings...");
        _strings = new StringTableList();
        _strings.readWith(new ROMStringTableReader(config, rom));

        writeln("Reading mods...");
        _mods = new ModList();
        _mods.readWith(new ROMModReader(config, rom));

        writeln("Reading stat mods...");
        _statMods = new StatModList();
        _statMods.readWith(new ROMStatModReader(config, rom));

        writeln("Reading palettes...");
        _palettes = new PaletteList();
        _palettes.readWith(new ROMPaletteReader(config, rom));

        writeln("Reading items...");
        _items = new ItemList();
        _items.readWith(new ROMItemReader(config, rom, _strings, _mods, _statMods, _palettes));

        writeln("Reading enemies...");
        _enemies = new EnemyList();
        _enemies.readWith(new ROMEnemyReader(config, rom, _items, _strings));

        writeln("Reading battle scripts...");
        _battleScripts = new BattleScriptList();
        _battleScripts.readWith(new ROMBattleScriptReader(config ,rom, _strings, _enemies));

        writeln("Reading scenes...");
        _scenes = new SceneList();
        _scenes.readWith(new ROMSceneReader(config, rom, _items));

        writeln("Reading scene scripts...");
        _sceneScripts = new SceneScriptList();
        _sceneScripts.readWith(new ROMSceneScriptReader(config, rom, _strings, _enemies, _items, _palettes, _scenes));

        writeln("Reading tilesets...");
        _tileSets = new TileSetList();
        _tileSets.readWith(new ROMTileSetReader(config, rom));

        writeln("Reading maps...");
        _maps = new MapList();
        _maps.readWith(new ROMMapReader(config, rom));

        writeln("Reading graphics...");
        _graphics = new GraphicsList();
        _graphics.readWith(new ROMGraphicsReader(config, rom));
    }

    public void write(string path) {
        writeln("Writing strings...");
        _strings.writeWith(new TextStringTableWriter(path ~ "/strings"));

        writeln("Writing mods...");
        _mods.writeWith(new JSONModWriter(path ~ "/mods"));

        writeln("Writing stat mods...");
        _statMods.writeWith(new JSONStatModWriter(path ~ "/statmods"));

        writeln("Writing palettes...");
        _palettes.writeWith(new ACTPaletteWriter(path ~ "/palettes"));

        writeln("Writing items...");
        _items.writeWith(new JSONItemWriter(path ~ "/items"));

        writeln("Writing enemies...");
        _enemies.writeWith(new JSONEnemyWriter(path ~ "/enemies"));

        writeln("Writing battle scripts...");
        _battleScripts.writeWith(new TextBattleScriptWriter(path ~ "/battlescripts"));

        writeln("Writing scenes...");
        _scenes.writeWith(new JSONSceneWriter(path ~ "/scenes"));

        writeln("Writing scene scripts...");
        _sceneScripts.writeWith(new TextSceneScriptWriter(path ~ "/scenescripts"));

        writeln("Writing tilesets...");
        _tileSets.writeWith(new JSONTileSetWriter(path ~ "/tilesets"));

        writeln("Writing maps...");
        _maps.writeWith(new JSONMapWriter(path ~ "/maps"));

        writeln("Writing graphics...");
        _graphics.writeWith(new BMPGraphicsWriter(path ~ "/graphics"));
    }

}