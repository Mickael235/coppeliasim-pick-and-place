-- ==============================================
-- V11 - DASHBOARD SOBRE / GRAND PUBLIC
-- ==============================================

local sim
local simUI
local ui
local dernierRefresh = -1

local function etapeLisible(etat)
    local mapping = {
        ATTENTE = "En attente d'une piece",
        STABILISATION = "Arret du convoyeur",
        APPROCHE = "Le robot s'approche de la piece",
        DESCENTE = "Le robot descend vers la piece",
        FERMETURE = "La pince saisit la piece",
        LEVAGE = "Le robot souleve la piece",
        VERIFICATION = "Verification de la prise",
        TRANSPORT = "Transport vers la table",
        DESCENTE_DEPOT = "Positionnement sur la table",
        LIBERATION = "Depose de la piece",
        RETRAIT = "Retrait de la pince",
        RETOUR = "Retour en position initiale",
        TERMINE = "Production terminee",
        ERREUR = "Erreur de prise"
    }

    return mapping[etat] or etat
end

function sysCall_init()
    sim = require('sim')
    simUI = require('simUI')

    local xml = [[
    <ui title="TABLEAU DE BORD | LIGNE ROBOTISEE"
        closeable="false"
        resizable="false"
        activate="false"
        placement="relative"
        position="-30,80"
        layout="vbox"
        style="background-color: #132330;
               color: #EAF3F8;">

        <group layout="vbox" flat="true" content-margins="16,14,16,14">

            <label text="LIGNE ROBOTISEE"
                style="font-size: 16px;
                       font-weight: bold;
                       color: #7FD8FF;"/>

            <label text="Convoyeur | Bras robotique | Pince"
                style="font-size: 11px;
                       color: #AFC2CF;"/>

            <label text="PIECES TRAITEES"
                style="font-size: 12px;
                       color: #AFC2CF;"/>

            <label id="1" text="0 / 3"
                style="font-size: 34px;
                       font-weight: bold;
                       color: #FFFFFF;"/>

            <progressbar id="2"
                minimum="0"
                maximum="100"
                value="0"
                text-visible="false"
                style="QProgressBar {
                    background-color: #314554;
                    border: 0px;
                    height: 12px;
                }
                QProgressBar::chunk {
                    background-color: #39D49A;
                }"/>

            <label id="3" text="Ligne : En attente"
                style="font-size: 13px;
                       font-weight: bold;
                       color: #FFFFFF;"/>

            <label id="4" text="Etape : En attente d'une piece"
                style="font-size: 12px;
                       color: #D8E4EB;"/>

            <label id="5" text="Convoyeur : En marche"
                style="font-size: 12px;
                       color: #D8E4EB;"/>

            <label id="6" text="Pince : Ouverte"
                style="font-size: 12px;
                       color: #D8E4EB;"/>

            <label id="7" text="Temps : 0.0 s"
                style="font-size: 12px;
                       color: #D8E4EB;"/>

            <label id="8" text="Production en cours"
                style="font-size: 13px;
                       font-weight: bold;
                       color: #49DEA9;"/>

            <label text="Simulation CoppeliaSim Edu"
                style="font-size: 10px;
                       color: #91A6B4;"/>

        </group>
    </ui>
    ]]

    ui = simUI.create(xml)
    print('Dashboard V11 sobre initialise')
end

function sysCall_sensing()
    if not ui then return end

    local temps = sim.getSimulationTime()

    if dernierRefresh >= 0 and temps - dernierRefresh < 0.15 then
        return
    end

    dernierRefresh = temps

    local cycles = sim.getIntProperty(
        sim.handle_scene,
        'signal.v11_cycles',
        {noError=true}
    ) or 0

    local objectif = sim.getIntProperty(
        sim.handle_scene,
        'signal.v11_objectif',
        {noError=true}
    ) or 3

    local etat = sim.getStringProperty(
        sim.handle_scene,
        'signal.v11_etat',
        {noError=true}
    ) or 'ATTENTE'

    local pince = sim.getIntProperty(
        sim.handle_scene,
        'signal.RG2_open',
        {noError=true}
    )

    simUI.setLabelText(ui, 1, cycles .. ' / ' .. objectif)

    local progression = 0
    if objectif > 0 then
        progression = math.floor(100 * cycles / objectif + 0.5)
    end

    progression = math.max(0, math.min(100, progression))
    simUI.setProgress(ui, 2, progression)

    local ligne = "En fonctionnement"

    if etat == 'ATTENTE' then
        ligne = "En attente"
    elseif etat == 'TERMINE' then
        ligne = "Terminee"
    elseif etat == 'ERREUR' then
        ligne = "En defaut"
    end

    simUI.setLabelText(ui, 3, "Ligne : " .. ligne)
    simUI.setLabelText(ui, 4, "Etape : " .. etapeLisible(etat))

    local convoyeurTxt = "A l'arret"
    if etat == 'ATTENTE' then
        convoyeurTxt = "En marche"
    end

    simUI.setLabelText(ui, 5, "Convoyeur : " .. convoyeurTxt)

    local pinceTxt = "Indeterminee"

    if pince == 1 then
        pinceTxt = "Ouverte"
    elseif pince == 0 then
        pinceTxt = "Fermee"
    end

    simUI.setLabelText(ui, 6, "Pince : " .. pinceTxt)

    simUI.setLabelText(ui, 7,
        string.format("Temps : %.1f s", temps)
    )

    local statut = "Production en cours"

    if etat == 'TERMINE' then
        statut = "Production terminee"
    elseif etat == 'ERREUR' then
        statut = "Erreur de fonctionnement"
    end

    simUI.setLabelText(ui, 8, statut)
end

function sysCall_cleanup()
    if ui then
        simUI.destroy(ui)
        ui = nil
    end
end
