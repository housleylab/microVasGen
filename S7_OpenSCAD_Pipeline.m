% =========================================================================
% Title:        OpenSCAD 3-D Geometry Generator for Microvascular Network
%               (Tapered Cylinders + Junction Spheres, STL Export)
% Author:       Aref Valipour, Housley Lab, Georgia Tech
% Date:         2026
%
% Description:
%   Converts a microvascular network graph into an OpenSCAD script suitable
%   for two-photon polymerisation (2PP) printing , or
%   any other STL-based additive manufacturing workflow.
%
%   Geometry model:
%     - Each vessel segment is rendered as a tapered cylinder (OpenSCAD
%       `cylinder()`) centred at the segment midpoint and rotated to align
%       with the segment axis. The cylinder diameters at each end equal the
%       largest adjacent node diameter, producing smooth transitions at
%       bifurcations.
%     - Each junction node is rendered as a sphere (`sphere()`) whose
%       diameter equals the largest adjacent vessel diameter and whose
%       z-position is offset by zShiftFactor × radius to model the out-of-
%       plane channel depth.
%     - The network is embedded in a `difference()` operation against a
%       flat substrate slab, which subtracts the bottom of all volumes to
%       produce open-top channels when printed.
%     - Inlet and outlet stubs (centred cylinders) connect the network to
%       the domain boundary.
%
%   Performance note:
%     Node spheres are grouped into batches of nodesPerHullGroup to reduce
%     the OpenSCAD geometry count. The hull() wrappers are preserved as
%     comments and can be uncommented to further merge geometry if needed.
%
%   Tiling:
%     The tiling loop produces spatially offset copies of the network along
%     the y-axis. Set tilingRange = 0:0 for a single device copy.
%
% Inputs:
%   ./Models/<modelName>.mat     Network graph with fields:
%                              nodes, segments, segment_diameters, domain_size
%
% Outputs:
%   ./OpenSCAD/<modelName>.txt    OpenSCAD script (plain text)
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
modelName = "Model_1_ICDT";    % Network file to load (no extension)

% --- Unit conversion ---
% The network graph stores all spatial quantities in mm. OpenSCAD scripts
% for Nanoscribe printing use µm (1 mm = 1000 µm).
mmToMicrons = 1000;     % µm per mm

% --- Out-of-plane z-offset factor ---
% Node sphere z-centres are raised by zShiftFactor × node radius to place
% the sphere centroid above the substrate plane, matching the tapered cone
% geometry used in the COMSOL and GDS scripts.
zShiftFactor = 0.25;    % Dimensionless

% --- OpenSCAD rendering resolution ---
% $fn sets the number of facets used to approximate circles and spheres.
% Low values (e.g. 3) speed up preview; increase to 16–64 for final export.
openScadFacets = 3;     % Integer

% --- Inlet/outlet stub geometry ---
% The stub is a cylinder connecting the boundary node to the domain edge.
% Its diameter matches the first segment's diameter (connectionDiameterStr).
% channelDistanceFromDesign sets the stub total length (µm).
channelDistanceFromDesign = 500;    % µm
% Alternative (geometry-derived): max(segment_middle(:,2)) - domain_size/2 + 500

% --- Tiling layout ---
% The tiling loop creates vertically stacked device copies separated by
% tilingSpacing µm along the y-axis. Set tilingRange = 0:0 for a single copy.
tilingRange   = 0:0;        % Integer range
tilingSpacing = 20000;      % y-axis separation between copies (µm)

% --- Node sphere batching ---
% Junction spheres are written in sequential batches of nodesPerHullGroup
% to reduce the OpenSCAD geometry count. The hull() wrapper that would
% merge each batch is preserved as a comment.
nodesPerHullGroup = 20;     % Nodes per batch

% --- Substrate subtraction slab ---
% A flat slab is subtracted from the union to open the bottom of the
% channels. Dimensions match typical Nanoscribe print field sizes (µm).
substrateSlabWidth  = 25000;    % x-dimension (µm)
substrateSlabDepth  = 100000;   % y-dimension (µm)
substrateSlabHeight = 200;      % z-dimension (µm)
substrateSlabZPos   = -100;     % z-position of slab centre (µm)


%% --- Load Network Graph -------------------------------------------------
load(append("./Models/", modelName, ".mat"));

% Convert all spatial quantities from mm to µm
domainSize        = domainSize        * mmToMicrons;
nodes             = networkNodes      * mmToMicrons;
segment_diameters = segmentDiameters * mmToMicrons;


%% --- Compute Per-Segment Geometry ---------------------------------------
% Pre-compute midpoint, length, angle, and z-position for each segment.
% The rotation angle uses a negated atan2 because OpenSCAD's right-handed
% coordinate system requires the opposite sign convention to COMSOL.

numSegments    = size(networkSegments, 1);
segmentLengths = zeros(numSegments, 1);
segmentMiddle  = zeros(numSegments, 2);
segmentR1      = zeros(numSegments, 1);     % Diameter at proximal node (µm)
segmentR2      = zeros(numSegments, 1);     % Diameter at distal node (µm)
segmentZ       = zeros(numSegments, 1);     % z-centre of cylinder (µm)
segmentAngle   = zeros(numSegments, 1);     % OpenSCAD rotation angle (degrees)

for i = 1:numSegments
    p1 = nodes(networkSegments(i, 1), :);
    p2 = nodes(networkSegments(i, 2), :);
    segmentLengths(i)   = norm(p2 - p1);
    segmentMiddle(i, :) = (p1 + p2) / 2;
    % Negated sign: OpenSCAD rotation convention (opposite to COMSOL)
    segmentAngle(i)     = -atan2(p2(2)-p1(2), p2(1)-p1(1)) * 180 / pi;
end


%% --- Compute Per-Node Maximum Adjacent Diameter -------------------------
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

% Assign proximal/distal diameters and z-offsets per segment
for k = 1:numSegments
    segmentR1(k) = nodeLargestDiameter(networkSegments(k, 1));
    segmentR2(k) = nodeLargestDiameter(networkSegments(k, 2));
    segmentZ(k)  = zShiftFactor * (segmentR1(k) + segmentR2(k)) / 2;
end

% Inlet/outlet stub diameter: taken from the first segment
connectionDiameterStr = num2str(segment_diameters(1));


%% --- Generate OpenSCAD Script -------------------------------------------
% The outer difference() subtracts the flat substrate slab from the union
% of all vessel cylinders, node spheres, and inlet/outlet stubs, producing
% open-top channel geometry when printed flat-side-down.

openScadScript = "//Optimized - using hull() to reduce geometry count";
openScadScript = [openScadScript; append("$fn = ", num2str(openScadFacets), ";")];

openScadScript = [openScadScript; "difference(){"];
openScadScript = [openScadScript; "union(){"];

% --- Tiling loop ---------------------------------------------------------
for jjj = tilingRange
    yOffset = tilingSpacing * jjj;

    % ------------------------------------------------------------------
    % (a) Tapered cylinders — one per vessel segment
    % ------------------------------------------------------------------
    % Each cylinder is translated to the segment midpoint (domain-centred
    % by subtracting domainSize/2) and rotated about the y-axis by the
    % segment angle to align with the vessel direction in the xy-plane.
    % ------------------------------------------------------------------
    for i = 1:numSegments
        xMid = segmentMiddle(i,1) - domainSize/2;
        yMid = segmentMiddle(i,2) - domainSize/2 + yOffset;
        zMid = segmentZ(i);

        openScadScript = [openScadScript; ...
            append("translate([", num2str(xMid), ",", num2str(yMid), ",", num2str(zMid), "])")];
        openScadScript = [openScadScript; ...
            append("rotate([", num2str(segmentAngle(i)), ",90,0])")];
        openScadScript = [openScadScript; ...
            append("cylinder(", num2str(segmentLengths(i)), ...
            ", d1=", num2str(segmentR1(i)), ...
            ", d2=", num2str(segmentR2(i)), ", center=true);")];
    end

    % ------------------------------------------------------------------
    % (b) Junction spheres — grouped in batches of nodesPerHullGroup
    % ------------------------------------------------------------------
    % Each sphere is domain-centred and raised in z by nodeLargestDiameter/4.
    % The hull() wrappers are preserved as comments; uncomment to merge
    % each batch into a convex hull and reduce the polygon count.
    % ------------------------------------------------------------------
    numHulls = ceil(size(nodes, 1) / nodesPerHullGroup);

    for hullIdx = 1:numHulls
        startIdx = (hullIdx - 1) * nodesPerHullGroup + 1;
        endIdx   = min(hullIdx * nodesPerHullGroup, size(nodes, 1));

        % openScadScript = [openScadScript; "hull(){"];
        for i = startIdx:endIdx
            xNode = nodes(i,1) - domainSize/2;
            yNode = nodes(i,2) - domainSize/2 + yOffset;
            zNode = nodeLargestDiameter(i) / 4;

            openScadScript = [openScadScript; ...
                append("translate([", num2str(xNode), ",", num2str(yNode), ",", num2str(zNode), "])")];
            openScadScript = [openScadScript; ...
                append("sphere(d=", num2str(nodeLargestDiameter(i)), ");")];
        end
        % openScadScript = [openScadScript; "}"];
    end

    % ------------------------------------------------------------------
    % (c) Inlet (left) and outlet (right) stubs
    % ------------------------------------------------------------------
    % Centred cylinders extend from ±domainSize/2 inward for
    % channelDistanceFromDesign µm. Rotated [0,90,90] so the axis is
    % parallel to y (into the domain). Diameter = connectionDiameterStr.
    %
    % Alternative geometries (extended arms, hull connectors, filter cubes,
    % tapered end caps) are preserved as comments for both sides.
    % ------------------------------------------------------------------

    % Left (inlet) stub
    openScadScript = [openScadScript; ...
        append("translate([", num2str(-domainSize/2), ",", ...
        num2str(channelDistanceFromDesign/2 + yOffset), ",", ...
        num2str(segmentZ(1)), "])")];
    openScadScript = [openScadScript; "rotate([0,90,90])"];
    openScadScript = [openScadScript; ...
        append("cylinder(", num2str(channelDistanceFromDesign), ...
        ", d=", connectionDiameterStr, ", center=true);")];

    % --- Commented left-stub alternative geometries ---
    % openScadScript = [openScadScript; append("translate([", num2str(-domainSize/4-100), ",", num2str(channelDistanceFromDesign+yOffset), ",",num2str(segmentZ(1)),"])  rotate([0,90,0])  cylinder(", num2str(domainSize/2-200), ", d=", connectionDiameterStr, ", center=true);")];
    % openScadScript = [openScadScript; append("translate([", num2str(-200), ",", num2str(channelDistanceFromDesign+500+yOffset), ",",num2str(segmentZ(1)),"])  rotate([0,90,90])  cylinder(1000, d=", connectionDiameterStr, ", center=true);")];
    % openScadScript = [openScadScript; append("translate([", num2str(-(domainSize*0.4+4000)/2-200), ",", num2str(channelDistanceFromDesign+1000+yOffset), ",",num2str(segmentZ(1)),"])  rotate([0,90,0])  cylinder(", num2str(domainSize*0.4+4000), ", d=", connectionDiameterStr, ", center=true);")];
    % openScadScript = [openScadScript; append("translate([", num2str(-(domainSize*0.4+4000)), ",", num2str(channelDistanceFromDesign+1000+yOffset), ",",num2str(segmentZ(1)),"])  rotate([0,0,0])  cylinder(", connectionDiameterStr, ", d1=800, d2=300, center=true);")];
    % Hull connectors:
    % openScadScript = [openScadScript; "hull(){"];
    % openScadScript = [openScadScript; append("translate([", num2str(-domainSize/2), ",", num2str(channelDistanceFromDesign+yOffset), ",", num2str(segmentZ(1)),"])  sphere(d=", connectionDiameterStr, ");")];
    % openScadScript = [openScadScript; append("translate([", num2str(-200), ",", num2str(channelDistanceFromDesign+yOffset), ",", num2str(segmentZ(1)),"])  sphere(d=", connectionDiameterStr, ");")];
    % openScadScript = [openScadScript; "}"];
    % openScadScript = [openScadScript; "hull(){"];
    % openScadScript = [openScadScript; append("translate([", num2str(-200), ",", num2str(channelDistanceFromDesign+yOffset), ",", num2str(segmentZ(1)),"])  sphere(d=", connectionDiameterStr, ");")];
    % openScadScript = [openScadScript; append("translate([", num2str(-200), ",", num2str(channelDistanceFromDesign+1000+yOffset), ",", num2str(segmentZ(1)),"])  sphere(d=", connectionDiameterStr, ");")];
    % openScadScript = [openScadScript; "}"];

    % Right (outlet) stub
    openScadScript = [openScadScript; ...
        append("translate([", num2str(domainSize/2), ",", ...
        num2str(channelDistanceFromDesign/2 + yOffset), ",", ...
        num2str(segmentZ(1)), "])")];
    openScadScript = [openScadScript; "rotate([0,90,90])"];
    openScadScript = [openScadScript; ...
        append("cylinder(", num2str(channelDistanceFromDesign), ...
        ", d=", connectionDiameterStr, ", center=true);")];

    % --- Commented right-stub alternative geometries ---
    % openScadScript = [openScadScript; append("translate([", num2str(domainSize/4+100), ",", num2str(channelDistanceFromDesign+yOffset), ",",num2str(segmentZ(1)),"])  rotate([0,90,0])  cylinder(", num2str(domainSize/2-200), ", d=", connectionDiameterStr, ", center=true);")];
    % openScadScript = [openScadScript; append("translate([", num2str(200), ",", num2str(channelDistanceFromDesign+500+yOffset), ",",num2str(segmentZ(1)),"])  rotate([0,90,90])  cylinder(1000, d=", connectionDiameterStr, ", center=true);")];
    % openScadScript = [openScadScript; append("translate([", num2str((domainSize*0.4+4000)/2+200), ",", num2str(channelDistanceFromDesign+1000+yOffset), ",",num2str(segmentZ(1)),"])  rotate([0,90,0])  cylinder(", num2str(domainSize*0.4+4000), ", d=", connectionDiameterStr, ", center=true);")];
    % openScadScript = [openScadScript; append("translate([", num2str(domainSize*0.4+4000), ",", num2str(channelDistanceFromDesign+1000+yOffset), ",",num2str(segmentZ(1)),"])  rotate([0,0,0])  cylinder(", connectionDiameterStr, ", d1=800, d2=300, center=true);")];
    % Hull connectors:
    % openScadScript = [openScadScript; "hull(){"];
    % openScadScript = [openScadScript; append("translate([", num2str(domainSize/2), ",", num2str(channelDistanceFromDesign+yOffset), ",", num2str(segmentZ(1)),"])  sphere(d=", connectionDiameterStr, ");")];
    % openScadScript = [openScadScript; append("translate([", num2str(200), ",", num2str(channelDistanceFromDesign+yOffset), ",", num2str(segmentZ(1)),"])  sphere(d=", connectionDiameterStr, ");")];
    % openScadScript = [openScadScript; "}"];
    % openScadScript = [openScadScript; "hull(){"];
    % openScadScript = [openScadScript; append("translate([", num2str(200), ",", num2str(channelDistanceFromDesign+yOffset), ",", num2str(segmentZ(1)),"])  sphere(d=", connectionDiameterStr, ");")];
    % openScadScript = [openScadScript; append("translate([", num2str(200), ",", num2str(channelDistanceFromDesign+1000+yOffset), ",", num2str(segmentZ(1)),"])  sphere(d=", connectionDiameterStr, ");")];
    % openScadScript = [openScadScript; "}"];

    % --- Commented filter cube geometry ---
    % openScadScript = [openScadScript; append("translate([", num2str(domainSize/2+500), ",", num2str(channelDistanceFromDesign+1000+yOffset), ",0])  rotate([0,0,45])  cube(size=[400,400,",num2str(segment_diameters(1)*1.5),"], center=true);")];
    % openScadScript = [openScadScript; append("translate([", num2str(-domainSize/2-500), ",", num2str(channelDistanceFromDesign+1000+yOffset), ",0])  rotate([0,0,45])  cube(size=[400,400,",num2str(segment_diameters(1)*1.5),"], center=true);")];

end % --- end tiling loop ---

% Close union()
openScadScript = [openScadScript; "}"];

% Substrate subtraction slab
openScadScript = [openScadScript; ...
    append("translate([0,0,", num2str(substrateSlabZPos), "])")];
openScadScript = [openScadScript; ...
    append("cube([", num2str(substrateSlabWidth), ",", ...
    num2str(substrateSlabDepth), ",", ...
    num2str(substrateSlabHeight), "],center=true);")];

% Close difference()
openScadScript = [openScadScript; "}"];

% --- Commented filter hole loop (OpenSCAD for-loop syntax) ---------------
% Generates diamond-pattern filter holes at inlet/outlet ports.
% Uncomment the entire block to activate.
%
% openScadScript = [openScadScript; "union(){"];
% for jjj = -1:1
%     openScadScript = [openScadScript; "for(isq=[-3:2])"];
%     openScadScript = [openScadScript; "for(jsq=[-7:7])"];
%     openScadScript = [openScadScript; "if(abs(isq)+abs(jsq)<4)"];
%     openScadScript = [openScadScript; append("translate([", num2str(domainSize/2+500), "+65*isq,", num2str(channelDistanceFromDesign+1000+(tilingSpacing*jjj)), "+65*jsq,0])")];
%     openScadScript = [openScadScript; append("cylinder(", num2str(segment_diameters(1)*1.6), ", d1=25, d2=40, center=true);")];
% end
% for jjj = -1:1
%     openScadScript = [openScadScript; "for(isq=[-2:2])"];
%     openScadScript = [openScadScript; "for(jsq=[-3:3])"];
%     openScadScript = [openScadScript; "if(abs(isq)+abs(jsq)<4)"];
%     openScadScript = [openScadScript; append("translate([", num2str(-(domainSize/2+500)), "+65*isq,", num2str(channelDistanceFromDesign+1000+(tilingSpacing*jjj)), "+65*jsq,0])")];
%     openScadScript = [openScadScript; append("cylinder(", num2str(segment_diameters(1)*1.6), ", d1=25, d2=40, center=true);")];
% end
% openScadScript = [openScadScript; "}"];


%% --- Write Output File --------------------------------------------------
outputFilePath = append("./OpenSCAD/", modelName, ".scad");
writelines(openScadScript, outputFilePath);

fprintf('OpenSCAD script written to: %s\n', outputFilePath);
fprintf('Nodes grouped into %d batches of %d.\n', ...
    ceil(size(nodes,1) / nodesPerHullGroup), nodesPerHullGroup);