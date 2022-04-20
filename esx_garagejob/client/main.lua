local isBarman, isInMarker, isInPublicMarker, hintIsShowed, HasAlreadyEnteredMarker = false, false, false, false, false
local LastZone, CurrentAction, CurrentActionMsg
local CurrentActionData, Blips, PlayerData = {}, {}, {}
local hintToDisplay = "no hint to display"

ESX = nil

Citizen.CreateThread(function()
  while ESX == nil do
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    Citizen.Wait(0)
  end
end)

function IsJobTrue()
    if PlayerData ~= nil then
        local IsJobTrue = false
        if PlayerData.job ~= nil and PlayerData.job.name == 'import' then
            IsJobTrue = true
        end
        return IsJobTrue
    end
end



function SetVehicleMaxMods(vehicle)
  local props = {
    modEngine = 0,
    modBrakes = 0,
    modTransmission = 0,
    modSuspension = 0,
    modTurbo = false,
  }

  ESX.Game.SetVehicleProperties(vehicle, props)
end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
  PlayerData.job = job
end)

function cleanPlayer(playerPed)
  ClearPedBloodDamage(playerPed)
  ResetPedVisibleDamage(playerPed)
  ClearPedLastWeaponDamage(playerPed)
  ResetPedMovementClipset(playerPed, 0)
end

function setClipset(playerPed, clip)
  RequestAnimSet(clip)
  while not HasAnimSetLoaded(clip) do
    Citizen.Wait(0)
  end
  SetPedMovementClipset(playerPed, clip, true)
end

function setUniform(job, playerPed)
  TriggerEvent('skinchanger:getSkin', function(skin)

    if skin.sex == 0 then
      if Config.Uniforms[job].male ~= nil then
        TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms[job].male)
      else
        ESX.ShowNotification(_U('no_outfit'))
      end
      if job ~= 'citizen_wear' and job ~= 'barman_outfit' then
        setClipset(playerPed, "MOVE_M@POSH@")
      end
    else
      if Config.Uniforms[job].female ~= nil then
        TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms[job].female)
      else
        ESX.ShowNotification(_U('no_outfit'))
      end
      if job ~= 'citizen_wear' and job ~= 'barman_outfit' then
        setClipset(playerPed, "MOVE_F@POSH@")
      end
    end
  end)
end



function OpenVehicleSpawnerMenu()
  local vehicles = Config.Zones.Vehicles

  ESX.UI.Menu.CloseAll()

  if Config.EnableSocietyOwnedVehicles then
    local elements = {}

    ESX.TriggerServerCallback('esx_society:getVehiclesInGarage', function(garageVehicles)

      for i=1, #garageVehicles, 1 do
        table.insert(elements, {label = GetDisplayNameFromVehicleModel(garageVehicles[i].model) .. ' [' .. garageVehicles[i].plate .. ']', value = garageVehicles[i]})
      end

      ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_spawner', {
          title    = _U('vehicle_menu'),
          align    = 'top-left',
          elements = elements,
        }, function(data, menu)

          menu.close()

          local vehicleProps = data.current.value
          ESX.Game.SpawnVehicle(vehicleProps.model, vehicles.SpawnPoint, vehicles.Heading, function(vehicle)
              ESX.Game.SetVehicleProperties(vehicle, vehicleProps)
              local playerPed = GetPlayerPed(-1)  
          end)            

          TriggerServerEvent('esx_society:removeVehicleFromGarage', 'import', vehicleProps)
        end, function(data, menu)

          menu.close()

          CurrentAction     = 'menu_vehicle_spawner'
          CurrentActionMsg  = _U('vehicle_spawner')
          CurrentActionData = {}

        end)
    end, 'import')
  else
    local elements = {}

    for i=1, #Config.AuthorizedVehicles, 1 do
      local vehicle = Config.AuthorizedVehicles[i]
      table.insert(elements, {label = vehicle.label, value = vehicle.name})
    end

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_spawner', {
        title    = _U('vehicle_menu'),
        align    = 'top-left',
        elements = elements,
      }, function(data, menu)

        menu.close()

        local model = data.current.value

        local vehicle = GetClosestVehicle(vehicles.SpawnPoint.x,  vehicles.SpawnPoint.y,  vehicles.SpawnPoint.z,  3.0,  0,  71)

        if not DoesEntityExist(vehicle) then

          local playerPed = GetPlayerPed(-1)

          if Config.MaxInService == -1 then

            ESX.Game.SpawnVehicle(model, {
              x = vehicles.SpawnPoint.x,
              y = vehicles.SpawnPoint.y,
              z = vehicles.SpawnPoint.z
            }, vehicles.Heading, function(vehicle)
              --TaskWarpPedIntoVehicle(playerPed,  vehicle,  -1) -- teleport into vehicle
              SetVehicleMaxMods(vehicle)
              SetVehicleDirtLevel(vehicle, 0)
            end)
          else
            ESX.TriggerServerCallback('esx_service:enableService', function(canTakeService, maxInService, inServiceCount)

              if canTakeService then
                ESX.Game.SpawnVehicle(model, {
                  x = vehicles[partNum].SpawnPoint.x,
                  y = vehicles[partNum].SpawnPoint.y,
                  z = vehicles[partNum].SpawnPoint.z
                }, vehicles[partNum].Heading, function(vehicle)
                  --TaskWarpPedIntoVehicle(playerPed,  vehicle,  -1)  -- teleport into vehicle
                  SetVehicleMaxMods(vehicle)
                  SetVehicleDirtLevel(vehicle, 0)
                end)
              else
                ESX.ShowNotification(_U('service_max') .. inServiceCount .. '/' .. maxInService)
              end
            end, 'etat')
          end
        else
          ESX.ShowNotification(_U('vehicle_out'))
        end
      end, function(data, menu)

        menu.close()

        CurrentAction = 'menu_vehicle_spawner'
        CurrentActionMsg = _U('vehicle_spawner')
        CurrentActionData = {}
      end)
  end
end











AddEventHandler('esx_importjob:hasEnteredMarker', function(zone)
    if zone == 'Vehicles' then
        CurrentAction     = 'menu_vehicle_spawner'
        CurrentActionMsg  = _U('vehicle_spawner')
        CurrentActionData = {}
    end

    if zone == 'VehicleDeleters' then
      local playerPed = GetPlayerPed(-1)

      if IsPedInAnyVehicle(playerPed,  false) then
        local vehicle = GetVehiclePedIsIn(playerPed,  false)

        CurrentAction     = 'delete_vehicle'
        CurrentActionMsg  = _U('store_vehicle')
        CurrentActionData = {vehicle = vehicle}
      end
    end

    if Config.EnableHelicopters then
        if zone == 'Helicopters' then
          local helicopters = Config.Zones.Helicopters

          if not IsAnyVehicleNearPoint(helicopters.SpawnPoint.x, helicopters.SpawnPoint.y, helicopters.SpawnPoint.z,  3.0) then

            ESX.Game.SpawnVehicle('swift2', {
              x = helicopters.SpawnPoint.x,
              y = helicopters.SpawnPoint.y,
              z = helicopters.SpawnPoint.z
            }, helicopters.Heading, function(vehicle)
              SetVehicleModKit(vehicle, 0)
              SetVehicleLivery(vehicle, 0)
            end)
          end
        end

        if zone == 'HelicopterDeleters' then
          local playerPed = GetPlayerPed(-1)

          if IsPedInAnyVehicle(playerPed,  false) then
            local vehicle = GetVehiclePedIsIn(playerPed,  false)

            CurrentAction     = 'delete_vehicle'
            CurrentActionMsg  = _U('store_vehicle')
            CurrentActionData = {vehicle = vehicle}
          end
        end
    end
end)




-- Display markers
Citizen.CreateThread(function()
    while true do

        Wait(0)
        if IsJobTrue() then

            local coords = GetEntityCoords(GetPlayerPed(-1))

            for k,v in pairs(Config.Zones) do
                if(v.Type ~= -1 and GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < Config.DrawDistance) then
                    DrawMarker(v.Type, v.Pos.x, v.Pos.y, v.Pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, v.Size.x, v.Size.y, v.Size.z, v.Color.r, v.Color.g, v.Color.b, 100, false, false, 2, false, false, false, false)
                end
            end
        end
    end
end)


Citizen.CreateThread(function()
  while true do

      Wait(0)
      if IsJobTrue() then
          local coords      = GetEntityCoords(GetPlayerPed(-1))
          local isInMarker  = false
          local currentZone = nil

          for k,v in pairs(Config.Zones) do
              if(GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < v.Size.x) then
                  isInMarker  = true
                  currentZone = k
              end
          end

          if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
              HasAlreadyEnteredMarker = true
              LastZone                = currentZone
              TriggerEvent('esx_importjob:hasEnteredMarker', currentZone)
          end

          if not isInMarker and HasAlreadyEnteredMarker then
              HasAlreadyEnteredMarker = false
              TriggerEvent('esx_importjob:hasExitedMarker', LastZone)
          end
      end
  end
end)

-- Key Controls
Citizen.CreateThread(function()
  while true do

    Citizen.Wait(0)

    if CurrentAction ~= nil then
      SetTextComponentFormat('STRING')
      AddTextComponentString(CurrentActionMsg)
      DisplayHelpTextFromStringLabel(0, 0, 1, -1)

      if IsControlJustReleased(0,  38) and IsJobTrue() then






        
        if CurrentAction == 'menu_vehicle_spawner' then
            OpenVehicleSpawnerMenu()
        end

        if CurrentAction == 'delete_vehicle' then

          if Config.EnableSocietyOwnedVehicles then
            local vehicleProps = ESX.Game.GetVehicleProperties(CurrentActionData.vehicle)
            TriggerServerEvent('esx_society:putVehicleInGarage', 'import', vehicleProps)
          else
            if GetEntityModel(vehicle) == GetHashKey('rentalbus') then
              TriggerServerEvent('esx_service:disableService', 'import')
            end
          end

          ESX.Game.DeleteVehicle(CurrentActionData.vehicle)
        end

        if CurrentAction == 'menu_boss_actions' and IsGradeBoss() then
          local options = {
            wash = Config.EnableMoneyWash,
          }

          ESX.UI.Menu.CloseAll()

          TriggerEvent('esx_society:openBossMenu', 'import', function(data, menu)

            menu.close()
            CurrentAction = 'menu_boss_actions'
            CurrentActionMsg = _U('open_bossmenu')
            CurrentActionData = {}
          end,options)
        end

        CurrentAction = nil
      end
    end

    if IsControlJustReleased(0,  167) and IsJobTrue() and not ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'import_actions') then
        OpenSocietyActionsMenu()
    end
  end
end)




-- Show top left hint
Citizen.CreateThread(function()
  while true do
    Wait(0)
    if hintIsShowed == true then
      SetTextComponentFormat("STRING")
      AddTextComponentString(hintToDisplay)
      DisplayHelpTextFromStringLabel(0, 0, 1, -1)
    end
  end
end)

