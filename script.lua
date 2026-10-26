local DEVICE_SPOOFER_SOURCE = [[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TARGET_DEVICE = "PC"
task.spawn(function()
	local cgm = ReplicatedStorage:WaitForChild("ClientGameModules", 30)
	if not cgm then return end
	local mod = cgm:WaitForChild("DeviceListener", 30)
	if not mod then return end
	local ok, DL = pcall(require, mod)
	if not ok or not DL then return end
	if DL.RegisterDeviceChanged then
		local OriginalRegister = DL.RegisterDeviceChanged
		DL.RegisterDeviceChanged = function(self, deviceTable, ...)
			if type(deviceTable) == "table" then
				for k, v in pairs(deviceTable) do
					if type(v) == "string" then
						local l = v:lower()
						if l == "mobile" or l == "phone" or l == "tablet" or l == "android" or l == "ios" then
							deviceTable[k] = TARGET_DEVICE
						end
					elseif typeof(v) == "EnumItem" then
						if v == Enum.Platform.Android or v == Enum.Platform.IOS then
							deviceTable[k] = Enum.Platform.Windows
						end
					end
				end
			elseif type(deviceTable) == "string" then
				local l = deviceTable:lower()
				if l == "mobile" or l == "phone" or l == "tablet" or l == "android" or l == "ios" then
					deviceTable = TARGET_DEVICE
				end
			end
			return OriginalRegister(self, deviceTable, ...)
		end
	end
	pcall(function() DL.Device = TARGET_DEVICE end)
	pcall(function()
		if type(DL.Device) == "table" then
			for k, v in pairs(DL.Device) do
				if type(v) == "string" then
					local l = v:lower()
					if l == "mobile" or l == "phone" or l == "android" or l == "ios" then
						DL.Device[k] = TARGET_DEVICE
					end
				end
			end
		end
	end)
	task.wait(1)
	pcall(function() DL:RegisterDeviceChanged(DL.Device) end)
	task.wait(2)
	pcall(function() DL:RegisterDeviceChanged(DL.Device) end)
	task.wait(3)
	pcall(function() DL:RegisterDeviceChanged(DL.Device) end)
end)
local mt = getrawmetatable(game)
local oldIndex = mt.__index
setreadonly(mt, false)
mt.__index = newcclosure(function(self, key)
	if self == UserInputService then
		if key == "GetPlatform" then
			return function() return Enum.Platform.Windows end
		end
		if key == "TouchEnabled" or key == "TouchScreenEnabled" or key == "AccelerometerEnabled" or key == "GyroscopeEnabled" or key == "GamepadEnabled" or key == "VREnabled" then
			return false
		end
		if key == "KeyboardEnabled" or key == "MouseEnabled" then
			return true
		end
		if key == "PreferredInput" then
			return Enum.PreferredInput.KeyboardAndMouse
		end
	end
	return oldIndex(self, key)
end)
setreadonly(mt, true)
]]

local Handlers = {}

local function packValues(...)
    return {{...}, select("#", ...)}
end

local function unpackValues(packed)
    return unpack(packed[1], 1, packed[2])
end

local function normalizeIterator(value, state, control)
    if type(value) ~= "function" then
        local mt = getmetatable(value)
        if mt ~= nil and mt.__iter ~= nil then
            return mt.__iter(value)
        elseif (mt and mt.__call) == nil and type(value) == "table" then
            return pairs(value)
        end
    end
    return value, state, control
end

local function setRange(target, first, ...)
    local values = {...}
    for index = 1, select("#", ...) do
        target[first + index - 1] = values[index]
    end
end

-- Bind shared dependencies once; returned callbacks retain their original identity.
local binders = {}
binders[0] = function(handler)
    return function(...)
        return handler(...)
    end
end
binders[1] = function(handler, arg1)
    return function(...)
        return handler(arg1, ...)
    end
end
binders[2] = function(handler, arg1, arg2)
    return function(...)
        return handler(arg1, arg2, ...)
    end
end
binders[3] = function(handler, arg1, arg2, arg3)
    return function(...)
        return handler(arg1, arg2, arg3, ...)
    end
end
binders[4] = function(handler, arg1, arg2, arg3, arg4)
    return function(...)
        return handler(arg1, arg2, arg3, arg4, ...)
    end
end
binders[5] = function(handler, arg1, arg2, arg3, arg4, arg5)
    return function(...)
        return handler(arg1, arg2, arg3, arg4, arg5, ...)
    end
end
binders[6] = function(handler, arg1, arg2, arg3, arg4, arg5, arg6)
    return function(...)
        return handler(arg1, arg2, arg3, arg4, arg5, arg6, ...)
    end
end
binders[7] = function(handler, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
    return function(...)
        return handler(arg1, arg2, arg3, arg4, arg5, arg6, arg7, ...)
    end
end
binders[8] = function(handler, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
    return function(...)
        return handler(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, ...)
    end
end
binders[9] = function(handler, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    return function(...)
        return handler(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, ...)
    end
end
binders[10] = function(handler, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
    return function(...)
        return handler(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, ...)
    end
end

local function bind(handler, ...)
    return binders[select("#", ...)](handler, ...)
end

-- ============================================================================
-- Entry point
-- ============================================================================

-- Initialize services, restore configuration, wire gameplay events, and construct the UI.
function Handlers.main(...)
    -- Services and shared state
    local parryCipher, backgroundColor, result, isBallCurvingRef, lastPingReadRef, disableParticleCleanupRef, refreshAimIfEnabledRef
    local cosmetics2, aimCacheRef, parryTransform, temporary4, animationRecentlyPlayedRef, loadConfig, ballCurveStates
    local swordApiRef, keybindPanelRef, curveOptionsPanelRef, speedLabelRef, watchBallTargetRef, triggerLabel, spamKeyButtonRef
    local runService, isParryBlockedRef, curveDropdownButtonRef, getParryConnectionFunction, tweenService, findAutoexecFolderRef, initializeCosmeticsSafely
    local positionRef, originalIndexRef, cipherKeyLengthRef, parrySucceededRef, fpsLabelRef, animationCacheRef, unboundKey
    local refreshCurvePanelRef, parryRemoteRef, cipherBufferRef, temporary8Ref, swordOverrideEnabledRef, resolveParryAnimationRef, curvePanelOpenRef
    local applyDeviceSpoofRef, findBallRef, getParryConnectionFunction2, temporary10, hideRightLegRef, cosmeticsRef, isPlayerAliveRef
    local spamPanel, deleteConfigAndResetRef, speedDisplayRef, shopControllerApiRef, replicatedStorage, resetFramePositionsRef, playParryAnimationRef
    local playAnimationRef, isVisualEffectRef, parryCooldownRef, ballPresentRef, swordOverrideNameRef, appearanceCacheRef, getPingRef
    local applySavedUiStateRef, initializeCosmeticsSafely2, curveOptionsOpenRef, curveKeyRowsRef, triggerKeyButtonRef, clearVisualEffectsRef, trySpamParryRef
    local setImmortalityHookRef, enableParticleCleanupRef, lastM1StopRef, createFloatingButton, triggerButtonRef, fpsPanelRef, keybindPanelOpenRef
    local refreshAimCacheRef, spamStroke, initializeCosmeticsSafely3, lighting, restoreRightLegRef, ballTargetedPlayerRef, updateSpeedLabelRef
    local selectedCurveRef, applyOptimizationRef, trackedBallsRef, hasRejoinFlagRef, triggerPanel, cacheRightLegRef, lastTriggerTimeRef
    local swordControllerRef, getTeleportQueueRef, keyOptionsPopupRef, beginKeyCaptureRef, immortalityButtonRef, temporary16, makeDraggableRef
    local resetFramePositionsRef2, immortalityTransformRef, unboundKey2, encodeTimestampRef, updateImmortalityTransformRef, hasFileAccessRef, hideHeadRef
    local optimizationStateRef, cachedPingRef, trackBallRef, tryUseAbilityRef, curveDropdownButtonRef2, getBallCurveStateRef, curveOptions
    local immortalityHookEnabledRef, disableNetworkOverrideRef, curveRows, spamCountRef, config, buildCurveWindow, spamHistory
    local onKeybindInputBeganRef, debugFlags, immortalityStrokeRef2, httpService, watchParryStateRef, mutedTextColor, initializeCosmeticsSafely4
    local enableNoRenderRef, triggerStroke, temporary24, applyAppearanceRef, keyOptionRowsRef, calculateCurveTargetRef, immortalityStroke
    local sendParryRef, resetFramePositionsRef3, enableNetworkOverrideRef, onBallFrameRef, spamLabel, tryParryAnimationRef, camera
    local accentColorRef, resetConfigDefaultsRef, saveConfigRef, saveKeybindsRef, refreshKeybindPanelRef, swordAnimationsRef, animationBusyRef
    local dragConnectionsRef, coreGui, textColor, setSwordOverrideRef, pendingKeybindRef, keyCaptureActiveRef, stats
    local ballConnectionsRef, defaultPositionsRef, players, localPlayerRef, originalFireServerRef, temporary30, keybinds
    local playerDataRef, ballSpeedStateRef, clearCloudsRef, styleFloatingButtonRef, immortalityPanel, getSwordConnectionFunction, ballTargetTimesRef
    local userInputService, curveOptionsPanelRef2, immortalityLabel, optimizationConnections, disableNoRenderRef, temporary32Ref, debris
    local watchBallPresenceRef, stopAnimationRef, spamButtonRef, restoreHeadRef, remoteBallPositions, screenGuiRef, cipherKeyBytes
    players = game:GetService("Players")
    runService = game:GetService("RunService")
    replicatedStorage = game:GetService("ReplicatedStorage")
    stats = game:GetService("Stats")
    userInputService = game:GetService("UserInputService")
    tweenService = game:GetService("TweenService")
    lighting = game:GetService("Lighting")
    httpService = game:GetService("HttpService")
    debris = game:GetService("Debris")
    camera = workspace.CurrentCamera
    swordApiRef = {value = replicatedStorage:WaitForChild("Shared"):WaitForChild("SwordAPI")}
    localPlayerRef = {value = players.LocalPlayer}
    unboundKey = Enum.KeyCode.None
    remoteBallPositions = setmetatable({}, {__mode = "k"})
    local netFolder = replicatedStorage:FindFirstChild("Packages")
    if netFolder then
        netFolder = replicatedStorage.Packages:FindFirstChild("_Index")
    end
    if netFolder then
        netFolder = replicatedStorage.Packages._Index:FindFirstChild("sleitnick_net@0.1.0")
    end
    if netFolder then
        netFolder = replicatedStorage.Packages._Index["sleitnick_net@0.1.0"]:FindFirstChild("net")
    end
    if netFolder then
        for _, remote in ipairs(netFolder:GetChildren()) do
            if remote:IsA("UnreliableRemoteEvent") then
                remote.OnClientEvent:Connect(bind(Handlers.onRemoteBallUpdate, remoteBallPositions))
            end
        end
    end
    -- File access, autoexec discovery, and device spoofing
    hasFileAccessRef = {value = bind(Handlers.hasFileAccess)}
    hasRejoinFlagRef = {value = bind(Handlers.hasRejoinFlag, hasFileAccessRef)}
    findAutoexecFolderRef = {value = bind(Handlers.findAutoexecFolder)}
    getTeleportQueueRef = {value = bind(Handlers.getTeleportQueueFunction)}
    applyDeviceSpoofRef = {
        value = bind(Handlers.applyDeviceSpoofAndRejoin, getTeleportQueueRef, hasFileAccessRef, localPlayerRef, hasRejoinFlagRef, findAutoexecFolderRef)
    }
    appearanceCacheRef = {value = {}}
    cacheRightLegRef = {value = bind(Handlers.cacheRightLegAppearance, appearanceCacheRef)}
    hideRightLegRef = {value = bind(Handlers.hideRightLeg)}
    restoreRightLegRef = {value = bind(Handlers.restoreRightLeg, appearanceCacheRef)}
    hideHeadRef = {value = bind(Handlers.hideHead)}
    restoreHeadRef = {value = bind(Handlers.restoreHead)}
    config = {
        parry = true,
        spamParry = false,
        spam = false,
        trigger = false,
        cps = 60,
        accuracy = 75,
        autoAccuracy = false,
        spamThreshold = 1,
        animfix = false,
        showStats = false,
        immortality = false,
        curveType = "straight",
        showBindWindow = false,
        showSpamUI = false,
        showTriggerUI = false,
        showImmortalUI = false,
        showCurveUI = false,
        showFpsUI = false,
        saveButtonPositions = false,
        buttonPositions = {},
        unlock_all = false,
        last_equipped_sword = "",
        last_equipped_explosion = "",
        favorite_swords = {},
        favorite_explosions = {},
        deleted_swords = {},
        deleted_explosions = {},
        imm = {
            angle = 70,
            height = 15,
            depth = -8,
            radius = 10,
            ui = false
        },
        optim = {
            destroyParticles = false,
            unlimitedKBPS = false,
            headless = false,
            korblox = false,
            noRender = false
        },
        ability = {cooldown_protection = false}
    }
    -- Default settings and character appearance
    applyAppearanceRef = {value = nil}
    defaultPositionsRef, applyAppearanceRef.value = localPlayerRef.value.Character, bind(Handlers.applyCharacterAppearance, restoreRightLegRef, restoreHeadRef, hideHeadRef, cacheRightLegRef, hideRightLegRef, config)
    if defaultPositionsRef then
        applyAppearanceRef.value(localPlayerRef.value.Character)
    end
    saveConfigRef, defaultPositionsRef = bind(Handlers.onCharacterAdded, applyAppearanceRef, appearanceCacheRef), localPlayerRef.value.CharacterAdded
    defaultPositionsRef, dragConnectionsRef = defaultPositionsRef.Connect, defaultPositionsRef
    defaultPositionsRef(dragConnectionsRef, saveConfigRef)
    defaultPositionsRef, dragConnectionsRef = task.spawn, bind(Handlers.watchCharacterAppearance, localPlayerRef, config, applyAppearanceRef)
    defaultPositionsRef(dragConnectionsRef)
    dragConnectionsRef = {}
    saveConfigRef = UDim2.new(0.5, -160, 0.15, 0)
    dragConnectionsRef.MainFrame = saveConfigRef
    saveConfigRef = UDim2.new(0.5, 5, 0.15, 0)
    dragConnectionsRef.TBFrame = saveConfigRef
    saveConfigRef = UDim2.new(0.5, 5, 0.25, 0)
    dragConnectionsRef.ImmFrame = saveConfigRef
    saveConfigRef = UDim2.new(0.5, 165, 0.15, 0)
    dragConnectionsRef.statsFrame = saveConfigRef
    saveConfigRef = UDim2.new(0.5, 165, 0.2, 0)
    dragConnectionsRef.fpsFrame = saveConfigRef
    saveConfigRef = UDim2.new(0.5, -75, 0.35, 0)
    dragConnectionsRef.CurveMainFrame = saveConfigRef
    saveConfigRef = UDim2.new(0.5, -110, 0.45, 0)
    dragConnectionsRef.KeybindMainFrame = saveConfigRef
    defaultPositionsRef = {value = dragConnectionsRef}
    saveConfigRef = {}
    dragConnectionsRef = {value = saveConfigRef}
    saveConfigRef = {value = saveConfigRef}
    loadConfig, saveConfigRef.value = bind(Handlers.loadConfig, httpService, config), bind(Handlers.saveConfig, config, httpService)
    loadConfig()
    config.immortality = false
    optimizationStateRef = {destroyParticles = nil, charAdded = nil, unlimitedKBPS = nil, noRender = nil}
    optimizationConnections = optimizationStateRef
    clearCloudsRef = {destroyParticles = false, unlimitedKBPS = false, noRender = false}
    optimizationStateRef = {value = clearCloudsRef}
    clearCloudsRef = {value = bind(Handlers.removeCloudsAndWaterEffects, lighting)}
    isVisualEffectRef = {value = bind(Handlers.isVisualEffect)}
    clearVisualEffectsRef = {value = bind(Handlers.clearVisualEffects, isVisualEffectRef, camera)}
    enableParticleCleanupRef = {
        value = bind(Handlers.enableParticleCleanup, optimizationConnections, localPlayerRef, isVisualEffectRef, optimizationStateRef, clearVisualEffectsRef, clearCloudsRef)
    }
    disableParticleCleanupRef = {value = bind(Handlers.disableParticleCleanup, optimizationStateRef, optimizationConnections)}
    enableNetworkOverrideRef = {value = bind(Handlers.enableNetworkRateOverride, optimizationStateRef, optimizationConnections, runService)}
    disableNetworkOverrideRef = {value = bind(Handlers.disableNetworkRateOverride, optimizationStateRef, optimizationConnections)}
    enableNoRenderRef = {value = bind(Handlers.enableNoRender, optimizationStateRef, localPlayerRef, optimizationConnections)}
    disableNoRenderRef = {value = bind(Handlers.disableNoRender, optimizationStateRef, localPlayerRef, optimizationConnections)}
    applyOptimizationRef = {value = applyOptimizationRef}
    applyOptimizationRef.value, watchParryStateRef = bind(Handlers.applyOptimization, disableNetworkOverrideRef, disableNoRenderRef, applyAppearanceRef, enableParticleCleanupRef, enableNetworkOverrideRef, disableParticleCleanupRef, enableNoRenderRef, localPlayerRef), config.optim
    parryCooldownRef, watchParryStateRef, ballTargetTimesRef = pairs(watchParryStateRef)
    parryCooldownRef, watchParryStateRef, ballTargetTimesRef = normalizeIterator(parryCooldownRef, watchParryStateRef, ballTargetTimesRef)
    for index2, item2 in parryCooldownRef, watchParryStateRef, ballTargetTimesRef do
        ballConnectionsRef, ballTargetedPlayerRef, ballTargetTimesRef = index2, item2, index2
        if ballTargetedPlayerRef then
            applyOptimizationRef.value(ballConnectionsRef, ballTargetedPlayerRef)
        end
    end
    ballConnectionsRef, ballTargetedPlayerRef, ballTargetTimesRef = nil, nil, nil
    watchParryStateRef = {failed_at = 0, duration = 2, last_parrying = nil, conn = nil}
    -- Parry cooldowns and ball tracking
    parryCooldownRef = {value = watchParryStateRef}
    watchParryStateRef = {value = watchParryStateRef}
    ballTargetTimesRef, watchParryStateRef.value = localPlayerRef.value.Character, bind(Handlers.watchCharacterParryState, parryCooldownRef)
    if ballTargetTimesRef then
        watchParryStateRef.value(localPlayerRef.value.Character)
    end
    ballTargetTimesRef, ballTargetedPlayerRef = localPlayerRef.value.CharacterAdded, bind(Handlers.updateCharacterParryWatcherSafely, watchParryStateRef)
    ballConnectionsRef, ballTargetTimesRef = ballTargetTimesRef, ballTargetTimesRef.Connect
    ballTargetTimesRef(ballConnectionsRef, ballTargetedPlayerRef)
    ballConnectionsRef = {}
    ballTargetTimesRef = {value = ballConnectionsRef}
    ballTargetedPlayerRef = {}
    ballConnectionsRef = {value = ballTargetedPlayerRef}
    ballTargetedPlayerRef = {value = false}
    ballPresentRef = {value = false}
    spamCountRef = {value = 0}
    swordOverrideEnabledRef = {value = false}
    swordOverrideNameRef = {value = ""}
    isPlayerAliveRef = {}
    spamHistory = isPlayerAliveRef
    ballSpeedStateRef, isPlayerAliveRef = bind(Handlers.expireSpamHistory, spamHistory, spamCountRef), task.spawn
    isPlayerAliveRef(ballSpeedStateRef)
    isPlayerAliveRef = {value = isPlayerAliveRef}
    isPlayerAliveRef.value, speedDisplayRef = bind(Handlers.isLocalPlayerAlive, localPlayerRef), {}
    speedDisplayRef.current = 0
    speedDisplayRef.peak = 0
    ballSpeedStateRef = {value = speedDisplayRef}
    speedDisplayRef = {value = nil}
    speedLabelRef = {value = nil}
    findBallRef = {value = bind(Handlers.findBall)}
    updateSpeedLabelRef = {value = bind(Handlers.updateBallSpeedLabel, speedLabelRef, ballSpeedStateRef, speedDisplayRef, findBallRef)}
    cachedPingRef, lastPingReadRef = task.spawn, bind(Handlers.watchPeakBallSpeed, config, ballSpeedStateRef)
    cachedPingRef(lastPingReadRef)
    lastPingReadRef, getPingRef, cachedPingRef = runService.RenderStepped, bind(Handlers.updateVisibleSpeedPanel, config, speedDisplayRef, updateSpeedLabelRef), runService.RenderStepped.Connect
    cachedPingRef(lastPingReadRef, getPingRef)
    cachedPingRef = {value = 100}
    lastPingReadRef = {value = 0}
    getPingRef = {value = getPingRef}
    getBallCurveStateRef, getPingRef.value = {}, bind(Handlers.getCachedPing, lastPingReadRef, stats, cachedPingRef)
    ballCurveStates = getBallCurveStateRef
    getBallCurveStateRef = {value = bind(Handlers.getBallCurveState, remoteBallPositions, ballTargetTimesRef, ballConnectionsRef, ballCurveStates)}
    isBallCurvingRef = {value = isBallCurvingRef}
    -- Sword modules and animation state
    isBallCurvingRef.value, swordControllerRef = bind(Handlers.isBallCurving, getBallCurveStateRef), swordApiRef.value
    swordControllerRef = {value = swordControllerRef}
    shopControllerApiRef = bind(Handlers.requireSwordApi, swordControllerRef, replicatedStorage)
    pcall(shopControllerApiRef)
    swordAnimationsRef = {value = nil}
    playerDataRef = bind(Handlers.requireSwordAnimations, swordAnimationsRef, replicatedStorage)
    pcall(playerDataRef)
    shopControllerApiRef = {value = nil}
    animationCacheRef = bind(Handlers.requireShopControllerApi, shopControllerApiRef, replicatedStorage)
    pcall(animationCacheRef)
    playerDataRef = {value = nil}
    stopAnimationRef = bind(Handlers.waitForPlayerData, replicatedStorage, playerDataRef)
    pcall(stopAnimationRef)
    stopAnimationRef, resolveParryAnimationRef = {}, {}
    stopAnimationRef.Cache = resolveParryAnimationRef
    animationCacheRef = {value = stopAnimationRef}
    stopAnimationRef = {value = bind(Handlers.stopAnimationTrack)}
    playAnimationRef = {value = bind(Handlers.playAnimationTrack, playerDataRef)}
    resolveParryAnimationRef = {value = bind(Handlers.resolveParryAnimation, swordControllerRef, animationCacheRef, swordApiRef, localPlayerRef, swordAnimationsRef)}
    parrySucceededRef = {value = false}
    animationBusyRef = {value = false}
    animationRecentlyPlayedRef = {value = false}
    lastM1StopRef = {value = false}
    isParryBlockedRef = {value = nil}
    playParryAnimationRef = {
        value = bind(Handlers.playParryAnimation, swordOverrideEnabledRef, resolveParryAnimationRef, shopControllerApiRef, stopAnimationRef, localPlayerRef, playAnimationRef, swordOverrideNameRef, swordApiRef, config, isParryBlockedRef)
    }
    tryParryAnimationRef = {
        value = bind(Handlers.tryPlayParryAnimation, animationBusyRef, playParryAnimationRef, parrySucceededRef, config, animationRecentlyPlayedRef, isParryBlockedRef, lastM1StopRef)
    }
    calculateCurveTargetRef = replicatedStorage.Shared.DebugFlags
    debugFlags = require(replicatedStorage.Shared.DebugFlags)
    isParryBlockedRef.value = bind(Handlers.isParryBlocked, localPlayerRef, debugFlags)
    calculateCurveTargetRef = {value = bind(Handlers.calculateCurveTarget, config, localPlayerRef)}
    temporary30 = packValues(replicatedStorage:FindFirstChild("PRY", true))
    result = require(unpackValues(temporary30))
    temporary30 = getupvalue(result, 3)
    temporary10 = getupvalue(result, 4)
    parryTransform = getupvalue(result, 8)
    parryCipher = temporary30[temporary30[1]]
    cipherKeyLengthRef = {}
    cipherKeyBytes = cipherKeyLengthRef
    cipherKeyLengthRef = {value = 0}
    cipherBufferRef = temporary10(parryCipher, "TIME")
    cipherKeyLengthRef.value, encodeTimestampRef = #cipherBufferRef, 1
    aimCacheRef = cipherKeyLengthRef.value
    if not (cipherKeyLengthRef.value ~= cipherKeyLengthRef.value) then
        if not (1 > cipherKeyLengthRef.value) then
            while true do
                parryRemoteRef = string.byte(cipherBufferRef, encodeTimestampRef)
                cipherKeyBytes[encodeTimestampRef] = parryRemoteRef
                encodeTimestampRef = encodeTimestampRef + 1
                if encodeTimestampRef > aimCacheRef then
                    break
                else
                    continue
                end
            end
        end
    end
    cipherBufferRef = table.create(24)
    cipherBufferRef = {value = cipherBufferRef}
    encodeTimestampRef = {value = bind(Handlers.encodeParryTimestamp, cipherKeyBytes, cipherKeyLengthRef, cipherBufferRef)}
    originalFireServerRef, refreshAimCacheRef = {}, {}
    refreshAimCacheRef.screen = originalFireServerRef
    originalFireServerRef = {}
    originalFireServerRef[2], originalFireServerRef[1] = 0, 0
    refreshAimCacheRef.aim = originalFireServerRef
    refreshAimCacheRef.cf = nil
    refreshAimCacheRef.lastRefresh = 0
    aimCacheRef = {value = refreshAimCacheRef}
    refreshAimCacheRef = {value = refreshAimCacheRef}
    refreshAimCacheRef.value, parryRemoteRef = bind(Handlers.refreshAimCache, aimCacheRef, camera, localPlayerRef), runService.PreSimulation
    parryRemoteRef, refreshAimIfEnabledRef, originalFireServerRef = parryRemoteRef.Connect, bind(Handlers.refreshAimIfEnabled, config, refreshAimCacheRef), parryRemoteRef
    parryRemoteRef(originalFireServerRef, refreshAimIfEnabledRef)
    parryRemoteRef = {value = nil}
    originalFireServerRef = {value = nil}
    trackedBallsRef = Instance.new("RemoteEvent")
    -- Gameplay event handlers
    sendParryRef, trackedBallsRef = trackedBallsRef.FireServer, bind(Handlers.interceptFireServer, parryRemoteRef, originalFireServerRef)
    refreshAimIfEnabledRef = hookfunction(sendParryRef, trackedBallsRef)
    originalFireServerRef.value = refreshAimIfEnabledRef
    refreshAimIfEnabledRef = {value = 0}
    sendParryRef = {value = sendParryRef}
    lastTriggerTimeRef, sendParryRef.value = {}, bind(Handlers.sendParry, {
        aimCacheRef = aimCacheRef,
        calculateCurveTargetRef = calculateCurveTargetRef,
        refreshAimIfEnabledRef = refreshAimIfEnabledRef,
        originalFireServerRef = originalFireServerRef,
        spamCountRef = spamCountRef,
        parryTransform = parryTransform,
        spamHistory = spamHistory,
        encodeTimestampRef = encodeTimestampRef,
        parryRemoteRef = parryRemoteRef,
        isParryBlockedRef = isParryBlockedRef,
        parryCipher = parryCipher,
        refreshAimCacheRef = refreshAimCacheRef,
        camera = camera
    })
    trackedBallsRef = {value = lastTriggerTimeRef}
    lastTriggerTimeRef = {value = 0}
    trackBallRef = {value = bind(Handlers.trackBall, trackedBallsRef)}
    tryUseAbilityRef = task.spawn
    onBallFrameRef = bind(Handlers.runTriggerLoop, playParryAnimationRef, lastTriggerTimeRef, sendParryRef, trackedBallsRef, config)
    tryUseAbilityRef(onBallFrameRef)
    tryUseAbilityRef = {value = bind(Handlers.tryUseAbility, parryCooldownRef, ballTargetedPlayerRef, replicatedStorage, config, ballPresentRef)}
    onBallFrameRef, trySpamParryRef = task.spawn, bind(Handlers.runAbilityLoop, ballPresentRef, parryRemoteRef, tryUseAbilityRef, config, ballTargetedPlayerRef)
    onBallFrameRef(trySpamParryRef)
    onBallFrameRef = {
        value = bind(Handlers.onTrackedBallFrame, {
            localPlayerRef = localPlayerRef,
            debris = debris,
            isBallCurvingRef = isBallCurvingRef,
            remoteConnections = remoteBallPositions,
            trackBallRef = trackBallRef,
            getPingRef = getPingRef,
            ballTargetTimesRef = ballTargetTimesRef,
            getBallCurveStateRef = getBallCurveStateRef,
            config = config,
            ballTargetedPlayerRef = ballTargetedPlayerRef,
            ballCurveStates = ballCurveStates,
            ballPresentRef = ballPresentRef
        })
    }
    trySpamParryRef = {
        value = bind(Handlers.trySpamParry, localPlayerRef, remoteBallPositions, spamCountRef, config, isPlayerAliveRef, ballPresentRef, getPingRef)
    }
    watchBallTargetRef = task.spawn
    watchBallPresenceRef = bind(Handlers.watchBallPresence, ballPresentRef)
    watchBallTargetRef(watchBallPresenceRef)
    watchBallTargetRef = {
        value = bind(Handlers.watchBallTarget, localPlayerRef, trackBallRef, ballCurveStates, config, ballPresentRef, ballTargetedPlayerRef, ballConnectionsRef)
    }
    watchBallPresenceRef = {value = 0}
    immortalityTransformRef, immortalityHookEnabledRef = runService.PreSimulation, bind(Handlers.onPreSimulation, parryRemoteRef, isPlayerAliveRef, sendParryRef, ballPresentRef, ballTargetedPlayerRef, config, watchBallPresenceRef, tryParryAnimationRef)
    originalIndexRef, immortalityTransformRef = immortalityTransformRef, immortalityTransformRef.Connect
    immortalityTransformRef(originalIndexRef, immortalityHookEnabledRef)
    immortalityTransformRef, originalIndexRef = task.spawn, bind(Handlers.runAutoParryLoop, watchBallTargetRef, trySpamParryRef, onBallFrameRef, parryRemoteRef, ballTargetedPlayerRef, config)
    immortalityTransformRef(originalIndexRef)
    immortalityHookEnabledRef, immortalityTransformRef = bind(Handlers.onParrySucceeded, parrySucceededRef, shopControllerApiRef, stopAnimationRef, config, animationBusyRef, animationRecentlyPlayedRef, localPlayerRef), replicatedStorage.Remotes.ParrySuccess.OnClientEvent
    immortalityTransformRef, originalIndexRef = immortalityTransformRef.Connect, immortalityTransformRef
    immortalityTransformRef(originalIndexRef, immortalityHookEnabledRef)
    originalIndexRef = bind(Handlers.connectM1StopEvent, replicatedStorage, lastM1StopRef)
    pcall(originalIndexRef)
    originalIndexRef = {}
    originalIndexRef.CFrame = nil
    originalIndexRef.Velocity = nil
    immortalityTransformRef = {value = originalIndexRef}
    updateImmortalityTransformRef, originalIndexRef = bind(Handlers.updateImmortalityTransform, runService, localPlayerRef, immortalityTransformRef, config), runService.Heartbeat
    immortalityHookEnabledRef, originalIndexRef = originalIndexRef, originalIndexRef.Connect
    originalIndexRef(immortalityHookEnabledRef, updateImmortalityTransformRef)
    immortalityHookEnabledRef = getrawmetatable(game)
    originalIndexRef = {value = immortalityHookEnabledRef.__index}
    immortalityHookEnabledRef = {value = false}
    setImmortalityHookRef = bind(Handlers.readImmortalityProperty, originalIndexRef, localPlayerRef, immortalityTransformRef, config)
    updateImmortalityTransformRef = newcclosure(setImmortalityHookRef)
    updateImmortalityTransformRef = {value = updateImmortalityTransformRef}
    setImmortalityHookRef = {value = setImmortalityHookRef}
    -- Floating control panels
    setImmortalityHookRef.value, screenGuiRef = bind(Handlers.setImmortalityHookEnabled, immortalityHookEnabledRef, updateImmortalityTransformRef, originalIndexRef), config.immortality
    if screenGuiRef then
        setImmortalityHookRef.value(true)
    end
    screenGuiRef = Instance.new("ScreenGui")
    screenGuiRef = {value = screenGuiRef}
    coreGui = game:FindFirstChild("CoreGui")
    if coreGui then
        accentColorRef = bind(Handlers.parentScreenGui, screenGuiRef, coreGui)
        pcall(accentColorRef)
    end
    if not screenGuiRef.value.Parent then
        makeDraggableRef = localPlayerRef.value:WaitForChild("PlayerGui")
        screenGuiRef.value.Parent = makeDraggableRef
    end
    screenGuiRef.value.ResetOnSpawn = false
    makeDraggableRef = {value = bind(Handlers.makeDraggable, dragConnectionsRef, userInputService, defaultPositionsRef, config, runService)}
    accentColorRef = Color3.fromRGB(255, 140, 0)
    accentColorRef = {value = accentColorRef}
    backgroundColor = Color3.fromRGB(30, 30, 30)
    textColor = Color3.fromRGB(255, 255, 255)
    mutedTextColor = Color3.fromRGB(130, 130, 130)
    createFloatingButton = bind(Handlers.createFloatingButton, backgroundColor, accentColorRef, tweenService)
    styleFloatingButtonRef = {value = bind(Handlers.styleFloatingButton, backgroundColor, accentColorRef, textColor, tweenService)}
    spamPanel = Instance.new("Frame", screenGuiRef.value)
    spamButtonRef = UDim2.new(0, 130, 0, 60)
    spamPanel.Size = spamButtonRef
    spamPanel.Position = defaultPositionsRef.value.MainFrame
    spamButtonRef = Color3.fromRGB(20, 20, 20)
    spamPanel.BackgroundColor3 = spamButtonRef
    spamPanel.BackgroundTransparency = 0.25
    spamButtonRef = Instance.new("UICorner", spamPanel)
    spamStroke = UDim.new(0, 10)
    spamButtonRef.CornerRadius = spamStroke
    spamButtonRef = Instance.new("UIStroke", spamPanel)
    spamButtonRef.Color = accentColorRef.value
    makeDraggableRef.value(spamPanel, nil, "MainFrame")
    spamButtonRef, spamStroke, spamLabel = createFloatingButton(spamPanel, "SPAM")
    spamButtonRef = {value = spamButtonRef}
    triggerPanel = Instance.new("Frame", screenGuiRef.value)
    triggerButtonRef = UDim2.new(0, 130, 0, 60)
    triggerPanel.Size = triggerButtonRef
    triggerPanel.Position = defaultPositionsRef.value.TBFrame
    triggerButtonRef = Color3.fromRGB(20, 20, 20)
    triggerPanel.BackgroundColor3 = triggerButtonRef
    triggerPanel.BackgroundTransparency = 0.25
    triggerButtonRef = Instance.new("UICorner", triggerPanel)
    triggerLabel = UDim.new(0, 10)
    triggerButtonRef.CornerRadius = triggerLabel
    triggerButtonRef = Instance.new("UIStroke", triggerPanel)
    triggerButtonRef.Color = accentColorRef.value
    makeDraggableRef.value(triggerPanel, nil, "TBFrame")
    triggerPanel.Visible = false
    triggerButtonRef, triggerLabel, triggerStroke = createFloatingButton(triggerPanel, "TRIGGER")
    triggerButtonRef = {value = triggerButtonRef}
    immortalityPanel = Instance.new("Frame", screenGuiRef.value)
    immortalityButtonRef = UDim2.new(0, 130, 0, 60)
    immortalityPanel.Size = immortalityButtonRef
    immortalityPanel.Position = defaultPositionsRef.value.ImmFrame
    immortalityButtonRef = Color3.fromRGB(20, 20, 20)
    immortalityPanel.BackgroundColor3 = immortalityButtonRef
    immortalityPanel.BackgroundTransparency = 0.25
    immortalityButtonRef = Instance.new("UICorner", immortalityPanel)
    immortalityLabel = UDim.new(0, 10)
    immortalityButtonRef.CornerRadius = immortalityLabel
    immortalityButtonRef = Instance.new("UIStroke", immortalityPanel)
    immortalityButtonRef.Color = accentColorRef.value
    makeDraggableRef.value(immortalityPanel, nil, "ImmFrame")
    immortalityPanel.Visible = false
    immortalityButtonRef, immortalityLabel, immortalityStroke = createFloatingButton(immortalityPanel, "IMMORTAL")
    immortalityButtonRef = {value = immortalityButtonRef}
    fpsPanelRef = Instance.new("Frame", screenGuiRef.value)
    speedDisplayRef.value = fpsPanelRef
    fpsPanelRef = UDim2.new(0, 160, 0, 40)
    speedDisplayRef.value.Size = fpsPanelRef
    speedDisplayRef.value.Position = defaultPositionsRef.value.statsFrame
    fpsPanelRef = Color3.fromRGB(20, 20, 20)
    speedDisplayRef.value.BackgroundColor3 = fpsPanelRef
    speedDisplayRef.value.BackgroundTransparency = 0.25
    fpsPanelRef = Instance.new("UICorner", speedDisplayRef.value)
    fpsLabelRef = UDim.new(0, 10)
    fpsPanelRef.CornerRadius = fpsLabelRef
    fpsPanelRef = Instance.new("UIStroke", speedDisplayRef.value)
    fpsPanelRef.Color = accentColorRef.value
    makeDraggableRef.value(speedDisplayRef.value, nil, "statsFrame")
    speedDisplayRef.value.Visible = false
    fpsPanelRef = Instance.new("TextLabel", speedDisplayRef.value)
    speedLabelRef.value = fpsPanelRef
    fpsPanelRef = UDim2.new(1, -10, 1, -10)
    speedLabelRef.value.Size = fpsPanelRef
    fpsPanelRef = UDim2.new(0, 5, 0, 5)
    speedLabelRef.value.Position = fpsPanelRef
    speedLabelRef.value.BackgroundTransparency = 1
    speedLabelRef.value.Text = "\226\154\161 0.0 | \240\159\147\136 0.0"
    fpsPanelRef = Color3.fromRGB(255, 200, 100)
    speedLabelRef.value.TextColor3 = fpsPanelRef
    speedLabelRef.value.Font = Enum.Font.GothamBold
    speedLabelRef.value.TextSize = 12
    fpsPanelRef = Instance.new("Frame", screenGuiRef.value)
    fpsPanelRef = {value = fpsPanelRef}
    fpsLabelRef = UDim2.new(0, 150, 0, 26)
    fpsPanelRef.value.Size = fpsLabelRef
    fpsPanelRef.value.Position = defaultPositionsRef.value.fpsFrame
    fpsLabelRef = Color3.fromRGB(20, 20, 20)
    fpsPanelRef.value.BackgroundColor3 = fpsLabelRef
    fpsPanelRef.value.BackgroundTransparency = 0.25
    fpsLabelRef = Instance.new("UICorner", fpsPanelRef.value)
    positionRef = UDim.new(0, 8)
    fpsLabelRef.CornerRadius = positionRef
    fpsLabelRef = Instance.new("UIStroke", fpsPanelRef.value)
    fpsLabelRef.Color = accentColorRef.value
    makeDraggableRef.value(fpsPanelRef.value, nil, "fpsFrame")
    fpsPanelRef.value.Visible = false
    fpsLabelRef = Instance.new("TextLabel", fpsPanelRef.value)
    fpsLabelRef = {value = fpsLabelRef}
    positionRef = UDim2.new(1, -10, 1, -6)
    fpsLabelRef.value.Size = positionRef
    positionRef = UDim2.new(0, 5, 0, 3)
    fpsLabelRef.value.Position = positionRef
    fpsLabelRef.value.BackgroundTransparency = 1
    fpsLabelRef.value.Text = "FPS: 0 | PING: 0 ms"
    positionRef = Color3.fromRGB(255, 200, 100)
    fpsLabelRef.value.TextColor3 = positionRef
    fpsLabelRef.value.Font = Enum.Font.GothamBold
    fpsLabelRef.value.TextSize = 11
    fpsLabelRef.value.TextXAlignment = Enum.TextXAlignment.Center
    positionRef = {value = 120}
    curveOptionsOpenRef, curveDropdownButtonRef2 = runService.RenderStepped, bind(Handlers.updateFpsAndPingLabel, getPingRef, positionRef, fpsLabelRef, fpsPanelRef)
    curveOptionsPanelRef2, curveOptionsOpenRef = curveOptionsOpenRef, curveOptionsOpenRef.Connect
    curveOptionsOpenRef(curveOptionsPanelRef2, curveDropdownButtonRef2)
    curveOptionsOpenRef = {value = nil}
    curveOptionsPanelRef2 = {value = nil}
    curveDropdownButtonRef2 = {value = nil}
    curvePanelOpenRef = {value = false}
    selectedCurveRef = config.curveType or "straight"
    selectedCurveRef = {value = selectedCurveRef}
    curveOptions = {}
    curveRows = curveOptions
    refreshCurvePanelRef = {}
    refreshCurvePanelRef[7], refreshCurvePanelRef[8], refreshCurvePanelRef[2], refreshCurvePanelRef[4], refreshCurvePanelRef[5], refreshCurvePanelRef[3], refreshCurvePanelRef[6], refreshCurvePanelRef[1] = "right", "random", "dot", "up", "down", "backwards", "left", "straight"
    curveOptions = refreshCurvePanelRef
    refreshCurvePanelRef = {
        value = bind(Handlers.refreshCurveWindow, curveRows, textColor, accentColorRef, curveDropdownButtonRef2, curveOptionsPanelRef2, selectedCurveRef, tweenService)
    }
    buildCurveWindow = bind(Handlers.buildCurveWindow, {
        accentColorRef = accentColorRef,
        selectedCurveRef = selectedCurveRef,
        saveConfigRef = saveConfigRef,
        makeDraggableRef = makeDraggableRef,
        config = config,
        refreshCurvePanelRef = refreshCurvePanelRef,
        curvePanelOpenRef = curvePanelOpenRef,
        curveOptionsPanelRef = curveOptionsPanelRef2,
        curveOptionsOpenRef = curveOptionsOpenRef,
        screenGuiRef = screenGuiRef,
        curveOptions = curveOptions,
        defaultPositionsRef = defaultPositionsRef,
        curveDropdownButtonRef = curveDropdownButtonRef2,
        curveRows = curveRows
    })
    buildCurveWindow()
    keybindPanelRef = {value = nil}
    keyOptionsPopupRef = {value = nil}
    keyCaptureActiveRef = {value = false}
    pendingKeybindRef = {value = nil}
    keybindPanelOpenRef = {value = false}
    saveKeybindsRef = {}
    saveKeybindsRef.spam = Enum.KeyCode.P
    saveKeybindsRef.trigger = Enum.KeyCode.T
    curveKeyRowsRef = {}
    saveKeybindsRef.curve = curveKeyRowsRef
    keybinds = saveKeybindsRef
    saveKeybindsRef = _G._417_savedBinds
    if _G._417_savedBinds then
        saveKeybindsRef, keyOptionRowsRef = _G._417_savedBinds, bind(Handlers.parseSavedKeyCode, unboundKey)
        curveKeyRowsRef = keyOptionRowsRef(saveKeybindsRef.spam)
        if curveKeyRowsRef then
            keybinds.spam = curveKeyRowsRef
        end
        spamKeyButtonRef = keyOptionRowsRef(saveKeybindsRef.trigger)
        if spamKeyButtonRef then
            keybinds.trigger = spamKeyButtonRef
        end
        triggerKeyButtonRef = type(saveKeybindsRef.curve)
        if triggerKeyButtonRef == "table" then
            triggerKeyButtonRef, curveDropdownButtonRef, curveOptionsPanelRef = pairs(saveKeybindsRef.curve)
            triggerKeyButtonRef, curveDropdownButtonRef, curveOptionsPanelRef = normalizeIterator(triggerKeyButtonRef, curveDropdownButtonRef, curveOptionsPanelRef)
            for index3, item3 in triggerKeyButtonRef, curveDropdownButtonRef, curveOptionsPanelRef do
                refreshKeybindPanelRef, beginKeyCaptureRef, curveOptionsPanelRef = index3, item3, index3
                resetFramePositionsRef = type(beginKeyCaptureRef)
                if resetFramePositionsRef ~= "string" then
                    unboundKey2 = nil
                else
                    resetFramePositionsRef = beginKeyCaptureRef == "NONE" or beginKeyCaptureRef == "None"
                    if resetFramePositionsRef then
                        unboundKey2 = unboundKey
                    else
                        unboundKey2 = Enum.KeyCode[beginKeyCaptureRef]
                    end
                end
                if unboundKey2 then
                    keybinds.curve[refreshKeybindPanelRef] = unboundKey2
                end
            end
            refreshKeybindPanelRef, beginKeyCaptureRef, curveOptionsPanelRef = nil, nil, nil
        end
    end
    saveKeybindsRef = {value = saveKeybindsRef}
    curveKeyRowsRef, saveKeybindsRef.value = {}, bind(Handlers.saveKeybinds, keybinds, saveConfigRef)
    keyOptionRowsRef = {value = curveKeyRowsRef}
    spamKeyButtonRef = {}
    curveKeyRowsRef = {value = spamKeyButtonRef}
    spamKeyButtonRef = {value = nil}
    triggerKeyButtonRef = {value = nil}
    curveDropdownButtonRef = {value = nil}
    curveOptionsPanelRef = {value = nil}
    refreshKeybindPanelRef = {
        value = bind(Handlers.refreshKeybindingWindow, {
            textColor = textColor,
            triggerKeyButtonRef = triggerKeyButtonRef,
            keybindPanelOpenRef = keybindPanelOpenRef,
            tweenService = tweenService,
            keyOptionRowsRef = keyOptionRowsRef,
            curveDropdownButtonRef = curveDropdownButtonRef,
            pendingKeybindRef = pendingKeybindRef,
            curveKeyRowsRef = curveKeyRowsRef,
            spamKeyButtonRef = spamKeyButtonRef,
            keybinds = keybinds,
            config = config,
            selectedKey = unboundKey,
            mutedTextColor = mutedTextColor,
            accentColorRef = accentColorRef
        })
    }
    beginKeyCaptureRef = {
        value = bind(Handlers.beginKeybindCapture, keybindPanelRef, keyCaptureActiveRef, refreshKeybindPanelRef, pendingKeybindRef, keyOptionsPopupRef)
    }
    unboundKey2 = bind(Handlers.buildKeybindingWindow, {
        accentColorRef = accentColorRef,
        keybinds = keybinds,
        keybindPanelOpenRef = keybindPanelOpenRef,
        curveOptionsPanelRef = curveOptionsPanelRef,
        triggerKeyButtonRef = triggerKeyButtonRef,
        tweenService = tweenService,
        saveKeybindsRef = saveKeybindsRef,
        keyOptionsPopupRef = keyOptionsPopupRef,
        keybindPanelRef = keybindPanelRef,
        keyCaptureActiveRef = keyCaptureActiveRef,
        textColor = textColor,
        pendingKeybindRef = pendingKeybindRef,
        curveKeyRowsRef = curveKeyRowsRef,
        makeDraggableRef = makeDraggableRef,
        curveOptions = curveOptions,
        spamKeyButtonRef = spamKeyButtonRef,
        keyOptionRowsRef = keyOptionRowsRef,
        beginKeyCaptureRef = beginKeyCaptureRef,
        refreshKeybindPanelRef = refreshKeybindPanelRef,
        selectedKey = unboundKey,
        screenGuiRef = screenGuiRef,
        defaultPositionsRef = defaultPositionsRef,
        curveDropdownButtonRef = curveDropdownButtonRef,
        mutedTextColor = mutedTextColor
    })
    unboundKey2()
    resetFramePositionsRef3, onKeybindInputBeganRef = userInputService.InputBegan, bind(Handlers.onKeybindInputBegan, {
        ballTargetedPlayerRef = ballTargetedPlayerRef,
        spamButtonRef = spamButtonRef,
        triggerLabel = triggerLabel,
        selectedCurveRef = selectedCurveRef,
        triggerStroke = triggerStroke,
        triggerButtonRef = triggerButtonRef,
        saveConfigRef = saveConfigRef,
        httpService = httpService,
        parryRemoteRef = parryRemoteRef,
        keybinds = keybinds,
        spamLabel = spamLabel,
        selectedKey = unboundKey,
        refreshKeybindPanelRef = refreshKeybindPanelRef,
        config = config,
        refreshCurvePanelRef = refreshCurvePanelRef,
        styleFloatingButtonRef = styleFloatingButtonRef,
        spamStroke = spamStroke
    })
    resetFramePositionsRef, resetFramePositionsRef3 = resetFramePositionsRef3, resetFramePositionsRef3.Connect
    resetFramePositionsRef3(resetFramePositionsRef, onKeybindInputBeganRef)
    onKeybindInputBeganRef, resetFramePositionsRef3 = bind(Handlers.toggleSpam, styleFloatingButtonRef, spamLabel, spamButtonRef, parryRemoteRef, ballTargetedPlayerRef, spamStroke), spamButtonRef.value.MouseButton1Click
    resetFramePositionsRef, resetFramePositionsRef3 = resetFramePositionsRef3, resetFramePositionsRef3.Connect
    resetFramePositionsRef3(resetFramePositionsRef, onKeybindInputBeganRef)
    onKeybindInputBeganRef, resetFramePositionsRef3 = bind(Handlers.toggleTrigger, styleFloatingButtonRef, triggerStroke, saveConfigRef, parryRemoteRef, config, triggerLabel, triggerButtonRef), triggerButtonRef.value.MouseButton1Click
    resetFramePositionsRef, resetFramePositionsRef3 = resetFramePositionsRef3, resetFramePositionsRef3.Connect
    resetFramePositionsRef3(resetFramePositionsRef, onKeybindInputBeganRef)
    onKeybindInputBeganRef, resetFramePositionsRef3 = bind(Handlers.toggleImmortality, styleFloatingButtonRef, immortalityStroke, saveConfigRef, parryRemoteRef, config, immortalityLabel, immortalityButtonRef, setImmortalityHookRef), immortalityButtonRef.value.MouseButton1Click
    resetFramePositionsRef, resetFramePositionsRef3 = resetFramePositionsRef3, resetFramePositionsRef3.Connect
    resetFramePositionsRef3(resetFramePositionsRef, onKeybindInputBeganRef)
    styleFloatingButtonRef.value(ballTargetedPlayerRef.value, spamButtonRef.value, spamStroke, spamLabel)
    styleFloatingButtonRef.value(config.trigger, triggerButtonRef.value, triggerLabel, triggerStroke)
    immortalityStrokeRef2 = immortalityStroke
    styleFloatingButtonRef.value(config.immortality, immortalityButtonRef.value, immortalityLabel, immortalityStroke)
    resetFramePositionsRef2 = {}
    resetFramePositionsRef2, resetFramePositionsRef3 = {}, resetFramePositionsRef2
    resetFramePositionsRef2, resetFramePositionsRef = {}, resetFramePositionsRef2
    resetFramePositionsRef3 = {value = resetFramePositionsRef3}
    resetFramePositionsRef = {value = resetFramePositionsRef}
    onKeybindInputBeganRef = {value = resetFramePositionsRef2}
    resetFramePositionsRef2 = {value = bind(Handlers.resetFramePositions, config, dragConnectionsRef, saveConfigRef)}
    immortalityStrokeRef2 = {value = bind(Handlers.refreshSettingsControls, config, resetFramePositionsRef, onKeybindInputBeganRef, resetFramePositionsRef3)}
    resetConfigDefaultsRef = {value = bind(Handlers.resetConfigDefaults, refreshKeybindPanelRef, keybinds, refreshCurvePanelRef, config, selectedCurveRef)}
    applySavedUiStateRef = {
        value = bind(Handlers.applySavedUiState, {
            spamPanel = spamPanel,
            selectedCurveRef = selectedCurveRef,
            spamLabel = spamLabel,
            ballTargetedPlayerRef = ballTargetedPlayerRef,
            applyOptimizationRef = applyOptimizationRef,
            curveOptionsPanelRef = curveOptionsPanelRef2,
            immortalityLabel = immortalityLabel,
            triggerButtonRef = triggerButtonRef,
            speedDisplayRef = speedDisplayRef,
            triggerStroke = triggerStroke,
            keybindPanelRef = keybindPanelRef,
            immortalityButtonRef = immortalityButtonRef,
            spamButtonRef = spamButtonRef,
            immortalityStroke = immortalityStroke,
            styleFloatingButtonRef = styleFloatingButtonRef,
            setImmortalityHookRef = setImmortalityHookRef,
            refreshCurvePanelRef = refreshCurvePanelRef,
            keyCaptureActiveRef = keyCaptureActiveRef,
            spamStroke = spamStroke,
            curveOptionsOpenRef = curveOptionsOpenRef,
            config = config,
            fpsPanelRef = fpsPanelRef,
            pendingKeybindRef = pendingKeybindRef,
            curvePanelOpenRef = curvePanelOpenRef,
            refreshKeybindPanelRef = refreshKeybindPanelRef,
            keyOptionsPopupRef = keyOptionsPopupRef,
            triggerPanel = triggerPanel,
            immortalityPanel = immortalityPanel,
            triggerLabel = triggerLabel
        })
    }
    deleteConfigAndResetRef = {value = bind(Handlers.deleteConfigAndReset, applySavedUiStateRef, resetFramePositionsRef2, immortalityStrokeRef2, resetConfigDefaultsRef)}
    -- Cosmetic controller and shop integration
    cosmeticsRef, initializeCosmeticsSafely2 = {}, {}
    cosmeticsRef.parry_connections = initializeCosmeticsSafely2
    initializeCosmeticsSafely2 = {}
    cosmeticsRef.fire_sword_connections = initializeCosmeticsSafely2
    cosmeticsRef.play_parry = nil
    cosmeticsRef.sword_fn = nil
    cosmetics2 = cosmeticsRef
    cosmeticsRef = replicatedStorage:WaitForChild("Remotes", 15)
    setSwordOverrideRef = cosmeticsRef and cosmeticsRef:WaitForChild("ParrySuccessAll", 10)
    initializeCosmeticsSafely2 = setSwordOverrideRef
    if setSwordOverrideRef then
        initializeCosmeticsSafely4 = type(getconnections)
        initializeCosmeticsSafely2 = initializeCosmeticsSafely4 == "function"
    end
    if initializeCosmeticsSafely2 then
        initializeCosmeticsSafely2, initializeCosmeticsSafely4 = pcall(getconnections, setSwordOverrideRef.OnClientEvent)
        initializeCosmeticsSafely3 = initi
... (556 KB left)
