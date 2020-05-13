/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module BinaryFile;

import std.string;
import std.stdio;
import std.path;
import std.bitmanip;

final class BinaryFile {
    private uint _position;
    private ubyte[] _data;

    this(const string fileName) {
        File input = File(fileName, "rb");
        const uint size = cast(uint)input.size();
        _data = new ubyte[size];
        input.rawRead(_data);
        input.close();
    }

    this(const ubyte[] ptr) {
        _data = ptr.dup;
    }

    public T read(T)() {
        const ubyte[T.sizeof] data = _data[_position.._position + T.sizeof];
        const T value = littleEndianToNative!T(data);
        _position += T.sizeof;

        return value;
    }

    public T peek(T)() {
        const ubyte[T.sizeof] data = _data[_position.._position + T.sizeof];
        const T value = littleEndianToNative!T(data);

        return value;
    }

    public ubyte[] readBytes(const uint length) {
        ubyte[] value = _data[+_position.._position + length];
        _position += length;

        return value;
    }

    public string readString() {
        int index = _position;
        string value;

        while(index < _data.length) {
            if (_data[index] == 0) {
                value = cast(immutable(char)[])_data[_position..index];
                break;
            }
            index++;
        }
        _position = index + 1;

        return value;
    }

    public void setPosition(const uint position) {
        if (position >= _data.length) {
            throw new Exception(format("Cannot set position to %d, this is past %d.", position, _data.length));
        }

        _position = position;
    }

    public uint getPosition() {
        return _position;
    }

    public void skip(const uint bytes) {
        setPosition(_position + bytes);
    }

    @property
    public ubyte* ptr() {
        return &_data[0];
    }

    @property
    public ubyte[] array() {
        return _data;
    }

    @property
    public uint size() {
        return _data.length;
    }
}