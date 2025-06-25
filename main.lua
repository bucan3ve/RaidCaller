-- main.lua (versione compatibile con client 1.12)
-- Questo è il punto di ingresso principale che collega tutti i moduli.

-- Creiamo un piccolo frame invisibile per gestire l'evento di caricamento.
-- Questo è il metodo standard e sicuro per il client 1.12.
local loaderFrame = CreateFrame("Frame")

-- Registriamo un evento: "OnLoad" si attiva quando il frame (e l'addon) è caricato.
loaderFrame:SetScript("OnLoad", function()
    -- Il nostro codice di inizializzazione va qui dentro.
    -- Questo codice verrà eseguito solo dopo che tutti i file sono stati caricati.

    -- Prende il nostro addon principale che è stato creato in RaidCaller.lua
    local addon = RaidCaller.addon
    if not addon then
        print("|cffff0000RaidCaller Error: Could not find main addon object.|r")
        return
    end

    -- Crea un'istanza di ogni modulo, passando le dipendenze necessarie
    local configModule = RaidCaller.ConfigModule:new(addon.db)
    local bossDetectorModule = RaidCaller.BossDetectorModule:new(addon)
    local uiModule = RaidCaller.UIModule:new(addon, configModule)

    -- Ora, collega i moduli appena creati all'addon principale
    addon:SetModules(configModule, uiModule, bossDetectorModule)

    -- Ora che tutto è collegato, possiamo aggiornare lo stato iniziale
    if addon.BossDetector then
        addon.BossDetector:UpdateZone()
    end

    print("|cff00ff00RaidCaller: Tutti i moduli sono stati caricati e collegati con successo!|r")
end)