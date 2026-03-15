# fivemservermingo

A self-hosted **FiveM** game-server configuration repository.

---

## Requirements

| Requirement | Notes |
|---|---|
| FiveM server binary (FXServer) | Download from [artifacts.fivem.net](https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/) (Linux) or the [Windows build](https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/) |
| FiveM license key | Obtain for free at [keymaster.fivem.net](https://keymaster.fivem.net) |
| GTA V server data | Clone [`cfx-server-data`](https://github.com/citizenfx/cfx-server-data) alongside this repo for the default resources |

---

## Quick Setup

### 1. Clone this repository

```bash
git clone https://github.com/MINGO-INC/fivemservermingo.git
cd fivemservermingo
```

### 2. Download the FiveM server binary

**Linux:**
```bash
# 1. Fetch the latest version number
LATEST_VERSION=$(curl -s https://changelogs-live.fivem.net/api/changelog/versions/linux/server \
  | python3 -c "import sys, json; print(json.load(sys.stdin)['latest'])")

# 2. Download that version
wget -O fx.tar.xz \
  "https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${LATEST_VERSION}/server.tar.xz"

# 3. Extract the archive
tar xf fx.tar.xz
```

**Windows:**  
Download the latest `FXServer.exe` from the [Windows artifacts page](https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/) and place it in this directory.

### 3. Download the default server data

```bash
git clone https://github.com/citizenfx/cfx-server-data.git

# Merge the default resources into this repo's resources directory.
# This copies cfx-server-data's resources (chat, mapmanager, etc.) alongside
# the custom category folders ([standalone], [scripts], [gamemodes]) already
# present here — it does NOT overwrite those folders.
cp -rn cfx-server-data/resources/. ./resources/
```

### 4. Configure the server

Open `server.cfg` and:
- Uncomment and set `sv_licenseKey` with your key from [keymaster.fivem.net](https://keymaster.fivem.net).
- Change `sv_hostname` to your desired server name.
- Adjust `sv_maxclients` as needed.

### 5. Start the server

**Linux / macOS:**
```bash
./run.sh
```

**Windows:**
```bat
run.bat
```

The server will start on port **30120** (TCP + UDP) by default.

---

## Directory Structure

```
fivemservermingo/
├── server.cfg          # Main server configuration
├── run.sh              # Linux/macOS startup script
├── run.bat             # Windows startup script
└── resources/          # Custom server resources
    ├── [standalone]/   # Utility / admin resources
    ├── [scripts]/      # General gameplay scripts
    └── [gamemodes]/    # Gamemode resources
```

---

## Adding Resources

1. Place your resource folder inside the appropriate `resources/[category]/` subfolder.
2. Add `ensure <resource-name>` to `server.cfg`.
3. Restart the server (or use `restart <resource-name>` in the server console).

---

## Custom Resources

### car-spawner

Located at `resources/[gameplay]/car-spawner/`.

Lets players spawn a curated set of high-quality vehicles and delete them on demand.

| Command | Description |
|---------|-------------|
| `/car <model>` | Spawn a car by model name (e.g. `/car zentorno`) |
| `/dv` | Delete the vehicle you are currently sitting in |
| `/cars` | List all allowed car models in chat |

**Available models:** adder, entityxf, infernus, osiris, t20, zentorno, cheetah, turismor, fmj, reaper, sultan, jester, elegy2, comet2, feltzer2, carbonizzare, dominator, gauntlet, vigero, cognoscenti, supervolito, jackal, akuma, bati, shotaro.

---

### weapon-loadout

Located at `resources/[gameplay]/weapon-loadout/`.

Gives players a full weapon loadout and applies per-weapon **recoil** using camera shake proportional to each weapon's power.

| Command | Description |
|---------|-------------|
| `/weapons` | Receive the complete loadout (all weapons + ammo) |
| `/gun <name>` | Receive a single weapon by name or label (e.g. `/gun ak47`, `/gun sniper rifle`) |
| `/guns` | List all available weapons grouped by category |
| `/recoil` | Toggle recoil camera shake on / off |

**Recoil system:** A per-frame client thread monitors clip ammo. When a shot is detected, it triggers a `ShakeGameplayCam` call scaled to the weapon's recoil value — light for pistols, heavy for snipers and launchers.

---

## Useful Links

- [FiveM Server Documentation](https://docs.fivem.net/docs/server-manual/setting-up-a-server/)
- [Native Reference](https://docs.fivem.net/natives/)
- [cfx-server-data (default resources)](https://github.com/citizenfx/cfx-server-data)
- [FiveM Forums](https://forum.cfx.re/)