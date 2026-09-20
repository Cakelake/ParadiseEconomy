print("========================================")
print("JIMOLEON ATM SYSTEM")
print("========================================")


--------------------------------------------------
-- SUPPORTED ATM TILE NAMES
--------------------------------------------------

local glytch3rATMTiles = {
    ["location_business_bank_01_64"] = true,
    ["location_business_bank_01_65"] = true,
    ["location_business_bank_01_66"] = true,
    ["location_business_bank_01_67"] = true
}


--------------------------------------------------
-- GET ATM SPRITE NAME
--------------------------------------------------

local function getSpriteName(worldObject)

    if worldObject == nil then
        return nil
    end

    local sprite = worldObject:getSprite()

    if sprite == nil then
        return nil
    end

    return sprite:getName()

end


--------------------------------------------------
-- CHECK FOR SUPPORTED ATM
--------------------------------------------------

local function isSupportedGlytch3rATM(worldObject)

    if worldObject == nil then
        return false
    end

    local spriteName = getSpriteName(worldObject)

    if spriteName == nil then
        return false
    end

    return glytch3rATMTiles[spriteName] == true

end


--------------------------------------------------
-- APPLY JIMOLEON PROTECTION
--------------------------------------------------
--
-- Protection only applies if Functional_ATMs4
-- has already converted this ATM.
--
--------------------------------------------------

local function protectATM(atm)

    if atm == nil then
        return
    end

    local modData = atm:getModData()

    if modData == nil then
        return
    end

    if modData['atm4Converted'] ~= true then
        return
    end


    --------------------------------------------------
    -- STOP DISMANTLING
    --------------------------------------------------

    if atm.setIsDismantable ~= nil then
        atm:setIsDismantable(false)
    end


    --------------------------------------------------
    -- STOP ZOMBIES FROM THUMPING ATM
    --------------------------------------------------

    if atm.setIsThumpable ~= nil then
        atm:setIsThumpable(false)
    end


    --------------------------------------------------
    -- VERY HIGH HEALTH
    --------------------------------------------------

    if atm.setMaxHealth ~= nil then
        atm:setMaxHealth(2147483647)
    end

    if atm.setHealth ~= nil then
        atm:setHealth(2147483647)
    end


    --------------------------------------------------
    -- KEEP ATM BLOCKING
    --------------------------------------------------

    if atm.setBlockAllTheSquare ~= nil then
        atm:setBlockAllTheSquare(true)
    end

    if atm.setCanPassThrough ~= nil then
        atm:setCanPassThrough(false)
    end


    --------------------------------------------------
    -- JIMOLEON MARKER
    --------------------------------------------------

    modData['JimmoleonProtectedATM'] = true

end


--------------------------------------------------
-- OPEN JIMOLEON BANK
--------------------------------------------------

local function openBank(worldObject, playerNum)

    local player = getSpecificPlayer(playerNum)

    if player == nil then

        print(
            "JIMOLEON ERROR: Player not found."
        )

        return

    end


    --------------------------------------------------
    -- MAKE SURE THIS IS A SUPPORTED ATM
    --------------------------------------------------

    if not isSupportedGlytch3rATM(worldObject) then

        player:setHaloNote(
            "This is not a supported ATM.",
            1,
            0,
            0,
            300
        )

        print(
            "JIMOLEON ERROR: Unsupported ATM."
        )

        return

    end


    --------------------------------------------------
    -- PROTECT IF ALREADY CONVERTED
    --------------------------------------------------

    protectATM(worldObject)


    --------------------------------------------------
    -- POWER CHECK ONLY FOR ALREADY-CONVERTED ATM
    --------------------------------------------------
    --
    -- We do NOT convert the ATM here.
    --
    --------------------------------------------------

    if FunctionalATMs4 ~= nil
    and FunctionalATMs4.isFunctionalATM ~= nil
    then

        if FunctionalATMs4.isFunctionalATM(worldObject) then

            if FunctionalATMs4.isPowerOff ~= nil then

                if FunctionalATMs4.isPowerOff(worldObject) then

                    player:setHaloNote(
                        "ATM requires power.",
                        1,
                        0,
                        0,
                        300
                    )

                    return

                end

            end

        end

    end


    --------------------------------------------------
    -- OPEN JIMOLEON ECONOMY
    --------------------------------------------------

    if JimmoleonBankUI ~= nil then

        JimmoleonBankUI.open(
            player
        )

    else

        print(
            "JIMOLEON ERROR: Bank UI not loaded."
        )

    end

end


--------------------------------------------------
-- RIGHT-CLICK CONTEXT MENU
--------------------------------------------------

local function onFillWorldObjectContextMenu(
    playerNum,
    context,
    worldObjects,
    test
)

    if test then
        return
    end

    if context == nil then
        return
    end

    if worldObjects == nil then
        return
    end


    --------------------------------------------------
    -- FIND SUPPORTED ATM
    --------------------------------------------------

    for _, worldObject in ipairs(worldObjects) do

        if isSupportedGlytch3rATM(worldObject) then


            --------------------------------------------------
            -- PROTECT CONVERTED ATM
            --------------------------------------------------

            protectATM(
                worldObject
            )


            --------------------------------------------------
            -- ADD JIMOLEON BANK
            --------------------------------------------------

            local option =
                context:addOptionOnTop(
                    "JIMOLEON BANK",
                    worldObject,
                    openBank,
                    playerNum
                )


            --------------------------------------------------
            -- ATM ICON
            --------------------------------------------------

            local atmIcon =
                getTexture(
                    "media/textures/ui/atm4.png"
                )

            if atmIcon ~= nil then

                option.iconTexture =
                    atmIcon

            end


            --------------------------------------------------
            -- ONLY DISABLE OPTION WHEN AN EXISTING
            -- FUNCTIONAL_ATMS4 ATM IS POWERED OFF
            --------------------------------------------------

            if FunctionalATMs4 ~= nil
            and FunctionalATMs4.isFunctionalATM ~= nil
            then

                if FunctionalATMs4.isFunctionalATM(
                    worldObject
                ) then

                    if FunctionalATMs4.isPowerOff ~= nil then

                        if FunctionalATMs4.isPowerOff(
                            worldObject
                        ) then

                            option.notAvailable = true

                        end

                    end

                end

            end


            break

        end

    end

end


--------------------------------------------------
-- REGISTER JIMOLEON BANK MENU
--------------------------------------------------

Events.OnFillWorldObjectContextMenu.Remove(
    onFillWorldObjectContextMenu
)

Events.OnFillWorldObjectContextMenu.Add(
    onFillWorldObjectContextMenu
)


--------------------------------------------------
-- STARTUP MESSAGE
--------------------------------------------------

print(
    "JIMOLEON ATM: EVENT REGISTERED"
)