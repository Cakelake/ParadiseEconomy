print("========================================")
print("JIMOLEON ECONOMY SYSTEM")
print("========================================")


--------------------------------------------------
-- SAVE GLOBAL JIMOLEON MOD DATA
--------------------------------------------------
-- Store/admin changes must be written to the
-- server's global data so price changes survive
-- reloads and world saves.
--------------------------------------------------

local function saveJimmoleonGlobalData()

    if GlobalModData ~= nil
    and GlobalModData.instance ~= nil
    and GlobalModData.instance.save ~= nil
    then

        local ok, err =
            pcall(function()
                GlobalModData.instance:save()
            end)

        if ok then
            print("JIMOLEON: global economy data saved.")
        else
            print(
                "JIMOLEON: global save failed: "
                .. tostring(err)
            )
        end

    else

        print(
            "JIMOLEON: GlobalModData save API unavailable."
        )

    end

end


--------------------------------------------------
-- PAYCHECK SETTINGS
--------------------------------------------------

local function getPaycheckSettings()

    local settings =
        ModData.getOrCreate(
            "JimmoleonSettings"
        )

    if settings.PaycheckEnabled == nil then
        settings.PaycheckEnabled = true
    end

    if settings.PaycheckIntervalHours == nil then
        settings.PaycheckIntervalHours = 1
    end

    if settings.PaycheckAmount == nil then
        settings.PaycheckAmount = 100
    end

    return settings

end


--------------------------------------------------
-- PLAYER SESSION DATA
--------------------------------------------------

local sessionData = {}


--------------------------------------------------
-- ACCOUNT REGISTRY
--------------------------------------------------

local function getAccountRegistry()

    local registry =
        ModData.getOrCreate(
            "JimmoleonAccounts"
        )

    if registry.Accounts == nil then
        registry.Accounts = {}
    end

    return registry

end


--------------------------------------------------
-- GENERATE UNIQUE ACCOUNT ID
--------------------------------------------------

local function generateUniqueAccountID()

    local registry =
        getAccountRegistry()

    local accountID

    repeat

        accountID =
            "JM-" ..
            tostring(
                ZombRand(
                    100000,
                    999999
                )
            )

    until registry.Accounts[accountID] == nil

    return accountID

end


--------------------------------------------------
-- GET ACCOUNT BY ID
--------------------------------------------------

local function getAccountByID(
    accountID
)

    if accountID == nil then
        return nil
    end

    local registry =
        getAccountRegistry()

    return registry.Accounts[
        tostring(
            accountID
        )
    ]

end


--------------------------------------------------
-- TRANSACTION RECORDING
--------------------------------------------------

local function recordTransaction(
    player,
    transactionType,
    amount,
    description
)

    if player == nil then
        return
    end

    local modData =
        player:getModData()

    if modData.JimmoleonTransactions == nil then

        modData.JimmoleonTransactions = {}

    end

    local transaction = {

        type =
            transactionType,

        amount =
            amount,

        description =
            description,

        worldHours =
            getGameTime():getWorldAgeHours()

    }

    table.insert(
        modData.JimmoleonTransactions,
        transaction
    )


    print("========================================")
    print("JIMOLEON: TRANSACTION RECORDED")

    print(
        "Character: " ..
        tostring(
            player:getDisplayName()
        )
    )

    print(
        "Type: " ..
        tostring(
            transactionType
        )
    )

    print(
        "Amount: " ..
        tostring(
            amount
        )
    )

    print(
        "Description: " ..
        tostring(
            description
        )
    )

    print("========================================")

end


--------------------------------------------------
-- TRANSFER RESPONSE
--------------------------------------------------

local function sendTransferResponse(
    player,
    success,
    message,
    data
)

    if player == nil then
        return
    end


    --------------------------------------------------
    -- SUCCESS HALO
    -- VERY BRIGHT GREEN
    --------------------------------------------------

    if success == true then

        player:setHaloNote(
            tostring(
                message
            ),
            0.15,
            1.0,
            0.15,
            300
        )


    --------------------------------------------------
    -- ERROR HALO
    -- BRIGHT RED
    --------------------------------------------------

    else

        player:setHaloNote(
            tostring(
                message
            ),
            1.0,
            0.05,
            0.05,
            300
        )

    end


    --------------------------------------------------
    -- SEND DATA TO CLIENT
    --------------------------------------------------

    local result = {

        success =
            success,

        message =
            message

    }


    if data ~= nil then

        for key, value in pairs(
            data
        ) do

            result[key] =
                value

        end

    end


    sendServerCommand(
        player,
        "JimmoleonEconomy",
        "TransferResult",
        result
    )

end


--------------------------------------------------
-- REGISTER ACCOUNT
--------------------------------------------------

local function registerAccount(
    player
)

    if player == nil then
        return nil
    end


    local modData =
        player:getModData()


    --------------------------------------------------
    -- CREATE ACCOUNT ID
    --------------------------------------------------

    if modData.JimmoleonAccountID == nil then

        modData.JimmoleonAccountID =
            generateUniqueAccountID()

    end


    --------------------------------------------------
    -- LOCAL DATA
    --------------------------------------------------

    if modData.JimmoleonBalance == nil then

        modData.JimmoleonBalance = 0

    end


    if modData.JimmoleonTransactions == nil then

        modData.JimmoleonTransactions = {}

    end


    --------------------------------------------------
    -- ACCOUNT REGISTRY
    --------------------------------------------------

    local registry =
        getAccountRegistry()

    local accountID =
        modData.JimmoleonAccountID

    local account =
        registry.Accounts[accountID]


    --------------------------------------------------
    -- CREATE ACCOUNT
    --------------------------------------------------

    if account == nil then

        registry.Accounts[accountID] = {

            characterName =
                player:getDisplayName(),

            balance =
                modData.JimmoleonBalance,

            pendingTransactions = {}

        }

        account =
            registry.Accounts[accountID]

    else

        account.characterName =
            player:getDisplayName()

    end


    --------------------------------------------------
    -- REGISTRY IS SOURCE OF TRUTH
    --------------------------------------------------

    modData.JimmoleonBalance =
        tonumber(
            account.balance
        ) or 0


    --------------------------------------------------
    -- PENDING TRANSACTIONS
    --------------------------------------------------

    if account.pendingTransactions == nil then

        account.pendingTransactions = {}

    end


    for _, pending in ipairs(
        account.pendingTransactions
    ) do

        recordTransaction(
            player,
            pending.type,
            pending.amount,
            pending.description
        )

    end


    account.pendingTransactions = {}


    return accountID

end


--------------------------------------------------
-- VALUABLE CATALOG / FRAMEWORK API
--------------------------------------------------

JimmoleonEconomy = JimmoleonEconomy or {}

local DEFAULT_VALUABLES = {
    {name="Cash",itemType="Base.Money",value=1},
    {name="Silver Coin",itemType="Base.SilverCoin",value=25},
    {name="Gold Coin",itemType="Base.GoldCoin",value=100},
    {name="Silver Ingot",itemType="Base.SilverBar",value=250},
    {name="Gold Ingot",itemType="Base.GoldBar",value=1000},
    {name="Diamond",itemType="Base.Diamond",value=500},
    {name="Ruby",itemType="Base.Ruby",value=500},
    {name="Sapphire",itemType="Base.Sapphire",value=500},
    {name="Emerald",itemType="Base.Emerald",value=500},
}

local function getValuableData()
    local data=ModData.getOrCreate("JimmoleonValuables")
    if data.Initialized ~= true then
        data.Valuables={}
        for _,v in ipairs(DEFAULT_VALUABLES) do table.insert(data.Valuables,{name=v.name,itemType=v.itemType,value=v.value}) end
        data.Initialized=true
    end
    if data.Valuables==nil then data.Valuables={} end
    return data
end

local function findValuable(itemType)
    itemType=tostring(itemType or "")
    for _,v in ipairs(getValuableData().Valuables) do if tostring(v.itemType)==itemType then return v end end
    return nil
end

local function getValuableValues()
    local values={}
    for _,v in ipairs(getValuableData().Valuables) do values[tostring(v.itemType)]={name=tostring(v.name),value=tonumber(v.value) or 0} end
    return values
end

local function getValuableCatalogForClient()
    local result={}
    for _,v in ipairs(getValuableData().Valuables) do table.insert(result,{name=tostring(v.name),itemType=tostring(v.itemType),value=tonumber(v.value) or 0}) end
    return result
end

local function sendValuableCatalog(player)
    if player==nil then return end
    sendServerCommand(player,"JimmoleonEconomy","ValuableCatalog",{valuables=getValuableCatalogForClient()})
end

local function broadcastValuableCatalog()
    for _,data in pairs(sessionData) do if data~=nil and data.player~=nil then sendValuableCatalog(data.player) end end
end

function JimmoleonEconomy.addValuable(name,itemType,value)
    name=tostring(name or ""); itemType=tostring(itemType or ""); value=tonumber(value)
    if name=="" or itemType=="" or value==nil or value<=0 then return false,"Invalid valuable data." end
    if getItem~=nil and getItem(itemType)==nil then return false,"The game does not recognize that item type." end
    local existing=findValuable(itemType)
    if existing~=nil then existing.name=name; existing.value=value else table.insert(getValuableData().Valuables,{name=name,itemType=itemType,value=value}) end
    broadcastValuableCatalog(); return true
end

function JimmoleonEconomy.updateValuable(itemType,value)
    itemType=tostring(itemType or ""); value=tonumber(value)
    if itemType=="" or value==nil or value<=0 then return false,"Invalid valuable data." end
    local v=findValuable(itemType); if v==nil then return false,"Valuable not found." end
    v.value=value; broadcastValuableCatalog(); return true
end

function JimmoleonEconomy.removeValuable(itemType)
    itemType=tostring(itemType or "")
    local data=getValuableData()
    for i,v in ipairs(data.Valuables) do if tostring(v.itemType)==itemType then table.remove(data.Valuables,i); broadcastValuableCatalog(); return true end end
    return false,"Valuable not found."
end



--------------------------------------------------
-- PLAYER MESSAGE
--------------------------------------------------

local function showMessage(
    player,
    message
)

    if player == nil then
        return
    end

    player:setHaloNote(
        message,
        0.15,
        1.0,
        0.15,
        300
    )

end


--------------------------------------------------
-- INITIALIZE PLAYER DATA
--------------------------------------------------

local function initializePlayerData(
    player
)

    if player == nil then
        return
    end

    registerAccount(
        player
    )

end


--------------------------------------------------
-- PLAYER LOGIN
--------------------------------------------------

local function playerStarted(
    playerNum,
    player
)

    if player == nil then
        return
    end


    initializePlayerData(
        player
    )


    local currentWorldHours =
        getGameTime():getWorldAgeHours()


    sessionData[playerNum] = {

        player =
            player,

        characterName =
            player:getDisplayName(),

        startHour =
            currentWorldHours

    }


    showMessage(
        player,
        "Session Started"
    )

    sendValuableCatalog(player)

end


--------------------------------------------------
-- PAYCHECK
--------------------------------------------------

local function checkPlaytime()

    local settings =
        getPaycheckSettings()


    if settings.PaycheckEnabled ~= true then
        return
    end


    local currentWorldHours =
        getGameTime():getWorldAgeHours()


    for playerNum, data in pairs(
        sessionData
    ) do

        local player =
            data.player


        if player ~= nil then

            local hoursPlayed =
                currentWorldHours -
                data.startHour


            if hoursPlayed >=
                settings.PaycheckIntervalHours
            then

                local rewardsEarned =
                    math.floor(
                        hoursPlayed /
                        settings.PaycheckIntervalHours
                    )


                local amountEarned =
                    rewardsEarned *
                    settings.PaycheckAmount


                local modData =
                    player:getModData()


                if modData.JimmoleonBalance == nil then

                    modData.JimmoleonBalance = 0

                end


                modData.JimmoleonBalance =
                    modData.JimmoleonBalance +
                    amountEarned


                --------------------------------------------------
                -- UPDATE REGISTRY
                --------------------------------------------------

                local accountID =
                    modData.JimmoleonAccountID


                local account =
                    getAccountByID(
                        accountID
                    )


                if account ~= nil then

                    account.balance =
                        modData.JimmoleonBalance

                end


                --------------------------------------------------
                -- TRANSACTION
                --------------------------------------------------

                recordTransaction(
                    player,
                    "DEPOSIT",
                    amountEarned,
                    "Playtime Paycheck"
                )


                data.startHour =
                    currentWorldHours


                showMessage(
                    player,
                    "Paycheck Earned"
                )

            end

        end

    end

end


--------------------------------------------------
-- GENERIC VALUABLE DEPOSIT
--------------------------------------------------

local function depositValuable(
    player,
    itemType,
    requestedAmount
)

    if player == nil then
        return
    end


    if itemType == nil then
        return
    end


    itemType =
        tostring(
            itemType
        )


    local valuable =
        getValuableValues()[itemType]


    if valuable == nil then

        sendServerCommand(
            player,
            "JimmoleonEconomy",
            "DepositResult",
            {
                success = false,

                message =
                    "This item is not accepted."
            }
        )

        return

    end


    --------------------------------------------------
    -- AMOUNT
    --------------------------------------------------

    local amount =
        tonumber(
            requestedAmount
        )


    if amount == nil then

        sendServerCommand(
            player,
            "JimmoleonEconomy",
            "DepositResult",
            {
                success = false,

                message =
                    "Enter a valid amount."
            }
        )

        return

    end


    amount =
        math.floor(
            amount
        )


    if amount <= 0 then

        sendServerCommand(
            player,
            "JimmoleonEconomy",
            "DepositResult",
            {
                success = false,

                message =
                    "Enter an amount greater than 0."
            }
        )

        return

    end


    --------------------------------------------------
    -- INVENTORY
    --------------------------------------------------

    local inventory =
        player:getInventory()


    local itemCount =
        inventory:getItemCount(
            itemType
        )


    if amount > itemCount then

        sendServerCommand(
            player,
            "JimmoleonEconomy",
            "DepositResult",
            {
                success = false,

                message =
                    "You only have " ..
                    tostring(
                        itemCount
                    ) ..
                    " " ..
                    tostring(
                        valuable.name
                    ) ..
                    "."
            }
        )

        return

    end


    --------------------------------------------------
    -- REMOVE ITEMS
    --------------------------------------------------

    for i = 1, amount do

        local item =
            inventory:getItemFromType(
                itemType
            )


        if item == nil then

            sendServerCommand(
                player,
                "JimmoleonEconomy",
                "DepositResult",
                {
                    success = false,

                    message =
                        "The deposit failed."
                }
            )

            return

        end


        inventory:Remove(
            item
        )


        sendRemoveItemFromContainer(
            inventory,
            item
        )

    end


    --------------------------------------------------
    -- ADD JIMOLEONS
    --------------------------------------------------

    local jimoleonsEarned =
        amount *
        valuable.value


    local modData =
        player:getModData()


    if modData.JimmoleonBalance == nil then

        modData.JimmoleonBalance = 0

    end


    modData.JimmoleonBalance =
        modData.JimmoleonBalance +
        jimoleonsEarned


    --------------------------------------------------
    -- UPDATE REGISTRY
    --------------------------------------------------

    local accountID =
        modData.JimmoleonAccountID


    local account =
        getAccountByID(
            accountID
        )


    if account ~= nil then

        account.balance =
            modData.JimmoleonBalance

    end


    --------------------------------------------------
    -- TRANSACTION
    --------------------------------------------------

    recordTransaction(
        player,
        "DEPOSIT",
        jimoleonsEarned,
        valuable.name ..
        " Deposit"
    )

    local transaction = {
        type = "DEPOSIT",
        amount = jimoleonsEarned,
        description = valuable.name .. " Deposit",
        worldHours = getGameTime():getWorldAgeHours()
    }


    --------------------------------------------------
    -- RESULT
    --------------------------------------------------

    sendServerCommand(
        player,
        "JimmoleonEconomy",
        "DepositResult",
        {
            success = true,

            amount =
                jimoleonsEarned,

            newBalance =
                modData.JimmoleonBalance,

            transaction = transaction,

            message =
                valuable.name ..
                " deposited."
        }
    )

end


--------------------------------------------------
-- TRANSFER JIMOLEONS
--------------------------------------------------

local function transferJimoleons(
    player,
    recipientAccountID,
    requestedAmount
)

    if player == nil then
        return
    end


    --------------------------------------------------
    -- RECIPIENT ID
    --------------------------------------------------

    if recipientAccountID == nil then

        sendTransferResponse(
            player,
            false,
            "Enter a recipient account ID."
        )

        return

    end


    recipientAccountID =
        tostring(
            recipientAccountID
        )


    recipientAccountID =
        string.upper(
            recipientAccountID
        )


    --------------------------------------------------
    -- AMOUNT
    --------------------------------------------------

    local amount =
        tonumber(
            requestedAmount
        )


    if amount == nil then

        sendTransferResponse(
            player,
            false,
            "Enter a valid amount."
        )

        return

    end


    amount =
        math.floor(
            amount
        )


    if amount <= 0 then

        sendTransferResponse(
            player,
            false,
            "Transfer amount must be greater than 0."
        )

        return

    end


    --------------------------------------------------
    -- SENDER
    --------------------------------------------------

    local senderModData =
        player:getModData()


    local senderAccountID =
        senderModData.JimmoleonAccountID


    local senderAccount =
        getAccountByID(
            senderAccountID
        )


    if senderAccount == nil then

        sendTransferResponse(
            player,
            false,
            "Your account could not be found."
        )

        return

    end


    --------------------------------------------------
    -- SELF TRANSFER
    --------------------------------------------------

    if recipientAccountID ==
        tostring(
            senderAccountID
        )
    then

        sendTransferResponse(
            player,
            false,
            "You cannot transfer to yourself."
        )

        return

    end


    --------------------------------------------------
    -- RECIPIENT
    --------------------------------------------------

    local recipientAccount =
        getAccountByID(
            recipientAccountID
        )


    if recipientAccount == nil then

        sendTransferResponse(
            player,
            false,
            "That account does not exist."
        )

        return

    end


    --------------------------------------------------
    -- CHECK BALANCE
    --------------------------------------------------

    if senderModData.JimmoleonBalance == nil then

        senderModData.JimmoleonBalance = 0

    end


    senderAccount.balance =
        senderModData.JimmoleonBalance


    if amount >
        senderModData.JimmoleonBalance
    then

        sendTransferResponse(
            player,
            false,
            "You do not have enough Jimoleons."
        )

        return

    end


    --------------------------------------------------
    -- REMOVE FROM SENDER
    --------------------------------------------------

    senderModData.JimmoleonBalance =
        senderModData.JimmoleonBalance -
        amount


    senderAccount.balance =
        senderModData.JimmoleonBalance


    --------------------------------------------------
    -- ADD TO RECIPIENT
    --------------------------------------------------

    recipientAccount.balance =
        tonumber(
            recipientAccount.balance
        ) or 0


    recipientAccount.balance =
        recipientAccount.balance +
        amount


    --------------------------------------------------
    -- SENDER TRANSACTION
    --------------------------------------------------

    recordTransaction(
        player,
        "TRANSFER",
        -amount,
        "Transfer to " ..
        tostring(
            recipientAccount.characterName
        )
    )


    --------------------------------------------------
    -- FIND ONLINE RECIPIENT
    --------------------------------------------------

    local recipientOnline =
        false


    for playerNum, session in pairs(
        sessionData
    ) do

        local recipientPlayer =
            session.player


        if recipientPlayer ~= nil then

            local recipientModData =
                recipientPlayer:getModData()


            if recipientModData.JimmoleonAccountID ==
                recipientAccountID
            then

                recipientOnline =
                    true


                --------------------------------------------------
                -- UPDATE ONLINE BALANCE
                --------------------------------------------------

                recipientModData.JimmoleonBalance =
                    recipientAccount.balance


                --------------------------------------------------
                -- RECIPIENT TRANSACTION
                --------------------------------------------------

                recordTransaction(
                    recipientPlayer,
                    "TRANSFER",
                    amount,
                    "Transfer from " ..
                    tostring(
                        player:getDisplayName()
                    )
                )


                --------------------------------------------------
                -- RECIPIENT HALO
                --------------------------------------------------

                recipientPlayer:setHaloNote(
                    "Received " ..
                    tostring(
                        amount
                    ) ..
                    " Jimoleons from " ..
                    tostring(
                        player:getDisplayName()
                    ),
                    0.15,
                    1.0,
                    0.15,
                    300
                )


                --------------------------------------------------
                -- RECIPIENT COMMAND
                --------------------------------------------------

                sendServerCommand(
                    recipientPlayer,
                    "JimmoleonEconomy",
                    "TransferReceived",
                    {
                        amount =
                            amount,

                        newBalance =
                            recipientAccount.balance,

                        senderName =
                            player:getDisplayName()
                    }
                )


                break

            end

        end

    end


    --------------------------------------------------
    -- OFFLINE RECIPIENT
    --------------------------------------------------

    if recipientOnline == false then

        if recipientAccount.pendingTransactions == nil then

            recipientAccount.pendingTransactions = {}

        end


        table.insert(
            recipientAccount.pendingTransactions,
            {

                type =
                    "TRANSFER",

                amount =
                    amount,

                description =
                    "Transfer from " ..
                    tostring(
                        player:getDisplayName()
                    )

            }
        )

    end


    --------------------------------------------------
    -- SENDER SUCCESS
    --------------------------------------------------

    sendTransferResponse(
        player,
        true,
        "Transfer successful.",
        {

            amount =
                amount,

            newBalance =
                senderModData.JimmoleonBalance,

            recipientName =
                recipientAccount.characterName,

            recipientAccountID =
                recipientAccountID

        }
    )

end




--------------------------------------------------
-- VALUABLE ADMIN
--------------------------------------------------

local function isValuableAdmin(player)
    return player ~= nil and player.getAccessLevel ~= nil and tostring(player:getAccessLevel()) == "admin"
end

local function sendValuableAdminResult(player,success,message)
    sendServerCommand(player,"JimmoleonEconomy","ValuableAdminResult",{success=success,message=message})
end



--------------------------------------------------
-- STORE CATALOG
--------------------------------------------------

local function getStoreData()

    local store =
        ModData.getOrCreate(
            "JimmoleonStore"
        )

    if store.Initialized ~= true then

        store.Categories = {
            {
                id = "CAT-WEAPONS-TOOLS",
                name = "WEAPONS & TOOLS",
                items = {
                    {
                        name = "Axe",
                        itemType = "Base.Axe",
                        price = 250
                    },
                    {
                        name = "Hammer",
                        itemType = "Base.Hammer",
                        price = 150
                    },
                    {
                        name = "Baseball Bat",
                        itemType = "Base.BaseballBat",
                        price = 500
                    }
                }
            },
            {
                id = "CAT-FOOD",
                name = "FOOD",
                items = {}
            },
            {
                id = "CAT-MISC",
                name = "MISC",
                items = {}
            }
        }

        store.Initialized = true

    end

    if store.Categories == nil then
        store.Categories = {}
    end

    return store

end


--------------------------------------------------
-- COPY STORE DATA FOR CLIENT
--------------------------------------------------

local function getStoreCatalogForClient()

    local store =
        getStoreData()

    local catalog = {
        categories = {}
    }

    for _, category in ipairs(store.Categories) do

        local clientCategory = {
            id = tostring(category.id),
            name = tostring(category.name),
            items = {}
        }

        if category.items ~= nil then

            for _, item in ipairs(category.items) do

                table.insert(
                    clientCategory.items,
                    {
                        name = tostring(item.name),
                        itemType = tostring(item.itemType),
                        price = tonumber(item.price) or 0
                    }
                )

            end

        end

        table.insert(
            catalog.categories,
            clientCategory
        )

    end

    return catalog

end


--------------------------------------------------
-- SEND STORE CATALOG
--------------------------------------------------

local function sendStoreCatalog(player)

    if player == nil then
        return
    end

    sendServerCommand(
        player,
        "JimmoleonEconomy",
        "StoreCatalog",
        {
            catalog = getStoreCatalogForClient()
        }
    )

end


--------------------------------------------------
-- STORE ADMIN CHECK
--------------------------------------------------

local function isStoreAdmin(player)

    if player == nil then
        return false
    end

    if player.getAccessLevel == nil then
        return false
    end

    return tostring(
        player:getAccessLevel()
    ) == "admin"

end


--------------------------------------------------
-- GENERATE CATEGORY ID
--------------------------------------------------

local function generateStoreCategoryID()

    local store =
        getStoreData()

    local categoryID

    repeat

        categoryID =
            "CAT-" ..
            tostring(
                ZombRand(
                    100000,
                    999999
                )
            )

        local exists = false

        for _, category in ipairs(store.Categories) do

            if tostring(category.id) == categoryID then
                exists = true
                break
            end

        end

        if not exists then
            return categoryID
        end

    until false

end


--------------------------------------------------
-- SEND STORE ADMIN RESULT
--------------------------------------------------

local function sendStoreAdminResult(
    player,
    success,
    message
)

    sendServerCommand(
        player,
        "JimmoleonEconomy",
        "StoreAdminResult",
        {
            success = success,
            message = message
        }
    )

    if success == true then
        sendStoreCatalog(player)
    end

end


--------------------------------------------------
-- CREATE STORE CATEGORY
--------------------------------------------------

local function createStoreCategory(
    player,
    name
)

    if not isStoreAdmin(player) then

        sendStoreAdminResult(
            player,
            false,
            "Admin access required."
        )
        return

    end

    name =
        tostring(name or "")

    if name == "" then

        sendStoreAdminResult(
            player,
            false,
            "Enter a category name."
        )
        return

    end

    local store =
        getStoreData()

    local lowerName =
        string.lower(name)

    for _, category in ipairs(store.Categories) do

        if string.lower(
            tostring(category.name)
        ) == lowerName then

            sendStoreAdminResult(
                player,
                false,
                "That category already exists."
            )
            return

        end

    end

    table.insert(
        store.Categories,
        {
            id = generateStoreCategoryID(),
            name = name,
            items = {}
        }
    )

    saveJimmoleonGlobalData()

    sendStoreAdminResult(
        player,
        true,
        "Category created: " .. name
    )

end


--------------------------------------------------
-- DELETE STORE CATEGORY
--------------------------------------------------

local function deleteStoreCategory(
    player,
    categoryID
)

    if not isStoreAdmin(player) then

        sendStoreAdminResult(
            player,
            false,
            "Admin access required."
        )
        return

    end

    categoryID =
        tostring(categoryID or "")

    local store =
        getStoreData()

    for index, category in ipairs(store.Categories) do

        if tostring(category.id) == categoryID then

            table.remove(
                store.Categories,
                index
            )

            saveJimmoleonGlobalData()

            sendStoreAdminResult(
                player,
                true,
                "Category deleted."
            )

            return

        end

    end

    sendStoreAdminResult(
        player,
        false,
        "Category not found."
    )

end


--------------------------------------------------
-- ADD ITEM TO STORE CATEGORY
--------------------------------------------------

local function addStoreItem(
    player,
    categoryID,
    itemName,
    itemType,
    price
)

    if not isStoreAdmin(player) then

        sendStoreAdminResult(
            player,
            false,
            "Admin access required."
        )
        return

    end

    categoryID =
        tostring(categoryID or "")

    itemName =
        tostring(itemName or "")

    itemType =
        tostring(itemType or "")

    price =
        tonumber(price)

    if itemName == "" then

        sendStoreAdminResult(
            player,
            false,
            "Enter an item display name."
        )
        return

    end

    if itemType == "" then

        sendStoreAdminResult(
            player,
            false,
            "Enter an item type."
        )
        return

    end

    if price == nil then

        sendStoreAdminResult(
            player,
            false,
            "Enter a valid price."
        )
        return

    end

    price =
        math.floor(price)

    if price <= 0 then

        sendStoreAdminResult(
            player,
            false,
            "Price must be greater than 0."
        )
        return

    end

    local store =
        getStoreData()

    for _, category in ipairs(store.Categories) do

        if tostring(category.id) == categoryID then

            if category.items == nil then
                category.items = {}
            end

            table.insert(
                category.items,
                {
                    name = itemName,
                    itemType = itemType,
                    price = price
                }
            )

            saveJimmoleonGlobalData()

            sendStoreAdminResult(
                player,
                true,
                itemName .. " added to " .. tostring(category.name) .. "."
            )

            return

        end

    end

    sendStoreAdminResult(
        player,
        false,
        "Category not found."
    )

end


--------------------------------------------------
-- UPDATE STORE ITEM PRICE
--------------------------------------------------

local function updateStoreItemPrice(
    player,
    categoryID,
    itemType,
    price
)

    if not isStoreAdmin(player) then
        sendStoreAdminResult(player,false,"Admin access required.")
        return
    end

    categoryID = tostring(categoryID or "")
    itemType = tostring(itemType or "")
    price = tonumber(price)

    if categoryID == "" or itemType == "" then
        sendStoreAdminResult(player,false,"Store category and item are required.")
        return
    end

    if price == nil then
        sendStoreAdminResult(player,false,"Enter a valid price.")
        return
    end

    price = math.floor(price)

    if price <= 0 then
        sendStoreAdminResult(player,false,"Price must be greater than 0.")
        return
    end

    local category, storeItem = findStoreItem(categoryID,itemType)

    if category == nil then
        sendStoreAdminResult(player,false,"Store category not found.")
        return
    end

    if storeItem == nil then
        sendStoreAdminResult(player,false,"Store item not found.")
        return
    end

    storeItem.price = price

    -- SAVE THE NEW PRICE TO GLOBAL SERVER DATA
    saveJimmoleonGlobalData()

    sendStoreAdminResult(
        player,
        true,
        tostring(storeItem.name or itemType) .. " price changed to " .. tostring(price) .. " Jimoleons."
    )
end


--------------------------------------------------
-- REMOVE STORE ITEM
--------------------------------------------------

local function removeStoreItem(
    player,
    categoryID,
    itemType
)

    if not isStoreAdmin(player) then
        sendStoreAdminResult(player,false,"Admin access required.")
        return
    end

    categoryID = tostring(categoryID or "")
    itemType = tostring(itemType or "")

    if categoryID == "" or itemType == "" then
        sendStoreAdminResult(player,false,"Store category and item are required.")
        return
    end

    local store = getStoreData()

    for _, category in ipairs(store.Categories) do
        if tostring(category.id) == categoryID then
            if category.items ~= nil then
                for index, item in ipairs(category.items) do
                    if tostring(item.itemType) == itemType then
                        local itemName = tostring(item.name or itemType)
                        table.remove(category.items,index)

                        -- SAVE THE REMOVAL TO GLOBAL SERVER DATA
                        saveJimmoleonGlobalData()

                        sendStoreAdminResult(
                            player,
                            true,
                            itemName .. " removed from " .. tostring(category.name) .. "."
                        )
                        return
                    end
                end
            end

            sendStoreAdminResult(player,false,"Store item not found.")
            return
        end
    end

    sendStoreAdminResult(player,false,"Store category not found.")
end


--------------------------------------------------
-- FIND STORE ITEM
--------------------------------------------------

local function findStoreItem(
    categoryID,
    itemType
)

    categoryID =
        tostring(categoryID or "")

    itemType =
        tostring(itemType or "")

    local store =
        getStoreData()

    for _, category in ipairs(
        store.Categories
    ) do

        if tostring(category.id) == categoryID then

            if category.items ~= nil then

                for _, item in ipairs(
                    category.items
                ) do

                    if tostring(item.itemType) == itemType then
                        return category, item
                    end

                end

            end

            return category, nil

        end

    end

    return nil, nil

end


--------------------------------------------------
-- STORE PURCHASE RESULT
--------------------------------------------------

local function sendStorePurchaseResult(
    player,
    success,
    message,
    data
)

    if player == nil then
        return
    end

    local result = {
        success = success,
        message = message
    }

    if data ~= nil then

        for key, value in pairs(data) do
            result[key] = value
        end

    end

    sendServerCommand(
        player,
        "JimmoleonEconomy",
        "StorePurchaseResult",
        result
    )

end


--------------------------------------------------
-- BUY STORE ITEM
--------------------------------------------------

local function buyStoreItem(
    player,
    categoryID,
    itemType
)

    if player == nil then
        return
    end

    categoryID =
        tostring(categoryID or "")

    itemType =
        tostring(itemType or "")

    if categoryID == "" then

        sendStorePurchaseResult(
            player,
            false,
            "Store category not specified."
        )
        return

    end

    if itemType == "" then

        sendStorePurchaseResult(
            player,
            false,
            "Store item not specified."
        )
        return

    end

    --------------------------------------------------
    -- FIND THE ITEM IN THE SERVER CATALOG
    --------------------------------------------------

    local category, storeItem =
        findStoreItem(
            categoryID,
            itemType
        )

    if category == nil then

        sendStorePurchaseResult(
            player,
            false,
            "That store category does not exist."
        )
        return

    end

    if storeItem == nil then

        sendStorePurchaseResult(
            player,
            false,
            "That item is not sold in this category."
        )
        return

    end

    --------------------------------------------------
    -- VALIDATE ITEM SCRIPT
    --------------------------------------------------

    if getItem ~= nil then

        local scriptItem =
            getItem(itemType)

        if scriptItem == nil then

            sendStorePurchaseResult(
                player,
                false,
                "This item no longer exists in the loaded game."
            )
            return

        end

    end

    --------------------------------------------------
    -- ACCOUNT
    --------------------------------------------------

    local modData =
        player:getModData()

    local accountID =
        modData.JimmoleonAccountID

    local account =
        getAccountByID(accountID)

    --------------------------------------------------
    -- REPAIR / REGISTER ACCOUNT IF NEEDED
    --
    -- A character can have an AccountID in its
    -- character data while the server registry is
    -- missing that account entry. Registering here
    -- repairs the registry instead of blocking a
    -- legitimate purchase.
    --------------------------------------------------

    if account == nil then

        print(
            "JIMOLEON STORE: Account lookup failed for " ..
            tostring(player:getDisplayName()) ..
            " ID=" ..
            tostring(accountID)
        )

        registerAccount(
            player
        )

        accountID =
            modData.JimmoleonAccountID

        account =
            getAccountByID(accountID)

    end

    if account == nil then

        sendStorePurchaseResult(
            player,
            false,
            "Your account could not be registered."
        )
        return

    end

    --------------------------------------------------
    -- PRICE COMES FROM SERVER CATALOG
    --------------------------------------------------

    local price =
        math.floor(
            tonumber(storeItem.price) or 0
        )

    if price <= 0 then

        sendStorePurchaseResult(
            player,
            false,
            "This item has an invalid store price."
        )
        return

    end

    --------------------------------------------------
    -- BALANCE
    --------------------------------------------------

    local balance =
        tonumber(account.balance) or 0

    modData.JimmoleonBalance =
        balance

    if balance < price then

        sendStorePurchaseResult(
            player,
            false,
            "You do not have enough Jimoleons."
        )
        return

    end

    --------------------------------------------------
    -- ADD ITEM SERVER-SIDE
    --------------------------------------------------

    local inventory =
        player:getInventory()

    if inventory == nil then

        sendStorePurchaseResult(
            player,
            false,
            "Your inventory could not be found."
        )
        return

    end

    local newItem = nil

    local ok, result =
        pcall(
            function()
                return inventory:AddItem(
                    itemType
                )
            end
        )

    if ok then
        newItem = result
    else
        print(
            "JIMOLEON STORE ERROR: AddItem failed for " ..
            tostring(itemType) ..
            " : " ..
            tostring(result)
        )
    end

    if newItem == nil then

        sendStorePurchaseResult(
            player,
            false,
            "The item could not be added to your inventory."
        )
        return

    end

    --------------------------------------------------
    -- SYNC THE NEW ITEM
    --------------------------------------------------

    if sendAddItemToContainer ~= nil then

        local syncOK, syncError =
            pcall(
                function()
                    sendAddItemToContainer(
                        inventory,
                        newItem
                    )
                end
            )

        if not syncOK then

            print(
                "JIMOLEON STORE ERROR: Item sync failed for " ..
                tostring(itemType) ..
                " : " ..
                tostring(syncError)
            )

            pcall(
                function()
                    inventory:Remove(
                        newItem
                    )
                end
            )

            sendStorePurchaseResult(
                player,
                false,
                "The item could not be synchronized."
            )
            return
        end

    else

        print(
            "JIMOLEON STORE ERROR: sendAddItemToContainer is unavailable."
        )

        pcall(
            function()
                inventory:Remove(
                    newItem
                )
            end
        )

        sendStorePurchaseResult(
            player,
            false,
            "The store could not synchronize the item."
        )
        return

    end

    --------------------------------------------------
    -- DEDUCT JIMOLEONS
    --------------------------------------------------

    local newBalance =
        balance - price

    account.balance =
        newBalance

    modData.JimmoleonBalance =
        newBalance

    print("JIMOLEON STORE PURCHASE: " .. tostring(player:getDisplayName()) .. " bought " .. tostring(itemType) .. " for " .. tostring(price))

    --------------------------------------------------
    -- TRANSACTION
    --------------------------------------------------

    recordTransaction(
        player,
        "STORE_PURCHASE",
        -price,
        "Purchased " ..
        tostring(storeItem.name)
    )

    --------------------------------------------------
    -- SUCCESS
    --------------------------------------------------

    sendStorePurchaseResult(
        player,
        true,
        "Purchase successful.",
        {
            itemName =
                tostring(storeItem.name),
            itemType =
                itemType,
            price =
                price,
            newBalance =
                newBalance,
            categoryID =
                categoryID
        }
    )

end


--------------------------------------------------
-- CLIENT COMMANDS
--------------------------------------------------

local function onClientCommand(
    module,
    command,
    player,
    args
)

    if module ~=
        "JimmoleonEconomy"
    then
        return
    end


    if player == nil then
        return
    end


    if args == nil then

        args = {}

    end


    --------------------------------------------------
    -- DEPOSIT
    --------------------------------------------------

    if command ==
        "DepositValuable"
    then

        depositValuable(
            player,
            args.itemType,
            args.amount
        )

        return

    end


    --------------------------------------------------
    -- VALUABLE CATALOG / ADMIN
    --------------------------------------------------

    if command == "GetValuableCatalog" then
        sendValuableCatalog(player)
        return
    end

    if command == "AddValuable" then
        if not isValuableAdmin(player) then sendValuableAdminResult(player,false,"Admin access required."); return end
        local ok,msg=JimmoleonEconomy.addValuable(args.name,args.itemType,args.value)
        sendValuableAdminResult(player,ok,msg or "Valuable added.")
        return
    end

    if command == "UpdateValuable" then
        if not isValuableAdmin(player) then sendValuableAdminResult(player,false,"Admin access required."); return end
        local ok,msg=JimmoleonEconomy.updateValuable(args.itemType,args.value)
        sendValuableAdminResult(player,ok,msg or "Valuable updated.")
        return
    end

    if command == "RemoveValuable" then
        if not isValuableAdmin(player) then sendValuableAdminResult(player,false,"Admin access required."); return end
        local ok,msg=JimmoleonEconomy.removeValuable(args.itemType)
        sendValuableAdminResult(player,ok,msg or "Valuable removed.")
        return
    end


    --------------------------------------------------
    -- TRANSFER
    --------------------------------------------------

    if command ==
        "TransferJimoleons"
    then

        transferJimoleons(
            player,
            args.recipientAccountID,
            args.amount
        )

        return

    end


    --------------------------------------------------
    -- BUY STORE ITEM
    --------------------------------------------------

    if command ==
        "BuyStoreItem"
    then

        buyStoreItem(
            player,
            args.categoryID,
            args.itemType
        )

        return

    end


    --------------------------------------------------
    -- UPDATE STORE ITEM PRICE
    --------------------------------------------------

    if command == "UpdateStoreItemPrice" then

        updateStoreItemPrice(
            player,
            args.categoryID,
            args.itemType,
            args.price
        )

        return

    end


    --------------------------------------------------
    -- REMOVE STORE ITEM
    --------------------------------------------------

    if command == "RemoveStoreItem" then

        removeStoreItem(
            player,
            args.categoryID,
            args.itemType
        )

        return

    end


    --------------------------------------------------
    -- STORE CATALOG REQUEST
    --------------------------------------------------

    if command ==
        "GetStoreCatalog"
    then

        sendStoreCatalog(
            player
        )

        return

    end


    --------------------------------------------------
    -- CREATE STORE CATEGORY
    --------------------------------------------------

    if command ==
        "CreateStoreCategory"
    then

        createStoreCategory(
            player,
            args.name
        )

        return

    end


    --------------------------------------------------
    -- DELETE STORE CATEGORY
    --------------------------------------------------

    if command ==
        "DeleteStoreCategory"
    then

        deleteStoreCategory(
            player,
            args.categoryID
        )

        return

    end


    --------------------------------------------------
    -- ADD STORE ITEM
    --------------------------------------------------

    if command ==
        "AddStoreItem"
    then

        addStoreItem(
            player,
            args.categoryID,
            args.name,
            args.itemType,
            args.price
        )

        return

    end

end


--------------------------------------------------
-- EVENTS
--------------------------------------------------

Events.OnCreatePlayer.Add(
    playerStarted
)


Events.EveryOneMinute.Add(
    checkPlaytime
)


Events.OnClientCommand.Add(
    onClientCommand
)