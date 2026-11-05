% =========================================================================
% Title:        Hydraulic Resistance Simulation of Microvascular Network
%               via Rectangular-Channel SPICE Analogy
% Author:       Aref Valipour, Housley Lab, Georgia Tech
% Date:         2026
%
% Description:
%   Computes geometry-dependent hydraulic resistance for each vessel segment
%   in a microvascular network graph and runs a DC SPICE circuit simulation
%   to obtain the total network resistance and branch-level flow rates.
%
%   The electrical analogy maps:
%     pressure drop    ↔   voltage (V)
%     volumetric flow  ↔   current (A)
%     fluidic resist.  ↔   electrical resistance (Ω)
%
%   Total network resistance (in TΩ, equivalent to TPa·s/m³ in fluidic
%   units) is reported, and branch currents encode relative flow rates for
%   downstream analysis.
%
% Workflow:
%   0. Choose dimater smoothing (to match 3D printed devices) or identical model (for theoritical studies). 
%   1. Load a network
%   2. Compute segment lengths and convert units to SI (metres)
%   3. Calculate geometry-dependent resistance per segment
%   4. Write a SPICE netlist
%   5. Run LTspice in batch mode
%   6. Parse the .raw output to extract voltages and currents
%   7. Compute and report total circuit resistance (TΩ)
%
% Inputs:
%   ./Models/<modelName>.mat     Network with electrically-assigned diameters
%                              (variables: nodes, segments, segment_diameters,
%                               domain_size)
%
% Outputs:
%   ./Electrical/<modelName>_tempSPICE.txt   SPICE netlist (plain text)
%   ./Electrical/<modelName>_tempSPICE.raw   LTspice simulation results
%   circuitResistanceTOhm                    Total resistance (TΩ, workspace)
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
modelName = "model_1_ICDT";    % Network file to load (no extension)

% --- LTspice executable path ---
ltspicePath = '"D:/Program Files/ADI/LTspice/LTspice.exe"';   

% --- Diameter smoothing ---
% 0: Identical graph.
% 1: To smooth the vessels. 
% this makes it match OpenSCAD_Pipeline. 
% Use this when fabricating 3D devices (2PP).
match_OpenSCAD = 0; 

% --- Microfluidic channel geometry ---
channelHeight = 50e-6;      % Fabricated channel height (m). Corresponds to
                            %   the out-of-plane dimension fixed by the
                            %   soft-lithography mold (e.g. SU-8 spin height).

% --- Fluid properties (water at ~20 °C) ---
dynamicViscosity = 1.002e-3;    % Dynamic viscosity mu (Pa·s)

% --- Rectangular channel resistance formula constant ---
% Shah-London correction factor for the aspect-ratio-dependent hydraulic
% resistance of a rectangular cross-section channel.
% Reference: Shah & London (1978), Eq. 369.
shahLondonFactor = 0.63;        % Dimensionless

% --- Unit conversion ---
% The network graph stores coordinates in mm and diameters in mm.
% SI calculations (resistance formula) require metres.
mmToMetres = 0.001;     % 1 mm = 0.001 m

% --- Output unit for total resistance ---
% LTspice voltages are in volts and currents in amperes, so the raw
% resistance (V/I) is in ohms. Microfluidic networks have resistances in
% the teraohm range (1 TΩ = 10^12 Ω).
ohmsPerTOhm = 1e12;


%% --- Load Network Graph -------------------------------------------------
load(append("./Models/", modelName, ".mat"));

% The .raw file path is defined here so it is available for the parser
% section even though the file is not created until LTspice runs.
rawFilePath     = append("./electrical/", modelName, "_tempSPICE.raw");
netlistFilePath = append("./electrical/", modelName, "_tempSPICE.txt");


%% --- Compute Segment Lengths (mm → m) -----------------------------------
% Euclidean length of each segment, converted from mm to metres for use
% in the Hele-Shaw resistance formula.

segmentLengths = zeros(size(networkSegments, 1), 1);
for i = 1:size(networkSegments, 1)
    p1 = networkNodes(networkSegments(i, 1), :);
    p2 = networkNodes(networkSegments(i, 2), :);
    segmentLengths(i) = norm(p2 - p1);
end

segmentLengths    = segmentLengths    * mmToMetres;
segment_diameters = segmentDiameters * mmToMetres;

%% Diameter smoothing

if match_OpenSCAD == 1
    min_diameter_vis_mm = min(segmentDiameters);
    min_diameter_vis_um = min_diameter_vis_mm*1000;
    num_nodes_actual = size(networkNodes, 1);
    node_max_diameters_um = zeros(num_nodes_actual, 1);
    segment_diameters_um = segmentDiameters;
    
    for i = 1:size(networkSegments, 1)
        node1_idx = networkSegments(i, 1);
        node2_idx = networkSegments(i, 2);
    
        if node1_idx <= 0 || node2_idx <= 0 || node1_idx > num_nodes_actual || node2_idx > num_nodes_actual
            fprintf('Warning: Skipping invalid segment %d: nodes [%d, %d] out of %d nodes\n', i, node1_idx, node2_idx, num_nodes_actual);
            continue;
        end
    
        current_diameter_um = min_diameter_vis_um;
        if i <= length(segment_diameters_um) && segment_diameters_um(i) > 0
            current_diameter_um = segment_diameters_um(i);
        else
            fprintf('Warning: Diameter for segment %d (nodes %d-%d) is invalid, using min_diameter_vis_um.\n', i, node1_idx, node2_idx);
        end
        % current_diameter_um = max(1, current_diameter_um);
    
        node_max_diameters_um(node1_idx) = max(node_max_diameters_um(node1_idx), current_diameter_um);
        node_max_diameters_um(node2_idx) = max(node_max_diameters_um(node2_idx), current_diameter_um);
    end
    
    % Store segment radii at each end
    segment_r1 = zeros(size(networkSegments, 1), 1);
    segment_r2 = zeros(size(networkSegments, 1), 1);
    segment_avg = zeros(size(networkSegments, 1), 1);
    
    for k = 1:size(networkSegments, 1)
        segment_r1(k) = node_max_diameters_um(networkSegments(k, 1)) / 2;
        segment_r2(k) = node_max_diameters_um(networkSegments(k, 2)) / 2;
        segment_avg (k) = (segment_r1(k) + segment_r2(k))/1000;
    end
    
    segment_diameters = segment_avg;
end

%% --- Generate SPICE Netlist with Geometry-Dependent Resistance ----------
% Each segment is represented as a resistor whose value is computed from
% the Hele-Shaw rectangular-channel formula (see header).
% A 1 V DC source is applied from the highest-index node to ground so
% that the resulting branch currents directly encode volumetric flow rates
% (via the hydraulic-electrical analogy).
%
% Alternative resistance models are preserved below for reference:
%   - Uniform resistance (END method, used in assignDiametersElectrical.m)
%   - Full circular cross-section (Hagen-Poiseuille)
%   - Half-circular cross-section (with effective diameter correction)
%   - 25%-cut circular cross-section (with effective diameter correction)

spiceNetlist = ["*"];
spiceNetlist = [spiceNetlist; "V1 " + num2str(size(networkNodes, 1)-1) + " 0 1;"];

for i = 1:size(networkSegments, 1)

    % --- Rectangular channel (Hele-Shaw / Shah-London) ---
    % Select the orientation of the rectangle based on which dimension
    % is larger: the vessel diameter (w) or the channel height (h).
    % w = segment_diameters(i);
    % h = channelHeight;
    % 
    % if w > h
    %     % Width-dominated regime: w > h
    %     segmentResistance = (1 / (1 - 0.63 * (h/w))) * ...
    %         (12 * dynamicViscosity * segmentLengths(i)) / (w * h^3);
    % else
    %     % Height-dominated regime: w <= h
    %     segmentResistance = (1 / (1 - 0.63 * (w/h))) * ...
    %         (12 * dynamicViscosity * segmentLengths(i)) / (h * w^3);
    % end


    % Full circular cross-section (Hagen-Poiseuille):
    segmentResistance = (128 * dynamicViscosity * segmentLengths(i)) / ...
        (pi * segment_diameters(i)^4);

    % Half-circular cross-section (effective diameter factor 0.611):
    % segmentResistance = (128 * dynamicViscosity * segmentLengths(i)) / ...
    %     (pi * (segment_diameters(i) * 0.611)^4);

    % 25%-cut circular cross-section (effective diameter factor 0.8538):
    % segmentResistance = (128 * dynamicViscosity * segmentLengths(i)) / ...
    %     (pi * (segment_diameters(i) * 0.8538)^4);

    spiceNetlist = [spiceNetlist; ...
        "R" + num2str(i) + " " + num2str(networkSegments(i,1)-1) + ...
        " " + num2str(networkSegments(i,2)-1) + " " + segmentResistance + ";"];
end

spiceNetlist = [spiceNetlist; ".op;"];
spiceNetlist = [spiceNetlist; ".print dc V(1);"];
spiceNetlist = [spiceNetlist; ".end"];

writematrix(spiceNetlist, netlistFilePath);

fprintf('SPICE netlist written to: %s\n', netlistFilePath);


%% --- Run LTspice Simulation ---------------------------------------------
% LTspice is invoked in batch mode (-b) so it runs without a GUI and writes
% results to a binary .raw file that is parsed in the next section.

pause(0.1);     % Brief pause to ensure the netlist file is flushed to disk

spiceCommand = sprintf('%s -b -run %s', ltspicePath, netlistFilePath);
[spiceStatus, spiceOutput] = system(spiceCommand);

if spiceStatus ~= 0
    fprintf('LTspice command: %s\n', spiceCommand);
    fprintf('LTspice output:\n%s\n', spiceOutput);
    error('LTspice simulation failed. Verify ltspicePath in the Parameters section.');
end

pause(1);       % Brief pause to ensure LTspice has finished writing the .raw file


%% --- Parse LTspice .raw Output ------------------------------------------
% LTspice2Matlab reads the binary .raw file and returns a struct with
% variable names, types, and values from the DC operating-point analysis.

ltspiceData  = LTspice2Matlab(rawFilePath);
voltageCount = sum(strcmp(ltspiceData.variable_type_list, 'voltage'));
currentCount = ltspiceData.num_variables - voltageCount - 1;

% --- Extract nodal voltages ----------------------------------------------
for i = 1:voltageCount
    nodeVoltages(i, 1) = str2double( ...
        extractBetween(string(ltspiceData.variable_name_list(i)), "(", ")"));
    nodeVoltages(i, 2) = ltspiceData.variable_mat(i);
end

nodeVoltages = sortrows(nodeVoltages);

% --- Extract segment (branch) currents -----------------------------------
% LTspice lists one current per resistor (I(R<n>)) plus the voltage source
% current (I(V1)). The source current entry shifts the resistor indexing
% by one position, tracked by foundSourceCurrent / skipOffsetActive.

foundSourceCurrent = 0;     % Flag: set to 1 once I(V1) is found
skipOffsetActive   = 0;     % Flag: set to 1 to apply the index offset

for i = 1:currentCount + 1
    varName = string(ltspiceData.variable_name_list(i + voltageCount));

    if contains(varName, 'I(V')
        % Voltage source current: record magnitude and set flags
        sourceCurrentMagnitude = abs(ltspiceData.variable_mat(i + voltageCount));
        foundSourceCurrent = 1;

    elseif skipOffsetActive == 1
        % I(V1) already found: resistor list index is offset by 1
        extractedIdx = extractBetween(varName, "I(R", ")");
        segmentCurrents(i-1, 1) = str2double(extractedIdx{1});
        segmentCurrents(i-1, 2) = ltspiceData.variable_mat(i + voltageCount);

    else
        % I(V1) not yet found: no index offset
        extractedIdx = extractBetween(varName, "I(R", ")");
        segmentCurrents(i, 1) = str2double(extractedIdx{1});
        segmentCurrents(i, 2) = ltspiceData.variable_mat(i + voltageCount);
    end

    if foundSourceCurrent == 1
        skipOffsetActive = 1;
    end
end

segmentCurrents = sortrows(segmentCurrents);


%% --- Compute Total Circuit Resistance -----------------------------------
% Total hydraulic resistance of the network = V / Q_total.
% In the electrical analogy, V = 1 V (applied source) and
% Q_total ↔ sourceCurrentMagnitude (A). The result is converted to TΩ
% (equivalent to TPa·s/m³ in fluidic units).

circuitResistanceTOhm = (1 / sourceCurrentMagnitude) / ohmsPerTOhm


%% --- (Reference) Visualisation: Flow Speed and Diameter Map ------------
% The block below renders a colour-mapped figure of flow speed (|Q/A|)
% and vessel diameter for each segment. It is preserved here as a
% reference implementation but is commented out by default to avoid
% dependency on specific figure dimensions or colour settings.
% Uncomment the entire block to activate.

fig = figure();
hold on;

CurrentMap          = zeros(size(networkSegments,1), 1);
CurrentMap_flowrate = zeros(size(networkSegments,1), 1);

% Compute flow speed (m/s) = current / cross-sectional area
for i = 1:size(networkSegments, 1)
    for j = 1:size(segmentCurrents, 1)
        if segmentCurrents(j,1) == i
            % Flow speed = Q / A, where A = pi*d^2/4 (circular approximation)
            CurrentMap(i) = abs(segmentCurrents(j,2) / ...
                (pi * (segment_diameters(i)*1000)^2 / 4));
            CurrentMap_flowrate(i) = abs(segmentCurrents(j,2));
        end
    end
end

colorMapp3D = zeros(size(networkSegments,1), 3);
maxColor = max(CurrentMap);
minColor = min(CurrentMap);

% Draw filled circles at junction nodes, coloured by local max flow speed
for i = 1:size(networkNodes, 1)
    connectedSegs = find(networkSegments(:,1) == i | networkSegments(:,2) == i);
    if size(connectedSegs,1) > 1 && ~isempty(connectedSegs)
        maxDiameter = max(segment_diameters(connectedSegs));
        radius      = maxDiameter * 10000 / 7.2 / 2;
        normalCol   = (max(CurrentMap(connectedSegs)) - minColor) / (maxColor - minColor);
        color       = [normalCol, 0, (1 - normalCol)];
        rectangle('Position', [networkNodes(i,1)-radius, networkNodes(i,2)-radius, 2*radius, 2*radius], ...
                  'Curvature', [1, 1], 'FaceColor', color, 'EdgeColor', 'none');
    end
end

% Draw vessel segments coloured by normalised flow speed (red = fast, blue = slow)
for i = 1:size(networkSegments, 1)
    p1         = networkNodes(networkSegments(i,1), :);
    p2         = networkNodes(networkSegments(i,2), :);
    normalCol  = (CurrentMap(i) - minColor) / (maxColor - minColor);
    color      = [normalCol, 0, 1 - normalCol];
    colorMapp3D(i,:) = color;
    segmentWidth = segment_diameters(i) * 75000;   % Scale factor for visualisation
    line([p1(1), p2(1)], [p1(2), p2(2)], 'LineWidth', segmentWidth, 'Color', color);
end

colorMapp3D = sortrows(colorMapp3D, 1);
colormap(colorMapp3D);

axis off;
axis([-1, domainSize+1, -1+domainSize*0.3, domainSize+1-domainSize*0.3]);
axis equal;
hold off;

title("Normalized Flow Speed");

cb = colorbar;
set(cb, 'position', [0.90, 0.32, 0.02, 0.4]);
% 
% % Save figure to file (uncomment to enable):
% % exportgraphics(fig, append("Model_Images/END_", modelName, ".png"), Resolution=300);