local UTILS = lib.require('client.utils')

local controlsString = '[E] - Copy Offset  \n [Q] - Remove Shell'
local testingShell = false
local inObjectPreview = false
local tempObject, tempObjectModel, tempObjectSnapToGround, tempCoords

local function __resetControlsString()
    controlsString = '[E] - Copy Offset  \n [Q] - Remove Shell'
    UTILS.showControls(controlsString)
end

RegisterNetEvent("qw-offset:client:offsetFinder", function()
    if GetInvokingResource() then return end

    if not testingShell then
        local selectedShell = UTILS.selectShell()
        if not selectedShell then
            return
        end

        local createdShell = UTILS.createShell(selectedShell)
        if not createdShell then
            return
        end

        testingShell = true
    else
        local objectModel = lib.inputDialog('Object Model Preview', {
            {
                type = 'input',
                label = 'Object Name',
                required = true,
            },
            {
                type = 'checkbox',
                label = 'Snap To Ground?'
            }
        })
        if not objectModel or not objectModel[1] then
            UTILS.notify('No object model provided', 'error')
            return
        end

        tempObjectModel = objectModel[1]
        tempObjectSnapToGround = objectModel[2]

        if tempObject and DoesEntityExist(tempObject) then
            DeleteEntity(tempObject)
        end

        controlsString = controlsString .. '  \n[L/R Arrow] Rotate Object  \n[Z] Place Object  \n[X] Cancel Object Offset Finder'

        local coords = GetEntityCoords(cache.ped)

        tempObject = UTILS.createObject(tempObjectModel, coords)

        SetEntityAlpha(tempObject, 150, false)
        SetEntityCollision(tempObject, false, false)

        inObjectPreview = true
    end

    UTILS.showControls(controlsString)

    CreateThread(function()
        while testingShell do
            Wait(0)

            -- press Q to remove shell
            if IsControlJustPressed(0, 44) then
                UTILS.removeShell()
                testingShell = false
                inObjectPreview = false
                tempObjectModel = nil
                tempObjectSnapToGround = nil
            end

            -- press E to copy offset off current object or current coords
            if IsControlJustPressed(0, 38) then
                local coords = GetEntityCoords(cache.ped)
                local coordsToCompare = inObjectPreview and GetEntityCoords(tempObject) or coords
                local heading = GetEntityHeading(inObjectPreview and tempObject or cache.ped)

                UTILS.copyOffset(coordsToCompare, heading)
            end

            if inObjectPreview then
                local hit, _, tempCoords, _, _ = lib.raycast.cam(1, 4)
                if hit then
                    SetEntityCoords(tempObject, tempCoords.x, tempCoords.y, tempCoords.z, false, false, false, false)
                    if tempObjectSnapToGround then
                        PlaceObjectOnGroundProperly(tempObject)
                    end

                    -- left and right arrows for temp object heading changes
                    if IsControlPressed(0, 174) then
                        SetEntityHeading(tempObject, GetEntityHeading(tempObject) - 1.0)
                    end

                    if IsControlPressed(0, 175) then
                        SetEntityHeading(tempObject, GetEntityHeading(tempObject) + 1.0)
                    end
                end

                if IsControlJustPressed(0, 73) then -- press X to cancel object offset finder
                    UTILS.removeObject(tempObject)
                    inObjectPreview = false
                    tempObjectModel = nil

                    __resetControlsString()
                end

                if IsControlJustPressed(0, 20) then -- press Z to create temp objects
                    local vec4Coords = vec4(tempCoords.x, tempCoords.y, tempCoords.z, GetEntityHeading(tempObject))

                    UTILS.createTempObject(tempObjectModel, vec4Coords)
                    inObjectPreview = false
                    tempObjectModel = nil

                    __resetControlsString()
                end
            end
        end
    end)
end)

-- remove shell on stop
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    UTILS.removeShell()
end)