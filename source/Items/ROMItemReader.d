/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module Items.ROMItemReader;

import std.json;
import std.stdio;
import std.string;

import List.ListReaderInterface;

import Items.Item;

import Mods.ModList;

import StringTables.StringTableList;

import StatMods.StatModList;

import Palettes.PaletteList;

import StatusEffects;
import ElementTypes;
import StringTools;
import BinaryFile;

public class ROMItemReader : ListReaderInterface!Item {

    private JSONValue _config;
    private BinaryFile _rom;
    private StringTableList _strings;
    private ModList _mods;
    private StatModList _statMods;
    private PaletteList _palettes;

    public this(JSONValue config, BinaryFile rom, StringTableList strings, ModList mods, StatModList statMods, PaletteList palettes) {
        _config = config;
        _rom = rom;
        _strings = strings;
        _mods = mods;
        _statMods = statMods;
        _palettes = palettes;
    }

    public Item[] read() {
        Item[] items;
        items ~= readWeapons(_rom);
        items ~= readArmor(_rom);
        items ~= readAccessories(_rom);
        items ~= readOther(_rom);

        // Assign names, descriptions and keys.
        foreach (int index, ref Item item; items) {
            item.name = _strings.get("item_names", index);
            if (!item.name.length) {
                item.name = "empty";
            }
            item.description = _strings.get("item_descriptions", index);
            item.key = format("%03d_%s", index, generateKeyFromName(item.name));
        }
        
        return items;
    }

    private Item[] readWeapons(BinaryFile data) {
        immutable uint count = cast(uint)_config["items"]["weapons"]["count"].integer;
        immutable uint address = cast(uint)_config["items"]["weapons"]["address"].integer;
        immutable uint addressSecondary = cast(uint)_config["items"]["weapons"]["addressSecondary"].integer;
        immutable uint addressPalettes = cast(uint)_config["items"]["weapons"]["addressPalettes"].integer;
        immutable uint addressSound1 = cast(uint)_config["items"]["weapons"]["addressSound1"].integer;
        immutable uint addressSound2 = cast(uint)_config["items"]["weapons"]["addressSound2"].integer;

        Item[] items = new Item[count];

        _rom.setPosition(address);
        foreach (ref Item item; items) {
            item = readAsWeapon(data);
        }

        _rom.setPosition(addressSecondary);
        foreach (ref Item item; items) {
            item = readWeaponOrArmorSecondaryData(item, data);
        }

        _rom.setPosition(addressPalettes);
        foreach (ref Item item; items) {
            item.weapon.palette = _palettes.getKeyByGroupIndex("weapon", data.read!ubyte());
        }

        _rom.setPosition(addressSound1);
        foreach (ref Item item; items) {
            item.weapon.sound1 = data.read!ubyte();
        }

        _rom.setPosition(addressSound2);
        foreach (ref Item item; items) {
            item.weapon.sound2 = data.read!ubyte();
        }

        return items;
    }

    private Item readAsWeapon(BinaryFile data) {
        Item item = Item(ItemType.WEAPON);

        auto values = data.readBytes(5);
        item.weapon.attack = values[0];
        item.weapon.critChance = cast(double)values[2];
        if (values[4]) {
            item.weapon.mod = _mods.getKeyByIndex(values[3]);
        }

        return item;
    }

    private Item readWeaponOrArmorSecondaryData(Item item, BinaryFile data) {
        item.flags = cast(ItemFlags)data.read!ubyte();
        item.price = data.read!ushort();
        item.equippable = cast(ItemEquippableFlags)data.read!ubyte();

        immutable ubyte statMod = data.read!ubyte();
        if (statMod) {
            item.statMod = _statMods.getKeyByIndex(statMod);
        }
        
        immutable ubyte protectValue = data.read!ubyte();
        immutable ubyte elements = (protectValue & 0xF0) >> 4;
        if (elements & 0x01) {
            item.protection ~= ElementType.FIRE;
        }
        if (elements & 0x02) {
            item.protection ~= ElementType.WATER;
        }
        if (elements & 0x04) {
            item.protection ~= ElementType.SHADOW;
        }
        if (elements & 0x08) {
            item.protection ~= ElementType.LIGHTNING;
        }
        item.protectionFactor = cast(double)(protectValue & 0x0F) / 10.0;

        return item;
    }

    private Item[] readArmor(BinaryFile data) {
        immutable uint count = cast(uint)_config["items"]["armor"]["count"].integer;
        immutable uint address = cast(uint)_config["items"]["armor"]["address"].integer;
        immutable uint addressSecondary = cast(uint)_config["items"]["armor"]["addressSecondary"].integer;

        Item[] items = new Item[count];

        _rom.setPosition(address);
        foreach (ref Item item; items) {
            item = readAsArmor(data);
        }

        _rom.setPosition(addressSecondary);
        foreach (ref Item item; items) {
            item = readWeaponOrArmorSecondaryData(item, data);
        }

        return items;
    }

    private Item readAsArmor(BinaryFile data) {
        Item item = Item(ItemType.ARMOR);

        auto values = data.readBytes(3);
        item.armor.defense = values[0];
        if (values[2]) {
            item.armor.mod = _mods.getKeyByIndex(values[1]);
        }

        return item;
    }

    private Item[] readAccessories(BinaryFile data) {
        immutable uint count = cast(uint)_config["items"]["accessory"]["count"].integer;
        immutable uint address = cast(uint)_config["items"]["accessory"]["address"].integer;
        immutable uint addressSecondary = cast(uint)_config["items"]["accessory"]["addressSecondary"].integer;

        Item[] items = new Item[count];

        _rom.setPosition(address);
        foreach (ref Item item; items) {
            item = readAsAccessory(_rom);
        }

        _rom.setPosition(addressSecondary);
        foreach (ref Item item; items) {
            item = readAccessorySecondaryData(item, data);
        }

        return items;
    }

    private Item readAsAccessory(BinaryFile data) {
        Item item = Item(ItemType.ACCESSORY);

        item.accessory.flags = cast(ItemAccessoryFlags)data.read!ushort();

        auto values = data.readBytes(2);
        if (item.accessory.flags & ItemAccessoryFlags.AFFECT_COUNTER) {
            item.accessory.counterChance = cast(double)values[1] / 100.0;
        } else if (item.accessory.flags & ItemAccessoryFlags.AFFECT_STATS && values[0]) {
            item.statMod = _statMods.getKeyByIndex(values[0]);
        } else if (item.accessory.flags & ItemAccessoryFlags.AFFECT_STATUS) {
            item.accessory.statuses = parseStatuses(values[0], values[1]);
            item.accessory.immunities = parseImmunities(values[0], values[1]);
        }

        return item;
    }
    
    private Item readAccessorySecondaryData(Item item, BinaryFile data) {
        item.flags = cast(ItemFlags)data.read!ubyte();
        item.price = data.read!ushort();
        item.equippable = cast(ItemEquippableFlags)data.read!ubyte();

        return item;
    }

    private Item[] readOther(BinaryFile data) {
        immutable uint count = cast(uint)_config["items"]["other"]["count"].integer;
        immutable uint address = cast(uint)_config["items"]["other"]["address"].integer;
        immutable uint addressSecondary = cast(uint)_config["items"]["other"]["addressSecondary"].integer;

        Item[] items = new Item[count];

        _rom.setPosition(address);
        foreach (ref Item item; items) {
            item = readAsOther(data);
        }

        _rom.setPosition(addressSecondary);
        foreach (ref Item item; items) {
            item = readOtherSecondaryData(item, data);
        }

        return items;
    }

    private Item readAsOther(BinaryFile data) {
        Item item = Item(ItemType.OTHER);

        item.consumable.healTypeMagic = ItemHealType.NONE;
        item.consumable.healTypeHealth = ItemHealType.NONE;

        // Heal, also used by revive.
        auto values = data.readBytes(4);
        if (values[0] == 0x80 || values[0] == 0x04) {
            if (values[1] & 0x08) {
                // This can also be set from tech data, for example Lapis which cannot be used from the menu but affects all party members.
                item.consumable.flags |= ItemConsumableFlags.TARGET_ALL;
            }

            bool healMagic = cast(bool)(values[1] & 0x40);
            bool healHealth = cast(bool)(values[1] & 0x80);
            immutable int multiplier = values[3] & 0x3F;
            if (multiplier == 0xF) {
                if (healMagic) {
                    item.consumable.healTypeMagic = ItemHealType.FULL;
                }
                if (healHealth) {
                    item.consumable.healTypeHealth = ItemHealType.FULL;
                }
            } else {
                immutable int heal = values[2] * (multiplier ? multiplier : 1);
                if (healMagic) {
                    item.consumable.healTypeMagic = ItemHealType.ABSOLUTE;
                    item.consumable.healMagic = heal;
                }
                if (healHealth) {
                    item.consumable.healTypeHealth = ItemHealType.ABSOLUTE;
                    item.consumable.healHealth = heal;
                }
            }
        }

        // Revive.
        if (values[0] == 0x04) {
            item.consumable.flags |= ItemConsumableFlags.REMOVE_ALL_STATUSES;
            if (values[3] & 0x80) {
                item.consumable.flags |= ItemConsumableFlags.REVIVES;
            }
        }

        // Apply status.
        if (values[0] == 0x40) {
            item.consumable.statuses = parseConsumableStatuses(values[1], values[2]);
        }

        // Full party heal.
        if (values[0] == 0x08) {
            item.consumable.flags |= ItemConsumableFlags.TARGET_ALL;
            item.consumable.flags |= ItemConsumableFlags.REQUIRE_SAVE_POINT;
            item.consumable.healTypeHealth = ItemHealType.FULL;
            item.consumable.healTypeMagic = ItemHealType.FULL;
        }

        // Random heal, for the Power Meal.
        if (values[0] == 0x10) {
            item.consumable.healTypeHealth = ItemHealType.RANDOM_FULL;
            item.consumable.healTypeMagic = ItemHealType.RANDOM_FULL;
            item.consumable.removeStatuses ~= StatusEffect.LOCK;
        }

        return item;
    }

    private Item readOtherSecondaryData(Item item, BinaryFile data) {
        item.flags = cast(ItemFlags)data.read!ubyte();
        item.price = data.read!ushort();

        return item;
    }

    private static StatusEffect[] parseConsumableStatuses(immutable ubyte type, immutable ubyte flags) {
        
        // Redirect these to the status parser with the types remapped.
        if (type == 0) {
            return parseStatuses(0, flags);
        } else if (type == 1) {
            return parseStatuses(1, flags);
        } else if (type == 3) {
            return parseStatuses(8, flags);
        } else if (type == 4) {
            return parseStatuses(9, flags);
        } else if (type == 5) {
            return parseStatuses(5, flags);
        }

        throw new Exception(format("Unknown consumable status type %d.", type));
    }

    private static StatusEffect[] parseStatuses(immutable ubyte type, immutable ubyte flags) {
        StatusEffect[] statuses;

        if (type == 0 && (flags & 0x80)) {
            statuses ~= StatusEffect.DEAD;
        } else if (type == 1) {
            if (flags & 0x01) {
                statuses ~= StatusEffect.BLIND;
            }
            if (flags & 0x02) {
                statuses ~= StatusEffect.SLEEP;
            }
            if (flags & 0x04) {
                statuses ~= StatusEffect.CONFUSE;
            }
            if (flags & 0x08) {
                statuses ~= StatusEffect.LOCK;
            }
            if (flags & 0x10) {
                statuses ~= StatusEffect.HP_DRAIN;
            }
            if (flags & 0x20) {
                statuses ~= StatusEffect.SLOW;
            }
            if (flags & 0x40) {
                statuses ~= StatusEffect.POISON;
            }
            if (flags & 0x80) {
                statuses ~= StatusEffect.STOP;
            }
        } else if (type == 5 && (flags & 0x80)) {
            statuses ~= StatusEffect.AUTO_REVIVE;
        } else if (type == 8) {
            if (flags & 0x01) {
                statuses ~= StatusEffect.EVADE_2;
            }
            if (flags & 0x40) {
                statuses ~= StatusEffect.EVADE_25;
            }
            if (flags & 0x80) {
                statuses ~= StatusEffect.HASTE;
            }
        } else if (type == 9) {
            if (flags & 0x02) {
                statuses ~= StatusEffect.ATTACK_UP;
            }
            if (flags & 0x04) {
                statuses ~= StatusEffect.SHIELD;
            }
            if (flags & 0x08) {
                statuses ~= StatusEffect.MAX_ATTACK_UP;
            }
            if (flags & 0x20) {
                statuses ~= StatusEffect.MP_REGEN;
            }
            if (flags & 0x40) {
                statuses ~= StatusEffect.BARRIER;
            }
            if (flags & 0x80) {
                statuses ~= StatusEffect.BERSERK;
            }
        }

        return statuses;
    }

    private static StatusEffect[] parseImmunities(immutable ubyte type, immutable ubyte flags) {
        StatusEffect[] immunities;

        if (type == 6) {
            if (flags & 0x01) {
                immunities ~= StatusEffect.BLIND;
            }
            if (flags & 0x02) {
                immunities ~= StatusEffect.SLEEP;
            }
            if (flags & 0x04) {
                immunities ~= StatusEffect.CONFUSE;
            }
            if (flags & 0x08) {
                immunities ~= StatusEffect.LOCK;
            }
            if (flags & 0x10) {
                immunities ~= StatusEffect.HP_DRAIN;
            }
            if (flags & 0x20) {
                immunities ~= StatusEffect.SLOW;
            }
            if (flags & 0x40) {
                immunities ~= StatusEffect.POISON;
            }
            if (flags & 0x80) {
                immunities ~= StatusEffect.STOP;
            }
        }

        return immunities;
    }

}
