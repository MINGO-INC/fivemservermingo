# Resources

Place your FiveM resources inside the appropriate category folders:

| Folder | Purpose |
|---|---|
| `[standalone]` | Resources that run independently (e.g., admin tools, utility scripts) |
| `[scripts]` | General gameplay scripts |
| `[gamemodes]` | Gamemode resources (roleplay frameworks, racing, etc.) |

Each resource must contain a `fxmanifest.lua` (or legacy `__resource.lua`) file.
After adding a resource, add `ensure <resource-name>` to `server.cfg`.

## Example resource structure

```
resources/
└── [standalone]/
    └── my-resource/
        ├── fxmanifest.lua
        ├── client.lua
        └── server.lua
```
