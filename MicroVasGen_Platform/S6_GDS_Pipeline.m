% =========================================================================
% Title:        GDS Photolithography Mask Generator for Microvascular
%               Network (Tapered Trapezoids + Node Circles)
% Author:       Aref Valipour, Housley Lab, Georgia Tech
% Date:         2026
%
% Description:
%   Converts a microvascular network graph into a GDSII photolithography
%   mask file suitable for soft-lithography or photolithography fabrication
%   of microfluidic devices.
%
%   Each vessel segment is rendered as a filled trapezoid whose width at
%   each end equals the largest diameter among all segments connected to
%   that endpoint node. Using the node maximum diameter (rather than the
%   segment diameter directly) ensures smooth, continuous channel widths
%   at bifurcations. Junction nodes are rendered as filled circles (implemented as
%   GDS arc elements) to complete the rounded channel geometry at forks.
%
%   Inlet and outlet boundary nodes receive short rectangular stub
%   extensions plus large circular pads to interface with external tubing
%   connectors.
%
%   The script supports tiling: a 'shifting' loop creates spatially offset
%   copies of the network on the same wafer for multi-device layouts.
%   Adjust the shifting range in the Parameters section as needed.
%
% Workflow:
%   1. Load network graph (nodes, segments, segment_diameters, domain_size)
%   2. Convert all spatial quantities from mm to µm
%   3. Determine the maximum adjacent diameter at every node
%   4. For each device copy (shifting loop):
%      a. Draw tapered trapezoid per vessel segment
%      b. Draw filled circle per junction node
%      c. Add inlet/outlet stubs and circular connection pads
%   5. Add wafer text labels
%   6. Write the GDSII library to disk
%
% Inputs:
%   ./Models/<modelName>.mat     Network graph with fields:
%                              nodes, segments, segment_diameters, domain_size
%
% Outputs:
%   ./GDS/FabricationMask_<modelName>.gds    GDSII mask file
%
% Dependencies:
%   GDS-MATLAB toolbox (K.-M. Müller & J. Cziber):
%     gds_structure(), gds_element(), gds_library(), write_gds_library(),
%     gdsii_arc(), gdsii_pathtext(), add_element()
%   Available at: https://github.com/ulfgri/gdsii-toolbox
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


%% --- Parameters ---------------------------------------------------------

% --- File and model identity ---
modelName = "model_1_ICDT";    % Network file to load (no extension)

% --- Wafer identification labels ---
% These strings are rendered as path-text elements on the GDS mask.
waferLabel    = char(modelName);     % Primary wafer/device label
processLabel  = '2026 SU8';  % Secondary process/batch label

% --- GDS layer assignment ---
% All geometry for this network is written to a single GDS layer.
% Change this value to target a different layer in a multi-layer process.
gdsLayer = 2;

% --- Unit conversion ---
% The network graph stores all spatial quantities in mm. GDS coordinates
% are written in µm (1 mm = 1000 µm).
micronsPerMm = 1000;    % µm per mm

% --- Tiling / wafer layout ---
% The shifting loop creates spatially offset copies of the network on the
% same wafer (useful for multi-device or redundancy layouts).
% shiftingRange = -1:0 produces two copies (at shifting = -1 and 0).
% Set shiftingRange = 0:0 for a single device; extend as needed.
shiftingRange = -1:0;   % Integer range of device copies

% --- Boundary stub geometry ---
% Short rectangular stubs extend from the inlet and outlet nodes to the
% edge of the domain, providing a clean interface for the circular pads.
stubLengthMm = 5;   % Length of inlet/outlet stub extensions (mm)

% --- Connection pad geometry ---
% Large annular pads at the stub endpoints interface with tubing connectors.
padInnerRadius_um  = 250;   % Inner radius of annular pad (µm)
padWidth_um        = 250;   % Width (annular thickness) of pad (µm)
padApproxError     = 2;     % Arc discretisation error tolerance (µm)

% --- Text label positions and geometry ---
% Path-text elements rendered at fixed wafer coordinates.
labelPosition1    = [37000, 0];     % (x, y) of primary label (µm)
labelPosition2    = [40000, 0];     % (x, y) of secondary label (µm)
labelHeight_um    = 1200;           % Text character height (µm)
labelRotation_deg = 90;             % Text rotation angle (degrees)
labelLineWidth    = 0.15 * 800;     % Path-text line width (µm)

% --- Segment skip threshold ---
% Segments shorter than this value (µm) are treated as degenerate and skipped.
minSegmentLength_um = 0.001;    % µm

% --- Node circle minimum size ---
% Nodes whose maximum adjacent diameter is below this threshold are skipped
% (prevents near-zero-area circles that cause GDS write errors).
minNodeDiameter_um = 1;     % µm

% --- Arc discretisation error for node circles ---
nodeCircleApproxError = 0.2;    % µm


%% --- Load Network Graph -------------------------------------------------
load(append("./Models/", modelName, ".mat"));

minDiameterVisMm = min(segmentDiameters);   % Fallback diameter (mm) for invalid segments


%% --- Unit Conversion (mm → µm) -----------------------------------------
nodesUm              = networkNodes     * micronsPerMm;    % Node coordinates (µm)
segmentDiametersUm   = segmentDiameters * micronsPerMm;    % Segment diameters (µm)
minDiameterVisUm     = minDiameterVisMm * micronsPerMm;    % Fallback diameter (µm)


%% --- Compute Maximum Adjacent Diameter per Node -------------------------
% For each node, find the largest diameter among all vessel segments
% connected to it. This value is used to set trapezoid widths and circle
% radii, ensuring smooth diameter transitions at bifurcations.

fprintf('Analysing network — determining maximum adjacent diameters...\n');

numNodes               = size(networkNodes, 1);
nodeLargestDiameter_um = zeros(numNodes, 1);

for i = 1:size(networkSegments, 1)
    node1Idx = networkSegments(i, 1);
    node2Idx = networkSegments(i, 2);

    % Skip segments with invalid node indices
    if node1Idx <= 0 || node2Idx <= 0 || ...
            node1Idx > numNodes || node2Idx > numNodes
        fprintf('Warning: Skipping invalid segment %d: nodes [%d, %d] (max valid: %d)\n', ...
            i, node1Idx, node2Idx, numNodes);
        continue;
    end

    % Use the segment diameter if valid; fall back to the minimum otherwise
    if i <= length(segmentDiametersUm) && segmentDiametersUm(i) > 0
        currentDiameterUm = segmentDiametersUm(i);
    else
        fprintf('Warning: Invalid diameter for segment %d (nodes %d–%d) — using fallback.\n', ...
            i, node1Idx, node2Idx);
        currentDiameterUm = minDiameterVisUm;
    end
    currentDiameterUm = max(minNodeDiameter_um, currentDiameterUm);

    nodeLargestDiameter_um(node1Idx) = max(nodeLargestDiameter_um(node1Idx), currentDiameterUm);
    nodeLargestDiameter_um(node2Idx) = max(nodeLargestDiameter_um(node2Idx), currentDiameterUm);
end

% Pre-compute proximal and distal radii for each segment from the node table
segmentR1 = zeros(size(networkSegments, 1), 1);    % Radius at proximal node (µm)
segmentR2 = zeros(size(networkSegments, 1), 1);    % Radius at distal node (µm)

for k = 1:size(networkSegments, 1)
    segmentR1(k) = nodeLargestDiameter_um(networkSegments(k, 1)) / 2;
    segmentR2(k) = nodeLargestDiameter_um(networkSegments(k, 2)) / 2;
end


%% --- Initialise GDS Structure -------------------------------------------
TOPS = gds_structure('tops');


%% --- Tiling Loop: Draw Network for Each Device Copy ---------------------
% Each iteration of this loop produces one spatially shifted copy of the
% full network on the wafer. xshift/yshift are in µm and are applied to
% every GDS element within the loop.

for shifting = shiftingRange

    % Compute spatial offset for this device copy (µm).
    % xshift centres the network at x = 0 on the wafer.
    % yshift stacks copies vertically with a 10 mm gap.
    xShift = -domainSize / 0.002;
    yShift = (domainSize / 0.002 + 10000) * shifting - 7500;

    % ------------------------------------------------------------------
    % (a) Tapered trapezoid per vessel segment
    % ------------------------------------------------------------------
    % Each segment is approximated as a filled quadrilateral (trapezoid)
    % whose two parallel sides have widths equal to the node radii at the
    % proximal and distal endpoints respectively. The perpendicular vector
    % to the segment axis is used to offset the four corners.
    % ------------------------------------------------------------------
    fprintf('Drawing %d tapered vessel segments (copy %d)...\n', size(networkSegments,1), shifting);

    for i = 1:size(networkSegments, 1)
        node1Idx = networkSegments(i, 1);
        node2Idx = networkSegments(i, 2);

        if node1Idx <= 0 || node2Idx <= 0 || ...
                node1Idx > numNodes || node2Idx > numNodes
            continue;
        end

        % Node positions (µm)
        x1 = nodesUm(node1Idx, 1);
        y1 = nodesUm(node1Idx, 2);
        x2 = nodesUm(node2Idx, 1);
        y2 = nodesUm(node2Idx, 2);

        % Node radii (µm)
        r1 = segmentR1(i);
        r2 = segmentR2(i);

        % Segment direction and length
        dx = x2 - x1;
        dy = y2 - y1;
        segLen = sqrt(dx^2 + dy^2);

        if segLen < minSegmentLength_um
            continue;   % Skip degenerate (near-zero-length) segments
        end

        % Unit vector along segment axis
        ux = dx / segLen;
        uy = dy / segLen;

        % Unit vector perpendicular to segment axis (90° rotation)
        px = -uy;
        py =  ux;

        % Four trapezoid corners: two at the proximal end (r1 wide),
        % two at the distal end (r2 wide).
        corner1 = [x1 + px*r1,  y1 + py*r1];  % Proximal, left
        corner2 = [x1 - px*r1,  y1 - py*r1];  % Proximal, right
        corner3 = [x2 - px*r2,  y2 - py*r2];  % Distal, right
        corner4 = [x2 + px*r2,  y2 + py*r2];  % Distal, left

        % Closed polygon (5th vertex = 1st to close the loop)
        offset = repmat([xShift, yShift], 5, 1);
        xyPolygon = [corner1; corner2; corner3; corner4; corner1] + offset;

        peTrapezoid = gds_element('boundary', 'xy', xyPolygon, 'layer', gdsLayer);
        TOPS = add_element(TOPS, peTrapezoid);

        if mod(i, 500) == 0
            fprintf('  Drew %d / %d segments...\n', i, size(networkSegments,1));
        end
    end

    % ------------------------------------------------------------------
    % (b) Filled circle per junction node
    % ------------------------------------------------------------------
    % Each node with a nonzero diameter receives a filled circular element
    % (rendered as a GDS arc with inner radius = 0 and sweep = 360°).
    % This closes any gaps between adjacent trapezoids at bifurcations.
    % ------------------------------------------------------------------
    fprintf('Adding node circles (copy %d)...\n', shifting);

    for i = 1:numNodes
        if nodeLargestDiameter_um(i) < minNodeDiameter_um
            continue;
        end

        circleRadius_um = max(minNodeDiameter_um, nodeLargestDiameter_um(i) / 2);

        arc.r  = 0;         % Filled circle: inner radius = 0
        arc.c  = [nodesUm(i,1), nodesUm(i,2)] + [xShift, yShift];
        arc.a1 = 0;
        arc.a2 = 360;
        arc.w  = circleRadius_um;
        arc.e  = nodeCircleApproxError;

        nodeCircle = gdsii_arc(arc, 1);
        nodeCircle.layer = gdsLayer;
        TOPS = add_element(TOPS, nodeCircle);

        if mod(i, 1000) == 0
            fprintf('  Added circle for node %d / %d...\n', i, numNodes);
        end
    end

    % ------------------------------------------------------------------
    % (c) Inlet / outlet stubs and connection pads
    % ------------------------------------------------------------------
    % The rightmost node (outlet) and leftmost node (inlet) each receive:
    %   - A short rectangular path stub extending outward (stubLengthMm mm)
    %   - A large annular pad at the stub tip for tubing connection
    % ------------------------------------------------------------------

    % Outlet: rightmost node
    [~, outletNodeIdx] = max(networkNodes(:, 1));
    stubOutletXY = [networkNodes(outletNodeIdx,1), networkNodes(outletNodeIdx,2); ...
                    networkNodes(outletNodeIdx,1) + stubLengthMm, networkNodes(outletNodeIdx,2)] ...
                   * micronsPerMm + repmat([xShift, yShift], 2, 1);
    peOutletStub = gds_element('path', 'xy', stubOutletXY, 'layer', gdsLayer, ...
        'width', nodeLargestDiameter_um(outletNodeIdx), 'ptype', 3);
    TOPS = add_element(TOPS, peOutletStub);

    arc.r  = padInnerRadius_um;
    arc.c  = [networkNodes(outletNodeIdx,1) + stubLengthMm, networkNodes(outletNodeIdx,2)] ...
             * micronsPerMm + [xShift, yShift];
    arc.a1 = 0;
    arc.a2 = 360;
    arc.w  = padWidth_um;
    arc.e  = padApproxError;
    outletPad = gdsii_arc(arc, 1);
    outletPad.layer = gdsLayer;
    TOPS = add_element(TOPS, outletPad);

    % Inlet: leftmost node
    [~, inletNodeIdx] = min(networkNodes(:, 1));
    stubInletXY = [networkNodes(inletNodeIdx,1), networkNodes(inletNodeIdx,2); ...
                   networkNodes(inletNodeIdx,1) - stubLengthMm, networkNodes(inletNodeIdx,2)] ...
                  * micronsPerMm + repmat([xShift, yShift], 2, 1);
    peInletStub = gds_element('path', 'xy', stubInletXY, 'layer', gdsLayer, ...
        'width', nodeLargestDiameter_um(inletNodeIdx), 'ptype', 3);
    TOPS = add_element(TOPS, peInletStub);

    arc.r  = padInnerRadius_um;
    arc.c  = [networkNodes(inletNodeIdx,1) - stubLengthMm, networkNodes(inletNodeIdx,2)] ...
             * micronsPerMm + [xShift, yShift];
    arc.a1 = 0;
    arc.a2 = 360;
    arc.w  = padWidth_um;
    arc.e  = padApproxError;
    inletPad = gdsii_arc(arc, 1);
    inletPad.layer = gdsLayer;
    TOPS = add_element(TOPS, inletPad);

end % --- end tiling loop ---


%% --- Add Wafer Text Labels ----------------------------------------------
% Path-text elements are rendered at fixed wafer coordinates and are
% independent of the tiling shift (they appear once per file).

peLabel1 = gdsii_pathtext(waferLabel,   labelPosition1, labelHeight_um, ...
    labelRotation_deg, labelLineWidth);
peLabel2 = gdsii_pathtext(processLabel, labelPosition2, labelHeight_um, ...
    labelRotation_deg, labelLineWidth);

peLabel1.layer = gdsLayer;
peLabel2.layer = gdsLayer;

TOPS = add_element(TOPS, peLabel1, peLabel2);


%% --- Write GDSII File ---------------------------------------------------
outputFilePath = append('./GDS/FabricationMask_', modelName, '.gds');

fprintf('Writing GDS file to: %s\n', outputFilePath);
write_gds_library(gds_library('tops', TOPS), char(append('!', outputFilePath)));
fprintf('Done. GDS mask written with tapered segments and node circles.\n');