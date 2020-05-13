module Items.JSONItemWriter;

import std.json;
import std.stdio;
import std.conv;
import std.string;
import std.traits;
import std.math;
import std.file;

import List.ListWriterInterface;

import Items.Item;

import ElementTypes;
import StatusEffects;

import ArrayTools;

public class JSONItemWriter : ListWriterInterface!Item {

    private string _outputPath;

    public this(immutable string outputPath) {
        _outputPath = outputPath;
    }

    public void write(const Item[] items) {
        mkdirRecurse(_outputPath);
        foreach (const Item item; items) {
            JSONValue json = serialize(item);
            File file = File(format("%s/%s.json", _outputPath, item.key), "w");
            file.writeln(json.toJSON(true));
            file.close();    
        }
    }

    public JSONValue serialize(const Item item) {
        JSONValue value;

        value["name"] = item.name;

        if (item.price) {
            value["price"] = item.price;
        }
        if (item.description) {
            value["description"] = item.description;
        }

        if (item.equippable) {
            value["equippable"] = flagStringArray!ItemEquippableFlags(item.equippable);
        }
        if (item.flags) {
            value["flags"] = flagStringArray!ItemFlags(item.flags);
        }
        if (item.statMod) {
            value["statMod"] = item.statMod;
        }
        
        if (item.type == ItemType.WEAPON) {
            value["weapon"] = serializeWeapon(item);
        } else if (item.type == ItemType.ARMOR) {
            value["armor"] = serializeArmor(item);
        } else if (item.type == ItemType.ACCESSORY) {
            JSONValue accessory = serializeAccessory(item);
            if (!accessory.isNull()) {
                value["accessory"] = accessory;
            }
        } else if (item.type == ItemType.OTHER) {
            JSONValue other = serializeOther(item);
            if (!other.isNull()) {
                value["other"] = other;
            }
        }

        return value;
    }

    private JSONValue serializeWeapon(const Item item) {
        JSONValue value;

        value["attack"] = item.weapon.attack;
        value["critChance"] = item.weapon.critChance;
        value["palette"] = item.weapon.palette;
        value["sound1"] = item.weapon.sound1;
        value["sound2"] = item.weapon.sound2;

        if (item.weapon.mod) {
            value["mod"] = item.weapon.mod;
        }

        return value;
    }

    private JSONValue serializeArmor(const Item item) {
        JSONValue value;

        if (item.protection) {
            value["protection"] = enumStringKeys!ElementType(item.protection);
            value["protectionFactor"] = item.protectionFactor;
        }
        if (item.armor.mod) {
            value["mod"] = item.armor.mod;
        }

        value["defense"] = item.armor.defense;

        return value;
    }

    private JSONValue serializeAccessory(const Item item) {
        JSONValue value;

        if (item.accessory.flags) {
            value["flags"] = flagStringArray!ItemAccessoryFlags(item.accessory.flags);
        }
        if (!isNaN(item.accessory.counterChance)) {
            value["counterChance"] = item.accessory.counterChance;
        }
        if (item.accessory.statuses.length) {
            value["statuses"] = enumStringKeys!StatusEffect(item.accessory.statuses);
        }
        if (item.accessory.immunities.length) {
            value["immunities"] = enumStringKeys!StatusEffect(item.accessory.immunities);
        }

        return value;
    }

    private JSONValue serializeOther(const Item item) {
        JSONValue value;

        if (item.consumable.healTypeHealth != ItemHealType.NONE) {
            if (item.consumable.healTypeHealth == ItemHealType.ABSOLUTE) {
                value["healHealth"] = item.consumable.healHealth;
            } else {
                value["healTypeHealth"] = item.consumable.healTypeHealth;
            }
        }
        if (item.consumable.healTypeMagic != ItemHealType.NONE) {
            if (item.consumable.healTypeMagic == ItemHealType.ABSOLUTE) {
                value["healMagic"] = item.consumable.healMagic;
            } else {
                value["healTypeMagic"] = item.consumable.healTypeMagic;
            }
        }

        if (item.consumable.statuses.length) {
            value["statuses"] = enumStringKeys!StatusEffect(item.consumable.statuses);
        }
        if (item.consumable.removeStatuses.length) {
            value["removeStatuses"] = enumStringKeys!StatusEffect(item.consumable.removeStatuses);
        }

        if (item.consumable.flags) {
            value["flags"] = flagStringArray!ItemConsumableFlags(item.consumable.flags);
        }

        return value;
    }

}
