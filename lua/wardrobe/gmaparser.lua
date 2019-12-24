local print = wardrobe and wardrobe.dbg or print

gmaparser = gmaparser or {}
gmaparser.cache = gmaparser.cache or {}

gmaparser.parser = {}
local parserObj = gmaparser.parser

gmaparser.entry = {}
--local entryObj = gmaparser.entry

GMA_NOTGMA        = 1
GMA_NEWFORMAT     = 2
GMA_NOFILE        = 3
GMA_SEEKFAIL      = 4
GMA_NODATA        = 5
GMA_EOF           = 6
GMA_CRCFAIL       = 7

gmaparser.reverseEnum = {
	"GMA_NOTGMA",
	"GMA_NEWFORMAT",
	"GMA_NOFILE",
	"GMA_SEEKFAIL",
	"GMA_NODATA",
	"GMA_EOF",
	"GMA_CRCFAIL",
}

NULL_INT = "\0\0\0\0"

local function stringByteToNumber(s)
	return
		string.byte(s, 1) +
		bit.lshift(string.byte(s, 2), 8 ) +
		bit.lshift(string.byte(s, 3), 16) +
		bit.lshift(string.byte(s, 4), 24)
end

local function readString(f)
	local str = ""
	while f:Tell() < f:Size() do
		local b = f:ReadByte()
		if b == 0 then break end

		str = str .. string.char(b)
	end

	return str
end

local meta = {
	__index = gmaparser.parser,
	__tostring = function(s)
		return string.format("gmaparser: %s", s.address)
	end
}

local entryMeta = {
	__index = gmaparser.entry,
	__tostring = function(s)
		return string.format("gmaentry: %s [CRC %s]", s.address, s.hash)
	end
}

function parserObj:terminate()
	self.file:Close()
	self.file = nil
	gmaparser.cache[self.path] = nil
end

function parserObj:isValid()
	return self.file and self.parsed
end

local max_file = bit.lshift(1, 28)
function parserObj:parse(force)
	if self.parsed and not force then return end

	local f = self.file
	f:Seek(5) -- identity + version

	self.steamid     = f:Read(8)
	self.timestamp   = f:Read(8)

	self.contents    = {}

	if self.version > 1 then
		local s = readString(f)

		while s and s ~= "" do
			s = readString(f)
			self.contents[#self.contents + 1] = s
		end
	end

	self.name        = readString(f)
	self.descStr     = readString(f)
	self.descTbl     = util.JSONToTable(self.descStr) or {}
	self.author      = readString(f)
	self.addonver    = f:Read(4)

	self.files = {}
	self.fileNames = {}
	self.currentOffset = 0

	for i = 1, 65536 do
		local readtype = f:Read(4) -- uint
		if not readtype then break end

		if readtype == NULL_INT then
			self.fileblock = f:Tell()

			break
		end

		local entry = {
			parser   = self,
			readtype = stringByteToNumber(readtype)
		}

		entry.name     = readString(f) or ""
		entry.namesafe = entry.name:lower():gsub("\\", "/"):gsub("//", "/"):gsub("/%./", "/"):gsub("%.%./", "/")
		entry.size     = stringByteToNumber(f:Read(4))
		assert(
			entry.size < max_file and
			f:Read(4) == NULL_INT,
			"GMA Contains files too larger to process (" .. entry.name .. ")"
		)

		entry.hash     = stringByteToNumber(f:Read(4))

		entry.offset   = self.currentOffset
		entry.index    = #self.files + 1
		entry.address  = tostring(entry):gsub("table: ", "")

		setmetatable(entry, entryMeta)

		self.currentOffset = self.currentOffset + entry.size
		self.files[entry.index] = entry
		self.fileNames[entry.index] = entry.name -- useful for when you only care about location, not data
	end

	self.parsed = true
end

function parserObj:seekEntry(entry)
	local off = self.fileblock + entry.offset
	if off >= self.fileSize then return false end

	self.file:Seek(off)
	return self.file:Tell() == off
end

function parserObj:readEntry(entry)
	local ok = self:seekEntry(entry)
	if not ok then return nil, GMA_SEEKFAIL end

	local size = entry.size
	local data = self.file:Read(size)

	if not data then return nil, GMA_NODATA end
	if #data ~= size then return nil, GMA_EOF end

	return data
end

function parserObj:getDescription()
	return self.descTbl and self.descTbl.description or "No description"
end

function parserObj:getType()
	return self.descTbl and self.descTbl.type or "No type"
end

function parserObj:getTags()
	return self.descTbl and self.descTbl.tags or {"none"}
end

function parserObj:filesMatching(pattern)
	local r = {}
	for i = 1, #self.fileNames do
		if self.fileNames[i]:match(pattern) then r[#r + 1] = self.files[i] end
	end

	return r
end

function parserObj:alreadyMounted(checkAll)
	if checkAll then
		for i = 1, #self.fileNames do
			if not file.Exists(self.fileNames[i], "GAME") then return false end
		end
	elseif not file.Exists(self.fileNames[1], "GAME") then
		return false
	end

	return true
end

function gmaparser.open(path)
	if gmaparser.cache[path] and gmaparser.cache[path]:isValid() then
		return gmaparser.cache[path]
	end

	local f = file.Open(path, "rb", "GAME")
	if not f then return nil, GMA_NOFILE end

	local identity = f:Read(4)
	if identity ~= "GMAD" then
		print("GMA: Magic number did not match, '" .. (identity or "***BROKEN***"):gsub("\0", "NUL") .. "' ~= 'GMAD'")
		print("THIS ERROR LITERALY CAN NOT BE FIXED, GO COMPLAIN TO WILLOX")
		print("(GMA is corrupt, you will need to clear your cache and restart)")

		return nil, GMA_NOTGMA
	end

	local version = string.byte(f:Read(1)) or 0
	if version > 3 then
		print("GMA: Version was higher than expected, " .. version .. " > 3")

		return nil, GMA_NEWFORMAT
	end

	local obj = {
		file = f,
		fileSize = f:Size(),
		version = version,
		path = path,
	}
	obj.address = tostring(obj):gsub("table: ", "")

	gmaparser.cache[path] = setmetatable(obj, meta)
	return gmaparser.cache[path]
end

print("loaded gma parser")
