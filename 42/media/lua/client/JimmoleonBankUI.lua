JimmoleonBankUI = JimmoleonBankUI or {}


--------------------------------------------------
-- CURRENT SELECTION
--------------------------------------------------

local selectedValuable = nil


--------------------------------------------------
-- DEPOSITABLE ITEMS
--------------------------------------------------

JimmoleonBankUI.depositValuables = JimmoleonBankUI.depositValuables or {
    { name = "Cash", itemType = "Base.Money", value = 1 },
    { name = "Silver Coin", itemType = "Base.SilverCoin", value = 25 },
    { name = "Gold Coin", itemType = "Base.GoldCoin", value = 100 },
    { name = "Silver Ingot", itemType = "Base.SilverBar", value = 250 },
    { name = "Gold Ingot", itemType = "Base.GoldBar", value = 1000 },
    { name = "Diamond", itemType = "Base.Diamond", value = 500 },
    { name = "Ruby", itemType = "Base.Ruby", value = 500 },
    { name = "Sapphire", itemType = "Base.Sapphire", value = 500 },
    { name = "Emerald", itemType = "Base.Emerald", value = 500 },
}

function JimmoleonBankUI.addValuable(name, itemType, value)
    name = tostring(name or "")
    itemType = tostring(itemType or "")
    value = tonumber(value)
    if name == "" or itemType == "" or value == nil then return false end

    for _, valuable in ipairs(JimmoleonBankUI.depositValuables) do
        if tostring(valuable.itemType) == itemType then
            valuable.name = name
            valuable.value = value
            return true
        end
    end

    table.insert(JimmoleonBankUI.depositValuables, {
        name = name, itemType = itemType, value = value
    })
    return true
end


--------------------------------------------------
-- STORE CATALOG
--
-- Add or remove categories and items here later.
-- The STORE screen reads directly from this table.
--------------------------------------------------

local storeCatalog = {
    categories = {}
}

local storeAdminOpen = false


--------------------------------------------------
-- CLIENT ADMIN CHECK
--------------------------------------------------

local function isClientAdmin(pl)

    if pl == nil then
        return false
    end

    if pl.getAccessLevel == nil then
        return false
    end

    return tostring(pl:getAccessLevel()) == "admin"

end


--------------------------------------------------
-- JIMOLEON ITEM LIST VIEWER HOOK
--
-- Uses the game's real ISItemsListViewer data.
-- The viewer's rows contain the actual ScriptItem object.
--------------------------------------------------

local jimmoleonItemPickerCallback = nil
local originalISItemsListTableAddItem = nil

local function installJimmoleonItemPickerHook()

    if ISItemsListTable == nil then
        return false
    end

    if ISItemsListTable.addItem == nil then
        return false
    end

    if originalISItemsListTableAddItem == nil then

        originalISItemsListTableAddItem =
            ISItemsListTable.addItem

        ISItemsListTable.addItem = function(self, item)

            if jimmoleonItemPickerCallback ~= nil then

                local callback =
                    jimmoleonItemPickerCallback

                jimmoleonItemPickerCallback = nil

                callback(item)

                return
            end

            return originalISItemsListTableAddItem(
                self,
                item
            )

        end

    end

    return true

end


--------------------------------------------------
-- OPEN JIMOLEON ITEM PICKER
--------------------------------------------------

function JimmoleonBankUI.openItemPicker(window, pl)

    if pl == nil then
        return
    end

    if not isClientAdmin(pl) then
        pl:setHaloNote(
            "Admin access required.",
            1,
            0,
            0,
            300
        )
        return
    end

    if ISItemsListViewer == nil then
        pl:setHaloNote(
            "The game's Item List Viewer is not loaded.",
            1,
            0,
            0,
            300
        )
        return
    end

    if not installJimmoleonItemPickerHook() then
        pl:setHaloNote(
            "The game's Item List Viewer is unavailable.",
            1,
            0,
            0,
            300
        )
        return
    end

    jimmoleonItemPickerCallback = function(item)

        if item == nil then
            return
        end

        local itemType =
            tostring(item:getFullName() or "")

        local displayName =
            tostring(item:getDisplayName() or "")

        if itemType == "" then
            pl:setHaloNote(
                "That item has no valid item type.",
                1,
                0,
                0,
                300
            )
            return
        end

        if displayName == "" then
            displayName = itemType
        end

        if window ~= nil then

            if window.itemNameBox ~= nil then
                window.itemNameBox:setText(
                    displayName
                )
            end

            if window.itemTypeBox ~= nil then
                window.itemTypeBox:setText(
                    itemType
                )
            end

            window.selectedGameItem = item

        end

        pl:setHaloNote(
            "Selected: " .. displayName,
            0.15,
            1.0,
            0.15,
            250
        )

        if ISItemsListViewer.instance ~= nil then
            ISItemsListViewer.instance:close()
        end

    end

    --------------------------------------------------
    -- OPEN THE VANILLA ITEM LIST VIEWER
    --------------------------------------------------

    ISItemsListViewer.OnOpenPanel()

end





--------------------------------------------------
-- CLOSE CURRENT WINDOW
--------------------------------------------------

function JimmoleonBankUI:ClosePanel()

    if JimmoleonBankUI.instance ~= nil then

        JimmoleonBankUI.instance:setVisible(false)

        JimmoleonBankUI.instance:removeFromUIManager()

        JimmoleonBankUI.instance = nil

    end

end


--------------------------------------------------
-- MAIN ECONOMY SCREEN
--------------------------------------------------

function JimmoleonBankUI.open(pl)

    if pl == nil then
        return
    end


    JimmoleonBankUI:ClosePanel()


    local md = pl:getModData()

    local accountID =
        md.JimmoleonAccountID or "UNKNOWN"

    local balance =
        md.JimmoleonBalance or 0


    local width = 450

    local height = 360


    local x =
        (getCore():getScreenWidth() - width) / 2

    local y =
        (getCore():getScreenHeight() - height) / 2


    --------------------------------------------------
    -- CREATE WINDOW
    --------------------------------------------------

    JimmoleonBankUI.instance =
        ISPanel:new(
            x,
            y,
            width,
            height
        )


    JimmoleonBankUI.instance:initialise()

    JimmoleonBankUI.instance.moveWithMouse = true

    JimmoleonBankUI.instance:setAlwaysOnTop(true)


    JimmoleonBankUI.instance.backgroundColor = {
        r = 0.05,
        g = 0.05,
        b = 0.05,
        a = 0.95
    }


    JimmoleonBankUI.instance.borderColor = {
        r = 0.2,
        g = 0.8,
        b = 0.2,
        a = 1
    }


    local window =
        JimmoleonBankUI.instance


    --------------------------------------------------
    -- TITLE
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            20,
            25,
            "JIMOLEON ECONOMY",
            1,
            1,
            1,
            1,
            UIFont.Large,
            true
        )
    )


    --------------------------------------------------
    -- ACCOUNT
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            65,
            25,
            "Account: " ..
            tostring(accountID),
            1,
            1,
            1,
            1,
            UIFont.Medium,
            true
        )
    )


    --------------------------------------------------
    -- BALANCE
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            100,
            25,
            "Balance: " ..
            tostring(balance) ..
            " Jimoleons",
            0.3,
            1,
            0.3,
            1,
            UIFont.Medium,
            true
        )
    )


    --------------------------------------------------
    -- BANK BUTTON
    --------------------------------------------------

    local bankButton =
        ISButton:new(
            75,
            150,
            135,
            40,
            "BANK",
            window,
            function()

                JimmoleonBankUI.openBank(
                    pl
                )

            end
        )


    bankButton:initialise()

    window:addChild(bankButton)


    --------------------------------------------------
    -- STORE BUTTON
    --------------------------------------------------

    local storeButton =
        ISButton:new(
            240,
            150,
            135,
            40,
            "STORE",
            window,
            function()

                JimmoleonBankUI.openStore(
                    pl
                )

            end
        )


    storeButton:initialise()

    window:addChild(storeButton)


    --------------------------------------------------
    -- TRANSACTIONS BUTTON
    --------------------------------------------------

    local transactionButton =
        ISButton:new(
            110,
            215,
            230,
            40,
            "TRANSACTIONS",
            window,
            function()

                JimmoleonBankUI.openTransactions(
                    pl,
                    false
                )

            end
        )


    transactionButton:initialise()

    window:addChild(transactionButton)


    --------------------------------------------------
    -- CLOSE BUTTON
    --------------------------------------------------

    local closeButton =
        ISButton:new(
            175,
            305,
            100,
            30,
            "CLOSE",
            window,
            function()

                JimmoleonBankUI:ClosePanel()

            end
        )


    closeButton:initialise()

    window:addChild(closeButton)


    --------------------------------------------------
    -- SHOW WINDOW
    --------------------------------------------------

    window:addToUIManager()

    window:setVisible(true)


    return window

end


--------------------------------------------------
-- BANK SCREEN
--------------------------------------------------

function JimmoleonBankUI.openBank(pl)

    if pl == nil then
        return
    end


    JimmoleonBankUI:ClosePanel()


    local md =
        pl:getModData()


    local accountID =
        md.JimmoleonAccountID or "UNKNOWN"


    local balance =
        md.JimmoleonBalance or 0


    local width = 450

    local height = 450


    local x =
        (getCore():getScreenWidth() - width) / 2

    local y =
        (getCore():getScreenHeight() - height) / 2


    --------------------------------------------------
    -- CREATE WINDOW
    --------------------------------------------------

    JimmoleonBankUI.instance =
        ISPanel:new(
            x,
            y,
            width,
            height
        )


    JimmoleonBankUI.instance:initialise()

    JimmoleonBankUI.instance.moveWithMouse = true

    JimmoleonBankUI.instance:setAlwaysOnTop(true)


    JimmoleonBankUI.instance.backgroundColor = {
        r = 0.05,
        g = 0.05,
        b = 0.05,
        a = 0.95
    }


    JimmoleonBankUI.instance.borderColor = {
        r = 0.2,
        g = 0.8,
        b = 0.2,
        a = 1
    }


    local window =
        JimmoleonBankUI.instance


    --------------------------------------------------
    -- TITLE
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            20,
            25,
            "JIMOLEON BANK",
            1,
            1,
            1,
            1,
            UIFont.Large,
            true
        )
    )


    --------------------------------------------------
    -- ACCOUNT
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            65,
            25,
            "Account: " ..
            tostring(accountID),
            1,
            1,
            1,
            1,
            UIFont.Medium,
            true
        )
    )


    --------------------------------------------------
    -- BALANCE
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            100,
            25,
            "Balance: " ..
            tostring(balance) ..
            " Jimoleons",
            0.3,
            1,
            0.3,
            1,
            UIFont.Medium,
            true
        )
    )


    --------------------------------------------------
    -- DEPOSIT
    --------------------------------------------------

    local depositButton =
        ISButton:new(
            110,
            145,
            230,
            35,
            "DEPOSIT",
            window,
            function()

                JimmoleonBankUI.openDeposit(
                    pl
                )

            end
        )


    depositButton:initialise()

    window:addChild(depositButton)


    --------------------------------------------------
    -- TRANSFER
    --------------------------------------------------

    local transferButton =
        ISButton:new(
            110,
            190,
            230,
            35,
            "TRANSFER",
            window,
            function()

                JimmoleonBankUI.openTransfer(
                    pl
                )

            end
        )


    transferButton:initialise()

    window:addChild(transferButton)


    --------------------------------------------------
    -- TRANSACTIONS
    --------------------------------------------------

    local transactionButton =
        ISButton:new(
            110,
            235,
            230,
            35,
            "TRANSACTIONS",
            window,
            function()

                JimmoleonBankUI.openTransactions(
                    pl,
                    true
                )

            end
        )


    transactionButton:initialise()

    window:addChild(transactionButton)


    --------------------------------------------------
    -- ADMIN: VALUABLE SETTINGS
    --------------------------------------------------

    if isClientAdmin(pl) then
        local valuableAdminButton = ISButton:new(110, 280, 230, 35, "VALUABLE ADMIN", window, function()
            JimmoleonBankUI.openValuableAdmin(pl)
        end)
        valuableAdminButton:initialise()
        window:addChild(valuableAdminButton)

        local balanceAdminButton = ISButton:new(110, 325, 230, 35, "BALANCE ADMIN", window, function()
            JimmoleonBankUI.openBalanceAdmin(pl)
        end)
        balanceAdminButton:initialise()
        window:addChild(balanceAdminButton)
    end

    --------------------------------------------------
    -- BACK TO ECONOMY
    --------------------------------------------------

    local backButton =
        ISButton:new(
            105,
            360,
            120,
            35,
            "BACK",
            window,
            function()

                JimmoleonBankUI.open(
                    pl
                )

            end
        )


    backButton:initialise()

    window:addChild(backButton)


    --------------------------------------------------
    -- CLOSE
    --------------------------------------------------

    local closeButton =
        ISButton:new(
            240,
            360,
            120,
            35,
            "CLOSE",
            window,
            function()

                JimmoleonBankUI:ClosePanel()

            end
        )


    closeButton:initialise()

    window:addChild(closeButton)


    --------------------------------------------------
    -- SHOW WINDOW
    --------------------------------------------------

    window:addToUIManager()

    window:setVisible(true)


    return window

end


--------------------------------------------------
-- STORE SCREEN
--------------------------------------------------

function JimmoleonBankUI.openStore(pl)

    if pl == nil then
        return
    end

    JimmoleonBankUI:ClosePanel()

    storeAdminOpen = false

    local width = 800
    local height = 540

    local x =
        (getCore():getScreenWidth() - width) / 2

    local y =
        (getCore():getScreenHeight() - height) / 2

    JimmoleonBankUI.instance =
        ISPanel:new(
            x,
            y,
            width,
            height
        )

    JimmoleonBankUI.instance:initialise()
    JimmoleonBankUI.instance.moveWithMouse = true
    JimmoleonBankUI.instance:setAlwaysOnTop(true)

    JimmoleonBankUI.instance.backgroundColor = {
        r = 0.05,
        g = 0.05,
        b = 0.05,
        a = 0.95
    }

    JimmoleonBankUI.instance.borderColor = {
        r = 0.2,
        g = 0.8,
        b = 0.2,
        a = 1
    }

    local window =
        JimmoleonBankUI.instance

    --------------------------------------------------
    -- TITLE
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            20,
            25,
            "JIMOLEON STORE",
            1,
            1,
            1,
            1,
            UIFont.Large,
            true
        )
    )

    --------------------------------------------------
    -- ACCOUNT / BALANCE
    --------------------------------------------------

    local md =
        pl:getModData()

    local accountID =
        md.JimmoleonAccountID or "UNKNOWN"

    local balance =
        md.JimmoleonBalance or 0

    window:addChild(
        ISLabel:new(
            20,
            58,
            25,
            "Account: " ..
            tostring(accountID),
            0.8,
            0.8,
            0.8,
            1,
            UIFont.Small,
            true
        )
    )

    window:addChild(
        ISLabel:new(
            20,
            80,
            25,
            "Balance: " ..
            tostring(balance) ..
            " Jimoleons",
            0.3,
            1,
            0.3,
            1,
            UIFont.Medium,
            true
        )
    )

    --------------------------------------------------
    -- CATEGORY LABEL
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            112,
            25,
            "CATEGORY",
            1,
            1,
            1,
            1,
            UIFont.Medium,
            true
        )
    )

    --------------------------------------------------
    -- CATEGORY SELECTOR
    --------------------------------------------------

    local categoryCombo =
        ISComboBox:new(
            20,
            142,
            740,
            32,
            window,
            function(target, combo)

                local selectedCategory =
                    combo:getSelectedData()

                if selectedCategory ~= nil then
                    JimmoleonBankUI.refreshStoreItems(
                        window,
                        pl,
                        selectedCategory
                    )
                end

            end
        )

    categoryCombo:initialise()

    window.categoryCombo = categoryCombo
    window:addChild(categoryCombo)

    --------------------------------------------------
    -- ITEMS AREA
    --------------------------------------------------

    local itemsPanel =
        ISPanel:new(
            20,
            190,
            760,
            275
        )

    itemsPanel:initialise()

    itemsPanel.backgroundColor = {
        r = 0.02,
        g = 0.02,
        b = 0.02,
        a = 0.55
    }

    itemsPanel.borderColor = {
        r = 0.12,
        g = 0.12,
        b = 0.12,
        a = 1
    }

    window.itemsPanel = itemsPanel
    window.storeItemControls = {}
    window:addChild(itemsPanel)

    --------------------------------------------------
    -- BACK
    --------------------------------------------------

    local backButton =
        ISButton:new(
            155,
            485,
            130,
            35,
            "BACK",
            window,
            function()
                JimmoleonBankUI.open(
                    pl
                )
            end
        )

    backButton:initialise()
    window:addChild(backButton)

    --------------------------------------------------
    -- CLOSE
    --------------------------------------------------

    local closeButton =
        ISButton:new(
            335,
            485,
            130,
            35,
            "CLOSE",
            window,
            function()
                JimmoleonBankUI:ClosePanel()
            end
        )

    closeButton:initialise()
    window:addChild(closeButton)

    --------------------------------------------------
    -- ADMIN
    --------------------------------------------------

    if isClientAdmin(pl) then

        local adminButton =
            ISButton:new(
                515,
                485,
                130,
                35,
                "ADMIN",
                window,
                function()
                    JimmoleonBankUI.openStoreAdmin(pl)
                end
            )

        adminButton:initialise()
        window:addChild(adminButton)

    end

    --------------------------------------------------
    -- SHOW WINDOW
    --------------------------------------------------

    window:addToUIManager()
    window:setVisible(true)

    --------------------------------------------------
    -- SHOW CURRENT CATALOG
    --------------------------------------------------

    JimmoleonBankUI.refreshStoreCategorySelector(
        window,
        pl
    )

    --------------------------------------------------
    -- ASK SERVER FOR CURRENT CATALOG
    --------------------------------------------------

    sendClientCommand(
        "JimmoleonEconomy",
        "GetStoreCatalog",
        {}
    )

    return window

end


--------------------------------------------------
-- REFRESH STORE CATEGORY SELECTOR
--------------------------------------------------

function JimmoleonBankUI.refreshStoreCategorySelector(
    window,
    pl
)

    if window == nil then
        return
    end

    if window.categoryCombo == nil then
        return
    end

    window.categoryCombo:clear()

    local categories =
        storeCatalog.categories or {}

    if #categories == 0 then

        window.categoryCombo:addOption(
            "No categories available"
        )

        JimmoleonBankUI.refreshStoreItems(
            window,
            pl,
            {
                name = "STORE",
                items = {}
            }
        )

        return

    end

    for _, category in ipairs(categories) do

        window.categoryCombo:addOptionWithData(
            tostring(category.name),
            category
        )

    end

    window.categoryCombo.selected = 1

    JimmoleonBankUI.refreshStoreItems(
        window,
        pl,
        categories[1]
    )

end


--------------------------------------------------
-- REFRESH STORE ITEMS
--------------------------------------------------

function JimmoleonBankUI.refreshStoreItems(
    window,
    pl,
    category
)

    if window == nil then
        return
    end

    if window.itemsPanel == nil then
        return
    end

    --------------------------------------------------
    -- REMOVE OLD CONTROLS
    --------------------------------------------------

    if window.storeItemControls ~= nil then
        for _, control in ipairs(window.storeItemControls) do
            if control ~= nil then
                window.itemsPanel:removeChild(control)
            end
        end
    end

    window.storeItemControls = {}
    window.storeItemList = nil

    --------------------------------------------------
    -- EMPTY CATEGORY
    --------------------------------------------------

    if category.items == nil
    or #category.items == 0
    then
        local emptyLabel =
            ISLabel:new(
                20,
                60,
                25,
                "No items available in this category yet.",
                0.8,
                0.8,
                0.8,
                1,
                UIFont.Medium,
                true
            )

        window.itemsPanel:addChild(emptyLabel)
        table.insert(window.storeItemControls, emptyLabel)
        return
    end

    --------------------------------------------------
    -- SCROLLING STORE ITEM LIST
    --
    -- Uses a native ISPanel scroll container.
    -- The scrollbar controls the panel's Y scroll position,
    -- while the store rows are explicitly repositioned from
    -- that scroll position. This keeps the real BUY buttons
    -- as actual clickable ISButton controls.
    --------------------------------------------------

    local storeList =
        ISPanel:new(
            0,
            38,
            760,
            228
        )

    storeList:initialise()

    storeList.backgroundColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 0
    }

    storeList.borderColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 0
    }

    --------------------------------------------------
    -- NATIVE SCROLL SETUP
    --------------------------------------------------

    -- We handle the child-row movement ourselves.
    -- This prevents the UI from applying the scroll twice.
    storeList:setScrollChildren(false)

    -- Make the children clip to the visible list area.
    if storeList.setRenderClippedChildren ~= nil then
        storeList:setRenderClippedChildren(true)
    end

    -- Keep a little room for the scrollbar.
    if storeList.setStencilRect ~= nil then
        storeList:setStencilRect(
            0,
            0,
            760,
            228
        )
    end

    -- Add the native vertical scrollbar.
    storeList:addScrollBars(false)

    storeList.storeRows = {}

    local rowHeight = 60
    local visibleHeight = 228
    local rowCount = #category.items

    -- The scrollable content must be taller than the visible area
    -- when there are enough items to overflow.
    local contentHeight =
        math.max(
            visibleHeight,
            (rowCount * rowHeight) + 4
        )

    storeList:setScrollHeight(contentHeight)

    --------------------------------------------------
    -- EXPLICIT MOUSE-WHEEL SCROLL
    --------------------------------------------------

    function storeList:onMouseWheel(del)

        if del == nil then
            return true
        end

        local scrollHeight =
            tonumber(self:getScrollHeight() or 0)

        local areaHeight =
            tonumber(self:getScrollAreaHeight() or self.height or 0)

        local maxScroll =
            math.max(
                0,
                scrollHeight - areaHeight
            )

        -- Project Zomboid's normal Y-scroll direction is negative
        -- when moving down through a scrollable panel.
        local newScroll =
            (self:getYScroll() or 0) - (del * 40)

        if newScroll > 0 then
            newScroll = 0
        end

        if newScroll < -maxScroll then
            newScroll = -maxScroll
        end

        self:setYScroll(newScroll)

        if self.updateScrollbars ~= nil then
            self:updateScrollbars()
        end

        return true
    end

    --------------------------------------------------
    -- POSITION THE ACTUAL STORE ROWS
    --
    -- This is the important fix:
    -- the row panels are moved using getYScroll().
    -- Dragging the scrollbar therefore moves the real rows.
    --------------------------------------------------

    function storeList:prerender()

        local scrollY =
            tonumber(self:getYScroll() or 0)

        if self.storeRows ~= nil then

            for _, rowData in ipairs(self.storeRows) do

                local rowPanel = rowData.panel
                local rowIndex = rowData.index

                if rowPanel ~= nil
                and rowIndex ~= nil
                then

                    local baseY =
                        ((rowIndex - 1) * rowHeight) + 2

                    local rowY =
                        baseY + scrollY

                    rowPanel:setY(rowY)

                    if rowY + 55 < 0
                    or rowY > visibleHeight
                    then
                        rowPanel:setVisible(false)
                    else
                        rowPanel:setVisible(true)
                    end

                end

            end

        end

        -- Draw the scrollbar normally.
        if ISPanel.prerender ~= nil then
            ISPanel.prerender(self)
        end
    end

    --------------------------------------------------
    -- FORWARD WHEEL EVENTS FROM THE ITEM AREA
    --------------------------------------------------

    window.itemsPanel.onMouseWheel =
        function(self, del)

            if window.storeItemList ~= nil then
                return window.storeItemList:onMouseWheel(del)
            end

            return false
        end

    --------------------------------------------------
    -- ADD LIST TO ITEMS PANEL
    --------------------------------------------------

    window.storeItemList = storeList

    window.itemsPanel:addChild(storeList)

    table.insert(
        window.storeItemControls,
        storeList
    )

    --------------------------------------------------
    -- ITEM ROWS
    -- Each row keeps the existing REAL BUY button.
    --------------------------------------------------

    for rowNumber, item in ipairs(category.items) do

        local rowIndex = rowNumber

        --------------------------------------------------
        -- ROW PANEL
        --------------------------------------------------

        local rowPanel =
            ISPanel:new(
                8,
                ((rowIndex - 1) * rowHeight) + 2,
                744,
                55
            )

        rowPanel:initialise()

        rowPanel.backgroundColor = {
            r = 0.03,
            g = 0.03,
            b = 0.03,
            a = 0.35
        }

        rowPanel.borderColor = {
            r = 0.12,
            g = 0.12,
            b = 0.12,
            a = 1
        }

        --------------------------------------------------
        -- FORWARD MOUSE WHEEL TO THE SCROLL CONTAINER
        --------------------------------------------------

        rowPanel.onMouseWheel =
            function(self, del)

                return storeList:onMouseWheel(del)

            end

        --------------------------------------------------
        -- ADD ROW TO SCROLL CONTAINER
        --------------------------------------------------

        storeList:addChild(rowPanel)

        table.insert(
            storeList.storeRows,
            {
                panel = rowPanel,
                index = rowIndex
            }
        )

        --------------------------------------------------
        -- ITEM ICON
        --------------------------------------------------

        local itemTexture = nil

        if item.itemType ~= nil then

            local ok, texture =
                pcall(
                    function()

                        return getItemTex(
                            tostring(item.itemType)
                        )

                    end
                )

            if ok then
                itemTexture = texture
            end

        end

        if itemTexture ~= nil then

            local iconPanel =
                ISPanel:new(
                    8,
                    7,
                    42,
                    42
                )

            iconPanel:initialise()

            iconPanel.itemTexture =
                itemTexture

            function iconPanel:prerender()

                ISPanel.prerender(self)

                if self.itemTexture ~= nil then

                    self:drawTextureScaled(
                        self.itemTexture,
                        2,
                        2,
                        38,
                        38,
                        1
                    )

                end

            end

            iconPanel.onMouseWheel =
                function(self, del)
                    return storeList:onMouseWheel(del)
                end

            rowPanel:addChild(iconPanel)

        end

        --------------------------------------------------
        -- ITEM NAME
        --------------------------------------------------

        local itemName =
            ISLabel:new(
                58,
                8,
                25,
                tostring(
                    item.name
                    or item.itemType
                    or "Item"
                ),
                1,
                1,
                1,
                1,
                UIFont.Medium,
                true
            )

        itemName.onMouseWheel =
            function(self, del)
                return storeList:onMouseWheel(del)
            end

        rowPanel:addChild(itemName)

        --------------------------------------------------
        -- PRICE
        --------------------------------------------------

        local itemPrice =
            ISLabel:new(
                58,
                30,
                25,
                tostring(
                    item.price
                    or 0
                ) .. " Jimoleons",
                0.3,
                1,
                0.3,
                1,
                UIFont.Small,
                true
            )

        itemPrice.onMouseWheel =
            function(self, del)
                return storeList:onMouseWheel(del)
            end

        rowPanel:addChild(itemPrice)

        --------------------------------------------------
        -- REAL BUY BUTTON
        --------------------------------------------------

        local buyButton =
            ISButton:new(
                650,
                9,
                82,
                36,
                "BUY",
                rowPanel,
                function()

                    if pl == nil then
                        return
                    end

                    sendClientCommand(
                        "JimmoleonEconomy",
                        "BuyStoreItem",
                        {
                            categoryID =
                                tostring(
                                    category.id
                                    or ""
                                ),

                            itemType =
                                tostring(
                                    item.itemType
                                    or ""
                                )
                        }
                    )

                end
            )

        buyButton:initialise()

        buyButton.onMouseWheel =
            function(self, del)
                return storeList:onMouseWheel(del)
            end

        rowPanel:addChild(
            buyButton
        )

    end

    --------------------------------------------------
    -- FORCE PZ TO RECALCULATE THE SCROLLBAR
    --------------------------------------------------

    if storeList.updateScrollbars ~= nil then
        storeList:updateScrollbars()
    end

    -- Start at the top whenever the category is refreshed.
    storeList:setYScroll(0)

    if storeList.updateScrollbars ~= nil then
        storeList:updateScrollbars()
    end
end

--------------------------------------------------
-- ADMIN BALANCE SCREEN
--------------------------------------------------

function JimmoleonBankUI.openBalanceAdmin(pl)
    if pl == nil then return end

    if not isClientAdmin(pl) then
        pl:setHaloNote("Admin access required.", 1, 0, 0, 300)
        return
    end

    JimmoleonBankUI:ClosePanel()

    local width, height = 800, 560
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2

    JimmoleonBankUI.instance = ISPanel:new(x, y, width, height)
    JimmoleonBankUI.instance:initialise()
    JimmoleonBankUI.instance.moveWithMouse = true
    JimmoleonBankUI.instance:setAlwaysOnTop(true)
    JimmoleonBankUI.instance.backgroundColor = {r=0.05,g=0.05,b=0.05,a=0.95}
    JimmoleonBankUI.instance.borderColor = {r=0.2,g=0.8,b=0.2,a=1}
    JimmoleonBankUI.instance.isBalanceAdmin = true

    local window = JimmoleonBankUI.instance

    window:addChild(
        ISLabel:new(
            20, 20, 25,
            "JIMOLEON BALANCE ADMIN",
            1,1,1,1,
            UIFont.Large,
            true
        )
    )

    window:addChild(
        ISLabel:new(
            20, 65, 25,
            "SELECT ONLINE PLAYER",
            1,1,1,1,
            UIFont.Medium,
            true
        )
    )

    local playerCombo =
        ISComboBox:new(
            20, 95, 360, 35,
            window,
            function()
                local data = playerCombo:getSelectedData()

                if data ~= nil then
                    window.selectedAdminPlayer = data

                    if window.currentBalanceLabel ~= nil then
                        window.currentBalanceLabel:setName(
                            "Current Balance: " ..
                            tostring(data.balance or 0) ..
                            " Jimoleons"
                        )
                    end
                end
            end
        )

    playerCombo:initialise()
    window.playerCombo = playerCombo
    window:addChild(playerCombo)

    local currentBalanceLabel =
        ISLabel:new(
            20, 145, 25,
            "Current Balance: 0 Jimoleons",
            0.3,1,0.3,1,
            UIFont.Medium,
            true
        )

    window.currentBalanceLabel = currentBalanceLabel
    window:addChild(currentBalanceLabel)

    window:addChild(
        ISLabel:new(
            20, 195, 25,
            "AMOUNT",
            1,1,1,1,
            UIFont.Medium,
            true
        )
    )

    local amountBox = ISTextEntryBox:new(
        "0",
        20, 225, 260, 35
    )

    amountBox:initialise()
    window.amountBox = amountBox
    window:addChild(amountBox)

    local addButton =
        ISButton:new(
            310, 225, 170, 40,
            "ADD JIMOLEONS",
            window,
            function()
                local data = window.selectedAdminPlayer
                local amount = tonumber(amountBox:getText())

                if data == nil then
                    pl:setHaloNote("Select an online player first.",1,0,0,300)
                    return
                end

                if amount == nil or amount <= 0 then
                    pl:setHaloNote("Enter an amount greater than 0.",1,0,0,300)
                    return
                end

                sendClientCommand(
                    "JimmoleonEconomy",
                    "AdminAddBalance",
                    {
                        accountID = tostring(data.accountID or ""),
                        username = tostring(data.username or ""),
                        amount = amount
                    }
                )
            end
        )

    addButton:initialise()
    window:addChild(addButton)

    local removeButton =
        ISButton:new(
            500, 225, 170, 40,
            "REMOVE JIMOLEONS",
            window,
            function()
                local data = window.selectedAdminPlayer
                local amount = tonumber(amountBox:getText())

                if data == nil then
                    pl:setHaloNote("Select an online player first.",1,0,0,300)
                    return
                end

                if amount == nil or amount <= 0 then
                    pl:setHaloNote("Enter an amount greater than 0.",1,0,0,300)
                    return
                end

                sendClientCommand(
                    "JimmoleonEconomy",
                    "AdminRemoveBalance",
                    {
                        accountID = tostring(data.accountID or ""),
                        username = tostring(data.username or ""),
                        amount = amount
                    }
                )
            end
        )

    removeButton:initialise()
    window:addChild(removeButton)

    local setButton =
        ISButton:new(
            310, 285, 360, 40,
            "SET BALANCE",
            window,
            function()
                local data = window.selectedAdminPlayer
                local amount = tonumber(amountBox:getText())

                if data == nil then
                    pl:setHaloNote("Select an online player first.",1,0,0,300)
                    return
                end

                if amount == nil or amount < 0 then
                    pl:setHaloNote("Enter a balance of 0 or greater.",1,0,0,300)
                    return
                end

                sendClientCommand(
                    "JimmoleonEconomy",
                    "AdminSetBalance",
                    {
                        accountID = tostring(data.accountID or ""),
                        username = tostring(data.username or ""),
                        amount = amount
                    }
                )
            end
        )

    setButton:initialise()
    window:addChild(setButton)

    window:addChild(
        ISLabel:new(
            20, 355, 25,
            "These controls change the player's actual server-side bank balance.",
            0.7,0.7,0.7,1,
            UIFont.Small,
            true
        )
    )

    local refreshButton =
        ISButton:new(
            20, 405, 170, 35,
            "REFRESH PLAYERS",
            window,
            function()
                sendClientCommand(
                    "JimmoleonEconomy",
                    "GetAdminPlayerList",
                    {}
                )
            end
        )

    refreshButton:initialise()
    window:addChild(refreshButton)

    local backButton =
        ISButton:new(
            250, 470, 150, 35,
            "BACK TO BANK",
            window,
            function()
                JimmoleonBankUI.openBank(pl)
            end
        )

    backButton:initialise()
    window:addChild(backButton)

    local closeButton =
        ISButton:new(
            420, 470, 150, 35,
            "CLOSE",
            window,
            function()
                JimmoleonBankUI:ClosePanel()
            end
        )

    closeButton:initialise()
    window:addChild(closeButton)

    window:addToUIManager()
    window:setVisible(true)

    sendClientCommand(
        "JimmoleonEconomy",
        "GetAdminPlayerList",
        {}
    )

    return window
end


--------------------------------------------------
-- VALUABLE ADMIN SCREEN
--------------------------------------------------

function JimmoleonBankUI.openValuableAdmin(pl)
    if pl == nil then return end
    if not isClientAdmin(pl) then
        pl:setHaloNote("Admin access required.", 1, 0, 0, 300)
        return
    end

    JimmoleonBankUI:ClosePanel()
    local width, height = 800, 620
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2

    JimmoleonBankUI.instance = ISPanel:new(x, y, width, height)
    JimmoleonBankUI.instance:initialise()
    JimmoleonBankUI.instance.moveWithMouse = true
    JimmoleonBankUI.instance:setAlwaysOnTop(true)
    JimmoleonBankUI.instance.backgroundColor = {r=0.05,g=0.05,b=0.05,a=0.95}
    JimmoleonBankUI.instance.borderColor = {r=0.2,g=0.8,b=0.2,a=1}
    JimmoleonBankUI.instance.isValuableAdmin = true

    local window = JimmoleonBankUI.instance
    window:addChild(ISLabel:new(20,20,25,"JIMOLEON VALUABLE ADMIN",1,1,1,1,UIFont.Large,true))
    window:addChild(ISLabel:new(20,65,25,"CURRENT DEPOSIT ITEMS",1,1,1,1,UIFont.Medium,true))

    local list = ISScrollingListBox:new(20,95,360,370)
    list:initialise()
    list:instantiate()
    list.font = UIFont.Small
    list.itemheight = 32
    list.doDrawItem = function(self, y, item, alt)
        local data = item.item
        if data ~= nil then
            self:drawText(tostring(data.name) .. " - " .. tostring(data.value) .. " Jimoleons", 8, y+7, 1,1,1,1, UIFont.Small)
        end
        return y + self.itemheight
    end
    window.valuableList = list
    window:addChild(list)

    window:addChild(ISLabel:new(420,65,25,"GAME ITEM",1,1,1,1,UIFont.Medium,true))
    local itemNameBox = ISTextEntryBox:new("",420,95,340,35)
    itemNameBox:initialise(); window.itemNameBox=itemNameBox; window:addChild(itemNameBox)

    local selectButton = ISButton:new(420,140,340,35,"SELECT GAME ITEM",window,function()
        JimmoleonBankUI.openItemPicker(window,pl)
    end)
    selectButton:initialise(); window:addChild(selectButton)

    window:addChild(ISLabel:new(420,190,25,"GAME ITEM TYPE",1,1,1,1,UIFont.Small,true))
    local itemTypeBox = ISTextEntryBox:new("",420,215,340,35)
    itemTypeBox:initialise(); window.itemTypeBox=itemTypeBox; window:addChild(itemTypeBox)

    window:addChild(ISLabel:new(420,265,25,"JIMOLEON VALUE",1,1,1,1,UIFont.Small,true))
    local valueBox = ISTextEntryBox:new("0",420,290,340,35)
    valueBox:initialise(); window.valueBox=valueBox; window:addChild(valueBox)

    local addButton = ISButton:new(420,340,160,40,"ADD",window,function()
        local selectedItem = window.selectedGameItem
        if selectedItem == nil then
            pl:setHaloNote("Select a game item first.",1,0,0,300); return
        end
        local value = tonumber(valueBox:getText())
        if value == nil or value <= 0 then
            pl:setHaloNote("Enter a value greater than 0.",1,0,0,300); return
        end
        sendClientCommand("JimmoleonEconomy","AddValuable",{name=tostring(selectedItem:getDisplayName() or selectedItem:getFullName()),itemType=tostring(selectedItem:getFullName() or ""),value=value})
    end)
    addButton:initialise(); window:addChild(addButton)

    local updateButton = ISButton:new(600,340,160,40,"UPDATE VALUE",window,function()
        local itemType=tostring(itemTypeBox:getText() or "")
        local value=tonumber(valueBox:getText())
        if itemType=="" or value==nil or value<=0 then
            pl:setHaloNote("Select an item and enter a valid value.",1,0,0,300); return
        end
        sendClientCommand("JimmoleonEconomy","UpdateValuable",{itemType=itemType,value=value})
    end)
    updateButton:initialise(); window:addChild(updateButton)

    local removeButton = ISButton:new(420,390,340,40,"REMOVE SELECTED VALUABLE",window,function()
        local itemType=tostring(itemTypeBox:getText() or "")
        if itemType=="" then pl:setHaloNote("Select a valuable first.",1,0,0,300); return end
        sendClientCommand("JimmoleonEconomy","RemoveValuable",{itemType=itemType})
    end)
    removeButton:initialise(); window:addChild(removeButton)

    window:addChild(ISLabel:new(420,445,340,"PAYCHECK AMOUNT",1,1,1,1,UIFont.Medium,true))
    local paycheckBox = ISTextEntryBox:new("100",420,475,160,35)
    paycheckBox:initialise(); window.paycheckBox=paycheckBox; window:addChild(paycheckBox)

    local paycheckButton = ISButton:new(600,475,160,35,"SET PAYCHECK",window,function()
        local amount = tonumber(paycheckBox:getText())
        if amount == nil or amount < 0 then
            pl:setHaloNote("Enter a paycheck amount of 0 or greater.",1,0,0,300); return
        end
        sendClientCommand("JimmoleonEconomy","SetPaycheckAmount",{amount=math.floor(amount)})
    end)
    paycheckButton:initialise(); window:addChild(paycheckButton)

    window:addChild(ISLabel:new(420,515,340,"Server paycheck setting saves globally.",0.7,0.7,0.7,1,UIFont.Small,true))

    local backButton=ISButton:new(180,565,200,35,"BACK TO BANK",window,function() JimmoleonBankUI.openBank(pl) end)
    backButton:initialise(); window:addChild(backButton)
    local closeButton=ISButton:new(420,565,200,35,"CLOSE",window,function() JimmoleonBankUI:ClosePanel() end)
    closeButton:initialise(); window:addChild(closeButton)

    list.onMouseDown = function(self,x,y)
        if #self.items == 0 then
            return
        end

        local row = self:rowAt(x,y)

        if row < 1 then
            row = 1
        elseif row > #self.items then
            row = #self.items
        end

        self.selected = row

        local selectedRow = self.items[row]
        if selectedRow ~= nil and selectedRow.item ~= nil then
            local data = selectedRow.item
            window.itemNameBox:setText(tostring(data.name or ""))
            window.itemTypeBox:setText(tostring(data.itemType or ""))
            window.valueBox:setText(tostring(data.value or 0))
            window.selectedGameItem = nil
        end
    end

    JimmoleonBankUI.refreshValuableAdminList(window)
    sendClientCommand("JimmoleonEconomy","GetValuableCatalog",{})
    window:addToUIManager(); window:setVisible(true)
    return window
end

function JimmoleonBankUI.refreshValuableAdminList(window)
    if window==nil or window.valuableList==nil then return end
    window.valuableList:clear()
    for _, valuable in ipairs(JimmoleonBankUI.depositValuables or {}) do
        window.valuableList:addItem(tostring(valuable.name),valuable)
    end
end


--------------------------------------------------
-- STORE ADMIN SCREEN
--------------------------------------------------

function JimmoleonBankUI.openStoreAdmin(pl)

    if pl == nil then
        return
    end

    if not isClientAdmin(pl) then
        pl:setHaloNote(
            "Admin access required.",
            1,
            0,
            0,
            300
        )
        return
    end

    JimmoleonBankUI:ClosePanel()
    storeAdminOpen = true

    local width = 800
    local height = 620

    local x =
        (getCore():getScreenWidth() - width) / 2

    local y =
        (getCore():getScreenHeight() - height) / 2

    JimmoleonBankUI.instance =
        ISPanel:new(
            x,
            y,
            width,
            height
        )

    JimmoleonBankUI.instance:initialise()
    JimmoleonBankUI.instance.moveWithMouse = true
    JimmoleonBankUI.instance:setAlwaysOnTop(true)

    JimmoleonBankUI.instance.backgroundColor = {
        r = 0.05,
        g = 0.05,
        b = 0.05,
        a = 0.95
    }

    JimmoleonBankUI.instance.borderColor = {
        r = 0.2,
        g = 0.8,
        b = 0.2,
        a = 1
    }

    local window =
        JimmoleonBankUI.instance

    window:addChild(
        ISLabel:new(
            20,
            20,
            25,
            "JIMOLEON STORE ADMIN",
            1,
            1,
            1,
            1,
            UIFont.Large,
            true
        )
    )

    --------------------------------------------------
    -- CREATE CATEGORY
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            70,
            25,
            "NEW CATEGORY NAME",
            1,
            1,
            1,
            1,
            UIFont.Medium,
            true
        )
    )

    local newCategoryBox =
        ISTextEntryBox:new(
            "",
            20,
            100,
            520,
            35
        )

    newCategoryBox:initialise()
    window.newCategoryBox = newCategoryBox
    window:addChild(newCategoryBox)

    local createCategoryButton =
        ISButton:new(
            555,
            100,
            205,
            35,
            "CREATE CATEGORY",
            window,
            function()

                local name =
                    newCategoryBox:getText()

                if name == nil
                or tostring(name) == ""
                then
                    pl:setHaloNote(
                        "Enter a category name.",
                        1,
                        0,
                        0,
                        300
                    )
                    return
                end

                sendClientCommand(
                    "JimmoleonEconomy",
                    "CreateStoreCategory",
                    {
                        name = tostring(name)
                    }
                )

            end
        )

    createCategoryButton:initialise()
    window:addChild(createCategoryButton)

    --------------------------------------------------
    -- CATEGORY SELECTOR
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            155,
            25,
            "CATEGORY TO MANAGE",
            1,
            1,
            1,
            1,
            UIFont.Medium,
            true
        )
    )

    local categoryCombo =
        ISComboBox:new(
            20,
            185,
            520,
            32,
            window,
            nil
        )

    categoryCombo:initialise()
    window.categoryCombo = categoryCombo
    window:addChild(categoryCombo)

    local deleteCategoryButton =
        ISButton:new(
            555,
            185,
            205,
            32,
            "DELETE CATEGORY",
            window,
            function()

                local category =
                    categoryCombo:getSelectedData()

                if category == nil then
                    pl:setHaloNote(
                        "Select a category first.",
                        1,
                        0,
                        0,
                        300
                    )
                    return
                end

                sendClientCommand(
                    "JimmoleonEconomy",
                    "DeleteStoreCategory",
                    {
                        categoryID = tostring(category.id)
                    }
                )

            end
        )

    deleteCategoryButton:initialise()
    window:addChild(deleteCategoryButton)

    --------------------------------------------------
    -- MANAGE STORE ITEMS
    --------------------------------------------------

    local manageItemsButton =
        ISButton:new(
            20,
            490,
            740,
            40,
            "MANAGE STORE ITEMS",
            window,
            function()
                JimmoleonBankUI.openStoreItemManager(pl)
            end
        )

    manageItemsButton:initialise()
    window:addChild(manageItemsButton)

    --------------------------------------------------
    -- ADD ITEM TO SELECTED CATEGORY
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            245,
            25,
            "ADD ITEM TO CATEGORY",
            1,
            1,
            1,
            1,
            UIFont.Large,
            true
        )
    )

    --------------------------------------------------
    -- ITEM PICKER
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            285,
            25,
            "GAME ITEM",
            1,
            1,
            1,
            1,
            UIFont.Small,
            true
        )
    )

    local itemNameBox =
        ISTextEntryBox:new(
            "",
            20,
            310,
            500,
            35
        )

    itemNameBox:initialise()
    window.itemNameBox = itemNameBox
    window:addChild(itemNameBox)

    local selectItemButton =
        ISButton:new(
            535,
            310,
            225,
            35,
            "SELECT GAME ITEM",
            window,
            function()
                JimmoleonBankUI.openItemPicker(
                    window,
                    pl
                )
            end
        )

    selectItemButton:initialise()
    window:addChild(selectItemButton)

    --------------------------------------------------
    -- ITEM TYPE FROM GAME
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            355,
            25,
            "GAME ITEM TYPE",
            1,
            1,
            1,
            1,
            UIFont.Small,
            true
        )
    )

    local itemTypeBox =
        ISTextEntryBox:new(
            "",
            20,
            380,
            500,
            35
        )

    itemTypeBox:initialise()
    window.itemTypeBox = itemTypeBox
    window:addChild(itemTypeBox)

    --------------------------------------------------
    -- PRICE
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            535,
            355,
            25,
            "PRICE",
            1,
            1,
            1,
            1,
            UIFont.Small,
            true
        )
    )

    local priceBox =
        ISTextEntryBox:new(
            "0",
            535,
            380,
            225,
            35
        )

    priceBox:initialise()
    window.priceBox = priceBox
    window:addChild(priceBox)

    local addItemButton =
        ISButton:new(
            20,
            435,
            740,
            40,
            "ADD ITEM TO SELECTED CATEGORY",
            window,
            function()

                local category =
                    categoryCombo:getSelectedData()

                local selectedGameItem =
                    window.selectedGameItem

                local itemName = nil
                local itemType = nil

                if selectedGameItem ~= nil then
                    itemName =
                        tostring(selectedGameItem:getDisplayName() or "")

                    itemType =
                        tostring(selectedGameItem:getFullName() or "")
                end

                local price =
                    tonumber(priceBox:getText())

                if category == nil then
                    pl:setHaloNote(
                        "Select a category first.",
                        1,
                        0,
                        0,
                        300
                    )
                    return
                end

                if selectedGameItem == nil
                or itemName == nil
                or tostring(itemName) == ""
                then
                    pl:setHaloNote(
                        "Select an item from the game Item List Viewer first.",
                        1,
                        0,
                        0,
                        300
                    )
                    return
                end

                if itemType == nil
                or tostring(itemType) == ""
                then
                    pl:setHaloNote(
                        "The selected game item has no valid item type.",
                        1,
                        0,
                        0,
                        300
                    )
                    return
                end

                if price == nil
                or price <= 0
                then
                    pl:setHaloNote(
                        "Enter a price greater than 0.",
                        1,
                        0,
                        0,
                        300
                    )
                    return
                end

                sendClientCommand(
                    "JimmoleonEconomy",
                    "AddStoreItem",
                    {
                        categoryID = tostring(category.id),
                        name = tostring(itemName),
                        itemType = tostring(itemType),
                        price = price
                    }
                )

            end
        )

    addItemButton:initialise()
    window:addChild(addItemButton)

    --------------------------------------------------
    -- BACK
    --------------------------------------------------

    local backButton =
        ISButton:new(
            230,
            535,
            150,
            35,
            "BACK TO STORE",
            window,
            function()
                storeAdminOpen = false
                JimmoleonBankUI.openStore(pl)
            end
        )

    backButton:initialise()
    window:addChild(backButton)

    --------------------------------------------------
    -- CLOSE
    --------------------------------------------------

    local closeButton =
        ISButton:new(
            420,
            535,
            150,
            35,
            "CLOSE",
            window,
            function()
                storeAdminOpen = false
                JimmoleonBankUI:ClosePanel()
            end
        )

    closeButton:initialise()
    window:addChild(closeButton)

    --------------------------------------------------
    -- SHOW WINDOW
    --------------------------------------------------

    window:addToUIManager()
    window:setVisible(true)

    JimmoleonBankUI.refreshAdminCategorySelector(
        window
    )

    sendClientCommand(
        "JimmoleonEconomy",
        "GetStoreCatalog",
        {}
    )

    return window

end


--------------------------------------------------
-- REFRESH ADMIN CATEGORY SELECTOR
--------------------------------------------------

function JimmoleonBankUI.refreshAdminCategorySelector(window)

    if window == nil
    or window.categoryCombo == nil
    then
        return
    end

    window.categoryCombo:clear()

    local categories =
        storeCatalog.categories or {}

    for _, category in ipairs(categories) do

        window.categoryCombo:addOptionWithData(
            tostring(category.name),
            category
        )

    end

    if #categories > 0 then
        window.categoryCombo.selected = 1
    end

end


--------------------------------------------------
-- STORE ITEM MANAGER
--------------------------------------------------

function JimmoleonBankUI.openStoreItemManager(pl)

    if pl == nil then
        return
    end

    if not isClientAdmin(pl) then
        pl:setHaloNote("Admin access required.", 1, 0, 0, 300)
        return
    end

    JimmoleonBankUI:ClosePanel()
    storeAdminOpen = true

    --------------------------------------------------
    -- LARGE, CLEAN MANAGER WINDOW
    --------------------------------------------------

    local width = 1000
    local height = 700

    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2

    JimmoleonBankUI.instance = ISPanel:new(x, y, width, height)
    JimmoleonBankUI.instance:initialise()
    JimmoleonBankUI.instance.moveWithMouse = true
    JimmoleonBankUI.instance:setAlwaysOnTop(true)

    JimmoleonBankUI.instance.backgroundColor = {
        r = 0.05,
        g = 0.05,
        b = 0.05,
        a = 0.95
    }

    JimmoleonBankUI.instance.borderColor = {
        r = 0.2,
        g = 0.8,
        b = 0.2,
        a = 1
    }

    JimmoleonBankUI.instance.isStoreItemManager = true

    local window = JimmoleonBankUI.instance

    --------------------------------------------------
    -- TITLE
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            18,
            25,
            "JIMOLEON STORE ITEM MANAGER",
            1,
            1,
            1,
            1,
            UIFont.Large,
            true
        )
    )

    window:addChild(
        ISLabel:new(
            20,
            52,
            25,
            "Change prices or remove items from the store.",
            0.7,
            0.7,
            0.7,
            1,
            UIFont.Medium,
            true
        )
    )

    --------------------------------------------------
    -- COLUMN HEADERS
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            30,
            80,
            25,
            "STORE ITEMS",
            0.65,
            0.65,
            0.65,
            1,
            UIFont.Small,
            true
        )
    )

    window:addChild(
        ISLabel:new(
            610,
            80,
            25,
            "PRICE",
            0.65,
            0.65,
            0.65,
            1,
            UIFont.Small,
            true
        )
    )

    --------------------------------------------------
    -- SCROLLING LIST
    --------------------------------------------------

    local listX = 20
    local listY = 102
    local listWidth = 960
    local listHeight = 525

    local list = ISPanel:new(
        listX,
        listY,
        listWidth,
        listHeight
    )

    list:initialise()

    list.backgroundColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 0
    }

    list.borderColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 0
    }

    list:setScrollChildren(false)

    if list.setRenderClippedChildren ~= nil then
        list:setRenderClippedChildren(true)
    end

    if list.setStencilRect ~= nil then
        list:setStencilRect(
            0,
            0,
            listWidth,
            listHeight
        )
    end

    list:addScrollBars(false)

    list.managerRows = {}

    --------------------------------------------------
    -- SCROLL
    --------------------------------------------------

    function list:onMouseWheel(del)

        if del == nil then
            return true
        end

        local scrollHeight =
            tonumber(
                self:getScrollHeight() or 0
            )

        local areaHeight =
            tonumber(
                self:getScrollAreaHeight()
                or self.height
                or 0
            )

        local maxScroll =
            math.max(
                0,
                scrollHeight - areaHeight
            )

        local newScroll =
            (self:getYScroll() or 0)
            - (del * 45)

        if newScroll > 0 then
            newScroll = 0
        end

        if newScroll < -maxScroll then
            newScroll = -maxScroll
        end

        self:setYScroll(newScroll)

        if self.updateScrollbars ~= nil then
            self:updateScrollbars()
        end

        return true
    end

    --------------------------------------------------
    -- MOVE CHILD ROWS WITH SCROLL
    --------------------------------------------------

    function list:prerender()

        local scrollY =
            tonumber(
                self:getYScroll() or 0
            )

        for _, rowData in ipairs(
            self.managerRows or {}
        ) do

            local control =
                rowData.control

            if control ~= nil then

                local controlY =
                    rowData.baseY + scrollY

                control:setY(controlY)

                local visible =
                    not (
                        controlY + rowData.height < 0
                        or
                        controlY > listHeight
                    )

                control:setVisible(
                    visible
                )

            end

        end

        if ISPanel.prerender ~= nil then
            ISPanel.prerender(self)
        end

    end

    window:addChild(list)

    window.storeItemManagerList =
        list

    --------------------------------------------------
    -- BACK TO ADMIN
    --------------------------------------------------

    local backButton =
        ISButton:new(
            330,
            645,
            170,
            35,
            "BACK TO ADMIN",
            window,
            function()

                JimmoleonBankUI.openStoreAdmin(
                    pl
                )

            end
        )

    backButton:initialise()

    window:addChild(
        backButton
    )

    --------------------------------------------------
    -- CLOSE
    --------------------------------------------------

    local closeButton =
        ISButton:new(
            520,
            645,
            150,
            35,
            "CLOSE",
            window,
            function()

                storeAdminOpen = false

                JimmoleonBankUI:ClosePanel()

            end
        )

    closeButton:initialise()

    window:addChild(
        closeButton
    )

    --------------------------------------------------
    -- SHOW
    --------------------------------------------------

    window:addToUIManager()

    window:setVisible(true)

    JimmoleonBankUI.refreshStoreItemManager(
        window,
        pl
    )

    sendClientCommand(
        "JimmoleonEconomy",
        "GetStoreCatalog",
        {}
    )

    return window

end


--------------------------------------------------
-- REFRESH STORE ITEM MANAGER
--------------------------------------------------

function JimmoleonBankUI.refreshStoreItemManager(
    window,
    pl
)

    if window == nil
    or window.storeItemManagerList == nil
    then
        return
    end

    local list =
        window.storeItemManagerList

    --------------------------------------------------
    -- REMOVE OLD CONTROLS
    --------------------------------------------------

    for _, rowData in ipairs(
        list.managerRows or {}
    ) do

        if rowData.control ~= nil then
            list:removeChild(
                rowData.control
            )
        end

    end

    list.managerRows = {}

    local oldRows =
        window.storeItemManagerRows
        or {}

    for _, row in ipairs(oldRows) do
        if row ~= nil then
            list:removeChild(row)
        end
    end

    window.storeItemManagerRows = {}

    --------------------------------------------------
    -- BUILD FLAT CATEGORY / ITEM DISPLAY
    --
    -- Categories are shown ONCE.
    -- Items are grouped underneath them.
    --------------------------------------------------

    local displayEntries = {}

    for _, category in ipairs(
        storeCatalog.categories or {}
    ) do

        table.insert(
            displayEntries,
            {
                kind = "category",
                category = category
            }
        )

        for _, item in ipairs(
            category.items or {}
        ) do

            table.insert(
                displayEntries,
                {
                    kind = "item",
                    category = category,
                    item = item
                }
            )

        end

    end

    --------------------------------------------------
    -- EMPTY STORE
    --------------------------------------------------

    if #displayEntries == 0 then

        local empty =
            ISLabel:new(
                20,
                20,
                25,
                "No items are currently in the store.",
                0.8,
                0.8,
                0.8,
                1,
                UIFont.Medium,
                true
            )

        list:addChild(empty)

        table.insert(
            list.managerRows,
            {
                control = empty,
                baseY = 20,
                height = 30
            }
        )

        list:setScrollHeight(
            list.height
        )

        list:setYScroll(0)

        return

    end

    --------------------------------------------------
    -- LAYOUT
    --------------------------------------------------

    local categoryHeight = 34
    local itemHeight = 76
    local currentY = 4

    for _, entry in ipairs(
        displayEntries
    ) do

        --------------------------------------------------
        -- CATEGORY HEADER
        --------------------------------------------------

        if entry.kind == "category" then

            local category =
                entry.category

            local header =
                ISPanel:new(
                    5,
                    currentY,
                    950,
                    categoryHeight - 4
                )

            header:initialise()

            header.backgroundColor = {
                r = 0.03,
                g = 0.03,
                b = 0.03,
                a = 0.80
            }

            header.borderColor = {
                r = 0.12,
                g = 0.12,
                b = 0.12,
                a = 1
            }

            list:addChild(header)

            local categoryLabel =
                ISLabel:new(
                    12,
                    6,
                    20,
                    tostring(
                        category.name
                        or
                        "STORE"
                    ),
                    0.3,
                    1,
                    0.3,
                    1,
                    UIFont.Medium,
                    true
                )

            categoryLabel.onMouseWheel =
                function(self, del)
                    return list:onMouseWheel(
                        del
                    )
                end

            header:addChild(
                categoryLabel
            )

            table.insert(
                list.managerRows,
                {
                    control = header,
                    baseY = currentY,
                    height = categoryHeight
                }
            )

            currentY =
                currentY + categoryHeight

        --------------------------------------------------
        -- ITEM ROW
        --------------------------------------------------

        else

            local category =
                entry.category

            local item =
                entry.item

            local row =
                ISPanel:new(
                    5,
                    currentY,
                    950,
                    itemHeight - 4
                )

            row:initialise()

            row.backgroundColor = {
                r = 0.03,
                g = 0.03,
                b = 0.03,
                a = 0.45
            }

            row.borderColor = {
                r = 0.12,
                g = 0.12,
                b = 0.12,
                a = 1
            }

            row.onMouseWheel =
                function(self, del)
                    return list:onMouseWheel(
                        del
                    )
                end

            list:addChild(row)

            table.insert(
                list.managerRows,
                {
                    control = row,
                    baseY = currentY,
                    height = itemHeight
                }
            )

            --------------------------------------------------
            -- ITEM NAME
            --------------------------------------------------

            local itemName =
                tostring(
                    item.name
                    or
                    item.itemType
                    or
                    "Item"
                )

            if #itemName > 62 then
                itemName =
                    string.sub(
                        itemName,
                        1,
                        59
                    )
                    .. "..."
            end

            local nameLabel =
                ISLabel:new(
                    12,
                    9,
                    25,
                    itemName,
                    1,
                    1,
                    1,
                    1,
                    UIFont.Medium,
                    true
                )

            nameLabel.onMouseWheel =
                function(self, del)
                    return list:onMouseWheel(
                        del
                    )
                end

            row:addChild(
                nameLabel
            )

            --------------------------------------------------
            -- ITEM TYPE
            --------------------------------------------------

            local itemType =
                tostring(
                    item.itemType
                    or
                    ""
                )

            if #itemType > 62 then
                itemType =
                    string.sub(
                        itemType,
                        1,
                        59
                    )
                    .. "..."
            end

            local typeLabel =
                ISLabel:new(
                    12,
                    37,
                    25,
                    itemType,
                    0.55,
                    0.55,
                    0.55,
                    1,
                    UIFont.Small,
                    true
                )

            typeLabel.onMouseWheel =
                function(self, del)
                    return list:onMouseWheel(
                        del
                    )
                end

            row:addChild(
                typeLabel
            )

            --------------------------------------------------
            -- PRICE BOX
            --------------------------------------------------

            local priceBox =
                ISTextEntryBox:new(
                    tostring(
                        item.price
                        or
                        0
                    ),
                    600,
                    17,
                    110,
                    35
                )

            priceBox:initialise()

            priceBox.onMouseWheel =
                function(self, del)
                    return list:onMouseWheel(
                        del
                    )
                end

            row:addChild(
                priceBox
            )

            --------------------------------------------------
            -- CHANGE PRICE
            --------------------------------------------------

            local priceButton =
                ISButton:new(
                    725,
                    17,
                    130,
                    35,
                    "CHANGE PRICE",
                    row,
                    function()

                        local newPrice =
                            tonumber(
                                priceBox:getText()
                            )

                        if newPrice == nil
                        or newPrice <= 0
                        then

                            pl:setHaloNote(
                                "Enter a price greater than 0.",
                                1,
                                0,
                                0,
                                300
                            )

                            return

                        end

                        sendClientCommand(
                            "JimmoleonEconomy",
                            "UpdateStoreItemPrice",
                            {
                                categoryID =
                                    tostring(
                                        category.id
                                    ),

                                itemType =
                                    tostring(
                                        item.itemType
                                    ),

                                price =
                                    math.floor(
                                        newPrice
                                    )
                            }
                        )

                    end
                )

            priceButton:initialise()

            priceButton.onMouseWheel =
                function(self, del)
                    return list:onMouseWheel(
                        del
                    )
                end

            row:addChild(
                priceButton
            )

            --------------------------------------------------
            -- REMOVE
            --------------------------------------------------

            local removeButton =
                ISButton:new(
                    870,
                    17,
                    75,
                    35,
                    "REMOVE",
                    row,
                    function()

                        sendClientCommand(
                            "JimmoleonEconomy",
                            "RemoveStoreItem",
                            {
                                categoryID =
                                    tostring(
                                        category.id
                                    ),

                                itemType =
                                    tostring(
                                        item.itemType
                                    )
                            }
                        )

                    end
                )

            removeButton:initialise()

            removeButton.onMouseWheel =
                function(self, del)
                    return list:onMouseWheel(
                        del
                    )
                end

            row:addChild(
                removeButton
            )

            currentY =
                currentY + itemHeight

        end

    end

    --------------------------------------------------
    -- SET CONTENT HEIGHT
    --------------------------------------------------

    local contentHeight =
        math.max(
            list.height,
            currentY + 4
        )

    list:setScrollHeight(
        contentHeight
    )

    list:setYScroll(0)

    if list.updateScrollbars ~= nil then
        list:updateScrollbars()
    end

end


--------------------------------------------------
-- DEPOSIT SCREEN
--------------------------------------------------

function JimmoleonBankUI.openDeposit(pl)

    if pl == nil then
        return
    end

    sendClientCommand("JimmoleonEconomy", "GetValuableCatalog", {})

    JimmoleonBankUI:ClosePanel()


    local inv =
        pl:getInventory()


    local width = 520

    local height = 390


    local x =
        (getCore():getScreenWidth() - width) / 2

    local y =
        (getCore():getScreenHeight() - height) / 2


    JimmoleonBankUI.instance =
        ISPanel:new(
            x,
            y,
            width,
            height
        )


    JimmoleonBankUI.instance:initialise()

    JimmoleonBankUI.instance.moveWithMouse = true

    JimmoleonBankUI.instance:setAlwaysOnTop(true)


    JimmoleonBankUI.instance.backgroundColor = {
        r = 0.05,
        g = 0.05,
        b = 0.05,
        a = 0.95
    }


    JimmoleonBankUI.instance.borderColor = {
        r = 0.2,
        g = 0.8,
        b = 0.2,
        a = 1
    }


    local window =
        JimmoleonBankUI.instance


    --------------------------------------------------
    -- TITLE
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            20,
            25,
            "DEPOSIT JIMOLEONS",
            1,
            1,
            1,
            1,
            UIFont.Large,
            true
        )
    )


    --------------------------------------------------
    -- ITEM LABEL
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            70,
            25,
            "Valuable:",
            1,
            1,
            1,
            1,
            UIFont.Medium,
            true
        )
    )


    --------------------------------------------------
    -- ITEM SELECTOR
    --------------------------------------------------

    local valuableCombo =
        ISComboBox:new(
            140,
            65,
            300,
            30,
            window,
            function(target, combo)

                selectedValuable =
                    combo:getSelectedData()


                if selectedValuable == nil then
                    return
                end


                JimmoleonBankUI.updateDepositInformation(
                    window,
                    inv
                )


                if window.amountBox ~= nil then
                    window.amountBox:setText("0")
                end

            end
        )


    valuableCombo:initialise()


    for _, valuable in ipairs(
        JimmoleonBankUI.depositValuables
    ) do

        valuableCombo:addOptionWithData(
            valuable.name,
            valuable
        )

    end


    valuableCombo.selected = 1

    selectedValuable =
        JimmoleonBankUI.depositValuables[1]


    window:addChild(
        valuableCombo
    )


    --------------------------------------------------
    -- AVAILABLE
    --------------------------------------------------

    local initialCount =
        inv:getItemCount(
            selectedValuable.itemType
        )


    local availableLabel =
        ISLabel:new(
            20,
            120,
            25,
            "You Have: " ..
            tostring(initialCount),
            0.8,
            0.8,
            0.8,
            1,
            UIFont.Medium,
            true
        )


    window.availableLabel =
        availableLabel


    window:addChild(
        availableLabel
    )


    --------------------------------------------------
    -- VALUE
    --------------------------------------------------

    local valueLabel =
        ISLabel:new(
            20,
            155,
            25,
            "Value: " ..
            tostring(
                selectedValuable.value
            ) ..
            " Jimoleons each",
            0.3,
            1,
            0.3,
            1,
            UIFont.Medium,
            true
        )


    window.valueLabel =
        valueLabel


    window:addChild(
        valueLabel
    )


    --------------------------------------------------
    -- AMOUNT
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            205,
            25,
            "Amount:",
            1,
            1,
            1,
            1,
            UIFont.Medium,
            true
        )
    )


    local amountBox =
        ISTextEntryBox:new(
            "0",
            140,
            200,
            120,
            30
        )


    amountBox:initialise()


    window.amountBox =
        amountBox


    window:addChild(
        amountBox
    )


    --------------------------------------------------
    -- DEPOSIT BUTTON
    --------------------------------------------------

    local depositButton =
        ISButton:new(
            280,
            200,
            160,
            35,
            "DEPOSIT",
            window,
            function()

                if selectedValuable == nil then
                    return
                end


                local amount =
                    tonumber(
                        amountBox:getText()
                    )


                if amount == nil then

                    pl:setHaloNote(
                        "Enter a valid amount.",
                        1,
                        0,
                        0,
                        300
                    )

                    return

                end


                sendClientCommand(
                    "JimmoleonEconomy",
                    "DepositValuable",
                    {
                        itemType =
                            selectedValuable.itemType,

                        amount =
                            amount
                    }
                )

            end
        )


    depositButton:initialise()

    window:addChild(
        depositButton
    )


    --------------------------------------------------
    -- BACK TO BANK
    --------------------------------------------------

    local backButton =
        ISButton:new(
            120,
            300,
            130,
            35,
            "BACK",
            window,
            function()

                JimmoleonBankUI.openBank(
                    pl
                )

            end
        )


    backButton:initialise()

    window:addChild(
        backButton
    )


    --------------------------------------------------
    -- CLOSE
    --------------------------------------------------

    local closeButton =
        ISButton:new(
            270,
            300,
            130,
            35,
            "CLOSE",
            window,
            function()

                JimmoleonBankUI:ClosePanel()

            end
        )


    closeButton:initialise()

    window:addChild(
        closeButton
    )


    --------------------------------------------------
    -- SHOW WINDOW
    --------------------------------------------------

    window:addToUIManager()

    window:setVisible(true)


    return window

end


--------------------------------------------------
-- TRANSFER SCREEN
--------------------------------------------------

function JimmoleonBankUI.openTransfer(pl)

    if pl == nil then
        return
    end


    JimmoleonBankUI:ClosePanel()


    local md =
        pl:getModData()


    local currentBalance =
        md.JimmoleonBalance or 0


    local width = 520

    local height = 390


    local x =
        (getCore():getScreenWidth() - width) / 2

    local y =
        (getCore():getScreenHeight() - height) / 2


    JimmoleonBankUI.instance =
        ISPanel:new(
            x,
            y,
            width,
            height
        )


    JimmoleonBankUI.instance:initialise()

    JimmoleonBankUI.instance.moveWithMouse = true

    JimmoleonBankUI.instance:setAlwaysOnTop(true)


    JimmoleonBankUI.instance.backgroundColor = {
        r = 0.05,
        g = 0.05,
        b = 0.05,
        a = 0.95
    }


    JimmoleonBankUI.instance.borderColor = {
        r = 0.2,
        g = 0.8,
        b = 0.2,
        a = 1
    }


    local window =
        JimmoleonBankUI.instance


    --------------------------------------------------
    -- TITLE
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            20,
            25,
            "TRANSFER JIMOLEONS",
            1,
            1,
            1,
            1,
            UIFont.Large,
            true
        )
    )


    --------------------------------------------------
    -- BALANCE
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            70,
            25,
            "Available: " ..
            tostring(currentBalance) ..
            " Jimoleons",
            0.3,
            1,
            0.3,
            1,
            UIFont.Medium,
            true
        )
    )


    --------------------------------------------------
    -- RECIPIENT
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            120,
            25,
            "Recipient Account:",
            1,
            1,
            1,
            1,
            UIFont.Medium,
            true
        )
    )


    local recipientBox =
        ISTextEntryBox:new(
            "",
            20,
            150,
            400,
            35
        )


    recipientBox:initialise()


    window.recipientBox =
        recipientBox


    window:addChild(
        recipientBox
    )


    --------------------------------------------------
    -- AMOUNT
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            205,
            25,
            "Amount:",
            1,
            1,
            1,
            1,
            UIFont.Medium,
            true
        )
    )


    local amountBox =
        ISTextEntryBox:new(
            "0",
            20,
            235,
            180,
            35
        )


    amountBox:initialise()


    window.amountBox =
        amountBox


    window:addChild(
        amountBox
    )


    --------------------------------------------------
    -- TRANSFER BUTTON
    --------------------------------------------------

    local transferButton =
        ISButton:new(
            225,
            235,
            195,
            40,
            "TRANSFER",
            window,
            function()

                local recipientAccountID =
                    recipientBox:getText()


                local amount =
                    tonumber(
                        amountBox:getText()
                    )


                if recipientAccountID == nil
                or tostring(recipientAccountID) == ""
                then

                    pl:setHaloNote(
                        "Enter a recipient account ID.",
                        1,
                        0,
                        0,
                        300
                    )

                    return

                end


                if amount == nil then

                    pl:setHaloNote(
                        "Enter a valid amount.",
                        1,
                        0,
                        0,
                        300
                    )

                    return

                end


                sendClientCommand(
                    "JimmoleonEconomy",
                    "TransferJimoleons",
                    {
                        recipientAccountID =
                            tostring(
                                recipientAccountID
                            ),

                        amount =
                            amount
                    }
                )

            end
        )


    transferButton:initialise()

    window:addChild(
        transferButton
    )


    --------------------------------------------------
    -- BACK
    --------------------------------------------------

    local backButton =
        ISButton:new(
            120,
            315,
            130,
            35,
            "BACK",
            window,
            function()

                JimmoleonBankUI.openBank(
                    pl
                )

            end
        )


    backButton:initialise()

    window:addChild(
        backButton
    )


    --------------------------------------------------
    -- CLOSE
    --------------------------------------------------

    local closeButton =
        ISButton:new(
            270,
            315,
            130,
            35,
            "CLOSE",
            window,
            function()

                JimmoleonBankUI:ClosePanel()

            end
        )


    closeButton:initialise()

    window:addChild(
        closeButton
    )


    --------------------------------------------------
    -- SHOW WINDOW
    --------------------------------------------------

    window:addToUIManager()

    window:setVisible(true)


    return window

end


--------------------------------------------------
-- TRANSACTION HISTORY
--------------------------------------------------

function JimmoleonBankUI.openTransactions(
    pl,
    returnToBank
)

    if pl == nil then
        return
    end

    JimmoleonBankUI:ClosePanel()

    local md = pl:getModData()
    local transactions = md.JimmoleonTransactions or {}
    local accountID = md.JimmoleonAccountID or "UNKNOWN"

    local width = 760
    local height = 540

    local x =
        (getCore():getScreenWidth() - width) / 2

    local y =
        (getCore():getScreenHeight() - height) / 2

    JimmoleonBankUI.instance =
        ISPanel:new(x, y, width, height)

    JimmoleonBankUI.instance:initialise()
    JimmoleonBankUI.instance.moveWithMouse = true
    JimmoleonBankUI.instance:setAlwaysOnTop(true)

    JimmoleonBankUI.instance.backgroundColor = {
        r = 0.05,
        g = 0.05,
        b = 0.05,
        a = 0.95
    }

    JimmoleonBankUI.instance.borderColor = {
        r = 0.2,
        g = 0.8,
        b = 0.2,
        a = 1
    }

    local window = JimmoleonBankUI.instance

    --------------------------------------------------
    -- TITLE
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            20,
            25,
            "TRANSACTION HISTORY",
            1,1,1,1,
            UIFont.Large,
            true
        )
    )

    --------------------------------------------------
    -- ACCOUNT
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            58,
            25,
            "Account: " .. tostring(accountID),
            0.8,0.8,0.8,1,
            UIFont.Small,
            true
        )
    )

    --------------------------------------------------
    -- TABLE HEADER
    --------------------------------------------------

    window:addChild(
        ISLabel:new(
            20,
            92,
            25,
            "AMOUNT",
            0.65,0.65,0.65,1,
            UIFont.Small,
            true
        )
    )

    window:addChild(
        ISLabel:new(
            170,
            92,
            25,
            "DESCRIPTION",
            0.65,0.65,0.65,1,
            UIFont.Small,
            true
        )
    )

    window:addChild(
        ISLabel:new(
            585,
            92,
            25,
            "TYPE",
            0.65,0.65,0.65,1,
            UIFont.Small,
            true
        )
    )

    --------------------------------------------------
    -- SCROLLING TRANSACTION LIST
    --------------------------------------------------

    local list =
        ISScrollingListBox:new(
            15,
            120,
            730,
            350
        )

    list:initialise()
    list:instantiate()
    list.itemheight = 50
    list.font = UIFont.Small
    list.drawBorder = true

    list.doDrawItem = function(self, y, item, alt)

        local tx = item.item or {}

        if alt then
            self:drawRect(
                0,
                y,
                self.width,
                item.height - 1,
                0.08,
                0.08,
                0.08,
                0.35
            )
        end

        local amount = tonumber(tx.amount) or 0
        local prefix = amount >= 0 and "+" or ""
        local amountText = prefix .. tostring(amount)

        local description =
            tostring(tx.description or "Unknown Transaction")

        if #description > 52 then
            description = string.sub(description, 1, 49) .. "..."
        end

        local txType =
            tostring(tx.type or "UNKNOWN")

        self:drawText(
            amountText,
            8,
            y + 15,
            0.3,1,0.3,1,
            UIFont.Small
        )

        self:drawText(
            description,
            155,
            y + 15,
            1,1,1,1,
            UIFont.Small
        )

        self:drawText(
            txType,
            570,
            y + 15,
            0.6,0.6,0.6,1,
            UIFont.Small
        )

        return y + item.height
    end

    window:addChild(list)
    window.transactionList = list

    if #transactions == 0 then
        list:addItem(
            "No transactions yet.",
            {
                amount = 0,
                description = "No transactions yet.",
                type = ""
            }
        )
    else
        for i = #transactions, 1, -1 do
            local transaction = transactions[i]
            list:addItem(
                tostring(transaction.description or "Transaction"),
                transaction
            )
        end
    end

    --------------------------------------------------
    -- BACK
    --------------------------------------------------

    local backButton =
        ISButton:new(
            230,
            485,
            120,
            30,
            "BACK",
            window,
            function()

                if returnToBank == true then
                    JimmoleonBankUI.openBank(pl)
                else
                    JimmoleonBankUI.open(pl)
                end

            end
        )

    backButton:initialise()
    window:addChild(backButton)

    --------------------------------------------------
    -- CLOSE
    --------------------------------------------------

    local closeButton =
        ISButton:new(
            410,
            485,
            120,
            30,
            "CLOSE",
            window,
            function()
                JimmoleonBankUI:ClosePanel()
            end
        )

    closeButton:initialise()
    window:addChild(closeButton)

    window:addToUIManager()
    window:setVisible(true)

    return window

end

--------------------------------------------------
-- SERVER COMMANDS
--------------------------------------------------

function JimmoleonBankUI.onServerCommand(
    module,
    command,
    args
)

    if module ~= "JimmoleonEconomy" then
        return
    end

    if args == nil then
        return
    end


    --------------------------------------------------
    -- DEPOSIT RESULT
    --------------------------------------------------

    if command == "DepositResult" then

        local pl = getPlayer()

        if args.success == true then
            print("JIMOLEON DEPOSIT SUCCESS: +" .. tostring(args.amount))

            if pl ~= nil then
                local modData = pl:getModData()
                modData.JimmoleonBalance = tonumber(args.newBalance) or modData.JimmoleonBalance or 0

                if args.transaction ~= nil then
                    if modData.JimmoleonTransactions == nil then
                        modData.JimmoleonTransactions = {}
                    end
                    table.insert(modData.JimmoleonTransactions, args.transaction)
                end

                pl:setHaloNote("+" .. tostring(args.amount) .. " Jimoleons", 0, 1, 0, 300)

                if JimmoleonBankUI.instance ~= nil then
                    JimmoleonBankUI.openBank(pl)
                end
            end
        else
            print("JIMOLEON DEPOSIT FAILED: " .. tostring(args.message))
            if pl ~= nil then
                pl:setHaloNote(tostring(args.message), 1, 0, 0, 300)
            end
        end

        return
    end


    --------------------------------------------------
    -- VALUABLE CATALOG
    --------------------------------------------------

    if command == "ValuableCatalog" then
        JimmoleonBankUI.depositValuables = args.valuables or {}
        if JimmoleonBankUI.instance ~= nil and JimmoleonBankUI.instance.isValuableAdmin == true then
            JimmoleonBankUI.refreshValuableAdminList(JimmoleonBankUI.instance)
            if JimmoleonBankUI.instance.paycheckBox ~= nil and args.paycheckAmount ~= nil then
                JimmoleonBankUI.instance.paycheckBox:setText(tostring(args.paycheckAmount))
            end
        end
        return
    end



    --------------------------------------------------
    -- ADMIN PLAYER LIST
    --------------------------------------------------

    if command == "AdminPlayerList" then
        local window = JimmoleonBankUI.instance

        if window ~= nil and window.isBalanceAdmin == true then
            window.playerCombo:clear()
            window.selectedAdminPlayer = nil

            local players = args.players or {}

            for _, data in ipairs(players) do
                if data ~= nil and data.online == true then
                    local name = tostring(data.characterName or data.username or "Player")
                    local accountID = tostring(data.accountID or "")
                    local label = name .. "  [" .. accountID .. "]"

                    window.playerCombo:addOptionWithData(
                        label,
                        data
                    )
                end
            end

            if #players > 0 then
                local firstOnline = nil

                for _, data in ipairs(players) do
                    if data ~= nil and data.online == true then
                        firstOnline = data
                        break
                    end
                end

                if firstOnline ~= nil then
                    window.playerCombo.selected = 1
                    window.selectedAdminPlayer = firstOnline

                    if window.currentBalanceLabel ~= nil then
                        window.currentBalanceLabel:setName(
                            "Current Balance: " ..
                            tostring(firstOnline.balance or 0) ..
                            " Jimoleons"
                        )
                    end
                end
            end
        end

        return
    end

    --------------------------------------------------
    -- ADMIN BALANCE RESULT
    --------------------------------------------------

    if command == "AdminBalanceResult" then
        local pl = getPlayer()

        if pl ~= nil then
            if args.success == true then
                pl:setHaloNote(
                    tostring(args.message or "Balance updated."),
                    0.15,1.0,0.15,300
                )

                local window = JimmoleonBankUI.instance

                if window ~= nil
                and window.isBalanceAdmin == true
                and args.username ~= nil
                then
                    local current = tonumber(args.balance) or 0

                    if window.currentBalanceLabel ~= nil then
                        window.currentBalanceLabel:setName(
                            "Current Balance: " ..
                            tostring(current) ..
                            " Jimoleons"
                        )
                    end

                    if window.selectedAdminPlayer ~= nil
                    and tostring(window.selectedAdminPlayer.accountID or "") == tostring(args.accountID or window.selectedAdminPlayer.accountID or "")
                    then
                        window.selectedAdminPlayer.balance = current
                    end
                end
            else
                pl:setHaloNote(
                    tostring(args.message or "Balance update failed."),
                    1,0,0,300
                )
            end
        end

        return
    end


    --------------------------------------------------
    -- LIVE ADMIN BALANCE UPDATE
    --------------------------------------------------

    if command == "AdminBalanceUpdated" then
        local pl = getPlayer()

        if pl ~= nil then
            if JimmoleonBankUI.instance ~= nil
            and JimmoleonBankUI.instance.isBalanceAdmin == true
            then
                local newBalance = tonumber(args.newBalance) or 0

                if JimmoleonBankUI.instance.currentBalanceLabel ~= nil then
                    JimmoleonBankUI.instance.currentBalanceLabel:setName(
                        "Current Balance: " ..
                        tostring(newBalance) ..
                        " Jimoleons"
                    )
                end
            end

            if pl:getModData() ~= nil then
                pl:getModData().JimmoleonBalance =
                    tonumber(args.newBalance) or
                    pl:getModData().JimmoleonBalance or
                    0
            end
        end

        return
    end


    --------------------------------------------------
    -- VALUABLE ADMIN RESULT
    --------------------------------------------------

    if command == "ValuableAdminResult" then
        local pl = getPlayer()
        if pl ~= nil then
            if args.success == true then
                pl:setHaloNote(tostring(args.message or "Valuable updated."), 0.15, 1.0, 0.15, 300)
            else
                pl:setHaloNote(tostring(args.message or "Valuable update failed."), 1, 0, 0, 300)
            end
        end
        return
    end


    --------------------------------------------------
    -- STORE CATALOG
    --------------------------------------------------

    if command == "StoreCatalog" then

        storeCatalog = args.catalog or { categories = {} }

        if JimmoleonBankUI.instance ~= nil then

            if JimmoleonBankUI.instance.isStoreItemManager == true then
                JimmoleonBankUI.refreshStoreItemManager(
                    JimmoleonBankUI.instance,
                    getPlayer()
                )
            elseif storeAdminOpen then
                JimmoleonBankUI.refreshAdminCategorySelector(
                    JimmoleonBankUI.instance
                )
            else
                JimmoleonBankUI.refreshStoreCategorySelector(
                    JimmoleonBankUI.instance,
                    getPlayer()
                )
            end

        end

        return

    end

    --------------------------------------------------
    -- STORE PURCHASE RESULT
    --------------------------------------------------

    if command == "StorePurchaseResult" then

        local pl =
            getPlayer()

        if args.success == true then

            if pl ~= nil then

                --------------------------------------------------
                -- UPDATE CLIENT BALANCE
                --------------------------------------------------

                local serverBalance =
                    tonumber(args.newBalance)

                if serverBalance ~= nil then
                    pl:getModData().JimmoleonBalance =
                        serverBalance
                end

                pl:setHaloNote(
                    "Purchased " ..
                    tostring(args.itemName or "item") ..
                    " for " ..
                    tostring(args.price or 0) ..
                    " Jimoleons.",
                    0.15,
                    1.0,
                    0.15,
                    300
                )

                if JimmoleonBankUI.instance ~= nil
                and not storeAdminOpen
                then
                    JimmoleonBankUI.openStore(
                        pl
                    )
                end

            end

        else

            if pl ~= nil then

                pl:setHaloNote(
                    tostring(args.message or "Purchase failed."),
                    1,
                    0,
                    0,
                    300
                )

            end

        end

        return

    end

    --------------------------------------------------
    -- STORE ADMIN RESULT
    --------------------------------------------------

    if command == "StoreAdminResult" then

        local pl =
            getPlayer()

        if args.success == true then

            if pl ~= nil then
                pl:setHaloNote(
                    tostring(args.message or "Store updated."),
                    0.15,
                    1.0,
                    0.15,
                    300
                )
            end

        else

            if pl ~= nil then
                pl:setHaloNote(
                    tostring(args.message or "Store update failed."),
                    1,
                    0,
                    0,
                    300
                )
            end

        end

        return

    end

    --------------------------------------------------
    -- TRANSFER RESULT
    --------------------------------------------------

    if command == "TransferResult" then

        local pl =
            getPlayer()


        if args.success == true then

            print(
                "JIMOLEON TRANSFER SUCCESS: -" ..
                tostring(args.amount)
            )


            if pl ~= nil then

                pl:setHaloNote(
                    "Transferred " ..
                    tostring(args.amount) ..
                    " Jimoleons to " ..
                    tostring(args.recipientName),
                    0,
                    1,
                    0,
                    300
                )


                JimmoleonBankUI.openBank(
                    pl
                )

            end

        else

            print(
                "JIMOLEON TRANSFER FAILED: " ..
                tostring(args.message)
            )


            if pl ~= nil then

                pl:setHaloNote(
                    tostring(args.message),
                    1,
                    0,
                    0,
                    300
                )

            end

        end


        return

    end


    --------------------------------------------------
    -- TRANSFER RECEIVED
    --------------------------------------------------

    if command == "TransferReceived" then

        local pl =
            getPlayer()


        if pl ~= nil then

            pl:setHaloNote(
                "Received " ..
                tostring(args.amount) ..
                " Jimoleons from " ..
                tostring(args.senderName),
                0,
                1,
                0,
                300
            )

        end


        return

    end

end


--------------------------------------------------
-- REGISTER SERVER COMMAND HANDLER
--------------------------------------------------

Events.OnServerCommand.Add(
    JimmoleonBankUI.onServerCommand
)


--------------------------------------------------
-- UPDATE DEPOSIT INFORMATION
--------------------------------------------------

function JimmoleonBankUI.updateDepositInformation(
    window,
    inv
)

    if selectedValuable == nil then
        return
    end


    local count =
        inv:getItemCount(
            selectedValuable.itemType
        )


    if window.availableLabel ~= nil then

        window.availableLabel:setName(
            "You Have: " ..
            tostring(count)
        )

    end


    if window.valueLabel ~= nil then

        window.valueLabel:setName(
            "Value: " ..
            tostring(
                selectedValuable.value
            ) ..
            " Jimoleons each"
        )

    end

end


--------------------------------------------------
-- STARTUP
--------------------------------------------------

print("========================================")
print("JIMOLEON BANK UI LOADED")
print("========================================")