module Decompress;

import std.stdio;

private class InvalidCompression : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

// Main decompression routine
// Reverse engineered by Michael Springer (evilpeer@hotmail.com)
public uint decompressLZ(ubyte[] romData, ubyte[] outputData, uint nStartAddr) {
    bool carryFlag = false;
    const ushort compressedSize = cast(ushort) (romData[nStartAddr] | (romData[nStartAddr + 1] << 8));
    uint bytePos = nStartAddr + 2;
    uint byteAfter = bytePos + compressedSize;
    ubyte bitCounter;
    ubyte currentByte;
    uint workPos = 0;
    bool smallerBitWidth = false;

    if ((romData[byteAfter] & 0xC0) != 0) {
        smallerBitWidth = true;
    }

    bitCounter = 8;
    while (true) {
        if (bytePos == byteAfter) {
            currentByte = romData[bytePos];
            currentByte &= 0x3F;
            if (currentByte == 0) {
                return workPos;
            }
            bitCounter = currentByte;
            carryFlag = false;
            byteAfter = cast(uint) (nStartAddr + ((romData[bytePos + 2] << 8) | romData[bytePos + 1]));
            bytePos += 3;
        } else {
            currentByte = romData[bytePos];
            if (currentByte == 0) {
                currentByte = romData[bytePos + 1];
                outputData[workPos++] = currentByte;
                currentByte = romData[bytePos + 2];
                outputData[workPos++] = currentByte;
                currentByte = romData[bytePos + 3];
                outputData[workPos++] = currentByte;
                currentByte = romData[bytePos + 4];
                outputData[workPos++] = currentByte;
                currentByte = romData[bytePos + 5];
                outputData[workPos++] = currentByte;
                currentByte = romData[bytePos + 6];
                outputData[workPos++] = currentByte;
                currentByte = romData[bytePos + 7];
                outputData[workPos++] = currentByte;
                currentByte = romData[bytePos + 8];
                outputData[workPos++] = currentByte;
                carryFlag = false;
                bytePos += 9;
            } else {
                bytePos++;
                if ((currentByte & 0x01) == 1) {
                    carryFlag = true;
                } else {
                    carryFlag = false;
                }
                currentByte >>= 1;
                ubyte mem0D = currentByte;
                if (carryFlag) {
                    try {
                        copyBytes(romData, outputData, bytePos, workPos, smallerBitWidth);
                    } catch (InvalidCompression e) {
                        return 0;
                    }
                } else {
                    currentByte = romData[bytePos];
                    outputData[workPos++] = currentByte;
                    bytePos++;
                }
                while (true) {
                    bitCounter--;
                    if (bitCounter == 0) {
                        bitCounter = 8;
                        break;
                    } else {
                        if ((mem0D & 0x01) == 1) {
                            carryFlag = true;
                        } else {
                            carryFlag = false;
                        }
                        mem0D >>= 1;
                        if (carryFlag) {
                            try {
                                copyBytes(romData, outputData, bytePos, workPos, smallerBitWidth);
                            } catch (InvalidCompression e) {
                                return 0;
                            }
                        } else {
                            currentByte = romData[bytePos];
                            outputData[workPos++] = currentByte;
                            bytePos++;
                        }
                    }
                }
            }
        }
    }
}

private void copyBytes(ubyte[] romData, ubyte[] outputData, ref uint bytePos, ref uint workPos, immutable bool smallerBitWidth) {
    ubyte bytesCopyNum;
    ushort bytesCopyOff;

    bytesCopyNum = romData[bytePos + 1];
    if (smallerBitWidth) {
        bytesCopyNum >>= 3;
    } else {
        bytesCopyNum >>= 4;
    }
    bytesCopyNum += 2;

    bytesCopyOff = cast(ushort)((romData[bytePos + 1] << 8) | romData[bytePos]);
    if (smallerBitWidth) {
        bytesCopyOff &= 0x07FF;
    } else {
        bytesCopyOff &= 0x0FFF;
    }
    
    if (cast(int)workPos - cast(int)bytesCopyOff < 0) {
        throw new InvalidCompression("Copy bytes invalid.");
    }

    for (int i = 0; i < bytesCopyNum + 1; i++) {
        outputData[workPos + i] = outputData[workPos - bytesCopyOff + i];
    }
    workPos += cast(uint)(bytesCopyNum + 1);
    bytePos += 2;
}
