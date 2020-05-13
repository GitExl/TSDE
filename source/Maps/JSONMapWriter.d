module Maps.JSONMapWriter;

import std.conv;
import std.base64;
import std.outbuffer;
import std.json;
import std.stdio;
import std.string;
import std.file;

import List.ListWriterInterface;

import Maps.Map;

import ArrayTools;

public class JSONMapWriter : ListWriterInterface!Map {

    private string _outputPath;

    public this(immutable string outputPath) {
        _outputPath = outputPath;
    }

    public void write(const Map[] maps) {
        mkdirRecurse(_outputPath);
        foreach (const Map map; maps) {
            JSONValue json = serialize(map);
            File file = File(format("%s/%s.json", _outputPath, map.key), "w");
            file.writeln(json.toJSON(true));
            file.close();    
        }
    }

    public JSONValue serialize(const Map map) {
        JSONValue value;

        JSONValue[] layers;

        JSONValue layer1;
        layer1["width"] = map.layers[0].width;
        layer1["height"] = map.layers[0].height;
        layer1["scroll"] = map.layers[0].scroll;
        layer1["tiles"] = encodeLayerTiles(map.layers[0].tiles);
        layers ~= layer1;
        
        JSONValue layer2;
        layer2["width"] = map.layers[1].width;
        layer2["height"] = map.layers[1].height;
        layer2["scroll"] = map.layers[1].scroll;
        layer2["tiles"] = encodeLayerTiles(map.layers[1].tiles);
        layers ~= layer2;

        if (map.hasL3) {
            JSONValue layer3;
            layer3["width"] = map.layers[2].width;
            layer3["height"] = map.layers[2].height;
            layer3["scroll"] = map.layers[2].scroll;
            layer3["tiles"] = encodeLayerTiles(map.layers[2].tiles);
            layers ~= layer3;
        }

        value["layers"] = layers;
        value["tileProperties"] = encodeTileProps(map.tileProps);

        value["screens"] = flagStringArray!ScreenFlags(map.screenFlags);
        value["effects"] = flagStringArray!MapEffectFlags(map.effectFlags);
        value["effectType"] = to!string(map.effectType);

        return value;
    }

    private char[] encodeLayerTiles(const TileIndex[] tiles) {
        OutBuffer buf = new OutBuffer();
        const uint bufferLen = Base64.encodeLength(tiles.length * TileIndex.sizeof);
        char[] buffer = new char[bufferLen];

        foreach (const TileIndex tile; tiles) {
            buf.write(tile);
        }
        Base64.encode(buf.toBytes(), buffer);
        
        return buffer;
    }

    private char[] encodeTileProps(const TileProps[] props) {
        OutBuffer buf = new OutBuffer();
        const uint bufferLen = Base64.encodeLength(props.length * 8);
        char[] buffer = new char[bufferLen];

        foreach (const TileProps prop; props) {
            buf.write(cast(ushort)prop.flags);

            buf.write(prop.zPlane);
            buf.write(cast(ubyte)prop.solidity);
            if (prop.solidity == SolidityType.CORNER) {
                buf.write(cast(ubyte)prop.corner);
            } else if (prop.solidity == SolidityType.STAIR) {
                buf.write(cast(ubyte)prop.stairs);
            } else if (prop.solidity == SolidityType.QUAD) {
                buf.write(cast(ubyte)prop.quad);
            } else {
                buf.write(cast(ubyte)0);
            }
            buf.write(prop.solidityMod);

            buf.write(prop.movement);
            buf.write(prop.movementSpeed);
        }
        Base64.encode(buf.toBytes(), buffer);
        
        return buffer;
    }

}
