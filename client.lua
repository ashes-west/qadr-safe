local _isMiniGameActive              = false -- Indicates whether the mini game is currently active.

local _safeCombination               = nil   -- Contains a randomly generated sequence of numbers (0–99) representing the safe dial positions for unlocking.
local _safeLockStatus                = nil   -- A table storing the lock status for each pin in the safe. Each entry is `true` if the pin is still locked and set `nil` once unlocked.
local _currentLockNum                = nil   -- Indicates which safe pin is currently being processed.

local _requiredDialRotationDirection = nil   -- Stores the required direction in which the player has to rotating the safe dial to solve. ("Clockwise", "Anticlockwise", or "Idle")
local _onSpot                        = false -- Indicates whether the player has currently aligned the dial to the correct position to unlock a pin.
local _currentDialRotationDirection  = nil   -- Stores the current direction in which the player is rotating the safe dial. ("Clockwise", "Anticlockwise", or "Idle")
local _lastDialRotationDirection     = nil   -- Stores the last direction in which the player was rotating the safe dial. ("Clockwise", "Anticlockwise", or "Idle")
local _safeDialRotation              =   0   -- Current rotation angle of the safe dial in degrees. (0–360). Each number corresponds to 3.6°.
local DEGREES_PER_NUMBER             =   3.6 -- Represents the angular increment (in degrees) for each number on the safe dial. Since the dial has 100 positions (0–99), each step corresponds to 3.6° (360° / 100).

local ROTATION_DELAY                 =  50   -- Delay between dial steps in ms (tweakable). Without delay, having high FPS leads to a huge rotation even with a short key press.
local _lastRotationTime              =   0   -- Timestamp of last dial rotation.

local KEY_CANCEL                     = 0xD27782E3 -- BACKSPACE. Key to cancel the safe mini game. 
local KEY_SNAP                       = 0x8FD015D8 -- W. Key to snap in the current pin.
local KEY_LEFT                       = 0x7065027D -- A. Key to rotate the safe dial to the left.
local KEY_RIGHT                      = 0xB4E465B4 -- D. Key to rotate the safe dial to the right.

-- Example calls: /createSafe (0 arguments: creates a 3 pin safe), /createSafe 5 (1 argument: creates a 5 pin safe), /createSafe 12 42 9 1 (> 1 argument: creates a safe with [argc] pins with the given combination)
RegisterCommand("createSafe", function(_, args)
	if #args == 0 then
		-- Default case -> use 3 random pins
		createSafe({math.random(0, 99), math.random(0, 99), math.random(0, 99)})
		return
	elseif #args == 1 then
		local count = tonumber(args[1])
		if count ~= nil then
			-- Case Number is given -> use [argc] pins
			if count < 1 or count > 9 then
				print("^1[SAFE] Fehler: Anzahl der Pins muss zwischen 1 und 9 liegen.^7")
				return
			end

			local randomCombination = {}
			for i = 1, count do
				table.insert(randomCombination, math.random(0, 99))
			end

			createSafe(randomCombination)
			return
		end
	end

	-- Case: multiple arguments -> treat as pin combination
	local combination = {}
	for i = 1, #args do
		local pin = tonumber(args[i])
		if not pin or pin < 0 or pin > 99 then
			print("^1[SAFE] Fehler: Ungültiger Pin '" .. tostring(args[i]) .. "'. Werte müssen zwischen 0 und 99 liegen.^7")
			return
		end
		table.insert(combination, pin)
	end

	if #combination < 1 or #combination > 9 then
		print("^1[SAFE] Fehler: Anzahl der Pins muss zwischen 1 und 9 liegen.^7")
		return
	end

	createSafe(combination)
end)

function createSafe(combination)
	if _isMiniGameActive then
		return
	end

	InitializeSafe(combination)
	SendNUIMessage({ action = "showSafeHud" })
	_isMiniGameActive = true

	RequestStreamedTextureDict("qadr_safe_cracking", false)
	RequestStreamedTextureDict("ui_startup_textures", false)

	if _isMiniGameActive then
		-- Launch lock pick animation
		local playerPed = PlayerPedId()
		local dict = 'mini_games@safecrack@base'
		local anim = 'dial_turn_right_stage_00'
		RequestAnimDict(dict)
		while not HasAnimDictLoaded(dict) do
			Citizen.Wait(1)
		end
		TaskPlayAnim(playerPed, dict, anim, 4.0, 4.0, -1, 1, 0, false, false, false, false)

		-- Loop until safe is open
		while _isMiniGameActive do
			DrawSprites(true)
			local res = RunMiniGame()

			if res ~= nil then
				return res
			end

			Citizen.Wait(0)
		end
	end
end

function InitializeSafe(safeCombination)
	_safeCombination = safeCombination

	_safeLockStatus = {}
	_currentLockNum = 1
	_onSpot = false
	_requiredDialRotationDirection = "Clockwise"
	_currentDialRotationDirection = "Idle"
	_lastDialRotationDirection = "Idle"

	-- Make all locks locked
	for i = 1,#_safeCombination do
		_safeLockStatus[i] = true
	end

	-- Start with a random dial rotation
	local dialStartNumber = math.random(0, 100)
	_safeDialRotation = DEGREES_PER_NUMBER * dialStartNumber
end

function DrawTexture(textureStreamed,textureName,x, y, width, height,rotation,r, g, b, a, p11)
	if not HasStreamedTextureDictLoaded(textureStreamed) then
		RequestStreamedTextureDict(textureStreamed, false)
	else
		DrawSprite(textureStreamed, textureName, x, y, width, height, rotation, r, g, b, a, p11);
	end
end

function DrawSprites(drawLocks)
	local textureDict = "qadr_safe_cracking"
	local _aspectRatio = 16/9 --GetAspectRatio(true)

	DrawTexture("des_safe_sml_l_fail+hi", "p_door_val_bankvault_small_ab", 0.8, 0.5, 0.3, _aspectRatio * 0.3, 0, 250, 250, 250, 185)
	DrawTexture(textureDict, "Dial_BG", 0.8, 0.5, 0.2, _aspectRatio * 0.2, 0, 255, 255, 255, 255)
	DrawTexture(textureDict, "Dial", 0.8, 0.5, 0.2, _aspectRatio * 0.2, _safeDialRotation, 255, 255, 255, 255)

	if not drawLocks then
		return
	end

	local xPos = 0.933
	local yPos = 0.43
	local _kilittexturedic = "elements_stamps_icons"
	for _,lockActive in pairs(_safeLockStatus) do
		local lockString
		if lockActive then
			lockString = "stamp_locked_rank"
		else
			lockString = "stamp_unlocked_rank"
		end

		DrawTexture(_kilittexturedic, lockString, xPos, yPos, 0.025, _aspectRatio * 0.025, 0, 231, 194, 81, 255)
		yPos = yPos + 0.05
	end
end

function RunMiniGame()
	-- If player is [almost] dead return 
	local isDead = GetEntityHealth(PlayerPedId()) <= 101
	if isDead then
		EndMiniGame(false)
		return false
	end

	SendNUIMessage({
		action = "updateKeys",
		keys = {
			backspace = IsControlPressed(0, KEY_CANCEL),
			w         = IsControlPressed(0, KEY_SNAP),
			a         = IsControlPressed(0, KEY_LEFT),
			d         = IsControlPressed(0, KEY_RIGHT)
		}
	})

	if IsControlJustPressed(0, KEY_CANCEL) then
		EndMiniGame(false)
		return false
	end

	if IsControlJustPressed(0, KEY_SNAP) then
		if _onSpot then
			ReleaseCurrentPin()
			_onSpot = false
			if _safeLockStatus[_currentLockNum] == nil then
				EndMiniGame(true)
				return true
			end
		else
			EndMiniGame(false)
			return false
		end
	end

	HandleSafeDialMovement()

	local incorrectMovement = _currentLockNum ~= 0 and _requiredDialRotationDirection ~= "Idle" and _currentDialRotationDirection ~= "Idle" and _currentDialRotationDirection ~= _requiredDialRotationDirection

	if incorrectMovement then
		_onSpot = false
	else
		local currentDialNumber = GetCurrentSafeDialNumber(_safeDialRotation)
		local correctMovement = _requiredDialRotationDirection ~= "Idle" and (_currentDialRotationDirection == _requiredDialRotationDirection or _lastDialRotationDirection == _requiredDialRotationDirection)  
		if correctMovement then
			local pinUnlocked = _safeLockStatus[_currentLockNum] and currentDialNumber == _safeCombination[_currentLockNum]
			if pinUnlocked and not _onSpot then
				sescal("Mud5_Sounds","Small_Safe_Tumbler")
				_onSpot = true
			end
		end
	end
end

function HandleSafeDialMovement()
	if IsControlPressed(0, KEY_LEFT) then
		RotateSafeDial("Anticlockwise")
	elseif IsControlPressed(0, KEY_RIGHT) then
		RotateSafeDial("Clockwise")
	else
		RotateSafeDial("Idle")
	end
end

function RotateSafeDial(rotationDirection)
	local currentTime = GetGameTimer()

	if currentTime - _lastRotationTime < ROTATION_DELAY then
		return
	end

	if rotationDirection == "Anticlockwise" or rotationDirection == "Clockwise" then
		local multiplier
		local rotationPerNumber = DEGREES_PER_NUMBER
		if rotationDirection == "Anticlockwise" then
			multiplier = 1
		elseif rotationDirection == "Clockwise" then
			multiplier = -1
		end

		local rotationChange = multiplier * rotationPerNumber
		_safeDialRotation = _safeDialRotation + rotationChange
		if _safeDialRotation > 360 then
			_safeDialRotation = _safeDialRotation - 360
		elseif _safeDialRotation < 0 then
			_safeDialRotation = _safeDialRotation + 360
		end
		sescal("Mud5_Sounds","Dial_Turn_Single")
		_lastRotationTime = currentTime

	end

	_currentDialRotationDirection = rotationDirection
	_lastDialRotationDirection = rotationDirection
end

function SetSafeDialStartNumber()
	local dialStartNumber = math.random(0, 100)
	_safeDialRotation = DEGREES_PER_NUMBER * dialStartNumber
end

function GetCurrentSafeDialNumber(currentDialAngle)
	local number = math.floor(100 * (currentDialAngle / 360))
	if number > 0 then
		number = 100 - number
	end

	return math.abs(number)
end

function ReleaseCurrentPin()
	local currentDialNumber = GetCurrentSafeDialNumber(_safeDialRotation)
	local pinUnlocked = _safeLockStatus[_currentLockNum] and currentDialNumber == _safeCombination[_currentLockNum]
	if not pinUnlocked then return end
	_safeLockStatus[_currentLockNum] = false
	_currentLockNum = _currentLockNum + 1
	if _requiredDialRotationDirection == "Anticlockwise" then
		_requiredDialRotationDirection = "Clockwise"
	else
		_requiredDialRotationDirection = "Anticlockwise"
	end
	sescal("Mud5_Sounds","Small_Safe_Tumbler")
end

function EndMiniGame(safeUnlocked)
	SendNUIMessage({ action = "hideSafeHud" })

	if safeUnlocked then
		sescal("Mud5_Sounds","Small_Safe_Unlock")
	end

	Citizen.CreateThread(function()
		ClearPedTasks(PlayerPedId())
	end)

	_isMiniGameActive = false
end

exports("createSafe",createSafe)
