-- ==============================================
-- CAMERA DYNAMIQUE V11.2
-- Demonstration LinkedIn
-- General -> Prise -> Bras face -> Depot
-- ==============================================

local sim
local camera
local plans = {}

local robot
local sphere

local phasePrecedente = ''
local planPrecedent = ''
local debutPhase = 0

-- REGLAGES
local vitesseTransition = 2.5

-- Duree du plan frontal pendant TRANSPORT
local maintienFaceTransport = 3.5


function sysCall_init()

    sim = require('sim')

    camera = sim.getObject('/Camera_LinkedIn')

    plans.general = sim.getObject(
        '/Camera_LinkedIn_Reference'
    )

    plans.prise = sim.getObject('/Cam_Prise')

    plans.face = sim.getObject('/Cam_Bras_Face')

    plans.depot = sim.getObject('/Cam_Depot')

    robot = sim.getObject('/IRB140')

    sphere = sim.getObject(
        '/IRB140/manipulationSphere'
    )

    -- Vue principale : camera animee
    sim.adjustView(0, camera, 0)

    sim.setObjectPose(
        camera,
        sim.getObjectPose(
            plans.general, sim.handle_world
        ),
        sim.handle_world
    )

    debutPhase = sim.getSimulationTime()

    print('CAMERA DYNAMIQUE V11.2 ACTIVE')
end


-- Vue frontale avec suivi de la pince
function poseFaceDynamique()

    local position = sim.getObjectPosition(
        plans.face, sim.handle_world
    )

    local base = sim.getObjectPosition(
        robot, sim.handle_world
    )

    local outil = sim.getObjectPosition(
        sphere, sim.handle_world
    )

    -- Cadrage entre le bras et la pince
    local cible = {
        0.25*base[1] + 0.75*outil[1],
        0.25*base[2] + 0.75*outil[2],
        0.25*base[3] + 0.75*outil[3]
    }

    local direction = {
        cible[1] - position[1],
        cible[2] - position[2],
        cible[3] - position[3]
    }

    return sim.buildPose(
        position,
        direction,
        9,
        {0,0,1}
    )
end


function sysCall_sensing()

    local temps = sim.getSimulationTime()

    local phase = sim.getStringProperty(
        sim.handle_scene,
        'signal.v11_etat',
        {noError=true}
    ) or 'ATTENTE'

    -- Chronometrer chaque phase
    if phase ~= phasePrecedente then
        debutPhase = temps
        phasePrecedente = phase
    end

    local dureePhase = temps - debutPhase

    local plan = 'GENERAL'

    -- 1. PREHENSION
    if phase == 'APPROCHE'
        or phase == 'DESCENTE'
        or phase == 'FERMETURE' then

        plan = 'PRISE'

    -- 2. PLAN FRONTAL DU BRAS
    elseif phase == 'LEVAGE'
        or phase == 'VERIFICATION' then

        plan = 'FACE'

    -- 3. TRANSPORT DU CUBE
    elseif phase == 'TRANSPORT' then

        if dureePhase < maintienFaceTransport then
            plan = 'FACE'
        else
            plan = 'DEPOT'
        end

    -- 4. DEPOT SUR LA TABLE
    elseif phase == 'DESCENTE_DEPOT'
        or phase == 'LIBERATION'
        or phase == 'RETRAIT' then

        plan = 'DEPOT'
    end

    -- Diagnostic
    if plan ~= planPrecedent then
        print('PLAN CAMERA : '..plan..
              ' | Phase : '..phase)

        planPrecedent = plan
    end

    local destination

    if plan == 'PRISE' then
        destination = sim.getObjectPose(
            plans.prise, sim.handle_world
        )

    elseif plan == 'FACE' then
        -- Position fixe, orientation qui
        -- accompagne le deplacement de la pince
        destination = poseFaceDynamique()

    elseif plan == 'DEPOT' then
        destination = sim.getObjectPose(
            plans.depot, sim.handle_world
        )

    else
        destination = sim.getObjectPose(
            plans.general, sim.handle_world
        )
    end

    -- TRANSITION FLUIDE
    local actuelle = sim.getObjectPose(
        camera, sim.handle_world
    )

    local dt = sim.getSimulationTimeStep()

    local alpha = 1 - math.exp(
        -vitesseTransition * dt
    )

    local nouvellePose = sim.interpolatePoses(
        actuelle,
        destination,
        alpha
    )

    sim.setObjectPose(
        camera,
        nouvellePose,
        sim.handle_world
    )
end