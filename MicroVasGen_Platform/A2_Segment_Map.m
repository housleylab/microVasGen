% =========================================================================
% Title:        Segment-Index Map of a Microvascular Network
% Author:       Aref Valipour, Housley Lab, Georgia Tech
% Date:         2026
%
% Description:
%   Renders the network with every vessel segment labelled by its index
%   (its row number in networkSegments), plus a zoomed view of a
%   user-defined window in which only the segments inside that window are
%   labelled.
%
%   The labels use the same indexing as segmentSubset in
%   S5_Integrated_Hybrid_END_CFD.m and as the flow evaluation points
%   written by A3_COMSOL_Eval_Points.m, so this map is the reference for
%   choosing segments for hybrid END-CFD and END-vs-CFD cross-validation.
%
%   Coordinates are plotted in mm, with x measured from the inlet wall and
%   y measured from the inlet–outlet centreline (domainSize/2). Vessel line
%   width is proportional to diameter.
%
% Inputs:
%   ./Models/<modelName>.mat     Network graph (networkNodes, networkSegments,
%                              segmentDiameters, domainSize)
%
% Outputs (when saveResults = 1):
%   ./Model_Images/SegmentMap_<modelName>.png/.eps        Full labelled map
%   ./Model_Images/SegmentMap_<modelName>_zoom.png/.eps   Zoomed window
%   Command window: indices of the segments inside the zoom window
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
modelName = "model_1_ICDT";    % Network file to load (no extension)

% --- Output control ---
saveResults      = 1;      % 1: save PNG and EPS figures;  0: display only
exportResolution = 300;    % PNG resolution (dpi)

% --- Orientation ---
% 0: y increases upward (standard plot orientation).
% 1: y increases downward, matching the velocity maps produced by S5.
flipYAxis = 0;

% --- Figure sizes (pixels: [width, height]) ---
fullMapSizePx = [600, 300];
zoomMapSizePx = [300, 300];

% --- Vessel rendering ---
% Line width (pt) = segment diameter (mm) × lineWidthScale.
% With diameters of ~25 µm, a scale of 50 gives lines of ~1.25 pt.
lineWidthScale = 50;
vesselColor    = [0, 0, 0];

% --- Label font sizes (pt) ---
labelFontSizeFull = 5;
labelFontSizeZoom = 7;

% --- Zoom window (mm) ---
% x is measured from the inlet wall; y from the inlet–outlet centreline.
% These defaults are network-specific; adjust for each model.
zoomXLimits = [6.9, 7.5];
zoomYLimits = [-0.3, 0.3];


%% --- Load Network Graph -------------------------------------------------
load(append("./Models/", modelName, ".mat"));

segmentDiameters = segmentDiameters(:);     % Ensure column vector (mm)
numSegments      = size(networkSegments, 1);

% Plot coordinates: shift y so the inlet–outlet centreline sits at y = 0
plotNodes       = networkNodes;
plotNodes(:, 2) = networkNodes(:, 2) - domainSize / 2;

% Segment midpoints in plot coordinates (label positions)
segmentMidpoints = (plotNodes(networkSegments(:, 1), :) + ...
                    plotNodes(networkSegments(:, 2), :)) / 2;


%% --- Full Network Map ---------------------------------------------------
figFull = figure('Position', [0, 0, fullMapSizePx], 'Color', 'w', 'Renderer', 'painters');
axFull  = axes('Parent', figFull);

drawSegmentMap(axFull, plotNodes, networkSegments, segmentDiameters, ...
    lineWidthScale, vesselColor, true(numSegments, 1), labelFontSizeFull, flipYAxis);


%% --- Zoomed Window ------------------------------------------------------
% Only segments whose midpoint lies inside the window are labelled, so no
% labels are drawn outside the visible axes.
inZoomWindow = segmentMidpoints(:, 1) >= zoomXLimits(1) & ...
               segmentMidpoints(:, 1) <= zoomXLimits(2) & ...
               segmentMidpoints(:, 2) >= zoomYLimits(1) & ...
               segmentMidpoints(:, 2) <= zoomYLimits(2);

figZoom = figure('Position', [0, 0, zoomMapSizePx], 'Color', 'w', 'Renderer', 'painters');
axZoom  = axes('Parent', figZoom);

drawSegmentMap(axZoom, plotNodes, networkSegments, segmentDiameters, ...
    lineWidthScale, vesselColor, inZoomWindow, labelFontSizeZoom, flipYAxis);
xlim(axZoom, zoomXLimits);
ylim(axZoom, zoomYLimits);

% Report segment indices in the window (ready to paste into segmentSubset)
fprintf('Segments inside zoom window: %s\n', mat2str(find(inZoomWindow)'));


%% --- Save Results -------------------------------------------------------
% Requires ./Model_Images/ (created by S0_setup_dirs.m).
if saveResults == 1
    fullMapPath = append("./Model_Images/SegmentMap_", modelName);
    zoomMapPath = append("./Model_Images/SegmentMap_", modelName, "_zoom");

    exportgraphics(figFull, append(fullMapPath, ".png"), 'Resolution', exportResolution);
    exportgraphics(figFull, append(fullMapPath, ".eps"), 'ContentType', 'vector');
    exportgraphics(figZoom, append(zoomMapPath, ".png"), 'Resolution', exportResolution);
    exportgraphics(figZoom, append(zoomMapPath, ".eps"), 'ContentType', 'vector');

    fprintf('Segment maps written to: %s(.png/.eps) and %s(.png/.eps)\n', ...
        fullMapPath, zoomMapPath);
end


%% ========================================================================
%  HELPER FUNCTIONS
%  ========================================================================

function drawSegmentMap(ax, plotNodes, networkSegments, segmentDiameters, ...
        lineWidthScale, vesselColor, labelMask, labelFontSize, flipYAxis)
% DRAWSEGMENTMAP  Draw the vessel network into axes ax and label segments.
%
%   All vessels are drawn first and labels second, so every label sits on
%   top of the vessel lines. Only segments where labelMask is true receive
%   an index label at their midpoint.

    hold(ax, 'on');
    numSegments = size(networkSegments, 1);

    % Vessels: line width proportional to diameter (must be > 0)
    for i = 1:numSegments
        p1 = plotNodes(networkSegments(i, 1), :);
        p2 = plotNodes(networkSegments(i, 2), :);
        line(ax, [p1(1), p2(1)], [p1(2), p2(2)], ...
            'LineWidth', max(0.01, segmentDiameters(i) * lineWidthScale), ...
            'Color', vesselColor);
    end

    % Segment index labels at midpoints
    for i = find(labelMask(:))'
        midpoint = (plotNodes(networkSegments(i, 1), :) + ...
                    plotNodes(networkSegments(i, 2), :)) / 2;
        text(ax, midpoint(1), midpoint(2), num2str(i), ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment',   'middle', ...
            'FontSize',            labelFontSize, ...
            'Color',               'k', ...
            'BackgroundColor',     'w', ...
            'EdgeColor',           'k', ...
            'Margin',              1, ...
            'Clipping',            'on');
    end

    xticks(ax, []);
    yticks(ax, []);
    axis(ax, 'equal');
    box(ax, 'on');
    if flipYAxis == 1
        set(ax, 'YDir', 'reverse');
    end
    set(ax, 'LineWidth', 0.5, 'Layer', 'top', 'FontSize', 8);
end
