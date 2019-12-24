-- For extended help + developer information please see the help menu ingame
-- or read it online at http://hexahedron.pw/wardrobe.html
-- If you need help with the addon itself please make a support ticket, don't add me on steam.

-- defaultLanguage: Change this if your players are too incompetent to click
-- the language button on the menu (don't worry, it saves per player)
wardrobe.config.defaultLanguage = "english"

-- extensions: Uncomment to enable the extension
-- extensions are loaded from lua/wardrobe/extensions/XXXXXX.lua
-- and are shared and automatically addcsluafile'd

-- Configuration of extensions is done WITHIN the extension!
-- eg: to change darkrp settings, check wardrobe/extensions/darkrp.lua
-- the extension will not load if you dont have support for whatever it extends
-- so dont worry about having multiple things enabled
wardrobe.config.extensions = {
	"darkrp",
	-- "basewars",
	-- "ulx",
	-- "serverguard",
	-- "pointshop",
	-- "pointshop2",
	-- "clockwork",
}

-- commandPrefix: Pattern to match the command prefix, [!|/] (the default) means ! or /
-- this can be any single character but patterns must be escaped (. -> %., + -> %+)
-- or a group of characters enclosed in [] and seperated by |
-- see https://www.lua.org/pil/20.2.html for more info
wardrobe.config.commandPrefix = "[!|/]"

-- command: The command that comes after the prefix to match
-- !"wardrobe", /"costume" et cetra
wardrobe.config.command = "wardrobe"

-- blacklistIds: Paths of files which should never be mounted
-- please don't add your personal dislikes here, as users can blacklist addons they don't
-- like themselves, this list is for BAD files (eg causes players to crash) or exploits / backdoors
-- WARNING: Inverse table, form: [mdl] = true,
wardrobe.config.blacklistFiles = {
	-- Uncomment these if you find people using stupid small models to trick people.
	--["models/player_chibiterasu.mdl"] = true,
	--["models/player/dewobedil/chucky/chucky.mdl"] = true,
}

-- blacklistIds: Workshop IDs of addons which should never be downloaded/mounted
-- please don't add your personal dislikes here, as users can blacklist addons they don't
-- like themselves, this list is for BAD addons (eg causes players to crash)
-- WARNING: Inverse table, form: [wsid] = true,
wardrobe.config.blacklistIds = {
	--[13377] = true,
	[834368988] = true, -- invisible playermodel
}

-- userSpecificModels: Any models or workshop ids which only specifc users should be allowed
-- to use. It may be better to use the hooks to automate this instead if you can code.
-- WARNING: Inverse table, form: [wsid/mdl] = {ids},
wardrobe.config.userSpecificModels = {
	--["models/jazzmcfly/kantai/kongou/kongou.mdl"] = {"STEAM_0:1:62445445"},
	--[649658152] = {"STEAM_0:1:62445445", "STEAM_0:1:337"},
}

-- whitelistIds: Addons which are on the 'whitelist', see whitelistMode for more information
-- WARNING: Inverse table, form: [wsid] = true,
wardrobe.config.whitelistIds = {
	--[649658152] = true,
}

-- whitelistMode: 0 Only skip saftey checks, 1 Non-admins can only use whitelist, 2 Everybody can only use whitelist
-- In case of mode 1 or 2 then the whitelisted addons are pre-loaded into the menu,
-- beware this WILL cause lag when opening the menu for the first time if on mode 1 or 2!
wardrobe.config.whitelistMode = 0

-- workshopDefaultUrl: The URL opened by default by the workshop browser
-- For the top rated playermodels (default behaviour) use
-- 	https://steamcommunity.com/workshop/browse/?appid=4000&searchtext=playermodel&browsesort=toprated&requiredtags[0]=model&actualsort=toprated
wardrobe.config.workshopDefaultUrl = "https://steamcommunity.com/workshop/browse/?appid=4000&searchtext=playermodel&browsesort=toprated&requiredtags[0]=model&actualsort=toprated"

-- shouldPrintSv: Should information be printed on the server
-- disable this if someone spams requests a lot or if you just dont want this info in the logs
wardrobe.config.shouldPrintSv = true

-- adminOnly: Should all functionality be restricted to admins?
-- this can be managed more finely with the shared Wardrobe_AccessAllowed hook
-- WARNING: If there is an admin mod specific extension this is redundant! You should
-- see how to use the extension for your admin mod (or you can disable the extension and use this)
wardrobe.config.adminOnly = false

-- rateLimitTime: The time between users being able to request a new costume
-- this is in place to stop abuse, if you trust your players set it to 0
wardrobe.config.rateLimitTime = 5

-- maxFileSize: Maximum size of an addon which is permitted. (In megabytes)
-- It is HIGHLY recommended you lower this to ~128-64 if you run anything other than sandbox or
-- where a large volume of players are expected
-- A value of 0 means no limit, this is a very bad idea and should only be used if you have
-- restricted usage to owners or similar
wardrobe.config.maxFileSize = 256

-- aggressive: Should addons which overwrite existing files of ANY kind be ignored? This is an added
-- security measure but should never really be needed.
wardrobe.config.aggressive = false
