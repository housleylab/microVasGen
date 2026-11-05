% =========================================================================
% Title:        Hybrid END-CFD Velocity Profile Visualisation and COMSOL
%               Geometry Export for Selected Vessel Segments
% Author:       Aref Valipour, Housley Lab, Georgia Tech
% Date:         2026
%
% Description:
%   Combines the Electrical Network Dynamics (END) flow solution with CFD for a user-
%   defined subset of vessel segments. 
%
%   Workflow:
%     1. Load a network graph
%     2. Apply a node-averaged diameter model (fabrication correction):
%           d_segment = mean(d_node1, d_node2)
%        This accounts for the rounding of vessel cross-sections at junctions
%        during soft-lithography fabrication.
%     3. Compute per-segment hydraulic resistance using the 25%-cut circular
%        cross-section Hagen-Poiseuille formula:
%           R = 128 * mu * L / (pi * (d_eff * 0.8538)^4)
%        where 0.8538 is the effective-diameter correction for a circle with
%        a 25% top-cut (approximating the PDMS mold release geometry).
%        A CFD-derived correction factor of 0.904 is applied to the average of the two
%        node-based resistances to account for the tapered cross-section.
%     4. Run LTspice to obtain branch currents (∝ volumetric flow rates)
%     5. Scale currents to physical flow rates using a measured inlet flow rate
%     6. Overlay a semi-transparent vessel outline on the velocity map
%     7. Export a COMSOL API geometry script (tapered cones + junction spheres)
%        for the selected segments, including 3-D z-offset derived from vessel
%        diameter (to represent the out-of-plane channel depth)
%     8. Report nodal pressures at terminal (degree-1) nodes of the segment set
%
%   Cross-section model options (see resistance calculation section):
%     - 25%-cut circle (active):   factor = 0.8538, correction = 0.904
%     - Full circle (commented):   no correction factor
%     - Half circle (commented):   factor = 0.611
%     - Rectangular (commented)
%
% Inputs:
%   ./Models/<modelName>.mat              Electrically-assigned network graph
%                                       (nodes, segments, segment_diameters,
%                                        domain_size)
%
% Outputs:
%   ./Hybrid_END_CFD/velocity-<name>.png  Velocity map (PNG, 300 dpi)
%   ./Hybrid_END_CFD/COMSOL_<name>.txt   COMSOL API geometry script
%
% Dependencies:
%   LTspice (ADI)    External circuit simulator. Update ltspicePath below.
%   LTspice2Matlab   Parser for LTspice .raw binary files.
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
modelName = "Model_1_ICDT";  % Network file to load (no extension)

% --- Output control ---
saveResults = 1;    % 1: save figures and COMSOL file;  0: display only

% --- Segments to visualise and export ------------------------------------
% Define a subset of segment indices to include in the velocity map and
% COMSOL geometry export. Multiple commented presets are preserved below
% for reference across different network realisations.
segmentSubset = [22, 26, 30];     % Active set 


% --- Inlet flow rate ---
% Physical inlet volumetric flow rate (m³/s), used to scale the normalised
% LTspice currents to absolute flow rates throughout the network.
inletFlowRate = 1.67e-12;   % m³/s

% --- LTspice path ---
ltspicePath = '"D:/Program Files/ADI/LTspice/LTspice.exe"';  

% --- Microfluidic channel properties ---
channelHeight    = 20e-6;       % Fabricated channel height (m)
dynamicViscosity = 1.002e-3;  % Water (for reference)

% --- Resistance model constants ---
% Correction factor for 25%-cut circular cross-section effective diameter.
% 0.8538 converts the nominal diameter to the hydraulic diameter of a circle
% with a 25% top cut (approximating PDMS mold release channel geometry).
cutCircleEffectiveDiameterFactor = 0.8538;  % Dimensionless

% CFD-calculated correction factor for the tapered (conical) cross-section along the segment.
taperCorrectionFactor = 0.904;  % Dimensionless

% --- Unit conversions ---
mmToMetres  = 0.001;    % mm → m
ohmsPerTOhm = 1e12;     % Ω → TΩ


% Resolution of the pixel grid used to render velocity profiles.
pixelsPerMm = 1000;         % pixels per mm

% Margin added around the bounding box of selected segments (mm).
viewMarginMm = 0;           % mm

% Fraction of each segment's length excluded from each end when rendering
% the velocity profile. Masking the ends prevents the parabolic profile
% from appearing in junction mixing zones where Poiseuille flow breaks down.
endExclusionFraction = 0.03;    % Dimensionless (3% of segment length per end)

% --- COMSOL geometry parameters ---
% Out-of-plane z-offset factor. The cone z-position is set to:
%   z = zShiftFactor × mean_radius
% This gives a small 3-D relief to otherwise planar 2-D networks.
zShiftFactor = 0.25;    % Dimensionless

% Sphere radius additive offset (µm). Added to the node half-diameter to
% ensure watertight Boolean unions between spheres and cone endpoints.
sphereRadiusOffset = 0.1;   % µm

% Diameter bounds used for cross-validation checks only (not in main computation)
maxDiameterCrossval = 150;  % µm (reference only)
minDiameterCrossval = 20;   % µm (reference only)


%% --- Load Network Graph -------------------------------------------------
load(append("./Models/", modelName, ".mat"));

rawFilePath     = append("./Electrical/", modelName, "_tempSPICE.raw");
netlistFilePath = append("./Electrical/", modelName, "_tempSPICE.txt");


%% --- Compute Segment Lengths and Convert Units --------------------------
segmentLengths = zeros(size(networkSegments, 1), 1);
for i = 1:size(networkSegments, 1)
    p1 = networkNodes(networkSegments(i, 1), :);
    p2 = networkNodes(networkSegments(i, 2), :);
    segmentLengths(i) = norm(p2 - p1);
end

segmentLengths    = segmentLengths    * mmToMetres;
segment_diameters = segmentDiameters * mmToMetres;


%% --- Node-Averaged Diameter Model (Fabrication Correction) -------------
% At each node, record the largest diameter among all connected segments.
% Then replace each segment's diameter with the mean of the largest diameters
% at its two endpoint nodes. This models the smooth diameter transition that
% occurs at junctions during soft-lithography fabrication.

nodeLargestDiameter = zeros(size(networkNodes, 1), 1);

for i = 1:size(networkSegments, 1)
    node1 = networkSegments(i, 1);
    node2 = networkSegments(i, 2);
    if segment_diameters(i) > nodeLargestDiameter(node1)
        nodeLargestDiameter(node1) = segment_diameters(i);
    end
    if segment_diameters(i) > nodeLargestDiameter(node2)
        nodeLargestDiameter(node2) = segment_diameters(i);
    end
end

for i = 1:size(networkSegments, 1)
    node1 = networkSegments(i, 1);
    node2 = networkSegments(i, 2);
    segment_diameters(i) = (nodeLargestDiameter(node1) + nodeLargestDiameter(node2)) / 2;
end


%% --- Generate SPICE Netlist (25%-Cut Circle Resistance) ----------------
% Each segment is modelled as a resistor. Resistance is computed as the
% average of two node-endpoint estimates, each using the 25%-cut circle
% Hagen-Poiseuille formula, then multiplied by taperCorrectionFactor.
%
% All alternative resistance models are preserved as comments below.

spiceNetlist = ["*"];
spiceNetlist = [spiceNetlist; "V1 " + num2str(size(networkNodes, 1)-1) + " 0 1;"];
allSegmentResistances = [];

for i = 1:size(networkSegments, 1)
    node1 = networkSegments(i, 1);
    node2 = networkSegments(i, 2);

    % 25%-cut circle (active model): effective diameter = d * 0.8538
    segRes1 = (128 * dynamicViscosity * segmentLengths(i)) / ...
              (pi * (nodeLargestDiameter(node1) * cutCircleEffectiveDiameterFactor)^4);
    segRes2 = (128 * dynamicViscosity * segmentLengths(i)) / ...
              (pi * (nodeLargestDiameter(node2) * cutCircleEffectiveDiameterFactor)^4);
    avgSegmentResistance = ((segRes1 + segRes2) / 2) * taperCorrectionFactor;

    % --- Alternative resistance models (uncomment to use instead) ---
    % Full circle using average node diameter:
    % segRes1 = (128*dynamicViscosity*segmentLengths(i))/(pi*(nodeLargestDiameter(node1))^4);
    % segRes2 = (128*dynamicViscosity*segmentLengths(i))/(pi*(nodeLargestDiameter(node2))^4);
    % avgSegmentResistance = (segRes1 + segRes2) / 2;

    allSegmentResistances = [allSegmentResistances; avgSegmentResistance];
    spiceNetlist = [spiceNetlist; ...
        "R" + num2str(i) + " " + num2str(networkSegments(i,1)-1) + ...
        " " + num2str(networkSegments(i,2)-1) + " " + avgSegmentResistance + ";"];
end

spiceNetlist = [spiceNetlist; ".op;"];
spiceNetlist = [spiceNetlist; ".print dc V(1);"];
spiceNetlist = [spiceNetlist; ".end"];

writematrix(spiceNetlist, netlistFilePath);
fprintf('SPICE netlist written to: %s\n', netlistFilePath);


%% --- Run LTspice Simulation ---------------------------------------------
pause(0.1);

spiceCommand = sprintf('%s -b -run %s', ltspicePath, netlistFilePath);
[spiceStatus, spiceOutput] = system(spiceCommand);

if spiceStatus ~= 0
    fprintf('LTspice command: %s\n', spiceCommand);
    fprintf('LTspice output:\n%s\n', spiceOutput);
    error('LTspice simulation failed. Verify ltspicePath in the Parameters section.');
end

pause(1);


%% --- Parse LTspice .raw Output ------------------------------------------
ltspiceData  = LTspice2Matlab(rawFilePath);
voltageCount = sum(strcmp(ltspiceData.variable_type_list, 'voltage'));
currentCount = ltspiceData.num_variables - voltageCount - 1;

% --- Extract nodal voltages (with ground-node seed row) ------------------
nodeVoltages(1, 1) = 1;
nodeVoltages(1, 2) = 0;
for i = 1:voltageCount
    nodeVoltages(i+1, 1) = str2double( ...
        extractBetween(string(ltspiceData.variable_name_list(i)), "(", ")")) + 1;
    nodeVoltages(i+1, 2) = ltspiceData.variable_mat(i);
end
disp(i)    % Debug: confirm last voltage index processed
nodeVoltages = sortrows(nodeVoltages);

% --- Extract segment (branch) currents -----------------------------------
foundSourceCurrent = 0;
skipOffsetActive   = 0;

for i = 1:currentCount + 1
    varName = string(ltspiceData.variable_name_list(i + voltageCount));

    if contains(varName, 'I(V')
        sourceCurrentMagnitude = abs(ltspiceData.variable_mat(i + voltageCount));
        foundSourceCurrent = 1;
    elseif skipOffsetActive == 1
        extractedIdx = extractBetween(varName, "I(R", ")");
        segmentCurrents(i-1, 1) = str2double(extractedIdx{1});
        segmentCurrents(i-1, 2) = ltspiceData.variable_mat(i + voltageCount);
    else
        extractedIdx = extractBetween(varName, "I(R", ")");
        segmentCurrents(i, 1) = str2double(extractedIdx{1});
        segmentCurrents(i, 2) = ltspiceData.variable_mat(i + voltageCount);
    end

    if foundSourceCurrent == 1
        skipOffsetActive = 1;
    end
end

segmentCurrents = sortrows(segmentCurrents);

% Total network resistance (TΩ = TPa·s/m³ in fluidic units)
circuitResistanceTOhm = (1 / sourceCurrentMagnitude) / ohmsPerTOhm


%% --- Map Currents to Physical Flow Rates --------------------------------
% Compute flow speed (m/s) and volumetric flow rate (m³/s) for each segment
% by scaling the normalised LTspice currents against the inlet flow rate.
% Flow speed = Q / A (circular cross-section approximation).

flowSpeedMap   = zeros(size(networkSegments, 1), 1);   % Flow speed per segment (normalised units)
flowRateMap    = zeros(size(networkSegments, 1), 1);   % Volumetric flow rate per segment (normalised)

for i = 1:size(networkSegments, 1)
    for j = 1:size(segmentCurrents, 1)
        if segmentCurrents(j, 1) == i
            % Flow speed = Q / A, where A = pi*d^2/4
            flowSpeedMap(i)  = abs(segmentCurrents(j,2) / ...
                (pi * (segment_diameters(i))^2 / 4));
            flowRateMap(i)   = abs(segmentCurrents(j,2));
        end
    end
end

% Scale normalised values to physical units using the inlet flow rate.
% flowRateMap(1) corresponds to the inlet segment current (∝ total inflow).
physicalFlowSpeed   = flowSpeedMap  * inletFlowRate / flowRateMap(1);   % m/s
physicalFlowRate    = flowRateMap   * inletFlowRate / flowRateMap(1);   % m³/s


%% --- Pixel-Grid Velocity Map for Selected Segments ----------------------
% A Poiseuille parabolic profile is rendered on a pixel grid for each
% segment in segmentSubset. End-exclusion zones (endExclusionFraction × length
% from each endpoint) are masked to avoid rendering the mixing region at
% junctions, where Poiseuille flow is not a valid approximation.
%
% For each pixel, we check all segments and record which segment(s) it
% belongs to. At pixels claimed by multiple segments the velocity
% contributions are summed (this is only expected near junction centres,
% which are largely masked by the end-exclusion zones).

fprintf('\n=== Creating velocity profiles for segments: %s ===\n', mat2str(segmentSubset));

% Compute bounding box of the selected segment subset
allSubsetNodeIdx  = unique([networkSegments(segmentSubset, 1); networkSegments(segmentSubset, 2)]);
allSubsetNodes    = networkNodes(allSubsetNodeIdx, :);

xMinView = min(allSubsetNodes(:,1)) - viewMarginMm;
xMaxView = max(allSubsetNodes(:,1)) + viewMarginMm;
yMinView = min(allSubsetNodes(:,2)) - viewMarginMm;
yMaxView = max(allSubsetNodes(:,2)) + viewMarginMm;

% Create pixel coordinate grid
nPixelsX = round((xMaxView - xMinView) * pixelsPerMm);
nPixelsY = round((yMaxView - yMinView) * pixelsPerMm);

fprintf('Creating pixel grid: %d × %d pixels\n', nPixelsX, nPixelsY);

xPixelCoords = linspace(xMinView, xMaxView, nPixelsX);
yPixelCoords = linspace(yMinView, yMaxView, nPixelsY);
[xGrid, yGrid] = meshgrid(xPixelCoords, yPixelCoords);

% Initialise velocity field arrays
velFieldX  = zeros(nPixelsY, nPixelsX);     % x-component of velocity (mm/s)
velFieldY  = zeros(nPixelsY, nPixelsX);     % y-component of velocity (mm/s)
hasFlow    = false(nPixelsY, nPixelsX);     % True where at least one segment contributes

% Cell arrays to track which segment(s) each pixel belongs to, and their
% velocity contributions — used in the second pass to handle overlapping segments.
pixelSegmentMembership = cell(nPixelsY, nPixelsX);
pixelVelocityContribs  = cell(nPixelsY, nPixelsX);

% Storage for per-segment properties (used later for COMSOL export)
segmentData = cell(length(segmentSubset), 1);

% --- First pass: compute velocity contributions per segment --------------
for idx = 1:length(segmentSubset)
    segIdx = segmentSubset(idx);
    fprintf('Processing segment %d (%d/%d)...\n', segIdx, idx, length(segmentSubset));

    p1       = networkNodes(networkSegments(segIdx, 1), :);
    p2       = networkNodes(networkSegments(segIdx, 2), :);
    node1Idx = networkSegments(segIdx, 1);
    node2Idx = networkSegments(segIdx, 2);

    segVec    = p2 - p1;
    segLength = norm(segVec);
    segDir    = segVec / segLength;

    % End-exclusion length: mask the first and last (endExclusionFraction × length)
    exclusionLength = segLength * endExclusionFraction;

    % Flow properties for this segment
    flowRate = physicalFlowRate(segIdx);      % m³/s
    diameter = segment_diameters(segIdx);     % m
    radius   = diameter / 2;

    % Peak velocity: v_max = 2 × Q / A (Poiseuille factor of 2 converts mean→peak)
    % Multiplied by 2000 to convert from m/s to mm/s with a ×2 Poiseuille factor
    vMax = physicalFlowSpeed(segIdx) * 2000;  % mm/s (peak centreline velocity)

    % Cache segment properties for COMSOL export section
    segmentData{idx}.segIdx         = segIdx;
    segmentData{idx}.p1             = p1;
    segmentData{idx}.p2             = p2;
    segmentData{idx}.diameter       = diameter;
    segmentData{idx}.vMax           = vMax;
    segmentData{idx}.flowRate       = flowRate;
    segmentData{idx}.segLength      = segLength;
    segmentData{idx}.node1Idx       = node1Idx;
    segmentData{idx}.node2Idx       = node2Idx;
    segmentData{idx}.radius         = radius;
    segmentData{idx}.segDir         = segDir;
    segmentData{idx}.exclusionLength = exclusionLength;

    % Evaluate Poiseuille profile at every pixel
    for row = 1:nPixelsY
        for col = 1:nPixelsX
            pixelPos  = [xGrid(row, col), yGrid(row, col)];
            vecToPixel = pixelPos - p1;
            projLength = dot(vecToPixel, segDir);

            % Only render the middle portion of the segment (exclude ends)
            if projLength >= exclusionLength && ...
                    projLength <= (segLength - exclusionLength)
                closestPt     = p1 + projLength * segDir;
                distMetres    = norm(pixelPos - closestPt) / 1000;  % mm → m

                if distMetres <= radius
                    % Parabolic Poiseuille profile: v(r) = v_max * (1 - (r/R)^2)
                    rNorm  = distMetres / radius;
                    vLocal = vMax * (1 - rNorm^2);

                    % Accumulate this segment's contribution at this pixel
                    if isempty(pixelSegmentMembership{row, col})
                        pixelSegmentMembership{row, col} = segIdx;
                        pixelVelocityContribs{row, col}  = struct( ...
                            'segIdx', segIdx, ...
                            'vX', vLocal * segDir(1), ...
                            'vY', vLocal * segDir(2), ...
                            'dist', distMetres);
                    else
                        pixelSegmentMembership{row, col}(end+1) = segIdx;
                        pixelVelocityContribs{row, col}(end+1)  = struct( ...
                            'segIdx', segIdx, ...
                            'vX', vLocal * segDir(1), ...
                            'vY', vLocal * segDir(2), ...
                            'dist', distMetres);
                    end
                end
            end
        end
    end

    fprintf('  Seg %d: d=%.3f mm, L=%.3f mm, excl=%.3f mm, v_max=%.4f mm/s\n', ...
        segIdx, diameter*1000, segLength, exclusionLength, vMax*1000);
end

% --- Second pass: resolve multi-segment pixels and build velocity field --
fprintf('Assigning velocities to pixel grid...\n');

for row = 1:nPixelsY
    for col = 1:nPixelsX
        if isempty(pixelSegmentMembership{row, col})
            continue;
        end

        if length(pixelSegmentMembership{row, col}) == 1
            % Single contributing segment
            velFieldX(row, col) = pixelVelocityContribs{row, col}(1).vX;
            velFieldY(row, col) = pixelVelocityContribs{row, col}(1).vY;
        else
            % Multiple segments overlap: sum all contributions.
            % Since ends are masked, any overlap is a legitimate bifurcation region.
            vXSum = 0;
            vYSum = 0;
            for k = 1:length(pixelVelocityContribs{row, col})
                vXSum = vXSum + pixelVelocityContribs{row, col}(k).vX;
                vYSum = vYSum + pixelVelocityContribs{row, col}(k).vY;
            end
            velFieldX(row, col) = vXSum;
            velFieldY(row, col) = vYSum;
        end
        hasFlow(row, col) = true;
    end
end

velocityMagnitude = sqrt(velFieldX.^2 + velFieldY.^2);
fprintf('Velocity field calculation complete.\n');


%% --- Plot Velocity Map --------------------------------------------------
% Render the velocity magnitude as an RGB image using Paul Tol's
% colorblind-safe sequential palette (blue → pale blue → cream → orange).

aspectRatio = (yMaxView - yMinView) / (xMaxView - xMinView);
figWidth    = 800;
figHeight   = round(figWidth * aspectRatio);

figVelocity = figure('Position', [100, 100, figWidth, figHeight]);
hold on;

maxVelField = max(velocityMagnitude(:));

if maxVelField > 0
    % Paul Tol's colorblind-safe sequential colormap (blue → orange)
    tolColors = [
        34,  34,  85;
        34,  85, 136;
        68, 119, 170;
       102, 153, 204;
       136, 187, 221;
       170, 221, 238;
       221, 238, 221;
       238, 221, 170;
       238, 187, 102;
       221, 170,  51;
       204, 136,  34;
       187, 102,  34
    ] / 255;

    xOrig   = linspace(0, 1, size(tolColors, 1));
    xNew    = linspace(0, 1, 256);
    cmap    = zeros(256, 3);
    cmap(:,1) = interp1(xOrig, tolColors(:,1), xNew, 'pchip');
    cmap(:,2) = interp1(xOrig, tolColors(:,2), xNew, 'pchip');
    cmap(:,3) = interp1(xOrig, tolColors(:,3), xNew, 'pchip');

    % Build RGB image: white background, colour only where hasFlow == true
    rgbImage = ones(nPixelsY, nPixelsX, 3);
    colormapMaxVelocity = max(max(velocityMagnitude)) * 1.2;
    for row = 1:nPixelsY
        for col = 1:nPixelsX
            if hasFlow(row, col)
                normVel  = velocityMagnitude(row, col) / colormapMaxVelocity;
                colorIdx = round(normVel * 255) + 1;
                colorIdx = max(1, min(256, colorIdx));
                rgbImage(row, col, :) = cmap(colorIdx, :);
            end
        end
    end

    image(xPixelCoords, yPixelCoords, rgbImage);
    axis xy;
else
    image(xPixelCoords, yPixelCoords, ones(nPixelsY, nPixelsX, 3));
    axis xy;
end

% Overlay semi-transparent vessel outlines
for idx = 1:length(segmentSubset)
    data     = segmentData{idx};
    p1       = data.p1;
    p2       = data.p2;
    diameter = data.diameter;
    lineWidth = diameter * 25000 / 2;
    line([p1(1), p2(1)], [p1(2), p2(2)], 'LineWidth', lineWidth, ...
         'Color', [0, 0, 0, 0.25]);

    % Uncomment to add segment index labels at midpoints:
    % midPt = (p1 + p2) / 2;
    % text(midPt(1), midPt(2), sprintf('%d', data.segIdx), ...
    %      'FontSize', 14, 'FontWeight', 'bold', 'Color', 'w', ...
    %      'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    %      'BackgroundColor', [0 0 0 0.6], 'EdgeColor', 'w', 'LineWidth', 1, 'Margin', 3);
end

% Colorbar: labelled in mm/s, limits set by colormapMaxVelocity
colormap(cmap);
cb = colorbar('location', 'southoutside');
caxis([0, colormapMaxVelocity]);
cb.Label.String  = 'Flow Velocity (mm/s)';
cb.Label.FontSize = 20;

axis equal;
set(gca, 'FontSize', 20);
set(gca, 'YDir', 'reverse');
axis off;
hold off;

% Uncomment titles/labels for presentation figures:
title(sprintf('Velocity Profiles — Segments %s', mat2str(segmentSubset)), 'FontSize', 16);
xlabel('X Position (mm)', 'FontSize', 14);
ylabel('Y Position (mm)', 'FontSize', 14);
grid on;
box on;

if saveResults == 1
    exportgraphics(figVelocity, ...
        append('Hybrid_END_CFD/velocity_', modelName, '.png'), 'Resolution', 300);

end


%% --- COMSOL Geometry Export for Selected Segments -----------------------
% Generates a COMSOL API script with tapered cones (one per segment) and
% junction spheres (one per node connected to ≥2 selected segments).
% Endpoint nodes with degree 1 in the subset are treated as terminal
% boundary inlets/outlets for CFD and are not given spheres.

fprintf('\n=== Generating COMSOL geometry for segments: %s ===\n', mat2str(segmentSubset));

% Convert units: nodes mm→µm, diameters m→µm
nodesUm             = networkNodes      * 1000;             % µm
segDiametersUm      = segment_diameters * 1e6;              % µm
domainSizeUm        = domainSize(1)     * 1000;             % µm (square domain)

% Count how many selected segments each node is connected to
nodeSegmentCount = zeros(size(networkNodes, 1), 1);
for segIdx = segmentSubset
    nodeSegmentCount(networkSegments(segIdx, 1)) = nodeSegmentCount(networkSegments(segIdx, 1)) + 1;
    nodeSegmentCount(networkSegments(segIdx, 2)) = nodeSegmentCount(networkSegments(segIdx, 2)) + 1;
end

junctionNodeIndices  = find(nodeSegmentCount >= 2);   % Nodes at bifurcations → spheres
terminalNodeIndices  = find(nodeSegmentCount == 1);   % Terminal (degree-1) nodes → BCs

fprintf('Selected segments: %d\n',         length(segmentSubset));
fprintf('Nodes in selected set: %d\n',     length(unique([networkSegments(segmentSubset,1); networkSegments(segmentSubset,2)])));
fprintf('Junction nodes (≥2 segs): %d\n',  length(junctionNodeIndices));
fprintf('Terminal nodes (1 seg):   %d\n',  length(terminalNodeIndices));

% Largest adjacent diameter per node (for sphere sizing and cone radii)
nodeLargestDiameterUm = zeros(size(networkNodes, 1), 1);
for idx = 1:length(segmentSubset)
    segIdx = segmentSubset(idx);
    n1 = networkSegments(segIdx, 1);
    n2 = networkSegments(segIdx, 2);
    if segDiametersUm(segIdx) > nodeLargestDiameterUm(n1)
        nodeLargestDiameterUm(n1) = segDiametersUm(segIdx);
    end
    if segDiametersUm(segIdx) > nodeLargestDiameterUm(n2)
        nodeLargestDiameterUm(n2) = segDiametersUm(segIdx);
    end
end

% Node z-positions: z = zShiftFactor × largest adjacent radius (µm)
nodeZPositionUm = zShiftFactor * nodeLargestDiameterUm;

% Per-segment geometry for selected subset (in µm / 3-D coordinates)
numSubset = length(segmentSubset);
segP1Comsol         = zeros(numSubset, 2);
segP2Comsol         = zeros(numSubset, 2);
segLengthsComsol    = zeros(numSubset, 1);
segR1Comsol         = zeros(numSubset, 1);
segR2Comsol         = zeros(numSubset, 1);
segZ1Comsol         = zeros(numSubset, 1);
segZ2Comsol         = zeros(numSubset, 1);
segAxisX            = zeros(numSubset, 1);
segAxisY            = zeros(numSubset, 1);
segAxisZ            = zeros(numSubset, 1);
segDiametersFiltered = zeros(numSubset, 1);

for idx = 1:numSubset
    segIdx = segmentSubset(idx);
    n1Idx  = networkSegments(segIdx, 1);
    n2Idx  = networkSegments(segIdx, 2);

    p1 = nodesUm(n1Idx, :);
    p2 = nodesUm(n2Idx, :);

    segP1Comsol(idx, :)      = p1;
    segP2Comsol(idx, :)      = p2;
    segDiametersFiltered(idx) = segDiametersUm(segIdx);

    segR1Comsol(idx) = nodeLargestDiameterUm(n1Idx) / 2;
    segR2Comsol(idx) = nodeLargestDiameterUm(n2Idx) / 2;
    segZ1Comsol(idx) = nodeZPositionUm(n1Idx);
    segZ2Comsol(idx) = nodeZPositionUm(n2Idx);

    % 3-D endpoint coordinates including z-offset
    p1_3d = [p1(1), p1(2), segZ1Comsol(idx)];
    p2_3d = [p2(1), p2(2), segZ2Comsol(idx)];

    % 3-D Euclidean length (accounts for z-offset difference between endpoints)
    segLengthsComsol(idx) = norm(p2_3d - p1_3d);

    % Direction vector components for the COMSOL cone axis
    dirVec       = p2_3d - p1_3d;
    segAxisX(idx) = dirVec(1);
    segAxisY(idx) = dirVec(2);
    segAxisZ(idx) = dirVec(3);
end

% --- Report nodal pressures at terminal (degree-1) nodes -----------------
% Convert normalised LTspice voltages to physical pressures using:
%   P (Pa) = (1 - V_normalised) × circuitResistanceTOhm × inletFlowRate × 1e12
circuitPressure = circuitResistanceTOhm * inletFlowRate * ohmsPerTOhm;

fprintf('\n=== Pressure at Terminal Nodes (Degree 1 in subset) ===\n');
for i = 1:length(terminalNodeIndices)
    nodeIdx     = terminalNodeIndices(i);
    voltageIdx  = find(nodeVoltages(:,1) == nodeIdx);
    seg1Idx     = find(networkSegments(:,1) == nodeIdx);
    seg2Idx     = find(networkSegments(:,2) == nodeIdx);
    if ~isempty(voltageIdx)
        voltageVal = nodeVoltages(voltageIdx, 2);
        fprintf('Node %d: V = %.6e (norm)  P = %.6f Pa;  Segments: %d, %d\n', ...
            nodeIdx, (1 - voltageVal), (1 - voltageVal) * circuitPressure, ...
            seg1Idx, seg2Idx);
    else
        fprintf('Node %d: voltage not found in nodeVoltages\n', nodeIdx);
    end
end
fprintf('==============================================\n\n');

% --- Build COMSOL API script ---------------------------------------------
comsolScript = "//COMSOL Geometry for Selected Segments";
comsolScript = [comsolScript;"clearModel(model);"];
comsolScript = [comsolScript;"model.modelNode().create(""comp1"");"];
comsolScript = [comsolScript;"model.geom().create(""geom"", 3);"];
comsolScript = [comsolScript;"model.geom(""geom"").lengthUnit(""um"");"];
comsolScript = [comsolScript; append("//Segments: ", mat2str(segmentSubset))];

% Tapered cones — one per segment
for idx = 1:numSubset
    segIdx   = segmentSubset(idx);
    coneName = append("cone", num2str(segIdx));

    p1_3d = [segP1Comsol(idx,1), segP1Comsol(idx,2), segZ1Comsol(idx)];

    comsolScript = [comsolScript; append( ...
        "model.geom(""geom"").create(""", coneName, """, ""Cone"");")];
    comsolScript = [comsolScript; append( ...
        "model.geom(""geom"").feature(""", coneName, """).set(""specifytop"", ""radius"");")];
    comsolScript = [comsolScript; append( ...
        "model.geom(""geom"").feature(""", coneName, """).set(""rtop"", ", ...
        num2str(segR2Comsol(idx)), ");")];
    comsolScript = [comsolScript; append( ...
        "model.geom(""geom"").feature(""", coneName, """).set(""r"", ", ...
        num2str(segR1Comsol(idx)), ");")];
    comsolScript = [comsolScript; append( ...
        "model.geom(""geom"").feature(""", coneName, """).set(""h"", ", ...
        num2str(segLengthsComsol(idx)), ");")];
    comsolScript = [comsolScript; append( ...
        "model.geom(""geom"").feature(""", coneName, """).set(""pos"", new double[]{", ...
        num2str(p1_3d(1)), ", ", num2str(p1_3d(2)), ", ", num2str(p1_3d(3)), "});")];
    comsolScript = [comsolScript; append( ...
        "model.geom(""geom"").feature(""", coneName, """).set(""axistype"", ""spherical"");")];
    comsolScript = [comsolScript; append( ...
        "model.geom(""geom"").feature(""", coneName, """).set(""axis"", new double[]{", ...
        num2str(segAxisX(idx)), ", ", num2str(segAxisY(idx)), ", ", ...
        num2str(segAxisZ(idx)), "});")];
end

% Junction spheres — only for nodes connected to ≥2 selected segments
for i = 1:length(junctionNodeIndices)
    nodeIdx = junctionNodeIndices(i);

    % Skip inlet/outlet boundary nodes
    if nodesUm(nodeIdx,1) == 0 || nodesUm(nodeIdx,1) == domainSizeUm
        continue;
    end

    sphereName = append("sph", num2str(nodeIdx));
    comsolScript = [comsolScript; append( ...
        "model.geom(""geom"").create(""", sphereName, """, ""Sphere"");")];
    % Sphere radius = half largest adjacent diameter + sphereRadiusOffset
    comsolScript = [comsolScript; append( ...
        "model.geom(""geom"").feature(""", sphereName, """).set(""r"", ", ...
        num2str(sphereRadiusOffset + nodeLargestDiameterUm(nodeIdx) / 2), ");")];
    comsolScript = [comsolScript; append( ...
        "model.geom(""geom"").feature(""", sphereName, """).set(""pos"", new double[]{", ...
        num2str(nodesUm(nodeIdx,1)), ", ", num2str(nodesUm(nodeIdx,2)), ", ", ...
        num2str(nodeZPositionUm(nodeIdx)), "});")];
end

comsolScript = [comsolScript; "model.geom(""geom"").run();"];
comsolScript = [comsolScript; "//"];
comsolScript = [comsolScript; "//End of geometry"];


%% --- Save COMSOL Script -------------------------------------------------
if saveResults == 1
    comsolFilePath = append("./Hybrid_END_CFD/COMSOL_", modelName, ".txt");
    writematrix(comsolScript, comsolFilePath, 'QuoteStrings', false);
    fprintf('COMSOL geometry written to: %s\n', comsolFilePath);
    fprintf('=== COMSOL geometry generation complete ===\n\n');
end
