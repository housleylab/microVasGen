% =========================================================================
% Title:        COMSOL API Geometry Script Generator for Microvascular
%               Network (Tapered Cones + Junction Spheres)
% Author:       Aref Valipour, Housley Lab, Georgia Tech
% Date:         2026
%
% Description:
%   Converts a microvascular network graph into a COMSOL Multiphysics
%   geometry script (Java-style COMSOL API commands) that can be pasted
%   into the COMSOL Script Editor or run via LiveLink for MATLAB.
%
%   Each vessel segment is represented as a tapered cone whose base radius
%   equals the largest vessel diameter at its proximal node, and whose tip
%   radius equals the largest vessel diameter at its distal node. Junction
%   nodes are represented as spheres whose radii are slightly larger than
%   the vessel diameter (by sphereRadiusOversize) to ensure watertight
%   Boolean unions in COMSOL and to model the rounded geometry of vascular
%   bifurcations.
%
%   The cone axis direction is specified in COMSOL spherical coordinates
%   using the (dx, dy) components of each segment's direction vector. The
%   Zshift parameter controls the out-of-plane (z) offset applied to the
%   cone mid-radius, which can be used to create a slight 3-D relief in
%   otherwise 2-D networks.
%
% Workflow:
%   1. Load a network graph (nodes, segments, diameters)
%   2. Convert all spatial quantities from mm to µm (× 1000)
%   3. Compute per-segment geometry: length, midpoint, angle, radii
%   4. Compute per-node maximum connected-segment diameter (for sphere sizing)
%   5. Write COMSOL API commands for cones (segments) and spheres (nodes)
%   6. Save the output text file to ./COMSOL_API/
%
% Inputs:
%   ./Models/<modelName>.mat     Network graph with fields:
%                              nodes, segments, segment_diameters, domain_size
%
% Outputs:
%   ./COMSOL_API/<modelName>.txt    COMSOL API script (plain text, Java syntax)
%
% Usage:
%   Paste the output file contents into the COMSOL Script Editor, or call
%   it via LiveLink for MATLAB using model.geom("geom").run() after import.
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
modelName = "Model_1_ICDT";    % Network file to load (no extension).
                               

% --- Unit conversion ---
% The network graph stores coordinates and diameters in mm. COMSOL geometry
% scripts for microfluidic devices typically use µm.
mmToMicrons = 1000;     % 1 mm = 1000 µm

% --- Junction sphere sizing ---
% Sphere radius = sphereRadiusOversize × (largest adjacent vessel radius).
% A value slightly above 1 ensures watertight Boolean unions in COMSOL by
% making each sphere marginally larger than the cone endpoints it connects.
% Two values are preserved here (1.002 and 1.003); 1.003 is currently active.
sphereRadiusOversize = 1.003;   % Dimensionless oversize factor
% sphereRadiusOversize = 1.002; % (alternative — kept for reference)

% --- Out-of-plane taper factor ---
% Zshift scales the mean cone radius to produce a small z-direction offset
% for the cone geometry. Set to 0 for a purely 2-D (planar) network.
zShiftFactor = 0.25;    % Dimensionless


%% --- Load Network Graph -------------------------------------------------
load(append("./Models/", modelName, ".mat"));

% Convert all spatial quantities to µm for the COMSOL geometry script
domainSize        = domainSize        * mmToMicrons;    % Domain size (µm)
nodes             = networkNodes      * mmToMicrons;    % Node coordinates (µm)
segment_diameters = segmentDiameters  * mmToMicrons;    % Vessel diameters (µm)


%% --- Compute Per-Segment Geometry ---------------------------------------
% For each segment, precompute the geometric quantities needed to define a
% tapered cone in COMSOL: endpoint coordinates, length, midpoint, and the
% (dx, dy) direction components used to set the cone axis in spherical form.

numSegments = size(networkSegments, 1);

segmentP1      = zeros(numSegments, 2);   % Proximal endpoint coordinates (µm)
segmentP2      = zeros(numSegments, 2);   % Distal endpoint coordinates (µm)
segmentLengths = zeros(numSegments, 1);   % Segment length (µm)
segmentMiddle  = zeros(numSegments, 2);   % Midpoint coordinates (µm)
segmentAngle   = zeros(numSegments, 1);   % Angle from x-axis (degrees)
segmentDirDX   = zeros(numSegments, 1);   % y-component of direction vector (for COMSOL axis)
segmentDirDY   = zeros(numSegments, 1);   % x-component of direction vector (for COMSOL axis)
% NOTE: COMSOL's spherical axis convention maps (anglex, angley) to
%       (dy, dx) in the API call — this ordering is preserved from the
%       original script and must not be swapped.

for i = 1:numSegments
    p1 = nodes(networkSegments(i, 1), :);
    p2 = nodes(networkSegments(i, 2), :);

    segmentP1(i, :)     = p1;
    segmentP2(i, :)     = p2;
    segmentLengths(i)   = norm(p2 - p1);
    segmentMiddle(i, :) = (p1 + p2) / 2;
    segmentAngle(i)     = atan2(p2(2)-p1(2), p2(1)-p1(1)) * 180 / pi;  % degrees
    segmentDirDX(i)     = p2(1) - p1(1);   % Used as first axis component in COMSOL
    segmentDirDY(i)     = p2(2) - p1(2);   % Used as second axis component in COMSOL
end


%% --- Compute Per-Node Maximum Adjacent Diameter -------------------------
% Each junction sphere is sized according to the largest diameter among all
% vessel segments connected to that node. This ensures the sphere fully
% encloses the cone endpoints at every bifurcation.

nodeLargestDiameter = zeros(size(nodes, 1), 1);

for k = 1:numSegments
    n1 = networkSegments(k, 1);
    n2 = networkSegments(k, 2);
    if n1 > 0 && n1 <= size(nodes, 1)
        if segment_diameters(k) > nodeLargestDiameter(n1)
            nodeLargestDiameter(n1) = segment_diameters(k);
        end
    end
    if n2 > 0 && n2 <= size(nodes, 1)
        if segment_diameters(k) > nodeLargestDiameter(n2)
            nodeLargestDiameter(n2) = segment_diameters(k);
        end
    end
end

% Compute proximal radius (r1), distal radius (r2), and z-offset for each
% segment from the node diameter table.
segmentR1 = zeros(numSegments, 1);     % Cone base radius = half max diameter at node 1
segmentR2 = zeros(numSegments, 1);     % Cone tip radius  = half max diameter at node 2
segmentZ  = zeros(numSegments, 1);     % z-offset = zShiftFactor × mean radius

for k = 1:numSegments
    segmentR1(k) = nodeLargestDiameter(networkSegments(k,1)) / 2;
    segmentR2(k) = nodeLargestDiameter(networkSegments(k,2)) / 2;
    segmentZ(k)  = zShiftFactor * (segmentR1(k) + segmentR2(k)) / 2;
end


%% --- Generate COMSOL API Script -----------------------------------------
% Produces Java-style COMSOL API commands for:
%   (a) Tapered cones  — one per vessel segment
%   (b) Junction spheres — one per interior node (inlet/outlet nodes excluded)
%
% Inlet and outlet nodes (x == 0 or x == domainSize) are skipped for spheres
% because they lie on the domain boundary and are handled as boundary
% conditions in the COMSOL model rather than geometric objects.
%
% The following COMSOL API blocks are preserved as comments for reference:
%   model.modelNode(), model.geom().create(), lengthUnit(), run()
% These can be uncommented if this script is used to build the full model
% from scratch rather than importing geometry into an existing model tree.

comsolScript = "//COMSOL API Geometry Script";
comsolScript = [comsolScript;"clearModel(model);"];
comsolScript = [comsolScript;"model.modelNode().create(""comp1"");"];
comsolScript = [comsolScript;"model.geom().create(""geom"", 3);"];
comsolScript = [comsolScript;"model.geom(""geom"").lengthUnit(""um"");"];

% --- (a) Tapered cone per vessel segment ---------------------------------
for i = 1:numSegments
    coneName = append("cone", num2str(i));

    % Create the cone object in the COMSOL geometry tree
    comsolScript = [comsolScript; append( ...
        "model.geom(""geom"").create(""", coneName, """, ""Cone"");")];

    % Enable specification of the top (distal) radius independently
    comsolScript = [comsolScript; append( ...
        "model.geom(""geom"").feature(""", coneName, """).set(""specifytop"", ""radius"");")];

    % Distal radius (tip) = half the largest diameter at the distal node
    comsolScript = [comsolScript; append( ...
        "model.geom(""geom"").feature(""", coneName, """).set(""rtop"", ", ...
        num2str(segmentR2(i)), ");")];

    % Proximal radius (base) = half the largest diameter at the proximal node
    comsolScript = [comsolScript; append( ...
        "model.geom(""geom"").feature(""", coneName, """).set(""r"", ", ...
        num2str(segmentR1(i)), ");")];

    % Cone height = segment length
    comsolScript = [comsolScript; append( ...
        "model.geom(""geom"").feature(""", coneName, """).set(""h"", ", ...
        num2str(segmentLengths(i)), ");")];

    % Cone base position = proximal node coordinate (x, y, 0)
    comsolScript = [comsolScript; append( ...
        "model.geom(""geom"").feature(""", coneName, """).set(""pos"", new double[]{", ...
        num2str(segmentP1(i,1)), ", ", num2str(segmentP1(i,2)), ", 0});")];

    % Axis type: spherical (direction specified by a 3-D vector)
    comsolScript = [comsolScript; append( ...
        "model.geom(""geom"").feature(""", coneName, """).set(""axistype"", ""spherical"");")];

    % Cone axis direction: (segmentDirDX, segmentDirDY, 0)
    % NOTE: COMSOL's API uses (dy, dx, 0) ordering — see note in geometry section above.
    comsolScript = [comsolScript; append( ...
        "model.geom(""geom"").feature(""", coneName, """).set(""axis"", new double[]{", ...
        num2str(segmentDirDX(i)), ", ", num2str(segmentDirDY(i)), ", 0});")];
end

% --- (b) Junction sphere per interior node -------------------------------
for i = 1:size(nodes, 1)
    % Skip inlet and outlet boundary nodes — handled as BCs, not geometry
    if nodes(i,1) == 0 || nodes(i,1) == domainSize
        continue;
    end

    sphereName = append("sph", num2str(i));

    % Create the sphere object
    comsolScript = [comsolScript; append( ...
        "model.geom(""geom"").create(""", sphereName, """, ""Sphere"");")];

    % Sphere radius = sphereRadiusOversize × half the largest adjacent diameter
    comsolScript = [comsolScript; append( ...
        "model.geom(""geom"").feature(""", sphereName, """).set(""r"", ", ...
        num2str(sphereRadiusOversize * nodeLargestDiameter(i) / 2), ");")];

    % Sphere centre position = node coordinate (x, y, 0)
    comsolScript = [comsolScript; append( ...
        "model.geom(""geom"").feature(""", sphereName, """).set(""pos"", new double[]{", ...
        num2str(nodes(i,1)), ", ", num2str(nodes(i,2)), ", 0});")];
end

comsolScript = [comsolScript; "model.geom(""geom"").run();"];
comsolScript = [comsolScript; "//"];



%% --- Write Output File --------------------------------------------------
outputFilePath = append("./COMSOL_API/", modelName, ".txt");
writematrix(comsolScript, outputFilePath, 'QuoteStrings', false);

fprintf('COMSOL API script written to: %s\n', outputFilePath);