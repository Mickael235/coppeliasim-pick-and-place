function sysCall_init()
    sim = require('sim')

    capteur = sim.getObject('/capteur_pick')
    cube = sim.getObject('/Cuboid')

    sphere = sim.getObject(
        '/IRB140/manipulationSphere'
    )

    approche = sim.getObject('/pose_approche')

    etat = 'attente'
    duree = 4.0

    print('Robot pret : attente du cube')
end

function sysCall_actuation()

    if etat == 'attente' then

        local detection =
            sim.checkProximitySensor(capteur, cube)

        if detection == 1 then

            print('Cube detecte : approche du bras')

            poseDepart = sim.getObjectPose(
                sphere, sim.handle_world
            )

            poseArrivee = sim.getObjectPose(
                approche, sim.handle_world
            )

            tDepart = sim.getSimulationTime()
            etat = 'deplacement'
        end
    end

    if etat == 'deplacement' then

        local t = (
            sim.getSimulationTime() - tDepart
        ) / duree

        t = math.min(1, math.max(0, t))

        -- Interpolation douce
        local alpha = t * t * (3 - 2 * t)

        local pose = sim.interpolatePoses(
            poseDepart, poseArrivee, alpha
        )

        sim.setObjectPose(
            sphere, pose, sim.handle_world
        )

        if t >= 1 then
            etat = 'termine'
            print('Position d approche atteinte')
        end
    end
end
