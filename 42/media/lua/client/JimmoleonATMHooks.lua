print("========================================")
print("JIMOLEON ATM HOOKS LOADED")
print("========================================")


--------------------------------------------------
-- PROTECT GLYTCH3R ATMS FROM SCRAPPING
--------------------------------------------------

local function isJimmoleonProtectedATM(object)

    if object == nil then
        return false
    end

    local modData =
        object:getModData()

    if modData == nil then
        return false
    end

    --------------------------------------------------
    -- GLYTCH3R ATM MARKER
    --------------------------------------------------

    if modData["atm4Converted"] == true then
        return true
    end

    return false
end


--------------------------------------------------
-- HOOK VANILLA SCRAP OBJECT LIST
--------------------------------------------------

local function hookScrapList()

    if ISMoveableCursor == nil then

        print(
            "JIMOLEON ATM HOOK ERROR: ISMoveableCursor not found."
        )

        return
    end


    if ISMoveableCursor.getScrapObjectList == nil then

        print(
            "JIMOLEON ATM HOOK ERROR: getScrapObjectList not found."
        )

        return
    end


    --------------------------------------------------
    -- PREVENT DOUBLE HOOKING
    --------------------------------------------------

    if ISMoveableCursor.JimmoleonScrapHooked == true then

        return

    end


    ISMoveableCursor.JimmoleonScrapHooked =
        true


    --------------------------------------------------
    -- SAVE VANILLA FUNCTION
    --------------------------------------------------

    local originalGetScrapObjectList =
        ISMoveableCursor.getScrapObjectList


    --------------------------------------------------
    -- REPLACE WITH OUR HOOK
    --------------------------------------------------

    ISMoveableCursor.getScrapObjectList =
        function(self)

            --------------------------------------------------
            -- GET VANILLA SCRAP LIST FIRST
            --------------------------------------------------

            local originalList =
                originalGetScrapObjectList(
                    self
                )


            if originalList == nil then

                return {}

            end


            --------------------------------------------------
            -- FILTER GLYTCH3R ATMS
            --------------------------------------------------

            local filteredList =
                {}


            for _, entry in ipairs(
                originalList
            ) do

                local object =
                    entry.object


                if not isJimmoleonProtectedATM(
                    object
                ) then

                    table.insert(
                        filteredList,
                        entry
                    )

                else

                    print(
                        "JIMOLEON: Blocking ATM from scrap list."
                    )

                end

            end


            return filteredList

        end


    print(
        "JIMOLEON: ATM scrap protection hook installed."
    )

end


--------------------------------------------------
-- INSTALL HOOK AFTER GAME START
--------------------------------------------------

Events.OnGameStart.Add(
    hookScrapList
)