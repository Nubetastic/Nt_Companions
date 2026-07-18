# Nt Companions

A companion and pet shop resource for RedM servers using RSG Core.
Players can purchase and manage multiple dogs, name an active pet.
Will fetch small animals on its own only if the player owner kills them.
Dog cannot die, it will run off when gets too hurt and needs time before it can return.
Food is need to keep the pet out. It will get hungry over time, and will run off if not feed but can be called back after a while.

## Dependencies

- `rsg-core`
- `ox_lib`
- `oxmysql`

## Installation

1. Import `installation/tbrp_companions.sql` into your database.
2. Add the `pet_food` item to your RSG Core shared items.
3. Copy the images from `installation/images` to `rsg-inventory/html/images`.
4. Add `ensure Nt_Companions` to `server.cfg` after its dependencies.
5. Adjust shops, pets, prices, controls, feeding, and behavior in `config.lua`. Retrieval settings and supported animals are in `configFetch.lua`.

By default, pet shelters are located in Valentine and Blackwater. Press **Z** to call the active pet and **E** to feed it when aiming without a weapon at the pet.

## Radial buttons

```lua
            {
                id = 'petawaypet',
                title = 'Putaway pet',
                icon = 'dog',
                type = 'client',
                event = 'tbrp_companions:putaway',
                shouldClose = true
            },
            {
                id = 'loadpet',
                title = 'Call pet',
                icon = 'dog',
                type = 'server',
                event = 'tbrp_companions:loaddog',
                shouldClose = true
            },
```