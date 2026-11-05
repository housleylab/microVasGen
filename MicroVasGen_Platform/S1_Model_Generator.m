% =========================================================================
% Title:        Stochastic Closed-Loop Microvascular Network Generator
% Author:       Aref Valipour, Housley Lab, Georgia Tech
% Date:         2026
%
% Description:
%   Generates a synthetic, closed-loop microvascular network graph within a
%   2-D square domain using a stochastic tip-growth algorithm. The model
%   mimics angiogenic sprouting: vessel tips advance iteratively, branch
%   probabilistically, and form anastomoses (loop-closing connections) when
%   they approach existing vessel segments. Vessel diameters follow a
%   parabolic profile (Murray's Law-inspired) that is widest at the inlet
%   and outlet and narrowest at the mid-domain capillary bed.
%
%   The output is a graph representation (nodes + segments + diameters)
%   suitable for downstream hemodynamic simulation (e.g., SPICE/COMSOL
%   import) or direct visualization.
%
% Inputs:
%   None. All tunable parameters are defined in the %% Parameters sections.
%
% Outputs (workspace variables):
%   networkNodes       - [N x 2] node (x,y) coordinates (mm)
%   networkSegments    - [M x 2] segment connectivity (node index pairs)
%   segmentDiameters   - [M x 1] vessel diameter for each segment (mm)
%   domainSize         - scalar domain width/height (mm)
%   tipGrowthAngles    - [1 x N] last growth angle stored at each node (rad)
%
% Dependencies:
%   All helper functions are defined at the bottom of this file:
%     calculateDiameter()       Parabolic diameter profile
%     lineSegmentIntersect()    Parametric line-line intersection test
%     pointToSegmentDist()      Closest-point distance from point to segment
%     findPathBFS()             Breadth-first search for loop detection
%
% Usage:
%   Run directly in MATLAB.
%   Set randomSeed to a nonzero integer to reproduce a specific network.
%   Set saveResults = 1 and ensure ./data/ and ./Model_Images/ exist before saving.
%
% Citation:
%   Valipour, A., Bourque, A. R. & Housley, S. N. Integrated Framework for Modeling Microvascular Networks. Nat. Commun. (2026, in press).
%   Preprint: Valipour, A., Bourque, A. R. & Housley, S. N. Integrated framework for multiscale microvascular models. 
%   bioRxiv https://doi.org/10.64898/2026.04.13.718340 (2026).
% =========================================================================

%% --- Workspace Initialization -------------------------------------------
clear;
close all;
clc;


%% --- Experiment Control -------------------------------------------------
experimentID = 1;
saveResults  = 1;   % 1: save outputs to disk;  0: fast iteration / no I/O

% Reproducibility: set randomSeed to any nonzero integer to fix the RNG
% and reproduce the exact same network. 0 = new random network each run.
randomSeed = 1;
if randomSeed ~= 0
    rng(randomSeed);  
end


%% --- Domain & Topology Parameters ---------------------------------------
% Defines the physical size of the simulation domain and the fixed
% inlet/outlet positions that all vessel paths grow between.

domainSize    = 20;                             % Side length of square domain (mm)
arteryInlet   = [0, domainSize/2];             % Inlet point: left edge, mid-height (mm)
arteryOutlet  = [domainSize, domainSize/2];    % Outlet point: right edge, mid-height (mm)


%% --- Growth Algorithm Parameters ----------------------------------------
% Core parameters governing tip advancement, branching, and anastomosis.

numInitialSprouts = 1;      % Number of sprouts seeded from the inlet stub.
                            %   Increase to raise network density near the inlet.
maxIterations     = 5000;   % Hard cap on growth iterations.

stepSize          = 0.30;   % Distance a vessel tip advances per step (mm).
                            %   Smaller values produce smoother, denser vessels.

branchProbability = 0.3;    % Base probability [0,1] that a bifurcation occurs
                            %   at each growth step.

% Anastomosis (loop-closing) distance thresholds (mm).
% A growing tip connects to an existing vessel when the distance to that
% vessel falls below the relevant threshold.
anastomosisDist       = stepSize / 2;   % Threshold used for overlap-forced connections
anastomosisDistNormal  = stepSize / 2;  % Threshold for voluntary anastomosis checks

% Minimum number of nodes that must already lie on the path between the
% current tip and a candidate anastomosis target before the loop is allowed
% to close. Prevents pathologically short (trivial) cycles.
minLoopNodes = 1;


%% --- Branching Behaviour Parameters -------------------------------------

% Smoothing window: number of recent growth history positions used to
% compute an averaged vessel direction for the branching calculation.
smoothingWindow  = 5;

% Minimum number of growth steps that must elapse on a given vessel lineage
% before it is eligible to branch again. Two separate thresholds allow the
% early network (first firstMinBranchIntervalLimit branching events) to use
% a different spacing before switching to the steady-state interval.
minBranchInterval           = 4;    % Steady-state minimum steps between branches
firstMinBranchInterval      = 2;    % Minimum interval applied during early growth phase
firstMinBranchIntervalLimit = 3;    % Number of branching events in early phase before
                                    %   switching to minBranchInterval (tune for early density)

% Weight [0,1] of the tip's own most recent branch angle on its next
% growth direction. 0 = pure parent axis; 1 = pure angle memory.
branchMemoryStrength = 0.35;

% Scale factor on the random angular perturbation applied during the
% exploration phase (Zones 1 & 2). Values < 1 → straighter vessels;
% values > 1 → more tortuous.
explorationAngleScale = 2 / 3;   % Dimensionless (≈ 0.5)


%% --- Spatial Gradient Parameters ----------------------------------------
% The domain is divided into three longitudinal zones along the x-axis that
% modulate branching frequency and directional bias:
%
%   Zone 1 (Entry):       x/domainSize in [0,              middleRegionStart)
%   Zone 2 (Middle):      x/domainSize in [middleRegionStart, middleRegionEnd]
%   Zone 3 (Convergence): x/domainSize in (middleRegionEnd, 1]
%
% Zone 2 has enhanced branching and wider angular spread to build a dense
% capillary bed. Zone 3 progressively steers vessels toward the outlet.

middleRegionStart  = 0.3;  % Zone 2 begins at this fraction of domainSize
middleRegionEnd    = 0.6;  % Zone 2 ends at this fraction of domainSize (tested at 0.6)

% Maximum fractional weight of outlet-directed bias in Zone 3 (0 to 1).
outletInfluenceMax = 0.7;

% Outlet attraction start threshold (fraction of domainSize).
% Kept for reference — governs when strong attraction to outlet begins.
% outletAttractionStart = 0.35;


%% --- Vessel Diameter Parameters -----------------------------------------
% Diameter varies spatially following a parabolic profile (see
% calculateDiameter()), approximating Murray's Law taper from feeding
% arterioles into the capillary bed and back out to collecting venules.

maxVesselDiameter = 200 / 1000;    % Diameter at x = 0 and x = domainSize (mm)
minVesselDiameter =  20 / 1000;    % Diameter at x = domainSize/2 (mm)


%% --- Data Structure Initialization --------------------------------------
% Arrays grow dynamically via `end+1` during the loop for code clarity.
% The pre-allocation below covers the vast majority of runs without resizing.

maxNodes = 10000;   % Upper bound estimate on total nodes (pre-allocation target)

networkNodes      = arteryInlet;                        % [N×2] node coordinates (mm)
networkSegments   = [];                                 % [M×2] segment connectivity
segmentNodesStore = zeros(maxIterations, 4);            % Reserved segment storage (for external use)
segmentDiameters  = [];                                 % [M×1] diameter per segment (mm)

activeTipIndices      = [];                             % Indices of currently growing tips
stepsSinceLastBranch  = zeros(1, maxIterations);        % Per-tip branch-spacing counter
vesselGrowthHistory   = cell(1, maxIterations);         % Rolling position history per tip
tipGrowthAngles       = zeros(1, maxIterations);        % Most recent growth angle per tip (rad)


%% --- Seed Network: Inlet Stub and Initial Sprout(s) ---------------------
% Create a short artery stub two step-lengths ahead of the inlet, then seed
% numInitialSprouts growing tips off its distal end.

networkNodes(end+1, :) = [arteryInlet(1) + stepSize*2, arteryInlet(2)];
networkSegments(end+1, :) = [1, 2];
segmentDiameters = [segmentDiameters; ...
    calculateDiameter(arteryInlet(1), domainSize, minVesselDiameter, maxVesselDiameter)];

inletTipIdx = 2;    % Index of the inlet stub distal node

for i = 1:numInitialSprouts
    % Small random angular perturbation around the rightward (0 rad) direction
    angleJitter = (rand - 0.5) * (pi / 10);
    baseAngle   = 0;    % 0 rad = rightward
    newTipPos   = networkNodes(inletTipIdx, :) + ...
                  stepSize * [cos(baseAngle + angleJitter), sin(baseAngle + angleJitter)];

    % Prevent the sprout from immediately growing backward
    if newTipPos(1) < networkNodes(inletTipIdx, 1)
        newTipPos(1) = networkNodes(inletTipIdx, 1) + stepSize * 0.1;
    end

    % Distribute multiple sprouts evenly along y for better initial coverage
    spacing      = domainSize / (numInitialSprouts + 1);
    newTipPos(2) = spacing * i;

    networkNodes(end+1, :) = newTipPos;
    newTipIdx = size(networkNodes, 1);

    networkSegments(end+1, :) = [inletTipIdx, newTipIdx];
    segmentDiameters = [segmentDiameters; ...
        calculateDiameter(newTipPos(1), domainSize, minVesselDiameter, maxVesselDiameter)];

    % Store initial growth direction for branch-angle memory
    branchVec = newTipPos - networkNodes(inletTipIdx, :);
    tipGrowthAngles(newTipIdx) = atan2(branchVec(2), branchVec(1));

    activeTipIndices(end+1) = newTipIdx;
end

fprintf('Initialization complete. Starting growth simulation...\n');


%% --- Main Growth Loop ---------------------------------------------------
% Each iteration advances every active tip by one step.
% A tip can: (a) grow forward, (b) bifurcate into a daughter branch,
% (c) anastomose onto an existing vessel and deactivate, or
% (d) exit the domain / reach the outlet and be removed.
%
% Segment splitting: when a tip anastomoses onto the interior of an existing
% segment (rather than a node endpoint), the crossed segment is replaced by
% two sub-segments joined at a new junction node.

iteration       = 0;
firstTimeBranch = 0;    % Counter tracking how many branching events have occurred
                        %   during the early-phase window

% Extend pre-allocated tracking arrays to maxNodes
if size(stepsSinceLastBranch, 2) < maxNodes
    stepsSinceLastBranch(maxNodes) = 0;
    vesselGrowthHistory{maxNodes}  = [];
    tipGrowthAngles(maxNodes)      = 0;
end

while ~isempty(activeTipIndices) && iteration < maxIterations
    iteration = iteration + 1;

    % Accumulate all structural changes during this iteration; apply at end
    nextActiveTips    = [];
    tipsToRemove      = [];
    tipsToAdd         = [];
    segmentsToRemove  = [];     % Indices of segments to replace due to splitting
    newSplitSegments  = [];     % Replacement sub-segments from splits
    newSplitDiameters = [];     % Diameters for replacement sub-segments

    currentTipSnapshot = activeTipIndices;  % Snapshot so mid-loop changes don't affect iteration

    for i = 1:length(currentTipSnapshot)
        currentTipIdx = currentTipSnapshot(i);

        % Skip tips already deactivated earlier in this iteration
        if ~ismember(currentTipIdx, activeTipIndices) || ...
                ismember(currentTipIdx, tipsToRemove)
            continue;
        end

        currentPos = networkNodes(currentTipIdx, :);

        % ---- 1. Identify Parent Node ------------------------------------
        % Locate the segment whose distal end is this tip to retrieve its
        % proximal parent node index.
        parentSegRow = find(networkSegments(:,2) == currentTipIdx, 1, 'last');
        if isempty(parentSegRow)
            fprintf('Warning: Tip %d has no parent segment.\n', currentTipIdx);
            tipsToRemove(end+1) = currentTipIdx;
            continue;
        end
        parentIdx = networkSegments(parentSegRow, 1);

        % ---- 2. Compute Growth Direction --------------------------------
        % The base growth direction is inherited from the grandparent→parent
        % vector, blended with an outlet-directed bias and a stochastic
        % angular perturbation to produce biologically realistic tortuosity.

        % Grandparent direction: one additional step back along the vessel axis
        if parentIdx > 0
            grandparentRows = find(networkSegments(:,2) == parentIdx);
            if ~isempty(grandparentRows)
                grandparentIdx  = networkSegments(grandparentRows(end), 1);
                parentDir       = networkNodes(parentIdx,:) - networkNodes(grandparentIdx,:);
                if norm(parentDir) > 1e-6
                    parentDir = parentDir / norm(parentDir);
                else
                    parentDir = [1, 0];
                end
            else
                parentDir = [1, 0];
            end
        else
            parentDir = [1, 0];
        end

        % Normalised x-position: 0 at inlet wall, 1 at outlet wall
        relX       = currentPos(1) / domainSize;
        inMiddle   = (relX >= middleRegionStart && relX <= middleRegionEnd);
        pastMiddle = (relX > middleRegionEnd);

        % Compute zone-dependent directional bias and angular noise.
        if pastMiddle
            % Zone 3 (Convergence): ramp up steering toward the outlet.
            % attractionStrength goes from 0 at middleRegionEnd to
            % outletInfluenceMax at the outlet wall.
            attractionStrength = min(1.0, ...
                (relX - middleRegionEnd) / (1 - middleRegionEnd) * outletInfluenceMax);

            vecToOutlet = arteryOutlet - currentPos;
            if norm(vecToOutlet) > 1e-6
                vecToOutlet = vecToOutlet / norm(vecToOutlet);
            else
                vecToOutlet = [1, 0];
            end

            % Angular noise decreases as the tip nears the outlet.
            % The second term is a y-restoring force countering vertical drift.
            randomAngle = (rand - 0.5) * (pi/2) * (1 - attractionStrength) ...
                - 2 * ((currentPos(2) - 0.5*domainSize) / (0.5*domainSize)) ...
                      * (currentPos(1) / domainSize);
        else
            % Zones 1 & 2 (Entry / Middle): wider angular exploration to fill
            % the capillary bed with dense, tortuous vessels.
            attractionStrength = 0.2;   % Weak outlet bias (0.3 also tested)

            % explorationAngleScale controls lateral spread; the restoring term
            % prevents tips from drifting far from the domain centre.
            randomAngle = explorationAngleScale * (rand - 0.5) * (pi/2) ...
                - 0.7 * ((currentPos(2) - 0.5*domainSize) / (0.5*domainSize)) ...
                        * (currentPos(1) / (0.5*domainSize));

            % Weakly randomised rightward vector (no hard outlet lock)
            vecToOutlet = [1, (rand - 0.5) * 0.4];
            if norm(vecToOutlet) > 1e-6
                vecToOutlet = vecToOutlet / norm(vecToOutlet);
            else
                vecToOutlet = [1, 0];
            end
        end

        % Blend parent axis with branch-angle memory (exponential smoothing
        % on growth angle to prevent sharp directional reversals).
        parentAngle     = atan2(parentDir(2), parentDir(1));
        prevBranchAngle = tipGrowthAngles(currentTipIdx);
        if prevBranchAngle ~= 0 && ~isnan(prevBranchAngle)
            % Weighted mix: (1-alpha)*parentAngle + alpha*memoryAngle
            parentAngle = (1 - branchMemoryStrength) * parentAngle + ...
                              branchMemoryStrength  * prevBranchAngle;
        end

        smoothAngle       = parentAngle + randomAngle;
        smoothUnbiasedVec = [cos(smoothAngle), sin(smoothAngle)];

        % Final growth vector: blend smoothed direction with outlet attraction
        growthVec = (1 - attractionStrength) * smoothUnbiasedVec + ...
                         attractionStrength  * vecToOutlet;
        if norm(growthVec) > 1e-6
            growthVec = growthVec / norm(growthVec);
        else
            growthVec = [1, 0];
        end

        % ---- 3. Proposed New Position -----------------------------------
        newPos = currentPos + stepSize * growthVec;

        % ---- 4. Boundary Check ------------------------------------------
        % Deactivate tips that would step outside the domain.
        if newPos(1) < 0 || newPos(1) > domainSize || ...
                newPos(2) < 0 || newPos(2) > domainSize
            tipsToRemove(end+1) = currentTipIdx;
            continue;
        end

        % ---- 5. Forced Snap to Outlet -----------------------------------
        % If the tip is within one step of the outlet in the convergence
        % zone, snap it directly onto the outlet node and deactivate.
        distToOutlet = norm(newPos - arteryOutlet);
        if distToOutlet < stepSize && relX > 0.9
            newPos = arteryOutlet;
            tipsToRemove(end+1) = currentTipIdx;
        end

        % ---- 6. Overlap Detection → Forced Anastomosis ------------------
        % If the proposed growth segment CROSSES an existing segment, a
        % junction node is placed at the crossing point and the crossed
        % segment is split into two sub-segments. This prevents vessels from
        % passing through one another and creates a realistic anastomotic loop.
        overlapDetected       = false;
        overlapTargetSegment  = -1;
        overlapIntersectPoint = [];
        minIntersectDist      = stepSize;   % Only accept crossings within one step

        for segIdx = 1:size(networkSegments, 1)
            % Skip the tip's own parent segment to avoid false self-crossing
            if (networkSegments(segIdx,1) == parentIdx && ...
                    networkSegments(segIdx,2) == currentTipIdx) || ...
               (networkSegments(segIdx,2) == parentIdx && ...
                    networkSegments(segIdx,1) == currentTipIdx)
                continue;
            end

            segP1 = networkNodes(networkSegments(segIdx,1), :);
            segP2 = networkNodes(networkSegments(segIdx,2), :);

            % Parametric intersection test.
            % t1: position along the growth step [0,1]
            % t2: position along the existing segment [0,1]
            [doesIntersect, intPoint, t1, t2] = lineSegmentIntersect( ...
                currentPos, newPos, segP1, segP2);

            % Accept only interior crossings (t > 0.01 avoids endpoint
            % coincidences) that are closer than any previously found crossing.
            if doesIntersect && t1 > 0.01 && t1 < 0.99 && ...
                    t2 > 0.01 && t2 < 0.99 && ...
                    norm(intPoint - currentPos) < minIntersectDist
                minIntersectDist      = norm(intPoint - currentPos);
                overlapIntersectPoint = intPoint;
                overlapTargetSegment  = segIdx;
                overlapDetected       = true;
                % Note: no 'break' here — we continue to find the CLOSEST crossing
            end
        end

        if overlapDetected && overlapTargetSegment ~= -1
            % Create a junction node at the crossing point
            networkNodes(end+1, :) = overlapIntersectPoint;
            junctionIdx = size(networkNodes, 1);

            % Connect the current tip to the new junction node
            networkSegments(end+1, :) = [currentTipIdx, junctionIdx];
            avgX = (currentPos(1) + overlapIntersectPoint(1)) / 2;
            segmentDiameters = [segmentDiameters; ...
                calculateDiameter(avgX, domainSize, minVesselDiameter, maxVesselDiameter)];

            % Split the crossed segment into two children at the junction
            origSeg  = networkSegments(overlapTargetSegment, :);
            newSeg1  = [origSeg(1), junctionIdx];
            newSeg2  = [junctionIdx, origSeg(2)];
            newSplitSegments  = [newSplitSegments; newSeg1; newSeg2];
            avgX1 = (networkNodes(newSeg1(1),1) + networkNodes(newSeg1(2),1)) / 2;
            avgX2 = (networkNodes(newSeg2(1),1) + networkNodes(newSeg2(2),1)) / 2;
            newSplitDiameters = [newSplitDiameters; ...
                calculateDiameter(avgX1, domainSize, minVesselDiameter, maxVesselDiameter); ...
                calculateDiameter(avgX2, domainSize, minVesselDiameter, maxVesselDiameter)];

            segmentsToRemove(end+1) = overlapTargetSegment;
            tipsToRemove(end+1)     = currentTipIdx;
            continue;   % Overlap handled — skip normal growth and anastomosis checks
        end

        % ---- 7. Normal Anastomosis Check --------------------------------
        % No crossing was detected. Check whether the proposed new position
        % is close enough to an existing node or segment for a voluntary
        % anastomosis (loop closure).
        anastomosed           = false;
        candidateTargetNode   = -1;
        candidateTargetSeg    = -1;
        candidateClosestPoint = [];
        minDistFound          = anastomosisDistNormal;  % Running minimum distance

        for k = size(networkSegments, 1):-1:1
            segNodeIndices = networkSegments(k, :);

            % Skip segments already marked for removal in this iteration
            if segNodeIndices(1) == 0 || segNodeIndices(2) == 0
                continue;
            end
            % Skip the tip's own parent segment
            if (segNodeIndices(1) == parentIdx && segNodeIndices(2) == currentTipIdx) || ...
               (segNodeIndices(2) == parentIdx && segNodeIndices(1) == currentTipIdx)
                continue;
            end
            % Skip segments sharing the parent node (prevents trivial loops)
            if segNodeIndices(1) == parentIdx || segNodeIndices(2) == parentIdx
                continue;
            end

            segP1 = networkNodes(segNodeIndices(1), :);
            segP2 = networkNodes(segNodeIndices(2), :);
            distToP1 = norm(newPos - segP1);
            distToP2 = norm(newPos - segP2);
            [distToSeg, closestPtOnSeg] = pointToSegmentDist(newPos, segP1, segP2);

            % Prefer connecting to the nearest endpoint; fall back to the
            % nearest interior point on the segment (with tighter threshold).
            if distToP1 < minDistFound && segNodeIndices(1) ~= currentTipIdx
                candidateTargetNode   = segNodeIndices(1);
                candidateTargetSeg    = -1;
                minDistFound          = distToP1;
                candidateClosestPoint = segP1;
            end
            if distToP2 < minDistFound && segNodeIndices(2) ~= currentTipIdx
                candidateTargetNode   = segNodeIndices(2);
                candidateTargetSeg    = -1;
                minDistFound          = distToP2;
                candidateClosestPoint = segP2;
            end
            if distToSeg < anastomosisDistNormal/2 && distToSeg < minDistFound
                candidateTargetNode   = -1;
                candidateTargetSeg    = k;
                minDistFound          = distToSeg;
                candidateClosestPoint = closestPtOnSeg;
            end
        end

        % Resolve candidate: mid-segment connections require a new junction node
        targetNodeForConnection = -1;
        segmentToSplitIdx       = -1;

        if candidateTargetNode ~= -1
            targetNodeForConnection = candidateTargetNode;
        elseif candidateTargetSeg ~= -1
            networkNodes(end+1, :)  = candidateClosestPoint;
            newJunctionIdx          = size(networkNodes, 1);
            targetNodeForConnection = newJunctionIdx;
            segmentToSplitIdx       = candidateTargetSeg;
        end

        % Loop-size guard: only permit anastomosis if the resulting loop would
        % contain at least minLoopNodes nodes.
        if targetNodeForConnection ~= -1
            loopPath = findPathBFS(currentTipIdx, targetNodeForConnection, ...
                networkSegments, networkNodes);
            if ~isempty(loopPath)
                loopSize = length(loopPath);    % BFS path includes start and end nodes
                if loopSize < minLoopNodes
                    targetNodeForConnection = -1;   % Loop too short — reject anastomosis
                    segmentToSplitIdx       = -1;
                end
            end
        end

        % Finalise anastomosis if the candidate passed the loop-size check
        if targetNodeForConnection ~= -1
            segExists1 = ismember([currentTipIdx, targetNodeForConnection], networkSegments, 'rows');
            segExists2 = ismember([targetNodeForConnection, currentTipIdx], networkSegments, 'rows');

            if ~segExists1 && ~segExists2
                % Connect tip to target node
                networkSegments(end+1, :) = [currentTipIdx, targetNodeForConnection];
                avgX = (networkNodes(currentTipIdx,1) + networkNodes(targetNodeForConnection,1)) / 2;
                segmentDiameters = [segmentDiameters; ...
                    calculateDiameter(avgX, domainSize, minVesselDiameter, maxVesselDiameter)];
                anastomosed = true;
                tipsToRemove(end+1) = currentTipIdx;

                % Split the target segment if anastomosis was mid-segment
                if segmentToSplitIdx ~= -1
                    origSeg = networkSegments(segmentToSplitIdx, :);
                    newSeg1 = [origSeg(1), targetNodeForConnection];
                    newSeg2 = [targetNodeForConnection, origSeg(2)];
                    newSplitSegments  = [newSplitSegments; newSeg1; newSeg2];
                    avgX1 = (networkNodes(newSeg1(1),1) + networkNodes(newSeg1(2),1)) / 2;
                    avgX2 = (networkNodes(newSeg2(1),1) + networkNodes(newSeg2(2),1)) / 2;
                    newSplitDiameters = [newSplitDiameters; ...
                        calculateDiameter(avgX1, domainSize, minVesselDiameter, maxVesselDiameter); ...
                        calculateDiameter(avgX2, domainSize, minVesselDiameter, maxVesselDiameter)];
                    segmentsToRemove(end+1) = segmentToSplitIdx;
                end
            else
                % Segment already exists (duplicate): deactivate tip silently
                anastomosed = true;
                tipsToRemove(end+1) = currentTipIdx;
            end

            if anastomosed
                continue;
            end
        end

        % ---- 8. Normal Growth Step (no anastomosis, no overlap) ---------
        % Advance the tip: add new node and connecting segment.
        networkNodes(end+1, :) = newPos;
        newNodeIdx = size(networkNodes, 1);

        % Extend tracking arrays on-demand if pre-allocated size is exceeded
        if newNodeIdx > length(stepsSinceLastBranch)
            stepsSinceLastBranch(newNodeIdx + 1000) = 0;
            tipGrowthAngles(newNodeIdx + 1000)      = 0;
            vesselGrowthHistory{newNodeIdx + 1000}  = [];
        end

        networkSegments(end+1, :) = [currentTipIdx, newNodeIdx];
        avgX = (networkNodes(currentTipIdx,1) + newPos(1)) / 2;
        segmentDiameters = [segmentDiameters; ...
            calculateDiameter(avgX, domainSize, minVesselDiameter, maxVesselDiameter)];

        % Record growth angle for branch-angle memory in subsequent steps
        growthAngle = atan2(growthVec(2), growthVec(1));
        tipGrowthAngles(newNodeIdx) = growthAngle;

        % Maintain a rolling window of recent positions for direction smoothing
        if isempty(vesselGrowthHistory{currentTipIdx}) || ...
                size(vesselGrowthHistory{currentTipIdx}, 1) == 0
            vesselGrowthHistory{newNodeIdx} = [networkNodes(currentTipIdx,:); newPos];
        else
            vesselGrowthHistory{newNodeIdx} = [vesselGrowthHistory{currentTipIdx}; newPos];
            if size(vesselGrowthHistory{newNodeIdx}, 1) > 10
                vesselGrowthHistory{newNodeIdx} = ...
                    vesselGrowthHistory{newNodeIdx}(end-9:end, :);
            end
        end

        % Propagate and increment the branch-interval counter to the new tip
        parentLineageSteps = stepsSinceLastBranch(currentTipIdx);
        stepsSinceLastBranch(newNodeIdx)    = parentLineageSteps + 1;
        stepsSinceLastBranch(currentTipIdx) = stepsSinceLastBranch(currentTipIdx) + 1;

        nextActiveTips(end+1) = newNodeIdx;

        % ---- 9. Branching Decision --------------------------------------
        % A bifurcation is attempted stochastically. The effective branch
        % probability is scaled by a position-dependent factor:
        %   Zone 2 (Middle):      enhanced branching to fill the capillary bed
        %   Zone 3 (Convergence): suppressed branching to funnel toward outlet
        positionBranchFactor = 1.2;

        if inMiddle
            positionBranchFactor = 1.5;
        elseif pastMiddle
            % Linearly reduce branching probability toward zero at the outlet
            positionBranchFactor = max(0.2, ...
                1.5 * (1 - (relX - middleRegionEnd) / (1 - middleRegionEnd)));
        end

        effectiveBranchProb = branchProbability * positionBranchFactor;

        % Early-phase branching window: during the first
        % firstMinBranchIntervalLimit branching events the algorithm uses
        % firstMinBranchInterval as the spacing threshold, enabling faster
        % initial network build-up. After that it switches to minBranchInterval.
        if firstTimeBranch < firstMinBranchIntervalLimit
            canBranch = (stepsSinceLastBranch(currentTipIdx) >= firstMinBranchInterval);
            % disp("distance branching condition skipped")  % Debug: early-phase active
            firstTimeBranch = firstTimeBranch + 1;
        else
            canBranch = (stepsSinceLastBranch(currentTipIdx) >= minBranchInterval);
        end

        if canBranch && rand < effectiveBranchProb
            branchOriginIdx = currentTipIdx;

            % Determine the local vessel axis at the branch point.
            % Prefer the direct parent vector; fall back to averaged history.
            parentDirBranch = networkNodes(currentTipIdx,:) - networkNodes(parentIdx,:);
            if norm(parentDirBranch) < 1e-6 && ...
                    ~isempty(vesselGrowthHistory{currentTipIdx}) && ...
                    size(vesselGrowthHistory{currentTipIdx}, 1) >= 2
                history    = vesselGrowthHistory{currentTipIdx};
                recentDirs = diff(history(max(1, end - smoothingWindow):end, :), 1);
                avgDir     = mean(recentDirs, 1);
                if norm(avgDir) > 1e-6
                    parentDirBranch = avgDir / norm(avgDir);
                else
                    parentDirBranch = growthVec;
                end
            elseif norm(parentDirBranch) > 1e-6
                parentDirBranch = parentDirBranch / norm(parentDirBranch);
            else
                parentDirBranch = growthVec;
            end

            % Apply branch-angle memory to the bifurcation base angle
            mainAngle = atan2(parentDirBranch(2), parentDirBranch(1));
            prevAngle = tipGrowthAngles(currentTipIdx);
            if prevAngle ~= 0 && ~isnan(prevAngle)
                baseAngle = (1 - branchMemoryStrength) * mainAngle + ...
                                branchMemoryStrength  * prevAngle;
            else
                baseAngle = mainAngle;
            end

            % Branch angular range: wider in Zone 2 (capillary bed),
            % narrower in Zone 3 (convergence toward outlet).
            if inMiddle
                branchAngleRange = pi / 3;
            elseif pastMiddle
                % Narrow range approaches zero at the outlet wall
                branchAngleRange = pi/4 * (1 - min(1.0, ...
                    (relX - middleRegionEnd) / (1 - middleRegionEnd)));
            else
                branchAngleRange = pi/4 * max(0.4, relX / middleRegionStart);
            end

            % Randomly select which side the daughter branch angles toward
            branchSide        = sign(0.5 - rand);
            branchAngleOffset = branchSide * (branchAngleRange * rand^1.2);
            branchAngle       = baseAngle + branchAngleOffset;
            branchVec         = [cos(branchAngle), sin(branchAngle)];

            % In Zone 3, blend the branch direction toward the outlet
            if pastMiddle
                outletBias = arteryOutlet - networkNodes(currentTipIdx,:);
                if norm(outletBias) > 1e-6
                    outletBias    = outletBias / norm(outletBias);
                    attractFactor = min(0.8, (relX - middleRegionEnd) / (1 - middleRegionEnd));
                    branchVec     = (1 - attractFactor) * branchVec + attractFactor * outletBias;
                    if norm(branchVec) > 1e-6
                        branchVec = branchVec / norm(branchVec);
                    end
                end
            end

            % Small positional jitter to break numerical symmetry at forks
            jitter    = [(rand-0.5)*0.05, (rand-0.5)*0.05];
            branchVec = branchVec + jitter;
            if norm(branchVec) > 1e-6
                branchVec = branchVec / norm(branchVec);
            end

            branchNewPos = networkNodes(branchOriginIdx,:) + stepSize * branchVec;

            % Reset the branch-interval counter on the current lineage node
            stepsSinceLastBranch(currentTipIdx) = 0;

            % Only add the branch if its first node starts inside the domain
            if branchNewPos(1) >= 0 && branchNewPos(1) <= domainSize && ...
                    branchNewPos(2) >= 0 && branchNewPos(2) <= domainSize

                networkNodes(end+1, :) = branchNewPos;
                branchTipIdx = size(networkNodes, 1);

                if branchTipIdx > length(stepsSinceLastBranch)
                    stepsSinceLastBranch(branchTipIdx + 1000) = 0;
                    tipGrowthAngles(branchTipIdx + 1000)      = 0;
                    vesselGrowthHistory{branchTipIdx + 1000}  = [];
                end

                networkSegments(end+1, :) = [branchOriginIdx, branchTipIdx];
                avgX = (networkNodes(branchOriginIdx,1) + branchNewPos(1)) / 2;
                segmentDiameters(end+1) = calculateDiameter( ...
                    avgX, domainSize, minVesselDiameter, maxVesselDiameter);

                tipGrowthAngles(branchTipIdx)      = branchAngle;
                stepsSinceLastBranch(branchTipIdx) = 0;

                tipsToAdd(end+1) = branchTipIdx;
            end
        end

        % The current tip has advanced to newNodeIdx; deactivate old position
        tipsToRemove(end+1) = currentTipIdx;

    end % --- end per-tip loop ---

    % Apply structural changes accumulated during this iteration.
    % Remove split segments; append replacement sub-segments.
    if ~isempty(segmentsToRemove)
        uniqueToRemove = unique(segmentsToRemove);
        networkSegments(uniqueToRemove, :) = [];
        segmentDiameters(uniqueToRemove)   = [];
    end
    if ~isempty(newSplitSegments)
        networkSegments  = [networkSegments;  newSplitSegments];
        segmentDiameters = [segmentDiameters; newSplitDiameters];
    end

    % Update the active tip list for the next iteration
    activeTipIndices = setdiff(activeTipIndices, unique(tipsToRemove));
    activeTipIndices = [activeTipIndices, nextActiveTips, tipsToAdd];
    activeTipIndices = unique(activeTipIndices);

    if mod(iteration, 100) == 0
        fprintf('Iter %4d | Active tips: %3d | Nodes: %4d | Segments: %4d\n', ...
            iteration, length(activeTipIndices), ...
            size(networkNodes,1), size(networkSegments,1));
    end

end % --- end growth loop ---

fprintf('Growth finished after %d iterations.\n', iteration);
fprintf('  Total nodes: %d,  Total segments: %d\n', ...
    size(networkNodes,1), size(networkSegments,1));


%% --- Post-Processing: Cleanup and Outlet Connection ---------------------
% After the stochastic growth phase, some tips may not have anastomosed.
% This section connects right-side danglers to the outlet and attempts to
% attach left-side danglers to the nearest well-connected node, ensuring
% the final network is as fully connected as possible.

fprintf('\nStarting post-processing cleanup...\n');

% Compute node degree (number of connected segments per node)
nodesDegree = zeros(size(networkNodes, 1), 1);
for k = 1:size(networkSegments, 1)
    if networkSegments(k,1) > 0 && networkSegments(k,1) <= size(networkNodes,1)
        nodesDegree(networkSegments(k,1)) = nodesDegree(networkSegments(k,1)) + 1;
    end
    if networkSegments(k,2) > 0 && networkSegments(k,2) <= size(networkNodes,1)
        nodesDegree(networkSegments(k,2)) = nodesDegree(networkSegments(k,2)) + 1;
    end
end

% Report fully isolated nodes (degree 0) — these are numerical artefacts
isolatedNodes = find(nodesDegree == 0);
if ~isempty(isolatedNodes)
    fprintf('Removing %d isolated nodes\n', length(isolatedNodes));
    for i = 1:length(isolatedNodes)
        fprintf('  Isolated node %d at (%.3f, %.3f)\n', isolatedNodes(i), ...
            networkNodes(isolatedNodes(i),1), networkNodes(isolatedNodes(i),2));
    end
end

% Dangling tips: nodes with exactly one connecting segment
danglingTips = find(nodesDegree == 1);
fprintf('Found %d dangling tips before cleanup\n', length(danglingTips));

% Ensure the outlet exists as a named node in the network
outletNodeIdx  = -1;
outletExists   = false;
for i = 1:size(networkNodes, 1)
    if norm(networkNodes(i,:) - arteryOutlet) < 1e-6
        outletNodeIdx = i;
        outletExists  = true;
        break;
    end
end
if ~outletExists
    networkNodes(end+1, :) = arteryOutlet;
    outletNodeIdx = size(networkNodes, 1);
    fprintf('Added outlet node at index %d\n', outletNodeIdx);
end

% Connect right-side danglers (x > 60% of domain) directly to the outlet
outletConnectionCount = 0;
for k = 1:length(danglingTips)
    tipIdx  = danglingTips(k);
    tipPos  = networkNodes(tipIdx, :);
    relXTip = tipPos(1) / domainSize;

    if relXTip > 0.6 && norm(tipPos - arteryOutlet) > 1e-6
        exists1 = ismember([tipIdx, outletNodeIdx], networkSegments, 'rows');
        exists2 = ismember([outletNodeIdx, tipIdx], networkSegments, 'rows');
        if ~exists1 && ~exists2
            networkSegments(end+1, :) = [tipIdx, outletNodeIdx];
            avgX = (tipPos(1) + arteryOutlet(1)) / 2;
            segmentDiameters = [segmentDiameters; ...
                calculateDiameter(avgX, domainSize, minVesselDiameter, maxVesselDiameter)];
            outletConnectionCount = outletConnectionCount + 1;
            fprintf('Connected dangling tip %d at (%.3f, %.3f) to outlet\n', ...
                tipIdx, tipPos(1), tipPos(2));
        end
    end
end

% Recalculate degrees after outlet connections
nodesDegree = zeros(size(networkNodes, 1), 1);
for k = 1:size(networkSegments, 1)
    if networkSegments(k,1) > 0 && networkSegments(k,1) <= size(networkNodes,1)
        nodesDegree(networkSegments(k,1)) = nodesDegree(networkSegments(k,1)) + 1;
    end
    if networkSegments(k,2) > 0 && networkSegments(k,2) <= size(networkNodes,1)
        nodesDegree(networkSegments(k,2)) = nodesDegree(networkSegments(k,2)) + 1;
    end
end

danglingTips = find(nodesDegree == 1);

% Attempt to connect remaining left-side danglers to the nearest node that
% is already embedded in the network (degree > 1), within 3 step lengths.
leftSideConnectionCount = 0;
remainingDanglers       = [];

for k = 1:length(danglingTips)
    tipIdx  = danglingTips(k);
    tipPos  = networkNodes(tipIdx, :);
    relXTip = tipPos(1) / domainSize;

    if relXTip <= 0.6
        minDist    = inf;
        bestTarget = -1;

        for j = 1:size(networkNodes, 1)
            if j ~= tipIdx && nodesDegree(j) > 1
                d = norm(tipPos - networkNodes(j,:));
                if d < minDist && d < stepSize * 3
                    minDist    = d;
                    bestTarget = j;
                end
            end
        end

        if bestTarget ~= -1
            exists1 = ismember([tipIdx, bestTarget], networkSegments, 'rows');
            exists2 = ismember([bestTarget, tipIdx], networkSegments, 'rows');
            if ~exists1 && ~exists2
                networkSegments(end+1, :) = [tipIdx, bestTarget];
                avgX = (tipPos(1) + networkNodes(bestTarget,1)) / 2;
                segmentDiameters = [segmentDiameters; ...
                    calculateDiameter(avgX, domainSize, minVesselDiameter, maxVesselDiameter)];
                leftSideConnectionCount = leftSideConnectionCount + 1;
                fprintf('Connected left dangler %d to node %d (dist=%.3f)\n', ...
                    tipIdx, bestTarget, minDist);
            end
        else
            remainingDanglers(end+1) = tipIdx;
        end
    end
end

% Final degree recount and connectivity summary
nodesDegree = zeros(size(networkNodes, 1), 1);
for k = 1:size(networkSegments, 1)
    if networkSegments(k,1) > 0 && networkSegments(k,1) <= size(networkNodes,1)
        nodesDegree(networkSegments(k,1)) = nodesDegree(networkSegments(k,1)) + 1;
    end
    if networkSegments(k,2) > 0 && networkSegments(k,2) <= size(networkNodes,1)
        nodesDegree(networkSegments(k,2)) = nodesDegree(networkSegments(k,2)) + 1;
    end
end
finalDanglers = sum(nodesDegree == 1);
finalIsolated = sum(nodesDegree == 0);

fprintf('Post-processing summary:\n');
fprintf('  Connected %d tips to outlet\n',               outletConnectionCount);
fprintf('  Connected %d left-side danglers to network\n', leftSideConnectionCount);
fprintf('  %d danglers remain unconnected\n',             length(remainingDanglers));
fprintf('Final network: %d dangling nodes, %d isolated nodes\n', finalDanglers, finalIsolated);


%% --- Save Results -------------------------------------------------------
% Saves the network graph to a .mat file and the figure to a PNG.
% Requires ./Models/ and ./Model_Images/ directories to exist before running.
%       saving multiple realisations with the same experimentID.

if saveResults == 1

    outputFile = append("./Models/model_", num2str(experimentID), ".mat");
    save(outputFile, "networkNodes", "networkSegments", "segmentDiameters", ...
         "domainSize", "tipGrowthAngles");
    disp(outputFile);
end


%% --- Visualization ------------------------------------------------------
% Renders the network with line width proportional to vessel diameter and a
% colour gradient: blue (inlet) → green (mid-domain) → red (outlet).

fig = figure();
hold on;

for i = 1:size(networkSegments, 1)
    p1 = networkNodes(networkSegments(i,1), :);
    p2 = networkNodes(networkSegments(i,2), :);

    % Line width scaled to vessel diameter for perceptual accuracy
    segmentWidth = segmentDiameters(i) * 20;

    % Colour gradient along x: blue→green (left half), green→red (right half)
    normX = ((p1(1) + p2(1)) / 2) / domainSize;
    if normX < 0.5
        segColor = [max(1 - 2*normX, 0), min(2*normX, 1), 0];
    else
        segColor = [0, max(1 - 2*(normX-0.5), 0), min(2*(normX-0.5), 1)];
    end

    line([p1(1), p2(1)], [p1(2), p2(2)], ...
        'LineWidth', segmentWidth, 'Color', segColor);
end

% Highlight inlet (red filled) and outlet (blue filled) nodes
scatter(arteryInlet(1),  arteryInlet(2),  100, 'r', 'filled');
scatter(arteryOutlet(1), arteryOutlet(2), 100, 'b', 'filled');

axis equal;

% Mark any remaining dangling tips in red for manual inspection
if ~isempty(remainingDanglers)
    for i = 1:length(remainingDanglers)
        dangPos = networkNodes(remainingDanglers(i), :);
        scatter(dangPos(1), dangPos(2), 50, 'r', 'x', 'LineWidth', 2);
    end
end

axis off;
axis([-1, domainSize+1, -1, domainSize+1]);
hold off;

if saveResults == 1
    imgFile = append("Model_Images/imageout-", num2str(experimentID),".png");
    exportgraphics(fig, imgFile, Resolution=300);
end


%% ========================================================================
%  HELPER FUNCTIONS
%  ========================================================================

function diameter = calculateDiameter(xPos, domainSize, minDiameter, maxDiameter)
% CALCULATEDIAMETER  Vessel diameter at position x using a parabolic profile.
%
%   Profile satisfies:
%     diameter(0)            = maxDiameter   (at inlet wall)
%     diameter(domainSize/2) = minDiameter   (at mid-domain capillary bed)
%     diameter(domainSize)   = maxDiameter   (at outlet wall)
%
%   This approximates Murray's Law taper from arterioles into capillaries.
%
%   Derivation of parabola coefficient a:
%     f(x_norm) = a*(x_norm - 0.5)^2 + minDiameter
%     At x_norm = 0:  maxDiameter = a*(0.25) + minDiameter
%     => a = (maxDiameter - minDiameter) / 0.25

    xNorm    = xPos / domainSize;
    a        = (maxDiameter - minDiameter) / 0.25;
    diameter = a * (xNorm - 0.5)^2 + minDiameter;
end


function [doesIntersect, intPoint, t1, t2] = lineSegmentIntersect(p1, p2, p3, p4)
% LINESEGMENTINTERSECT  Parametric intersection of two line segments.
%
%   Uses the parametric form:
%     Segment 1: P(t1) = p1 + t1*(p2-p1),  t1 in [0,1]
%     Segment 2: Q(t2) = p3 + t2*(p4-p3),  t2 in [0,1]
%
%   The caller must verify t1 and t2 both lie in (0,1) to confirm that
%   the intersection is interior to both finite segments (not extrapolated).
%
%   Outputs:
%     doesIntersect - true if the two infinite lines intersect (non-parallel)
%     intPoint      - [x, y] intersection coordinates
%     t1, t2        - parametric positions along each segment

    doesIntersect = false;
    intPoint      = [NaN, NaN];
    t1            = NaN;
    t2            = NaN;

    d1        = p2 - p1;
    d2        = p4 - p3;
    crossProd = d1(1)*d2(2) - d1(2)*d2(1);

    % Parallel or collinear lines have no unique intersection point
    if abs(crossProd) < 1e-10
        return;
    end

    dp = p3 - p1;
    t1 = (dp(1)*d2(2) - dp(2)*d2(1)) / crossProd;
    t2 = (dp(1)*d1(2) - dp(2)*d1(1)) / crossProd;

    intPoint      = p1 + t1 * d1;
    doesIntersect = true;
end


function [dist, closestPoint] = pointToSegmentDist(p, v, w)
% POINTTOSEGMENTDIST  Shortest distance from point p to segment [v, w].
%
%   Projects p onto the infinite line through v and w, clamps the parameter
%   t to [0,1] to stay within the finite segment, then returns the distance
%   and the closest point on the segment.
%
%   Parameterisation:  point on segment = v + t*(w-v),  t in [0,1]
%   Projection:        t = dot(p-v, w-v) / |w-v|^2

    segLenSq = sum((w - v).^2);    % Squared segment length |w-v|^2

    if segLenSq == 0
        % Degenerate segment: v and w are the same point
        dist         = norm(p - v);
        closestPoint = v;
        return;
    end

    t            = max(0, min(1, sum((p-v).*(w-v)) / segLenSq));
    closestPoint = v + t * (w - v);
    dist         = norm(p - closestPoint);
end


function path = findPathBFS(startNode, endNode, segments, nodes)
% FINDPATHBFS  Breadth-first search for a path between two nodes.
%
%   Called before forming an anastomosis to check whether a loop already
%   exists between the candidate tip and the target node. If a path is
%   found, the caller checks its length against minLoopNodes before
%   permitting the new loop to close.
%
%   Inputs:
%     startNode - index of the source node
%     endNode   - index of the target node
%     segments  - [M x 2] segment connectivity matrix
%     nodes     - [N x 2] node coordinate matrix (used for size only)
%
%   Output:
%     path - ordered node index array from startNode to endNode;
%            empty [] if no path exists between them.

    n       = size(nodes, 1);
    adjList = cell(1, n);

    % Build undirected adjacency list from the segment connectivity matrix
    for i = 1:size(segments, 1)
        n1 = segments(i, 1);
        n2 = segments(i, 2);
        if n1 > 0 && n1 <= n && n2 > 0 && n2 <= n
            adjList{n1} = [adjList{n1}, n2];
            adjList{n2} = [adjList{n2}, n1];
        end
    end

    visited            = false(1, n);
    parent             = zeros(1, n);
    queue              = startNode;
    visited(startNode) = true;

    while ~isempty(queue)
        current  = queue(1);
        queue(1) = [];

        if current == endNode
            break;
        end

        for i = 1:length(adjList{current})
            nb = adjList{current}(i);
            if ~visited(nb)
                visited(nb)  = true;
                parent(nb)   = current;
                queue(end+1) = nb;
            end
        end
    end

    if ~visited(endNode)
        path = [];  % No path exists between the two nodes
        return;
    end

    % Trace back through parent pointers to reconstruct the full path
    path    = endNode;
    current = endNode;
    while current ~= startNode
        current = parent(current);
        path    = [current, path];
    end
end