-- =====================================================
-- CELLULE ROBOTISEE V10
-- Convoyeur + ABB IRB140 + RG2
-- Pick-and-Place automatique de 3 pieces colorees
-- =====================================================

function sysCall_init()
    sim = require('sim')

    -- Equipements
    capteur = sim.getObject('/capteur_pick')
    convoyeur = sim.getObject('/conveyor')

    -- Piece originale uniquement
    cubeModele = sim.getObject('/Piece_modele')
    cubeActuel = cubeModele

    -- Position initiale du cube
    poseApparition = sim.getObjectPose(
        cubeModele, sim.handle_world
    )

    -- Cible IK du robot
    sphere = sim.getObject(
        '/IRB140/manipulationSphere'
    )

    -- Positions du robot
    approche = sim.getObject('/pose_approche')
    prise = sim.getObject('/pose_prise')
    depotHaut = sim.getObject('/pose_depot_haut')
    depotBas = sim.getObject('/pose_depot_bas')
    repos = sim.getObject('/pose_repos')

    -- Parametres de production
    vitesse = 0.072
    NB_PIECES = 3
    nbCycles = 0

    -- Decalages des depots selon Y
    offsetsDepotY = {0, 0.075, -0.075}

    -- Couleurs des pieces
    couleursCube = {
        {0.20, 0.55, 0.95}, -- Piece 1 : Bleu
        {0.20, 0.80, 0.40}, -- Piece 2 : Vert
        {0.98, 0.65, 0.15}  -- Piece 3 : Orange
    }

    -- Colorer uniquement le cube original
    sim.setShapeColor(
        cubeModele,
        nil,
        sim.colorcomponent_ambient_diffuse,
        couleursCube[1]
    )

    etat = 'ATTENTE'
    
    -- V11 : initialisation supervision
    sim.setIntProperty(
        sim.handle_scene, 'signal.v11_cycles', 0
    )

    sim.setIntProperty(
        sim.handle_scene, 'signal.v11_objectif', NB_PIECES
    )

    sim.setStringProperty(
        sim.handle_scene, 'signal.v11_etat', etat
    )


    -- Pince ouverte
    commanderPince(true)

    print('================================')
    print('CELLULE ROBOTISEE V10')
    print('Production de 3 pieces colorees')
    print('================================')
    print('Piece 1 : BLEU')
    print('Piece 2 : VERT')
    print('Piece 3 : ORANGE')
    print('Attente de la premiere piece...')
end


-- =====================================================
-- COMMANDE DE LA PINCE RG2
-- =====================================================

function commanderPince(ouvrir)
    sim.setIntProperty(
        sim.handle_scene,
        'signal.RG2_open',
        ouvrir and 1 or 0
    )
end


-- =====================================================
-- RECUPERER LA POSE D'UN OBJET
-- =====================================================

function poseDe(objet)
    return sim.getObjectPose(
        objet, sim.handle_world
    )
end


-- =====================================================
-- CALCUL DES POSITIONS DE DEPOT
-- =====================================================

function poseDepot(objet)
    local pose = poseDe(objet)

    pose[2] = pose[2] +
        offsetsDepotY[nbCycles + 1]

    return pose
end


-- =====================================================
-- DEMARRER UN MOUVEMENT DU BRAS
-- =====================================================

function demarrerMouvement(cible, duree, phase)

    poseDepart = poseDe(sphere)
    poseFin = cible

    dureeMouvement = duree
    debutMouvement = sim.getSimulationTime()

    etat = phase

    print('Mouvement : ' .. phase)
end


-- =====================================================
-- INTERPOLATION PROGRESSIVE DES MOUVEMENTS
-- =====================================================

function avancer()

    local t = (
        sim.getSimulationTime() - debutMouvement
    ) / dureeMouvement

    t = math.max(0, math.min(1, t))

    -- Interpolation douce
    local alpha = t*t*(3-2*t)

    local pose = sim.interpolatePoses(
        poseDepart, poseFin, alpha
    )

    sim.setObjectPose(
        sphere, pose, sim.handle_world
    )

    return t >= 1
end


-- =====================================================
-- GENERATION AUTOMATIQUE D'UNE NOUVELLE PIECE
-- =====================================================

function nouveauCube()

    -- Copier uniquement la piece modele
    local copies = sim.copyPasteObjects(
        {cubeModele}, 2
    )

    cubeActuel = copies[1]

    -- Numero de la nouvelle piece
    local numero = nbCycles + 1

    -- Nom unique
    sim.setObjectAlias(
        cubeActuel,
        'Piece_' .. numero
    )

    -- Couleur correspondant au numero
    local couleur = couleursCube[numero]

    sim.setShapeColor(
        cubeActuel,
        nil,
        sim.colorcomponent_ambient_diffuse,
        couleur
    )

    -- Remettre la piece a l'entree du convoyeur
    sim.setObjectPose(
        cubeActuel,
        poseApparition,
        sim.handle_world
    )

    print('--------------------------------')
    print('Nouvelle piece : ' .. numero)

    if numero == 2 then
        print('Couleur : VERT')
    elseif numero == 3 then
        print('Couleur : ORANGE')
    end

    print('--------------------------------')
end


-- =====================================================
-- MACHINE A ETATS : PICK AND PLACE
-- =====================================================

function sysCall_actuation()

    local temps = sim.getSimulationTime()

    -- Convoyeur actif uniquement en ATTENTE
    local v = 0

    if etat == 'ATTENTE' then
        v = vitesse
    end

    sim.writeCustomTableData(
        convoyeur, '__ctrl__', {vel=v}
    )


    -- ETAPE 1 : DETECTION
    if etat == 'ATTENTE' then

        local detection = sim.checkProximitySensor(
            capteur, cubeActuel
        )

        if detection == 1 then

            print('Piece detectee !')
            print('Arret du convoyeur')

            commanderPince(true)

            debutEtat = temps
            etat = 'STABILISATION'
        end


    -- ETAPE 2 : STABILISATION
    elseif etat == 'STABILISATION' then

        if temps - debutEtat >= 2 then

            demarrerMouvement(
                poseDe(approche),
                4,
                'APPROCHE'
            )
        end


    -- ETAPE 3 : APPROCHE DU ROBOT
    elseif etat == 'APPROCHE' then

        if avancer() then

            demarrerMouvement(
                poseDe(prise),
                3,
                'DESCENTE'
            )
        end


    -- ETAPE 4 : DESCENTE VERS LA PIECE
    elseif etat == 'DESCENTE' then

        if avancer() then

            zAvant = sim.getObjectPosition(
                cubeActuel,
                sim.handle_world
            )[3]

            commanderPince(false)

            print('Fermeture RG2')

            debutEtat = temps
            etat = 'FERMETURE'
        end


    -- ETAPE 5 : FERMETURE DE RG2
    elseif etat == 'FERMETURE' then

        if temps - debutEtat >= 2 then

            local cible = poseDe(sphere)

            -- Soulever de 5 cm
            cible[3] = cible[3] + 0.05

            demarrerMouvement(
                cible,
                3,
                'LEVAGE'
            )
        end


    -- ETAPE 6 : LEVAGE
    elseif etat == 'LEVAGE' then

        if avancer() then

            debutEtat = temps
            etat = 'VERIFICATION'
        end


    -- ETAPE 7 : VERIFIER LA PREHENSION
    elseif etat == 'VERIFICATION' then

        if temps - debutEtat >= 0.5 then

            local zApres = sim.getObjectPosition(
                cubeActuel,
                sim.handle_world
            )[3]

            local dz = zApres - zAvant

            print(string.format(
                'Levage : %.3f m',
                dz
            ))

            if dz > 0.025 then

                print('Prise validee')

                demarrerMouvement(
                    poseDepot(depotHaut),
                    5,
                    'TRANSPORT'
                )

            else

                print('ERREUR : piece non soulevee')
                etat = 'ERREUR'
            end
        end


    -- ETAPE 8 : TRANSPORT VERS LA TABLE
    elseif etat == 'TRANSPORT' then

        if avancer() then

            print('Arrivee au-dessus de la table')

            demarrerMouvement(
                poseDepot(depotBas),
                3,
                'DESCENTE_DEPOT'
            )
        end


    -- ETAPE 9 : DESCENTE POUR DEPOT
    elseif etat == 'DESCENTE_DEPOT' then

        if avancer() then

            commanderPince(true)

            print('Liberation de la piece')

            debutEtat = temps
            etat = 'LIBERATION'
        end


    -- ETAPE 10 : LIBERATION
    elseif etat == 'LIBERATION' then

        if temps - debutEtat >= 1.5 then

            demarrerMouvement(
                poseDepot(depotHaut),
                3,
                'RETRAIT'
            )
        end


    -- ETAPE 11 : RETRAIT DE LA PINCE
    elseif etat == 'RETRAIT' then

        if avancer() then

            demarrerMouvement(
                poseDe(repos),
                4,
                'RETOUR'
            )
        end


    -- ETAPE 12 : RETOUR EN POSITION DE REPOS
    elseif etat == 'RETOUR' then

        if avancer() then

            nbCycles = nbCycles + 1

            print('================================')
            print(
                'CYCLE ' .. nbCycles ..
                '/' .. NB_PIECES .. ' TERMINE'
            )
            print('================================')

            if nbCycles < NB_PIECES then

                nouveauCube()
                etat = 'ATTENTE'

            else

                etat = 'TERMINE'

                print('================================')
                print('FIN DE PRODUCTION')
                print('Cycles executes : ' .. nbCycles)
                print('================================')
            end
        end
    end
    
    -- V11 : publication des informations
    sim.setIntProperty(
        sim.handle_scene,
        'signal.v11_cycles',
        nbCycles
    )

    sim.setStringProperty(
        sim.handle_scene,
        'signal.v11_etat',
        etat
    )

    -- Egalement utilise par la camera dynamique
    sim.setStringProperty(
        sim.handle_scene,
        'signal.phaseRobot',
        etat
    )

end
