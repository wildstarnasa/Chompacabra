-----------------------------------------------------------------------------------------------
-- Client Lua Script for Chompacabra
-- Copyright (c) 2014 NCsoft. All rights reserved
-- Written by Jon "Bitwise" Wiesman for Carbine Studios
-- Art by Max Gonzalez
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- Chompacabra Module Definition
-----------------------------------------------------------------------------------------------
local Chompacabra = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999

local EGrid = {
	Wall = 1,
	Space = 2,
	Door = 3,
}

local EChuaMode = {
	Home = 1,
	Scatter = 2,
	Chase = 3,
	Frightened = 4,
	Chomped = 5,
}

local EChuaTypes = {
	Shadow = 1,
	Speedy = 2,
	Bashful = 3,
	Clyde = 4,
}

local kSquareSize = 20
local kHalfSquare = kSquareSize / 2
local kObjectSize = 32
local kHalfObject = kObjectSize / 2
local kWorldSize = {x = 28, y = 31}
local kChompaSpeed = 7
local kChompaPowerSpeed = 9
local kChuaSpeed = 6

local kOppoDirection = {
	3, 4, 1, 2
}

local kChuasChompedScore = {
	100, 200, 400, 800
}
 
local kChuaScatterTargets = {
	{x = 0, y = 0},
	{x = kWorldSize.x + 1, y = 0},
	{x = 0, y = kWorldSize.y + 1},
	{x = kWorldSize.x + 1, y = kWorldSize.y + 1},
}

local kChuaColors = {
	ApolloColor.new("xkcdRed"),
	ApolloColor.new("xkcdPink"),
	ApolloColor.new("xkcdRobinsEggBlue"),
	ApolloColor.new("xkcdOrange"),
}

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Chompacabra:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	o.tStartingBoard = {
	--   0123456789ABCDEFGHIJKLMNOPQR                  
		"----------------------------",
		"|............||............|",
		"|.WWWW.WWWWW.WW.WWWWW.WWWW.|",
		"|PW  W.W   W.WW.W   W.W  WP|",
		"|.WWWW.WWWWW.WW.WWWWW.WWWW.|",
		"|..........................|",
		"|.WWWW.WW.WWWWWWWW.WW.WWWW.|",
		"|.WWWW.WW.WWWWWWWW.WW.WWWW.|",
		"|......WW....WW....WW......|",
		"|WWWWW.WWWWW WW WWWWW.WWWWW|",
		"     W.WWWWW WW WWWWW.W     ",
		"     W.WW            .W     ",
		"     W.WW WWWWWWWW WW.W     ",
		"WWWWWW.WW WOOOOOOW WW.WWWWW-",
		"      .WW W      D WW.      ",
		"WWWWWW.WW WOOOOOOW WW.WWWWW-",
		"     W.WW WWWWWWWW WW.W     ",
		"     W.            WW.W     ",
		"     W.WW WWWWWWWW WW.W     ",
		"|WWWWW.WW WWWWWWWW WW.WWWWW|",
		"|............WW............|",
		"|.----.-----.||.-----.----.|",
		"|.----.-----.||.-----.----.|",
		"|P..||.......  .......||..P|",
		"|--.||.||.--------.||.||.--|",
		"|--.||.||.--------.||.||.--|",
		"|............||............|",
		"|.----.--.--.||.--.--.----.|",
		"|.----.--.--.||.--.--.----.|",
		"|......WW..........WW......|",
		"----------------------------",
	}
	

    return o
end

function Chompacabra:Init()
    Apollo.RegisterAddon(self, false, "", {})
end
 

-----------------------------------------------------------------------------------------------
-- Chompacabra OnLoad
-----------------------------------------------------------------------------------------------
function Chompacabra:OnLoad()
	-- set our documents to load
	self.xmlDoc = XmlDoc.CreateFromFile("Chompacabra.xml")
	self.xmlSprites = XmlDoc.CreateFromFile("ChompacabraSprites.xml")
	
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	self.xmlSprites:RegisterCallback("OnDocLoaded", self)
end

function Chompacabra:OnDocLoaded()
	-- this event will get called twice, once for each file that loads
	-- it's possible (but unlikely) that BOTH files will be loaded on the first call so if our self.wndMain exists, just exit
	if self.wndMain ~= nil then
		return
	end
	
	if self.xmlDoc:IsLoaded() and self.xmlSprites:IsLoaded() then		
		-- load the sprites
		Apollo.LoadSprites(self.xmlSprites)
	
	    -- load our forms
		self.wndMain = Apollo.LoadForm(self.xmlDoc, "ChompacabraForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
		end
	    self.wndMain:Show(false, true)
	    self.wndGame = self.wndMain:FindChild("GameWindow")

	    -- Register handlers for events, slash commands and timer, etc.
	    -- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("chompacabra", "OnChomp", self)
		Apollo.RegisterEventHandler("NextFrame", "OnFrame", self)

	end
end



-----------------------------------------------------------------------------------------------
-- Chompacabra Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here
function Chompacabra:OnChomp()
	self.wndMain:Show(true)
end

function Chompacabra:GetObjectRect(tLoc, iDirection, fProgress)
	local rect = {}
	rect[1] = tLoc.x * kSquareSize - kSquareSize + kHalfSquare - kHalfObject
	rect[2] = tLoc.y * kSquareSize - kSquareSize + kHalfSquare - kHalfObject
	rect[3] = tLoc.x * kSquareSize - kSquareSize + kHalfSquare + kHalfObject
	rect[4] = tLoc.y * kSquareSize - kSquareSize + kHalfSquare + kHalfObject

	if iDirection == 1 or iDirection == 3 then
		rect[2] = rect[2] + fProgress * kSquareSize 
		rect[4] = rect[4] + fProgress * kSquareSize 
	end	
	if iDirection == 2 or iDirection == 4 then
		rect[1] = rect[1] + fProgress * kSquareSize 
		rect[3] = rect[3] + fProgress * kSquareSize 
	end	
	
	
	return rect
end

function Chompacabra:GetNextSquare(ptLoc, iDirection, nCount)
	if nCount == nil then
		nCount = 1
	end

	-- handle exceptions
	if ptLoc.y == 15 then
		if ptLoc.x == kWorldSize.x and iDirection == 2 then
			return {x = 1, y = ptLoc.y}
		end
		if ptLoc.x == 1 and iDirection == 4 then
			return {x = kWorldSize.x, y = ptLoc.y}
		end
	end
	
	if iDirection == 1 then
		return {x = ptLoc.x, y = ptLoc.y - nCount}
	elseif iDirection == 2 then
		return {x = ptLoc.x + nCount, y = ptLoc.y}
	elseif iDirection == 3 then
		return {x = ptLoc.x, y = ptLoc.y + nCount}
	end
	return {x = ptLoc.x - nCount, y = ptLoc.y}
end

function Chompacabra:IsSquareOpen(ptLoc, iDirection)
	if ptLoc.x < 1 or ptLoc.x > kWorldSize.x or ptLoc.y < 1 or ptLoc.y > kWorldSize.y then
		return false
	end
	if self.tGame.tGrid[ptLoc.y][ptLoc.x] == EGrid.Space then
		return true
	end
	if self.tGame.tGrid[ptLoc.y][ptLoc.x] == EGrid.Door and iDirection == 2 then
		return true
	end
	return false
end


function Chompacabra:OnFrame()
	if self.tGame == nil then
		return
	end
	
	if self.fGameTime == nil then
		self.fGameTime = GameLib.GetGameTime()
		return
	end
	
	local fNow = GameLib.GetGameTime()
	local fElapsed = math.min(0.025, fNow - self.fGameTime)
	self.fGameTime = fNow
	
	self:ProcessTick(fElapsed)
	
end

function Chompacabra:CreateChua(idx)
	local tChua = {}
	tChua.eType = idx
	tChua.ptLoc = {x = 10 + idx * 2, y = 15}
	tChua.iDirection = 2
	tChua.iPending = 2
	tChua.fProgress = 0
	tChua.fSpeed = kChuaSpeed
	tChua.eMode = EChuaMode.Scatter
	tChua.eNextMode = EChuaMode.Chase
	tChua.fTimeToNextMode = 7
	tChua.tPixie = {}
	tChua.tPixie.strSprite = "ChuaWalk"
	tChua.tPixie.cr = kChuaColors[idx]
	tChua.tPixie.loc = {fPoints = {0, 0, 0, 0}, nOffsets = self:GetObjectRect(tChua.ptLoc, tChua.iDirection, tChua.fProgress)}
	tChua.idPixie = self.wndGame:AddPixie(tChua.tPixie)
	
	return tChua
end

function Chompacabra:UpdateScore()
	local str = string.format("Score: %d", self.tGame.nScore)
	self.wndMain:FindChild("Score"):SetText(str)
end

function Chompacabra:ProcessTick(fElapsed)

	if self.tGame.bPaused then
		return
	end

	self.tGame.fAge = self.tGame.fAge + fElapsed
	if self.tGame.fTimeToNextMode > 0 then
	end	
	
	local tChompa = self.tGame.tChompa
	if tChompa.bAlive then
		tChompa.fPendingAge = tChompa.fPendingAge + fElapsed
		if tChompa.iDirection == tChompa.iPending + 2 or tChompa.iDirection == tChompa.iPending - 2 then
			tChompa.iDirection = tChompa.iPending
		end
		
		local ptNextSquare = self:GetNextSquare(tChompa.ptLoc, tChompa.iDirection)
		local bCanMovePast0 = self:IsSquareOpen(ptNextSquare, tChompa.iDirection)
		local fPreProg = tChompa.fProgress
		
		if tChompa.iDirection == 1 or tChompa.iDirection == 4 then
			tChompa.fProgress = tChompa.fProgress - fElapsed * tChompa.fSpeed
		else
			tChompa.fProgress = tChompa.fProgress + fElapsed * tChompa.fSpeed
		end
		
		local fPostProg = tChompa.fProgress 

		
		
		if (fPreProg > 0 and fPostProg <= 0) or (fPreProg < 0 and fPostProg >= 0) or (fPreProg == 0 and fPostProg ~= 0) then 
			if not bCanMovePast0 then
				tChompa.fProgress = 0
			end
		end
			
		if tChompa.iPending ~= tChompa.iDirection then
			local ptNextPending = self:GetNextSquare(tChompa.ptLoc, tChompa.iPending)
			if self:IsSquareOpen(ptNextPending, tChompa.iDirection) then
				tChompa.iDirection = tChompa.iPending
				tChompa.fProgress = 0
			end
		end
	
		if tChompa.fProgress > 0.5 then
			tChompa.ptLoc = ptNextSquare
			tChompa.fProgress = tChompa.fProgress - 1
			if tChompa.fPendingAge > 0.5 then
				tChompa.iPending = tChompa.iDirection
				tChompa.fPendingAge = 0
			end
		elseif tChompa.fProgress < -0.5 then
			tChompa.ptLoc = ptNextSquare
			tChompa.fProgress = tChompa.fProgress + 1
			if tChompa.fPendingAge > 0.5 then
				tChompa.iPending = tChompa.iDirection
				tChompa.fPendingAge = 0
			end
		end
		
		if self.tGame.tPellets[tChompa.ptLoc.y * kWorldSize.x + tChompa.ptLoc.x] ~= nil then
		
			local tPellet = self.tGame.tPellets[tChompa.ptLoc.y * kWorldSize.x + tChompa.ptLoc.x]
			if tPellet.bPower then
				self.tGame.nScore = self.tGame.nScore + 50
				self.tGame.nChuasChomped = 0
				self:ChangeChuaModes(EChuaMode.Frightened)
				
				for idx,tChua in pairs(self.tGame.arChua) do
					tChua.eNextMode = EChuaMode.Chase
					tChua.fTimeToNextMode = 10
				end
				
			else
				self.tGame.nScore = self.tGame.nScore + 10
			end
			self.wndGame:DestroyPixie(self.tGame.tPellets[tChompa.ptLoc.y * kWorldSize.x + tChompa.ptLoc.x].id)
			self.tGame.nPelletCount = self.tGame.nPelletCount - 1
			self.tGame.tPellets[tChompa.ptLoc.y * kWorldSize.x + tChompa.ptLoc.x] = nil
			
			self:UpdateScore()
		end
		
		if tChompa.iDirection == 1 then
			tChompa.tPixie.strSprite = "ChompaWest"
			tChompa.tPixie.fRotation = 90
		elseif tChompa.iDirection == 2 then 
			tChompa.tPixie.strSprite = "ChompaEast"
			tChompa.tPixie.fRotation = 0
		elseif tChompa.iDirection == 3 then 
			tChompa.tPixie.strSprite = "ChompaEast"
			tChompa.tPixie.fRotation = 90
		elseif tChompa.iDirection == 4 then 
			tChompa.tPixie.strSprite = "ChompaWest"
			tChompa.tPixie.fRotation = 0
		end
		
		tChompa.tPixie.loc.nOffsets = self:GetObjectRect(tChompa.ptLoc, tChompa.iDirection, tChompa.fProgress)
		self.wndGame:UpdatePixie(tChompa.idPixie, tChompa.tPixie)
	
		for idx,tChua in pairs(self.tGame.arChua) do
			self:ProcessChua(tChua, fElapsed)
		
			if tChua.ptLoc.x == tChompa.ptLoc.x and tChua.ptLoc.y == tChompa.ptLoc.y then
				if tChua.eMode == EChuaMode.Frightened then
					tChua.ptLoc = {x = 11, y = 15}
					tChua.iDirection = 2
					tChua.iPending = 2
					tChua.fProgress = 0
					tChua.eMode = EChuaMode.Scatter
					tChua.eNextMode = EChuaMode.Chase
					tChua.fTimeToNextMode = 5
					
					self.tGame.nChuasChomped = self.tGame.nChuasChomped + 1
					self.tGame.nScore = self.tGame.nScore + kChuasChompedScore[self.tGame.nChuasChomped]
					self:UpdateScore()
					
					local tFloater = {}
					tFloater.strText = tostring(kChuasChompedScore[self.tGame.nChuasChomped])
					tFloater.loc = {
						fPoints = {0, 0, 0, 0},
						nOffsets = self:GetObjectRect(tChompa.ptLoc, tChompa.iDirection, tChompa.fProgress)
					}
					tFloater.strSprite = ""
					tFloater.flagsText = {DT_VCENTER = 1, DT_CENTER = 1}
					tFloater.strFont = "CRB_HeaderLarge_O"
					tFloater.fRotation = 0
					tFloater.crText = ApolloColor.new("white")
					tFloater.id = self.wndGame:AddPixie(tFloater)
					tFloater.fAge = 0
					self.tGame.tFloaters[tFloater.id] = tFloater
					
				else
					-- death
					self:ResetChuas()
					self.tGame.fDeathTime = 0
					tChompa.bAlive = false
					tChompa.tPixie.strSprite = "ChompaDeath"
					self.wndGame:UpdatePixie(tChompa.idPixie, tChompa.tPixie)
					self.wndGame:RestartPixieSprite(tChompa.idPixie)
					break
				end
			end
		end
	else
		self.tGame.fDeathTime = self.tGame.fDeathTime + fElapsed
		if self.tGame.fDeathTime > 2.0 then
			self:ResetPositions()
		end
	end

	
	for idx,tFloater in pairs(self.tGame.tFloaters) do
		tFloater.fAge = tFloater.fAge + fElapsed
		if tFloater.fAge > 1.0 then
			self.wndGame:DestroyPixie(tFloater.id)
			self.tGame.tFloaters[tFloater.id] = nil
		end
		tFloater.loc.nOffsets[2] = tFloater.loc.nOffsets[2] - fElapsed * 50
		tFloater.loc.nOffsets[4] = tFloater.loc.nOffsets[4] - fElapsed * 50
		self.wndGame:UpdatePixie(tFloater.id, tFloater)
	end
end


function Chompacabra:GetPendingChuaDirection(tChua)
	local ptLoc = tChua.ptLoc
	
	local ptTarget = {x = 0, y = 0}
	
	if tChua.eMode == EChuaMode.Scatter then
		ptTarget = kChuaScatterTargets[tChua.eType]
	end
	
	if tChua.eMode == EChuaMode.Frightened then
		local ptChompa = self.tGame.tChompa.ptLoc
		if ptLoc.x > ptChompa.x then
			ptTarget.x = kWorldSize.x
		else
			ptTarget.x = 0
		end
		if ptLoc.y > ptChompa.y then
			ptTarget.y = kWorldSize.y
		else
			ptTarget.y = 0
		end
	end
	
	if tChua.eMode == EChuaMode.Chase then
		local ptChompa = self.tGame.tChompa.ptLoc

		if tChua.eType == EChuaTypes.Shadow then
			ptTarget = ptChompa
		elseif tChua.eType == EChuaTypes.Speedy then
			ptTarget = self:GetNextSquare(ptChompa, self.tGame.tChompa.iDirection, 4)
		elseif tChua.eType == EChuaTypes.Bashful then
			local ptMid = self:GetNextSquare(ptChompa, self.tGame.tChompa.iDirection, 2)
			local ptChase = self.tGame.arChua[1].ptLoc
			ptTarget.x = ptMid.x + (ptMid.x - ptChase.x)
			ptTarget.y = ptMid.y + (ptMid.y - ptChase.y)
		elseif tChua.eType == EChuaTypes.Clyde then
			local fDist = (ptChompa.x - tChua.ptLoc.x) * (ptChompa.x - tChua.ptLoc.x) + (ptChompa.y - tChua.ptLoc.y) * (ptChompa.y - tChua.ptLoc.y)
			if fDist > 64 then	
				ptTarget = ptChompa
			else
				ptTarget = kChuaScatterTargets[tChua.eType]
			end
		end
	end
	
	
	
	local iNewDir = tChua.iDirection
	local fBestScore = 1000000
	for idx = 1,4 do
		if idx ~= tChua.iDirection + 2 and idx ~= tChua.iDirection - 2 then
			local ptSquare = self:GetNextSquare(ptLoc, idx)
			if self:IsSquareOpen(ptSquare, tChua.iDirection) then
				-- evaluate this square
				local fScore = (ptTarget.x - ptSquare.x) * (ptTarget.x - ptSquare.x) + (ptTarget.y - ptSquare.y) * (ptTarget.y - ptSquare.y)
				if fScore < fBestScore then
					iNewDir = idx
					fBestScore = fScore
				end
			end
		end
	end
	
	return iNewDir
end

function Chompacabra:ProcessChua(tChua, fElapsed)
	local fPreProg = tChua.fProgress

	local ptNextSquare = self:GetNextSquare(tChua.ptLoc, tChua.iDirection)
	
	local fSpeed = tChua.fSpeed
	if tChua.ptLoc.y == 15 and (tChua.ptLoc.x < 4 or tChua.ptLoc.x > kWorldSize.x - 4) then
		fSpeed = fSpeed / 2
	end
	
	if tChua.iDirection == 1 or tChua.iDirection == 4 then
		tChua.fProgress = tChua.fProgress - fElapsed * fSpeed
	else
		tChua.fProgress = tChua.fProgress + fElapsed * fSpeed
	end
	
	local fPostProg = tChua.fProgress 

	
	
	if (fPreProg > 0 and fPostProg <= 0) or (fPreProg < 0 and fPostProg >= 0) or (fPreProg == 0 and fPostProg ~= 0) then 
		if tChua.iDirection ~= tChua.iPending then
			tChua.fProgress = 0
			tChua.iDirection = tChua.iPending
		end
	end

	if tChua.fProgress > 0.5 then
		tChua.ptLoc = ptNextSquare
		tChua.fProgress = tChua.fProgress - 1
		tChua.iPending = self:GetPendingChuaDirection(tChua)
	elseif tChua.fProgress < -0.5 then
		tChua.ptLoc = ptNextSquare
		tChua.fProgress = tChua.fProgress + 1
		tChua.iPending = self:GetPendingChuaDirection(tChua)
	end
	if tChua.eMode == EChuaMode.Frightened then
		tChua.tPixie.cr = ApolloColor.new("xkcdBrightBlue")
	else
		tChua.tPixie.cr = kChuaColors[tChua.eType]
	end
	tChua.tPixie.loc.nOffsets = self:GetObjectRect(tChua.ptLoc, tChua.iDirection, tChua.fProgress)
	self.wndGame:UpdatePixie(tChua.idPixie, tChua.tPixie)

	if tChua.fTimeToNextMode > 0 then
		tChua.fTimeToNextMode = tChua.fTimeToNextMode - fElapsed
		if tChua.fTimeToNextMode <= 0 then
			tChua.eMode = tChua.eNextMode
		end
	end	
end

function Chompacabra:ChangeChuaModes(eMode)

	if eMode == EChuaMode.Frightened then
		self.tGame.tChompa.fSpeed = kChompaPowerSpeed
	else
		self.tGame.tChompa.fSpeed = kChompaSpeed
	end

	for k, tChua in pairs(self.tGame.arChua) do
		if tChua.eMode ~= eMode then
			tChua.iDirection = kOppoDirection[tChua.iDirection]
			tChua.eMode = eMode
			
			self.wndGame:UpdatePixie(tChua.idPixie, tChua.tPixie)
		end
	end
end

-----------------------------------------------------------------------------------------------
-- ChompacabraForm Functions
-----------------------------------------------------------------------------------------------

function Chompacabra:ResetChuas()
	if self.tGame == nil then
		return
	end
	
	local tGame = self.tGame
	for idx,tChua in pairs(tGame.arChua) do 	
		tChua.ptLoc = {x = 10 + idx * 2, y = 15}
		tChua.fProgress = 0
		tChua.tPixie.loc = {fPoints = {0, 0, 0, 0}, nOffsets = self:GetObjectRect(tChua.ptLoc, tChua.iDirection, tChua.fProgress)}
		tChua.eMode = EChuaMode.Scatter
		tChua.eNextMode = EChuaMode.Chase
		tChua.fTimeToNextMode = 7
		tChua.iDirection = 2
		tChua.iPending = 2
		self.wndGame:UpdatePixie(tChua.idPixie, tChua.tPixie)
	end
end

function Chompacabra:ResetPositions()
	if self.tGame == nil then
		return
	end
	
	local tGame = self.tGame
	local tChompa = tGame.tChompa
	
	tGame.fAge = 0
	
	tChompa.ptLoc = {x = 15, y = 24}
	tChompa.tPixie.strSprite = "ChompaWest"
	tChompa.iDirection = 4
	tChompa.iPending = 4
	tChompa.fSpeed = kChompaSpeed
	tChompa.tPixie.loc = {fPoints = {0, 0, 0, 0}, nOffsets = self:GetObjectRect(tChompa.ptLoc, tChompa.iDirection, tChompa.fProgress)}
	self.wndGame:UpdatePixie(tChompa.idPixie, tChompa.tPixie)
	
	tChompa.bAlive = true
end

function Chompacabra:OnNewGame()

	self.wndGame:DestroyAllPixies()
	self.tGame = {}

	local tGame = self.tGame
	
	tGame.tGrid = {}
	tGame.tPellets = {}
	tGame.tFloaters = {}
	tGame.nScore = 0
	tGame.nPelletCount = 0
	tGame.bPaused = false
	tGame.fTimeToNextMode = 0
	
	for y,strLine in ipairs(self.tStartingBoard) do	
		
		tGame.tGrid[y] = {}
		
		local fPoints = {0, 0, 0, 0}
		local rect = {0, 0, 0, 0}
		rect[2] = y * kSquareSize - kSquareSize
		rect[4] = y * kSquareSize
		
		for x =1,kWorldSize.x do
			rect[1] = x * kSquareSize - kSquareSize
			rect[3] = x * kSquareSize
		
			local ch = string.sub(strLine, x, x)
			if ch == 'W' or ch == '|' or ch == '-' then
				tGame.tGrid[y][x] = EGrid.Wall
			elseif ch == '.' then
				tGame.tGrid[y][x] = EGrid.Space

				tGame.tPellets[y * kWorldSize.x + x] = {}
				local tPixie = {}
				tPixie.strSprite = "WhiteCircle"
				tPixie.cr = ApolloColor.new("white")
				tPixie.loc = {}
				tPixie.loc.fPoints = fPoints
				tPixie.loc.nOffsets = {rect[1] + kHalfSquare - 2, rect[2] + kHalfSquare - 2, rect[1] + kHalfSquare + 2, rect[2] + kHalfSquare + 2}
				tPixie.id = self.wndGame:AddPixie(tPixie)
				tPixie.bPower = false
				tGame.tPellets[y * kWorldSize.x + x] = tPixie

			elseif ch == 'P' then
				tGame.tGrid[y][x] = EGrid.Space

				tGame.tPellets[y * kWorldSize.x + x] = {}
				local tPixie = {}
				tPixie.strSprite = "WhiteCircle"
				tPixie.cr = ApolloColor.new("white")
				tPixie.loc = {}
				tPixie.loc.fPoints = fPoints
				tPixie.loc.nOffsets = {rect[1] + kHalfSquare - 8, rect[2] + kHalfSquare - 8, rect[1] + kHalfSquare + 8, rect[2] + kHalfSquare + 8}
				tPixie.id = self.wndGame:AddPixie(tPixie)
				tPixie.bPower = true
				tGame.tPellets[y * kWorldSize.x + x] = tPixie

			elseif ch == 'O' then
				-- invisible wall
				tGame.tGrid[y][x] = EGrid.Wall
			elseif ch == 'D' then
				tGame.tGrid[y][x] = EGrid.Door
			else
				tGame.tGrid[y][x] = EGrid.Space
			end
		end
	end
	
	tGame.fAge = 0
	
	local tChompa = {}
	tChompa.iDirection = 4	-- west
	tChompa.ptLoc = {x = 15, y = 24}
	tChompa.fProgress = -0.5
	tChompa.iPending = 4
	tChompa.fPendingAge = 0
	tChompa.fSpeed = kChompaSpeed
	tChompa.bAlive = true
	tChompa.tPixie = {}
	tChompa.tPixie.strSprite = "ChompaEast"
	tChompa.tPixie.cr = ApolloColor.new("white")
	tChompa.tPixie.loc = {fPoints = {0, 0, 0, 0}, nOffsets = self:GetObjectRect(tChompa.ptLoc, tChompa.iDirection, tChompa.fProgress)}
	tChompa.idPixie = self.wndGame:AddPixie(tChompa.tPixie)
	tGame.tChompa = tChompa

	tGame.arChua = {}
	for idx = 1,4 do
		local tChua = self:CreateChua(idx)
		tGame.arChua[idx] = tChua
	end

end

-- when the Cancel button is clicked
function Chompacabra:OnCancel()
	self.wndMain:Show(false) -- hide the window
end

function Chompacabra:OnNorth()
	if self.tGame == nil then
		return
	end
	self.tGame.tChompa.iPending = 1
	self.tGame.tChompa.fPendingAge = 0
end

function Chompacabra:OnSouth()
	if self.tGame == nil then
		return
	end
	self.tGame.tChompa.iPending = 3
	self.tGame.tChompa.fPendingAge = 0
end

function Chompacabra:OnEast()
	if self.tGame == nil then
		return
	end
	self.tGame.tChompa.iPending = 2
	self.tGame.tChompa.fPendingAge = 0
end

function Chompacabra:OnWest()
	if self.tGame == nil then
		return
	end
	self.tGame.tChompa.iPending = 4
	self.tGame.tChompa.fPendingAge = 0
end

function Chompacabra:OnMouseButtonDown( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if self.tGame ~= nil and eMouseButton == 1 then
		self.tGame.bPaused = not self.tGame.bPaused
	end
end

-----------------------------------------------------------------------------------------------
-- Chompacabra Instance
-----------------------------------------------------------------------------------------------
local ChompacabraInst = Chompacabra:new()
ChompacabraInst:Init()
