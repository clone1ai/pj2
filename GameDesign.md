GAME DESIGN DOCUMENT: BRAINROT MARKET TYCOON
Version: Final (Solo Dev Edition)Tech Stack: Roblox Lua (Argon / VS Code)

1. MINTING & VALUATION SYSTEM (THE BOX)
Description: Players spend currency to generate assets. Upon creation, the system immediately calculates an Intrinsic Value (Floor Price) for the Brainrot based on its RNG stats.

Input: Rizz Coins (Soft Currency).
RNG Mechanics (3 Layers):
Model: Skibidi, Nugget, Grimace, etc. (Rarity Multipliers: Common x1, Rare x2, Legendary x10).
Element: Plastic (x1), Gold (x3), Void (x5), Glitch (x10).
Size: Randomized float from 0.5 to 3.0.
Floor Price Calculation Formula:
Executed once immediately upon opening the box.
Floor Price = (Base Box Cost) * (Model Mult) * (Element Mult) * (Size Mult)
Example: Box Cost 100$ * Gold (x3) * Size 2.0 (x2) = **$600 Floor Price**.
Storage: This FloorPrice is saved permanently into the Item's data (IntrinsicValue) and never changes.
2. SHOWROOM / SHELF SYSTEM (PASSIVE INCOME)
Description: The primary source of Rizz Coins. Brainrots generate income based on their calculated Floor Price.

Infrastructure: Each player gets a personal Plot with 6 Shelves/Slots.
Mechanism:
Player places a Brainrot from Inventory onto a Shelf.
Server Script (Looping every 1s) calculates total income.
Income Formula:
Income/sec = (Item Floor Price) * 0.1
Example: An item with a $600 Floor Price generates $60/sec.
Implication: Higher valuation items = Higher passive income.
3. INVENTORY (MANAGEMENT & VALUATION)
Description: Asset management UI, emphasizing price transparency.

UI Display:
Brainrot Icon.
Tags: Size, Element.
Crucial: Display the text "Floor Value: $XXX" directly on the item slot so the player knows its inherent worth.
Sorting Features:
Sort by Income (Best earners).
Sort by Floor Price (Most valuable).
4. QUICK SELL (LIQUIDITY)
Description: Sell items instantly to the System (NPC) based on Floor Price, bypassing the player market.

Mechanism:
Player selects Item -> Clicks "Quick Sell".
Cash Received = 50% of Floor Price.
Example: Gold Skibidi (Floor: $600) -> Quick Sell for $300.
Purpose: Ensures items are never worthless. Even if no one buys them on the market, players can liquidate them to recover capital.
5. TRADING & MARKETPLACE (P2P ECONOMY)
Description: Free market trading between players, using Floor Price as a reference.

Listing Mechanism:
Player selects Item -> Inputs Asking Price.
UI Helper: When inputting price, system auto input floor price in the input first
Buying Mechanism:
Buyer browses the list.
UI displays: Seller's Price vs. Floor Price.
Example: Buyer sees an item listed for $700 (Floor Price is $600) -> Buyer knows this is a fair deal.
Server Injection: The Server occasionally generates a high-tier item and lists it at a high price to function as a "Money Sink" (removing inflation).
6. MARKET FLUCTUATIONS (THE SYNERGY HOUR)
Description: Temporary income buffs to stimulate trading and shelf reorganization.

Mechanism: Every 20 minutes, a random event triggers (Duration: 5-10 minutes).
Buff Rules (Random 1 of 2):
Single Buff: "All [GOLD] Element items generate x5 Income!"
Combo Buff: "If a Shelf contains both [MODEL NUGGET] and [ELEMENT VOID], both generate x20 Income!"
Impact:
When an event starts, the Passive Income formula (Section 2) applies the multiplier.
The Item's Floor Price remains unchanged, but its Utility Value spikes, causing players to rush to the market to buy specific types.

-after read that project requirements first research how big studio design their design pattern then combine with OOP and use that for this project (dont use knit) 
-first understand the project then create a template for development and make sure the project codes and files must be : clean, scaleable, security, fast,simple and light 
-In project structure folders: src mean the intire project tree, Client mean starter player script, Shared mean ReplicatedStorage, Server mean ServerScriptService