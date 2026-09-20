print("========================================")
print("JIMOLEON ATM PLACEMENT SERVER LOADED")
print("========================================")


--------------------------------------------------
-- ALLOWED GLYTCH3R ATM SPRITES
--------------------------------------------------

local allowedATMSprites = {

    ["location_business_bank_01_64"] = true,
    ["location_business_bank_01_65"] = true,
    ["location_business_bank_01_66"] = true,
    ["location_business_bank_01_67"] = true

}


--------------------------------------------------
-- CHECK WHETHER SQUARE ALREADY HAS AN ATM
--------------------------------------------------

local function squareHasATM(
    square
)

    if square == nil then
        return false
    end


    for i = 0, square:getObjects():size() - 1 do

        local object =
            square:getObjects():get(i)


        if object ~= nil then

            local modData =
                object:getModData()


            if modData ~= nil
            and modData["atm4Converted"] == true
            then

                return true

            end

        end

    end


    return false

end


--------------------------------------------------
-- CREATE GLYTCH3R ATM
--------------------------------------------------

local function createGlytch3rATM(
    player,
    square,
    spriteName
)

    if square == nil then
        return
    end


    --------------------------------------------------
    -- MAKE SURE GLYTCH3R EXISTS
    --------------------------------------------------

    if FunctionalATMs4 == nil then

        print(
            "JIMOLEON ERROR: FunctionalATMs4 not loaded."
        )

        return

    end


    --------------------------------------------------
    -- MAKE SURE SPRITE IS ALLOWED
    --------------------------------------------------

    if allowedATMSprites[spriteName] ~= true then

        print(
            "JIMOLEON ERROR: Invalid ATM sprite requested: " ..
            tostring(
                spriteName
            )
        )

        return

    end


    --------------------------------------------------
    -- PREVENT DUPLICATE ATM
    --------------------------------------------------

    if squareHasATM(
        square
    ) then

        player:setHaloNote(
            "There is already a Jimmoleon ATM here.",
            1.0,
            0.0,
            0.0,
            300
        )

        return

    end


    --------------------------------------------------
    -- CREATE THE ATM USING GLYTCH3R'S OBJECT TYPE
    --------------------------------------------------

    local atm =
        IsoThumpable.new(
            getCell(),
            square,
            spriteName,
            false,
            ISWoodenContainer:new(
                spriteName,
                nil
            )
        )


    atm:setSprite(
        spriteName
    )


    atm:getSprite():setName(
        spriteName
    )


    --------------------------------------------------
    -- GLYTCH3R ATM SETTINGS
    --------------------------------------------------

    atm:setIsThumpable(
        true
    )


    atm:setIsContainer(
        true
    )


    atm:setCanPassThrough(
        false
    )


    atm:setIsDismantable(
        false
    )


    atm:setBlockAllTheSquare(
        true
    )


    atm:getContainer():setType(
        "atm4"
    )


    --------------------------------------------------
    -- GLYTCH3R ATM MARKER
    --------------------------------------------------

    atm:getModData()[
        "atm4Converted"
    ] = true


    --------------------------------------------------
    -- JIMOLEON MARKER
    --------------------------------------------------

    atm:getModData()[
        "JimmoleonATM"
    ] = true


    --------------------------------------------------
    -- ADD TO WORLD
    --------------------------------------------------

    square:AddTileObject(
        atm
    )


    --------------------------------------------------
    -- TRANSMIT TO CLIENTS
    --------------------------------------------------

    atm:transmitCompleteItemToClients()


    --------------------------------------------------
    -- SAVE MOD DATA
    --------------------------------------------------

    square:transmitModdata()


    --------------------------------------------------
    -- SUCCESS
    --------------------------------------------------

    player:setHaloNote(
        "Jimmoleon ATM placed.",
        0.3,
        1.0,
        0.3,
        300
    )


    print(
        "JIMOLEON: ATM placed by admin."
    )

    print(
        "Sprite: " ..
        tostring(
            spriteName
        )
    )

end


--------------------------------------------------
-- CLIENT COMMAND
--------------------------------------------------

local function onClientCommand(
    module,
    command,
    player,
    args
)

    --------------------------------------------------
    -- MODULE CHECK
    --------------------------------------------------

    if module ~=
        "JimmoleonEconomy"
    then

        return

    end


    --------------------------------------------------
    -- PLAYER CHECK
    --------------------------------------------------

    if player == nil then
        return
    end


    --------------------------------------------------
    -- COMMAND CHECK
    --------------------------------------------------

    if command ~=
        "PlaceATM"
    then

        return

    end


    --------------------------------------------------
    -- SERVER-SIDE ADMIN SECURITY
    --------------------------------------------------

    if not player:isAccessLevel(
        "admin"
    ) then

        print(
            "JIMOLEON SECURITY: Unauthorized ATM placement attempt by " ..
            tostring(
                player:getDisplayName()
            )
        )

        player:setHaloNote(
            "Admin access required.",
            1.0,
            0.0,
            0.0,
            300
        )

        return

    end


    --------------------------------------------------
    -- ARGUMENT CHECK
    --------------------------------------------------

    if args == nil then

        return

    end


    local x =
        tonumber(
            args.x
        )


    local y =
        tonumber(
            args.y
        )


    local z =
        tonumber(
            args.z
        )


    local spriteName =
        tostring(
            args.sprite or
            ""
        )


    if x == nil
    or y == nil
    or z == nil
    then

        player:setHaloNote(
            "Invalid ATM placement coordinates.",
            1.0,
            0.0,
            0.0,
            300
        )

        return

    end


    --------------------------------------------------
    -- GET SQUARE
    --------------------------------------------------

    local square =
        getCell():getGridSquare(
            x,
            y,
            z
        )


    if square == nil then

        player:setHaloNote(
            "Invalid placement location.",
            1.0,
            0.0,
            0.0,
            300
        )

        return

    end


    --------------------------------------------------
    -- CREATE ATM
    --------------------------------------------------

    createGlytch3rATM(
        player,
        square,
        spriteName
    )

end


--------------------------------------------------
-- REGISTER SERVER EVENT
--------------------------------------------------

Events.OnClientCommand.Add(
    onClientCommand
)