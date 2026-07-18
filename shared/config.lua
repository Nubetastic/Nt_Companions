
Config = {}

Config.Debug = false
Config.FadeIn = true
Config.EnableTarget = true
Config.DistanceSpawn = 40.0
Config.Img = "rsg-inventory/html/images/"

---------------------------------
-- openting hours
---------------------------------
Config.AlwaysOpen = true -- if false configure the open/close times
Config.OpenTime = 8 -- store opens
Config.CloseTime = 20 -- store closes

Config.CallPetKey = true --Set to true to use the CallPet hotkey below

Config.TriggerKeys = {
    CallPet = 'Z',
    FeedPet = 'E',
}

Config.DefensiveMode = true --If set to true, pets will become hostile to anything you are in combat with
Config.DisablePetFlee = false
Config.FeedInterval = 1800 -- 1800 = 30 min, How often in seconds the pet will want to be fed
Config.FeedMinMinutes = 60 -- Minimum minutes before the pet needs food after being called/fed
Config.FeedMaxMinutes = 120 -- Maximum minutes before the pet needs food after being called/fed
Config.FeedWarningMinutes = 15 -- Notify the player this many minutes before the pet runs away
Config.RaiseAnimal = true -- If this is enabled, you will have to feed your animal for it to gain XP and grow. Only full grown pets can use commands (halfway you get the Stay command)
Config.FullGrownXp = 1000 -- The amount of XP that it is fully grown. At the halfway point the pet will grow to 50% of max size.
Config.XpPerFeed = 20 -- The amount of XP every feed gives
Config.NotifyWhenHungry = true -- Puts up a little notification letting you know your pet can be fed. 
Config.AnimalFood = 'pet_food' -- The item required to feed and/or level up your pet
Config.AttackRange = 60
Config.PetFleetCooldown = 300 * 1000

Config.Blip = {
    blipName = Lang:t('label.petshop'), -- Config.Blip.blipName
    blipSprite = -1733535731, -- Config.Blip.blipSprite
    blipScale = 0.2, -- Config.Blip.blipScale
}

Config.PetBlip = {
    blipName = 'Pet',
    blipSprite = 1451797164,
    blipScale = 0.2,
}

Config.Shops = {
    {
        prompt = 'valentine-petshop',
		Name = Lang:t('label.petshop'),
        ActiveDistance = 1.5,
        Coords = vector3(-285.5119, 658.00457, 113.30006),
        Spawndog = vector4(-286.3233, 659.20825, 113.41064, 130.15997),
        npcmodel = `mbh_rhodesrancher_females_01`,
        npccoords = vector4(-285.5119, 658.00457, 113.30006, 100.1551),
        npcpetmodel = `A_C_DogHound_01`,
        npcpetcoords = vector4(-284.7644, 657.09729, 113.21657, 104.9031),
		scenario = 'MP_LOBBY_STANDING_D',
        showblip = true,
        Camera = vector4(-285.4416, 655.1256, 112.6158, 344.4715),
    },
    {
        prompt = 'blackwater-petshop',
		Name = Lang:t('label.petshop'),
        ActiveDistance = 1.5,
        Coords = vector3(-945.7324, -1226.065, 52.751701),
        Spawndog = vector4(-947.0184, -1225.372, 52.836936, 192.60287),
        npcmodel = `u_m_m_bwmstablehand_01`,
        npccoords = vector4(-945.7324, -1226.065, 52.751701, 185.14344),
        npcpetmodel = `A_C_DogAustralianSheperd_01`,
        npcpetcoords = vector4(-944.7804, -1226.214, 52.694541, 146.14712),
		scenario = 'MP_LOBBY_STANDING_C',
        showblip = true,
        Camera = vector4(-943.9482, -1228.3572, 52.1087, 25.6149),
    }
}

Config.PetShop = {
    -- pet shop items
    [1] = { name = 'pet_food', price = .5, amount = 500, info = {}, type = 'item', slot = 1, },
}

Config.PetAttributes = {
    FollowDistance = 5,
    FollowSpeed = 3,
    Invincible = false,
    SpawnLimiter = 100, -- Set this to limit how often a pet can be spawned or 0 to disable it
    DeathCooldown = 300, -- Time before a pet can be respawned after dying
}




-- Pets availability will only be limited if the object exists in the pet config.
Config.Pets = {
    {
        Text = "$200 - Husky",
        SubText = "",
        Desc = "Best pet you'll ever have",
		img = 'animal_dog_husky.png',
        Param = {
            Price = 200,
            Model = "A_C_DogHusky_01",
            Level = 1
        },
        outfitMax = 3,
    },
    {
        Text = "$50 - Mutt",
        SubText = "",
        Desc = "Best pet you'll ever have",
		img = 'animal_dog_catahoularcur.png',
        Param = {
            Price = 50,
            Model = "A_C_DogCatahoulaCur_01",
            Level = 1
        },
        outfitMax = 6,
    },
    {
        Text = "$100 - Labrador Retriever",
        SubText = "",
        Desc = "Best pet you'll ever have",
		img = 'animal_dog_lab.png',
        Param = {
            Price = 100,
            Model = "A_C_DogLab_01",
            Level = 1
        },
        outfitMax = 3,
    },
    {
        Text = "$100 - Rufus",
        SubText = "",
        Desc = "Best pet you'll ever have",
		img = 'animal_dog_chesbayretriever.png',
        Param = {
            Price = 100,
            Model = "A_C_DogRufus_01",
            Level = 1
        },
        outfitMax = 1,
    },
    {
        Text = "$150 - Coon Hound",
        SubText = "",
        Desc = "Best pet you'll ever have",
		img = 'animal_dog_bluetickcoonhound.png',
        Param = {
            Price = 150,
            Model = "A_C_DogBluetickCoonhound_01",
            Level = 1
        },
        outfitMax = 5,
    },
        {
        Text = "$150 - Hound Dog",
        SubText = "",
        Desc = "Best pet you'll ever have",
		img = 'animal_dog_hound.png',
        Param = {
            Price = 150,
            Model = "A_C_DogHound_01",
            Level = 1
        },
        outfitMax = 8,
    }, 
    {
        Text = "$200 - Border Collie",
        SubText = "",
        Desc = "Best pet you'll ever have",
		img = 'animal_dog_collie.png',
        Param = {
            Price = 200,
            Model = "A_C_DogCollie_01",
            Level = 1
        },
        outfitMax = 3,
    },
    {
        Text = "$200 - Poodle",
        SubText = "",
        Desc = "Best pet you'll ever have",
		img = 'animal_dog_poodle.png',
        Param = {
            Price = 200,
            Model = "A_C_DogPoodle_01",
            Level = 1
        },
        outfitMax = 3,
    },
    {
        Text = "$100 - Foxhound",
        SubText = "",
        Desc = "Best pet you'll ever have",
		img = 'animal_dog_americanfoxhound.png',
        Param = {
            Price = 100,
            Model = "A_C_DogAmericanFoxhound_01",
            Level = 1
        },
        outfitMax = 3,
    },
    {
        Text = "$100 - Australian Shephard",
        SubText = "",
        Desc = "Best pet you'll ever have",
		img = 'animal_dog_australianshepherd.png',
        Param = {
            Price = 100,
            Model = "A_C_DogAustralianSheperd_01",
            Level = 1
        },
        outfitMax = 3,
    },
}

Config.Keys = { ['G'] = 0x760A9C6F, ["B"] = 0x4CC0E2FE, ['S'] = 0xD27782E3, ['W'] = 0x8FD015D8, ['H'] = 0x24978A28, ['U'] = 0xD8F73058, ['Z'] = 0x26E9DC00, ["R"] = 0x0D55A0F0, ["ENTER"] = 0xC7B5340A, ['E'] = 0xDFF812F9, ["J"] = 0xF3830D8E, ["7"] = 0xB03A913B, ['8'] = 0x42385422 }
