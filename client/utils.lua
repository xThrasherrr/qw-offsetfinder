local INTERIORS = lib.require('configs.shells')

local shellHandle
local lastCoords

local utils = {}

-- remove object by handle
function utils.removeObject(object)
    if DoesEntityExist(object) then
        DeleteEntity(object)
    end
end

-- create object/shell
function utils.createObject(model, coords)
    if not IsModelInCdimage(model) then
        return utils.notify(("The object \"%s\" is not in cd image"):format(model), 'error')
    end

    lib.requestModel(model)

    local object = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
    FreezeEntityPosition(object, true)
    SetEntityHeading(object, 0.0)

    return object
end

-- remove shell, remove placed objects and teleport player to last coords
function utils.removeShell()
    if shellHandle and DoesEntityExist(shellHandle) then
        DeleteEntity(shellHandle)
        shellHandle = nil
    end

    lib.hideTextUI()

    if lastCoords then
        SetEntityCoordsNoOffset(cache.ped, lastCoords.x, lastCoords.y, lastCoords.z, true, true, true)
        lastCoords = nil
    end
end

-- create shell object and teleport player inside
function utils.createShell(shell)
    if not IsModelInCdimage(shell) then
        return utils.notify(("The shell \"%s\" is not in cd image, did you start the shell?"):format(shell), 'error')
    end

    utils.removeShell()

    lastCoords = GetEntityCoords(cache.ped)
    local newCoords = lastCoords - vec3(0, 0, 240)

    shellHandle = utils.createObject(shell, newCoords)

    while not DoesEntityExist(shellHandle) or not HasCollisionForModelLoaded(shell) do
        Wait(100)
    end

    SetEntityCollision(shellHandle, true, true)

    -- teleport player into shell
    local z = newCoords.z
    local success, groundZ, _ = GetGroundZAndNormalFor_3dCoord(newCoords.x, newCoords.y, newCoords.z)
    while not success do
        success, groundZ, _ = GetGroundZAndNormalFor_3dCoord(newCoords.x, newCoords.y, z)
        z = z + 0.5 -- increment z until found
        Wait(10)
    end

    SetEntityCoordsNoOffset(cache.ped, newCoords.x, newCoords.y, groundZ + 1.0, true, true, true)

    return shellHandle
end

-- select shell model input
function utils.selectShell()
    local options = {}

    for shell, label in pairs(INTERIORS) do
        options[#options + 1] = {
            value = shell,
            label = label
        }
    end

    local shellSelect = lib.inputDialog('Select Interior', {
        { type = 'select', label = 'Interior', required = true, options = options },
    })

    return shellSelect and shellSelect[1] or false
end

-- copy offset to clipboard
function utils.copyOffset(coordsToCompare, heading)
    local offset = GetOffsetFromEntityGivenWorldCoords(shellHandle, coordsToCompare.x, coordsToCompare.y, coordsToCompare.z)

    lib.setClipboard(('vec4(%f, %f, %f, %f)'):format(offset.x, offset.y, offset.z, heading))

    utils.notify("Copied offset to clipboard.", 'success')
end

function utils.notify(message, messageType)
    lib.notify({
        title = 'Offset Finder',
        description = message,
        type = messageType
    })
end

function utils.showControls(string)
    lib.showTextUI(string, {
        position = 'top-center'
    })
end

return utils