return {
    {
        name = "Knight",
        health = 140,
        speed = 80,
        attack = 4, -- TODO: Not sure what this number should actually be
        crit = 0.01,
        intelligence = 1,  -- TODO: Not sure what this number should actually be
        weapons = {
            "sword",
            "axe",
            "mace",
        },
        equipment = {
            "shield",
            "heavy_armour",
        },
    },
    {
        name = "Ranger",
        health = 100,
        speed = 120,
        attack = 2, -- TODO: Not sure what this number should actually be
        crit = 0.1,
        intelligence = 2,  -- TODO: Not sure what this number should actually be
        weapons = {
            "bow",
            "dagger",
        },
        equipment = {
            "medium_armour",
        },
    },
    {
        name = "Wizard",
        health = 60,
        speed = 100,
        attack = 1, -- TODO: Not sure what this number should actually be
        crit = 0.1,
        intelligence = 4,  -- TODO: Not sure what this number should actually be
        weapons = {
            "spell",
        },
        equipment = {
            "light_armour",
        },
    },
}