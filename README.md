# HCWarden

A custom addon for **World of Warcraft Classic Era**, built for Hardcore-mode play.

## Features

- **Death-risk warnings & nearby-danger tracking** (`Alerts.lua`, `DangerZone.lua`)
- **Self and target status windows** with cast bars (`HUD.lua`, `TargetHUD.lua`, `CastBar.lua`)
- **Totem and weapon-enchant tracking** — a TotemTimers-style totem bar and Windfury/weapon
  enchant tracker (`TotemBar.lua`, `WeaponBar.lua`)
- **Upgrade-pickup alerts** (`PawnUpgradeAlert.lua`) — announces (banner + sound) when a
  newly picked-up bag item is an upgrade, using [Pawn](https://www.curseforge.com/wow/addons/pawn)'s
  own item scoring. Requires Pawn.
- **Elemental Shaman leveling fix** (`PawnScaleSetup.lua`) — Pawn's stock Elemental scale
  weighs melee weapon DPS/AP at 0, which is correct at max level but means real weapon
  upgrades never show up while leveling (when low mana forces melee between casts). This
  automatically clones the scale with melee stats added in, once, on login.

## Installation

Copy this folder into `Interface/AddOns/HCWarden/` in your WoW Classic Era install, then
enable it in the in-game AddOns list.

## Dependencies

- [Pawn](https://www.curseforge.com/wow/addons/pawn) (optional, but required for the
  upgrade-alert and scale-fix features — everything else works without it)
