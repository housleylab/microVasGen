% =========================================================================
% Title:        COMSOL Evaluation-Point Generator for END-vs-CFD
%               Cross-Validation
% Author:       Aref Valipour, Housley Lab, Georgia Tech
% Date:         2026
%
% Description:
%   Writes two coordinate files that COMSOL can import as 3-D cut-point
%   datasets (Results → Datasets → Cut Point 3D → "From file"), so that
%   CFD results on the S4 geometry can be compared one-to-one against the
%   END (SPICE) solution from S3:
%
%     Flow points     — one point per vessel segment, at the segment
%                       midpoint on the vessel centreline. Evaluate velocity
%                       (or flow rate) here and compare with the S3 branch
%                       currents.
%     Pressure points — one point per network node. Evaluate pressure here
%                       and compare with the S3 nodal voltages.
%
%   Row order matches the network graph exactly:
%     row i of the flow file     ↔ segment i (networkSegments(i,:), R<i> in SPICE)
%     row i of the pressure file ↔ node i    (networkNodes(i,:), SPICE node i−1)
%   Segment indices can be looked up on the map from A2_Segment_Map.m.
%
%   Coordinates are written in µm to match the COMSOL geometry length unit
%   set by S4. S4 places every cone base at z = 0 with an in-plane axis,
%   so all vessel centrelines lie in the plane z = evalPlaneZ_um (0 µm).
%   Note: the S5 subset geometry raises nodes out of plane
%   (zShiftFactor × node diameter), so these points match S4, not S5.
%
% Inputs:
%   ./Models/<modelName>.mat     Network graph (networkNodes, networkSegments)
%
% Outputs:
%   ./COMSOL_API/<modelName>_EvalPoints_Flow.txt       [M × 3] x, y, z (µm)
%   ./COMSOL_API/<modelName>_EvalPoints_Pressure.txt   [N × 3] x, y, z (µm)
%
% Citation:
%   [TBA]
% =========================================================================

%% --- Workspace Initialization -------------------------------------------
clear;
close all;
clc;


%% --- Parameters ---------------------------------------------------------

% --- File and model identity ---
modelName = "Model_1_ICDT";    % Network file to load (no extension).
                               %   Use the same model as S4.

% --- Unit conversion ---
% The network graph stores coordinates in mm; the S4 COMSOL geometry uses µm.
mmToMicrons = 1000;     % µm per mm

% --- Evaluation plane ---
% z-coordinate (µm) of the vessel centrelines in the S4 geometry.
evalPlaneZ_um = 0;


%% --- Load Network Graph -------------------------------------------------
load(append("./Models/", modelName, ".mat"));

numNodes    = size(networkNodes, 1);
numSegments = size(networkSegments, 1);

nodesUm = networkNodes * mmToMicrons;   % Node coordinates (µm)


%% --- Compute Evaluation Points ------------------------------------------
% Flow points: segment midpoints on the centreline (µm)
segP1Um          = nodesUm(networkSegments(:, 1), :);
segP2Um          = nodesUm(networkSegments(:, 2), :);
segmentMidUm     = (segP1Um + segP2Um) / 2;
flowEvalPoints   = [segmentMidUm, repmat(evalPlaneZ_um, numSegments, 1)];   % [M × 3]

% Pressure points: node positions on the centreline plane (µm)
pressureEvalPoints = [nodesUm, repmat(evalPlaneZ_um, numNodes, 1)];        % [N × 3]


%% --- Write Output Files -------------------------------------------------
flowFilePath     = append("./COMSOL_API/", modelName, "_EvalPoints_Flow.txt");
pressureFilePath = append("./COMSOL_API/", modelName, "_EvalPoints_Pressure.txt");

writematrix(flowEvalPoints,     flowFilePath);
writematrix(pressureEvalPoints, pressureFilePath);

fprintf('Flow evaluation points (%d segments) written to: %s\n', numSegments, flowFilePath);
fprintf('Pressure evaluation points (%d nodes) written to: %s\n', numNodes, pressureFilePath);
