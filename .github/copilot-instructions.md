# Copilot Instructions for This Codebase

## Elite Roblox Systems Architect Rules

- **ENGLISH CONTENT ONLY:**
  - All GUI text, StringValues, Notification messages, and variable names MUST be in ENGLISH.
  - NEVER translate in-game content to Vietnamese.
  - Vietnamese is ONLY allowed for explaining the logic to the user (comments or chat explanation).

- **Modern Luau Standards:**
  - Use `task.wait`, `task.spawn`, `task.delay` exclusively for yielding/spawning.
  - Use Dependency Injection or Service/Controller patterns (ModuleScripts) instead of loose global scripts.

- **External Workflow Awareness:**
  - Assume the user is using **Argon** and **VS Code**.
  - Suggest file paths (e.g., `src/Server/Services/MyService.lua`) instead of Roblox Studio hierarchy paths.

- **Design Patterns:**
  - Favor OOP combined with scalable patterns from large studios (MVC, ECS, SSA).
  - Always implement cleanup logic (Janitor/Maid patterns) to prevent memory leaks.
  - Use `ProfileService` or safe DataStore wrappers for persistence.
  - For UI, use classic Roblox UI methods, organized in multiple files for clarity.
  - RemoteEvents/RemoteFunctions should be created and managed via code, not manually in Studio.

- **Replication, Security, Scalability:**
  - Minimize network bandwidth (replicate only what is needed).
  - Enforce server authority and sanity checks to prevent exploits.
  - Design for scalability (100+ players) and avoid per-player bottlenecks.

- **Interaction Mode:**
  - If a feature requires Studio-only actions (e.g., asset creation), provide step-by-step instructions.
  - If a request is vague, ask clarifying questions about intended architecture (Client vs. Server authority) before coding.
  - If bad practices are detected (e.g., `while wait() do`, accessing UI from Server), correct and explain why.

## Project & Game Design Overview
- **Type:** Roblox Tycoon/Inventory/Market game (Luau)
- **Gameplay Structure:**
  - Players manage a tycoon, collect and upgrade items, and interact with a market system.
  - Core systems: Inventory, Market, Tycoon progression, Notifications, HUD.
- **Code Structure:**
  - `src/Client/`: Client-side (UI, player input, HUD, notifications)
  - `src/Server/`: Server-side (data, tycoon logic, inventory, market)
  - `src/Shared/`: Shared configs/utilities (item/game constants, async/event helpers)

## Architectural Patterns
- **ModuleScript Pattern:**
  - Each major system is a ModuleScript returning a table of methods (e.g., `InventoryController`, `MarketService`).
  - Use `require` for dependencies; avoid circular dependencies.
- **Naming:**
  - Suffixes: `Controller` (client), `Service` (server), `Config`/`Utils` (shared).
- **Communication:**
  - Client ↔ Server via RemoteEvents/RemoteFunctions (see `EventService.lua`).
  - Shared configs/constants are required from `src/Shared/Configs`.
- **Async/Event Patterns:**
  - Use `Promise.luau` for async flows, `Signal.luau` for custom events (see `src/Shared/Utils`).

## Game System Responsibilities
- **Inventory:**
  - Server: `InventoryService.lua` manages player inventories, item logic, and syncs with client.
  - Client: `InventoryController.lua` handles UI, player actions, and receives updates from server.
  - Config: `ItemConfig.lua` defines item properties and types.
- **Market:**
  - Server: `MarketService.lua` manages item trading, pricing, and transactions.
  - Client: `MarketController.lua` handles market UI and player interactions.
- **Tycoon:**
  - Server: `TycoonService.lua` manages player tycoon state, upgrades, and progression.
  - Client: `TycoonController.lua` handles tycoon UI and feedback.
- **HUD/Notifications:**
  - `HUDController.lua` and `NotificationController.lua` manage player-facing UI and alerts.
- **Data:**
  - `DataService.lua` handles persistent player data (progress, inventory, etc.).

## Developer Workflows
- **Editing:**
  - Edit scripts in `src/`, then sync with Roblox Studio.
- **Debugging:**
  - Use Roblox Studio's output and breakpoints.
  - Test shared modules in isolation by requiring them in a test script.
- **No build/test scripts:**
  - All logic is designed for direct use in Studio.

## Integration Points
- **External Libraries:**
  - `Promise.luau`, `Signal.luau` in `src/Shared/Utils/_Index/` for async/events.
  - `Janitor` for resource management.
- **Data Flow:**
  - Server services own game state and logic; clients receive updates and send actions via events.
  - Configs are read-only and shared.

## Example: Adding a New Item Type
1. Add item definition to `ItemConfig.lua` (shared).
2. Update `InventoryService.lua` (server logic for new item).
3. Update `InventoryController.lua` (client UI/logic for new item).
4. If tradable, update `MarketService.lua` and `MarketController.lua`.
5. Use `EventService.lua` for new events if needed.

## References
- **Controllers:** `src/Client/Controllers/`
- **Services:** `src/Server/Services/`
- **Configs:** `src/Shared/Configs/`
- **Utils:** `src/Shared/Utils/`

---
**Edit this file to update project-specific AI guidance.**
