% =========================================================================
% Title:        Topological and Morphometric Statistics of a
%               Microvascular Network Graph
% Author:       Aref Valipour, Housley Lab, Georgia Tech
% Date:         2026
%
% Description:
%   Computes a panel of graph-theoretic and morphometric descriptors for a
%   microvascular network graph and renders a nine-panel summary figure
%   sized for a journal double-column width (180 × 170 mm).
%
%   The script runs on any network produced by the pipeline. Topology
%   metrics are identical before and after ICDT. Calibre (diameter) metrics
%   are only physically meaningful after S2 (ICDT) has assigned diameters.
%
% Metrics computed:
%   1.  Vessel density            segments / mm²
%   2.  Diameter distribution     min, max, mean, median, SD, IQR
%   3.  Connectivity              independent loops (E − N + P), mean degree
%   4.  Topological complexity    mean / max shortest-path length (hops)
%   5.  Segment length            distribution, total length, length density
%   6.  Clustering coefficient    local triangle density per node
%   7.  Mesh–tree character       mesh coefficient; alpha, beta, gamma indices
%   8.  Fractal dimension         box-counting slope
%   9.  Tortuosity                vessel path length / chord length, where a
%                                 "vessel" is the chain of segments between
%                                 two branch points or terminals (degree ≠ 2)
%   10. Hierarchical order        hop distance from the nearest terminal node
%   11. Lacunarity                variance / mean² of local vessel density
%   12. Betweenness centrality    distribution and critical-node fraction
%
% Inputs:
%   ./Models/<modelName>.mat     Network graph (networkNodes, networkSegments,
%                              segmentDiameters, domainSize)
%
% Outputs (when saveResults = 1):
%   ./Statistics/<modelName>_metrics.mat          Full metrics struct
%   ./Statistics/<modelName>_summary.csv          One-row table of scalar metrics
%   ./Model_Images/Statistics_<modelName>.png     Summary figure (300 dpi)
%   ./Model_Images/Statistics_<modelName>.eps     Summary figure (vector)
%
% Dependencies:
%   None beyond base MATLAB (graph, distances, centrality, conncomp).
%   Percentiles use a local helper so the Statistics Toolbox is not needed.
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
modelName = "model_1_ICDT";    % Network file to load (no extension).
                               %   Topology metrics are valid at any stage;
                               %   calibre metrics require S2 (ICDT) output.

% --- Output control ---
saveResults = 1;    % 1: save metrics, summary table, and figure;  0: display only

% --- Spatial regions along the inlet → outlet (x) axis ---
% Segments are binned by midpoint x-position (as a fraction of domainSize)
% to show how vessel mass is distributed between inlet, capillary bed, and
% outlet. Edges must start at 0 and end at 1.
regionEdges = [0, 0.25, 0.5, 0.75, 1];
regionNames = ["Inlet (0-25%)", "Mid-inlet (25-50%)", ...
               "Mid-outlet (50-75%)", "Outlet (75-100%)"];

% --- Vessel density map (used for lacunarity) ---
densityGridSize       = 20;          % Grid cells per domain side
lacunarityWindowSizes = [2, 4, 8];   % Sliding-window sizes (grid cells)

% --- Box-counting fractal dimension ---
% Box sizes are log-spaced between the two fractions of domainSize below.
% Boxes much smaller than a segment length resolve individual straight
% segments and bias the slope toward 1 (a line).
numBoxSizes        = 15;        % Number of box sizes in the log-log fit
minBoxSizeFraction = 1/100;     % Smallest box (fraction of domainSize)
maxBoxSizeFraction = 1/2;       % Largest box (fraction of domainSize)

% --- Shortest-path statistics ---
% All-pairs distances are exact up to exactPathMaxNodes nodes. Larger
% networks are estimated from all paths that start at numPathSampleSources
% randomly chosen nodes (the maximum is then a lower bound).
exactPathMaxNodes    = 1000;
numPathSampleSources = 200;
pathSamplingSeed     = 1;       % RNG seed for reproducible sampling

% --- Betweenness centrality ---
betweennessMaxNodes    = 5000;  % Skipped above this size (cost grows ~ N·E)
criticalNodePercentile = 90;    % Nodes above this percentile are "critical"

% --- Mesh–tree composite score ---
% overall = meshCoefficientWeight × mesh coefficient + alphaIndexWeight × alpha
meshCoefficientWeight = 0.6;
alphaIndexWeight      = 0.4;

% --- Figure settings (journal double-column) ---
figWidthMm  = 180;
figHeightMm = 170;
fontName    = 'Arial';
fontSize    = 5;

% Panel 1 (network) line width: proportional to vessel diameter
networkLineWidthPerUm = 1/25;   % Line width (pt) per µm of diameter
minNetworkLineWidth   = 0.3;    % Minimum line width (pt)

% Paul Tol's muted colorblind-safe palette
tolMuted = {
    [ 51,  34, 136] / 255,   % indigo
    [136, 204, 238] / 255,   % cyan
    [ 68, 170, 153] / 255,   % teal
    [ 17, 119,  51] / 255,   % green
    [153, 153,  51] / 255,   % olive
    [221, 204, 119] / 255,   % sand
    [204, 102, 119] / 255,   % rose
    [136,  34,  85] / 255,   % wine
    [170,  68, 153] / 255    % purple
};


%% --- Load Network Graph -------------------------------------------------
load(append("./Models/", modelName, ".mat"));

segmentDiameters = segmentDiameters(:);     % Ensure column vector (mm)

numNodes    = size(networkNodes, 1);
numSegments = size(networkSegments, 1);
domainArea  = domainSize^2;                 % mm²

metrics           = struct();
metrics.modelName = modelName;


%% --- Per-Segment Geometry, Node Degree, and Graph Object ----------------
segP1          = networkNodes(networkSegments(:, 1), :);   % Proximal endpoints (mm)
segP2          = networkNodes(networkSegments(:, 2), :);   % Distal endpoints (mm)
segmentLengths = vecnorm(segP2 - segP1, 2, 2);             % Segment lengths (mm)
segmentMidX    = (segP1(:, 1) + segP2(:, 1)) / 2;          % Midpoint x (mm)

% Node degree = number of segment ends attached to each node
nodeDegree = accumarray(networkSegments(:), 1, [numNodes, 1]);

% graph() only creates nodes up to the largest referenced index, so any
% trailing isolated nodes are appended to keep node numbering aligned with
% networkNodes (required for plotting with XData/YData).
G = graph(networkSegments(:, 1), networkSegments(:, 2));
if numnodes(G) < numNodes
    G = addnode(G, numNodes - numnodes(G));
end

% Bin segments into longitudinal regions by midpoint x-position
regionIdx    = discretize(segmentMidX / domainSize, regionEdges);
regionCounts = accumarray(regionIdx(~isnan(regionIdx)), 1, [numel(regionNames), 1]);


%% --- 0. Network Summary -------------------------------------------------
fprintf('\n--- Network Statistics: %s ---\n', modelName);
fprintf('Total nodes:             %d\n',   numNodes);
fprintf('Total segments:          %d\n',   numSegments);
fprintf('Junctions (degree > 2):  %d\n',   sum(nodeDegree > 2));
fprintf('Terminals (degree = 1):  %d\n',   sum(nodeDegree == 1));
fprintf('Segment-to-node ratio:   %.4f\n', numSegments / numNodes);
fprintf('Mean segment length:     %.1f um\n',   mean(segmentLengths) * 1000);
fprintf('Mean segment diameter:   %.2f um\n\n', mean(segmentDiameters) * 1000);

for r = 1:numel(regionNames)
    fprintf('Segments in %-22s %5d (%.1f%%)\n', regionNames(r) + ":", ...
        regionCounts(r), 100 * regionCounts(r) / numSegments);
end
fprintf('\n');

metrics.regions.names  = regionNames;
metrics.regions.counts = regionCounts;


%% --- 1. Vessel Density --------------------------------------------------
fprintf('Calculating network metrics...\n');
fprintf('  - Computing vessel density...\n');

metrics.vesselDensity = numSegments / domainArea;   % segments / mm²

fprintf('    Vessel density: %.2f segments/mm^2\n', metrics.vesselDensity);


%% --- 2. Diameter Distribution -------------------------------------------
% Stored in mm (native graph units); printed and plotted in µm.
fprintf('  - Analysing diameter distribution...\n');

metrics.diameter.min       = min(segmentDiameters);
metrics.diameter.max       = max(segmentDiameters);
metrics.diameter.mean      = mean(segmentDiameters);
metrics.diameter.median    = median(segmentDiameters);
metrics.diameter.std       = std(segmentDiameters);
metrics.diameter.range     = metrics.diameter.max - metrics.diameter.min;
metrics.diameter.p25       = percentileValue(segmentDiameters, 25);
metrics.diameter.p75       = percentileValue(segmentDiameters, 75);
metrics.diameter.allValues = segmentDiameters;

fprintf('    Diameter range: %.2f - %.2f um\n', ...
    metrics.diameter.min * 1000, metrics.diameter.max * 1000);
fprintf('    Diameter mean +/- SD: %.2f +/- %.2f um\n', ...
    metrics.diameter.mean * 1000, metrics.diameter.std * 1000);


%% --- 3. Connectivity (Anastomotic Loops) --------------------------------
% Number of independent cycles (cyclomatic number):
%     M = E − N + P
% where E = edges, N = nodes, P = connected components. Isolated nodes
% count as their own components and do not change M.
fprintf('  - Computing network connectivity...\n');

[componentBins, componentSizes] = conncomp(G);
numComponents = numel(componentSizes);

metrics.connectivity.numNodes      = numNodes;
metrics.connectivity.numEdges      = numSegments;
metrics.connectivity.numComponents = numComponents;
metrics.connectivity.numLoops      = numSegments - numNodes + numComponents;
metrics.connectivity.loopDensity   = metrics.connectivity.numLoops / domainArea;  % loops / mm²
metrics.connectivity.meanDegree    = mean(nodeDegree);
metrics.connectivity.maxDegree     = max(nodeDegree);

fprintf('    Anastomotic loops: %d\n',          metrics.connectivity.numLoops);
fprintf('    Loop density: %.2f loops/mm^2\n',  metrics.connectivity.loopDensity);
fprintf('    Mean node degree: %.2f\n',         metrics.connectivity.meanDegree);


%% --- 4. Topological Complexity (Shortest-Path Length) -------------------
% Path lengths are measured in hops (segments) within the largest
% connected component.
fprintf('  - Computing topological complexity...\n');

if numComponents > 1
    warning(['Graph has %d connected components (isolated nodes included). ' ...
             'Path metrics use the largest component only.'], numComponents);
end

[~, largestComponentIdx] = max(componentSizes);
GLargest        = subgraph(G, find(componentBins == largestComponentIdx));
numNodesLargest = numnodes(GLargest);

if numNodesLargest <= exactPathMaxNodes
    % Exact: all pairwise distances (upper triangle, no diagonal)
    allDistances  = distances(GLargest);
    pairDistances = allDistances(triu(true(numNodesLargest), 1));
    metrics.topology.method = "exact";
else
    % Estimate: all paths from a random subset of source nodes
    fprintf('    Large network: sampling paths from %d source nodes...\n', ...
        min(numPathSampleSources, numNodesLargest));
    rng(pathSamplingSeed);
    sourceNodes      = randperm(numNodesLargest, min(numPathSampleSources, numNodesLargest));
    sampledDistances = distances(GLargest, sourceNodes);      % [S × N]
    selfMask         = false(size(sampledDistances));
    selfMask(sub2ind(size(selfMask), 1:numel(sourceNodes), sourceNodes)) = true;
    pairDistances    = sampledDistances(~selfMask);
    metrics.topology.method = "sampled";
end

pairDistances = pairDistances(isfinite(pairDistances));
if isempty(pairDistances)
    pairDistances = NaN;
end

metrics.topology.meanPathLength   = mean(pairDistances);
metrics.topology.medianPathLength = median(pairDistances);
metrics.topology.maxPathLength    = max(pairDistances);
metrics.topology.stdPathLength    = std(pairDistances);
metrics.topology.networkDiameter  = metrics.topology.maxPathLength;  % Longest shortest path

fprintf('    Mean path length: %.2f segments (%s)\n', ...
    metrics.topology.meanPathLength, metrics.topology.method);
fprintf('    Network diameter: %.0f segments\n', metrics.topology.networkDiameter);


%% --- 5. Segment Length and Total Vessel Length --------------------------
fprintf('  - Computing segment-length metrics...\n');

metrics.segmentLength.mean      = mean(segmentLengths);     % mm
metrics.segmentLength.median    = median(segmentLengths);
metrics.segmentLength.std       = std(segmentLengths);
metrics.segmentLength.min       = min(segmentLengths);
metrics.segmentLength.max       = max(segmentLengths);
metrics.segmentLength.allValues = segmentLengths;

metrics.totalVesselLength   = sum(segmentLengths);                      % mm
metrics.vesselLengthDensity = metrics.totalVesselLength / domainArea;   % mm / mm²

fprintf('    Total vessel length: %.2f mm\n',          metrics.totalVesselLength);
fprintf('    Vessel length density: %.2f mm/mm^2\n',   metrics.vesselLengthDensity);


%% --- 6. Clustering Coefficient ------------------------------------------
% Local clustering coefficient of node i:
%     C_i = (triangles through i) / (k_i (k_i − 1) / 2)
% computed from the simple adjacency matrix A (parallel edges merged,
% self-loops removed), where triangles through i = (A³)_ii / 2.
fprintf('  - Computing clustering coefficient...\n');

adjacencyMatrix = double(adjacency(G) ~= 0);
adjacencyMatrix(1:numNodes+1:end) = 0;                     % Remove self-loops
neighbourCount  = full(sum(adjacencyMatrix, 2));
triangleCount   = full(sum((adjacencyMatrix * adjacencyMatrix) .* adjacencyMatrix, 2)) / 2;

clusteringCoeffs = zeros(numNodes, 1);
hasPairs = neighbourCount >= 2;
clusteringCoeffs(hasPairs) = triangleCount(hasPairs) ./ ...
    (neighbourCount(hasPairs) .* (neighbourCount(hasPairs) - 1) / 2);

metrics.clustering.coefficients         = clusteringCoeffs;
metrics.clustering.mean                 = mean(clusteringCoeffs);
metrics.clustering.median               = median(clusteringCoeffs);
metrics.clustering.std                  = std(clusteringCoeffs);
metrics.clustering.max                  = max(clusteringCoeffs);
metrics.clustering.nodesWithClustering  = sum(clusteringCoeffs > 0);
metrics.clustering.percentClustered     = 100 * metrics.clustering.nodesWithClustering / numNodes;

fprintf('    Mean clustering coefficient: %.4f\n',   metrics.clustering.mean);
fprintf('    Median clustering coefficient: %.4f\n', metrics.clustering.median);
fprintf('    Nodes with clustering: %d (%.1f%%)\n', ...
    metrics.clustering.nodesWithClustering, metrics.clustering.percentClustered);


%% --- 7. Mesh-Like vs Tree-Like Character --------------------------------
% Mesh coefficient: excess edges relative to a spanning forest (tree = 0).
% Kansky / Garrison–Marble planar network indices:
%     alpha = (E − N + P) / (2N − 5)    observed loops / max planar loops
%     beta  = E / N                     edges per node
%     gamma = E / (3(N − 2))            observed edges / max planar edges
fprintf('  - Computing mesh-like vs tree-like character...\n');

treeEdges       = numNodes - numComponents;        % Edges in a spanning forest
excessEdges     = numSegments - treeEdges;         % = independent loops
meshCoefficient = excessEdges / treeEdges;

maxPlanarLoops = 2 * numNodes - 5;
if maxPlanarLoops > 0
    alphaIndex = excessEdges / maxPlanarLoops;
else
    alphaIndex = 0;
end
betaIndex  = numSegments / numNodes;
gammaIndex = numSegments / (3 * (numNodes - 2));

meshTreeOverall = meshCoefficientWeight * meshCoefficient + alphaIndexWeight * alphaIndex;

if meshTreeOverall < 0.1
    meshTreeCharacter = 'Strongly tree-like';
elseif meshTreeOverall < 0.3
    meshTreeCharacter = 'Moderately tree-like';
elseif meshTreeOverall < 0.6
    meshTreeCharacter = 'Balanced tree-mesh';
elseif meshTreeOverall < 0.9
    meshTreeCharacter = 'Moderately mesh-like';
else
    meshTreeCharacter = 'Strongly mesh-like';
end

metrics.meshTree.overallRatio      = meshTreeOverall;
metrics.meshTree.character         = meshTreeCharacter;
metrics.meshTree.fundamentalCycles = excessEdges;
metrics.meshTree.meshCoefficient   = meshCoefficient;
metrics.meshTree.excessEdges       = excessEdges;
metrics.meshTree.alphaIndex        = alphaIndex;
metrics.meshTree.betaIndex         = betaIndex;
metrics.meshTree.gammaIndex        = gammaIndex;

fprintf('    Fundamental cycles (loops): %d\n', excessEdges);
fprintf('    Mesh coefficient: %.4f\n',         meshCoefficient);
fprintf('    Alpha index: %.4f\n',              alphaIndex);
fprintf('    Beta index: %.4f\n',               betaIndex);
fprintf('    Gamma index: %.4f\n',              gammaIndex);
fprintf('    Overall mesh-tree ratio: %.4f (%s)\n', meshTreeOverall, meshTreeCharacter);


%% --- 8. Fractal Dimension (Box Counting) --------------------------------
% For each box size r, count occupied boxes N(r). The fractal dimension is
% the negative slope of log N(r) versus log r. Each segment is sampled at
% intervals of r/2 so that no box it crosses is missed.
fprintf('  - Computing fractal dimension...\n');

boxSizes  = logspace(log10(minBoxSizeFraction * domainSize), ...
                     log10(maxBoxSizeFraction * domainSize), numBoxSizes);   % mm
boxCounts = zeros(numBoxSizes, 1);

for b = 1:numBoxSizes
    boxSize   = boxSizes(b);
    gridRes   = ceil(domainSize / boxSize);
    occupied  = false(gridRes, gridRes);

    for s = 1:numSegments
        nSamples = max(ceil(segmentLengths(s) / (boxSize / 2)), 2);
        t        = linspace(0, 1, nSamples)';
        points   = segP1(s, :) .* (1 - t) + segP2(s, :) .* t;
        xIdx     = min(max(ceil(points(:, 1) / boxSize), 1), gridRes);
        yIdx     = min(max(ceil(points(:, 2) / boxSize), 1), gridRes);
        occupied(sub2ind([gridRes, gridRes], yIdx, xIdx)) = true;
    end

    boxCounts(b) = nnz(occupied);
end

logBoxSizes  = log(boxSizes(:));
logBoxCounts = log(boxCounts(:));
validBoxes   = isfinite(logBoxSizes) & isfinite(logBoxCounts) & (boxCounts > 0);

metrics.complexity.boxSizes   = boxSizes;
metrics.complexity.boxCounts  = boxCounts;
metrics.complexity.validBoxes = validBoxes;

if sum(validBoxes) >= 3     % At least 3 points for a meaningful fit
    fitCoeffs        = polyfit(logBoxSizes(validBoxes), logBoxCounts(validBoxes), 1);
    fractalDimension = -fitCoeffs(1);

    fittedCounts = polyval(fitCoeffs, logBoxSizes(validBoxes));
    ssResidual   = sum((logBoxCounts(validBoxes) - fittedCounts).^2);
    ssTotal      = sum((logBoxCounts(validBoxes) - mean(logBoxCounts(validBoxes))).^2);
    fitRSquared  = 1 - ssResidual / ssTotal;

    metrics.complexity.fractalDimension = fractalDimension;
    metrics.complexity.fractalFitR2     = fitRSquared;

    fprintf('    Fractal dimension: %.3f (R^2 = %.3f)\n', fractalDimension, fitRSquared);
else
    metrics.complexity.fractalDimension = NaN;
    metrics.complexity.fractalFitR2     = NaN;
    fprintf('    WARNING: Too few valid box sizes for fractal dimension\n');
end


%% --- 9. Tortuosity Index ------------------------------------------------
% Each segment is a straight line, so per-segment tortuosity is always 1.
% Tortuosity is therefore measured per vessel: the chain of segments that
% runs between two anchor nodes (branch points or terminals, degree ≠ 2)
% through intermediate degree-2 nodes.
%     tortuosity = (sum of segment lengths along the chain) / (chord length)
% Closed chains that return to their starting anchor (chord ≈ 0) and pure
% degree-2 rings with no anchor are excluded.
fprintf('  - Computing vessel tortuosity...\n');

incidentSegments = cell(numNodes, 1);
for k = 1:numSegments
    incidentSegments{networkSegments(k, 1)}(end+1) = k;
    incidentSegments{networkSegments(k, 2)}(end+1) = k;
end

segmentVisited    = false(numSegments, 1);
vesselPathLength  = [];
vesselChordLength = [];
anchorNodes       = find(nodeDegree ~= 2);

for a = anchorNodes'
    for startSeg = incidentSegments{a}
        if segmentVisited(startSeg)
            continue;
        end

        % Walk along the chain until the next anchor node
        pathLength  = 0;
        currentNode = a;
        currentSeg  = startSeg;
        while true
            segmentVisited(currentSeg) = true;
            pathLength = pathLength + segmentLengths(currentSeg);

            if networkSegments(currentSeg, 1) == currentNode
                currentNode = networkSegments(currentSeg, 2);
            else
                currentNode = networkSegments(currentSeg, 1);
            end

            if nodeDegree(currentNode) ~= 2
                break;      % Reached a branch point or terminal
            end

            nextSegs = incidentSegments{currentNode};
            nextSegs = nextSegs(~segmentVisited(nextSegs));
            if isempty(nextSegs)
                break;
            end
            currentSeg = nextSegs(1);
        end

        vesselPathLength(end+1, 1)  = pathLength;                                           %#ok<SAGROW>
        vesselChordLength(end+1, 1) = norm(networkNodes(currentNode, :) - networkNodes(a, :)); %#ok<SAGROW>
    end
end

validVessels     = vesselChordLength > 1e-9;
tortuosityValues = vesselPathLength(validVessels) ./ vesselChordLength(validVessels);

metrics.complexity.numVessels       = numel(tortuosityValues);
metrics.complexity.tortuosityMean   = mean(tortuosityValues);
metrics.complexity.tortuosityMedian = median(tortuosityValues);
metrics.complexity.tortuosityStd    = std(tortuosityValues);
metrics.complexity.tortuosityMax    = max([tortuosityValues; NaN]);
metrics.complexity.tortuosityValues = tortuosityValues;

fprintf('    Vessels (branch point to branch point): %d\n', metrics.complexity.numVessels);
fprintf('    Mean tortuosity: %.3f +/- %.3f\n', ...
    metrics.complexity.tortuosityMean, metrics.complexity.tortuosityStd);


%% --- 10. Hierarchical Order ---------------------------------------------
% Vessel order of a node = hop distance to the nearest terminal (degree-1)
% node. Higher orders sit deeper inside the network.
fprintf('  - Computing hierarchical order...\n');

terminalNodes = find(nodeDegree == 1);

if ~isempty(terminalNodes)
    distFromTerminals = distances(G, terminalNodes);       % [T × N]
    vesselOrders      = min(distFromTerminals, [], 1)';
    finiteOrders      = vesselOrders(isfinite(vesselOrders));

    metrics.complexity.vesselOrders      = vesselOrders;
    metrics.complexity.maxVesselOrder    = max(finiteOrders);
    metrics.complexity.meanVesselOrder   = mean(finiteOrders);
    metrics.complexity.orderDistribution = histcounts(finiteOrders, 0:max(finiteOrders)+1);

    fprintf('    Maximum vessel order: %d\n', metrics.complexity.maxVesselOrder);
    fprintf('    Mean vessel order: %.2f\n',  metrics.complexity.meanVesselOrder);
else
    metrics.complexity.vesselOrders      = [];
    metrics.complexity.maxVesselOrder    = NaN;
    metrics.complexity.meanVesselOrder   = NaN;
    metrics.complexity.orderDistribution = [];
    fprintf('    No terminal nodes found - hierarchy not computed\n');
end


%% --- 11. Spatial Heterogeneity (Lacunarity) -----------------------------
% A coarse density map counts segment sample points per grid cell. For each
% window size, lacunarity = variance / mean² of the window sums over all
% sliding-window positions. Higher values indicate gappier, more
% heterogeneous vessel coverage.
fprintf('  - Computing spatial heterogeneity (lacunarity)...\n');

densityMap = zeros(densityGridSize, densityGridSize);
cellSize   = domainSize / densityGridSize;

for s = 1:numSegments
    nSamples = max(ceil(segmentLengths(s) / (cellSize / 2)), 2);
    t        = linspace(0, 1, nSamples)';
    points   = segP1(s, :) .* (1 - t) + segP2(s, :) .* t;
    xIdx     = min(max(ceil(points(:, 1) / cellSize), 1), densityGridSize);
    yIdx     = min(max(ceil(points(:, 2) / cellSize), 1), densityGridSize);
    densityMap = densityMap + accumarray([yIdx, xIdx], 1, [densityGridSize, densityGridSize]);
end

lacunarityByScale = NaN(numel(lacunarityWindowSizes), 1);
for w = 1:numel(lacunarityWindowSizes)
    windowSize = lacunarityWindowSizes(w);
    if windowSize > densityGridSize
        continue;
    end
    windowSums = conv2(densityMap, ones(windowSize), 'valid');
    if mean(windowSums(:)) > 0
        lacunarityByScale(w) = var(windowSums(:)) / mean(windowSums(:))^2;
    end
end

metrics.complexity.densityMap        = densityMap;
metrics.complexity.lacunarityByScale = lacunarityByScale;
metrics.complexity.lacunarityMean    = mean(lacunarityByScale(~isnan(lacunarityByScale)));

fprintf('    Mean lacunarity: %.3f\n', metrics.complexity.lacunarityMean);


%% --- 12. Betweenness Centrality -----------------------------------------
% Computed on the simple graph (parallel edges and self-loops removed) so
% that duplicate segments do not inflate shortest-path counts.
fprintf('  - Computing betweenness centrality...\n');

if numNodes <= betweennessMaxNodes
    betweennessValues = centrality(simplify(G), 'betweenness');
    criticalThreshold = percentileValue(betweennessValues, criticalNodePercentile);
    numCriticalNodes  = sum(betweennessValues > criticalThreshold);

    metrics.complexity.betweennessValues   = betweennessValues;
    metrics.complexity.betweennessMean     = mean(betweennessValues);
    metrics.complexity.betweennessMax      = max(betweennessValues);
    metrics.complexity.betweennessStd      = std(betweennessValues);
    metrics.complexity.criticalNodes       = numCriticalNodes;
    metrics.complexity.criticalNodesPct    = 100 * numCriticalNodes / numNodes;

    fprintf('    Mean betweenness centrality: %.2f\n', metrics.complexity.betweennessMean);
    fprintf('    Critical nodes (top %d%%): %d (%.1f%%)\n', ...
        100 - criticalNodePercentile, numCriticalNodes, metrics.complexity.criticalNodesPct);
else
    metrics.complexity.betweennessValues = [];
    metrics.complexity.betweennessMean   = NaN;
    metrics.complexity.betweennessMax    = NaN;
    metrics.complexity.betweennessStd    = NaN;
    metrics.complexity.criticalNodes     = NaN;
    metrics.complexity.criticalNodesPct  = NaN;
    fprintf('    Network too large for exact betweenness (> %d nodes)\n', betweennessMaxNodes);
end

% Store graph objects for downstream use
metrics.graph                 = G;
metrics.largestComponentGraph = GLargest;

fprintf('\nMetric calculation complete.\n\n');


%% --- Summary Table ------------------------------------------------------
% One row of scalar metrics, convenient for comparing network realisations
% (append rows from several models with vertcat before writing).
summaryTable = table( ...
    string(modelName), numNodes, numSegments, ...
    metrics.vesselDensity, ...
    metrics.diameter.mean * 1000, metrics.diameter.std * 1000, ...
    metrics.segmentLength.mean * 1000, ...
    metrics.totalVesselLength, metrics.vesselLengthDensity, ...
    metrics.connectivity.numLoops, metrics.connectivity.loopDensity, ...
    metrics.connectivity.meanDegree, ...
    metrics.topology.meanPathLength, metrics.topology.networkDiameter, ...
    metrics.clustering.mean, ...
    metrics.meshTree.meshCoefficient, metrics.meshTree.alphaIndex, ...
    metrics.meshTree.betaIndex, metrics.meshTree.gammaIndex, ...
    metrics.meshTree.overallRatio, ...
    metrics.complexity.fractalDimension, ...
    metrics.complexity.tortuosityMean, ...
    metrics.complexity.maxVesselOrder, ...
    metrics.complexity.lacunarityMean, ...
    metrics.complexity.betweennessMean, ...
    'VariableNames', { ...
    'model', 'numNodes', 'numSegments', ...
    'vesselDensity_perMm2', ...
    'diameterMean_um', 'diameterSD_um', ...
    'segmentLengthMean_um', ...
    'totalVesselLength_mm', 'vesselLengthDensity_mmPerMm2', ...
    'numLoops', 'loopDensity_perMm2', ...
    'meanNodeDegree', ...
    'meanPathLength_hops', 'networkDiameter_hops', ...
    'meanClustering', ...
    'meshCoefficient', 'alphaIndex', ...
    'betaIndex', 'gammaIndex', ...
    'meshTreeOverall', ...
    'fractalDimension', ...
    'tortuosityMean', ...
    'maxVesselOrder', ...
    'lacunarityMean', ...
    'betweennessMean'});

disp(summaryTable);


%% --- Visualisation: Nine-Panel Summary Figure ---------------------------
% Layout (3 × 3 grid):
%   Row 1:  network structure | diameter histogram | segment-length histogram
%   Row 2:  node-degree bar   | connectivity map (spans two columns)
%   Row 3:  vessel order      | betweenness        | mesh–tree indices

figWidthCm  = figWidthMm  / 10;
figHeightCm = figHeightMm / 10;

fig = figure('Color', 'white', 'Units', 'centimeters', ...
    'Position', [1, 1, figWidthCm, figHeightCm]);

% Panel positions [left, bottom, width, height] in normalised units
rowHeight    = 0.22;
colWidth     = 0.24;
hSpacing     = 0.10;
vSpacing     = 0.10;
leftMargin   = 0.06;
bottomMargin = 0.08;

panelPositions = cell(3, 3);
for row = 1:3
    for col = 1:3
        left   = leftMargin   + (col - 1) * (colWidth  + hSpacing);
        bottom = bottomMargin + (3 - row) * (rowHeight + vSpacing);
        panelPositions{row, col} = [left, bottom, colWidth, rowHeight];
    end
end

% --- Panel 1: Network structure ------------------------------------------
% Colour runs red (inlet) → blue (outlet); width scales with diameter.
subplot('Position', panelPositions{1, 1});
hold on;
for i = 1:numSegments
    colorInterp = segmentMidX(i) / domainSize;
    lineColor   = [1 - 0.7 * colorInterp, 0.2, 0.8 * colorInterp];
    lineWidth   = max(minNetworkLineWidth, segmentDiameters(i) * 1000 * networkLineWidthPerUm);
    plot([segP1(i, 1), segP2(i, 1)], [segP1(i, 2), segP2(i, 2)], ...
        'Color', lineColor, 'LineWidth', lineWidth);
end
plot(networkNodes(:, 1), networkNodes(:, 2), 'k.', 'MarkerSize', 1);
axis([0, domainSize, 0, domainSize]);
xlabel('X position (mm)', 'FontSize', fontSize, 'FontName', fontName);
ylabel('Y position (mm)', 'FontSize', fontSize, 'FontName', fontName);
title('Network Structure', 'FontSize', fontSize, 'FontName', fontName);
box off;
set(gca, 'FontName', fontName, 'FontSize', fontSize, 'LineWidth', 0.5);

% --- Panel 2: Diameter distribution --------------------------------------
subplot('Position', panelPositions{1, 2});
histogram(segmentDiameters * 1000, 20, 'FaceColor', tolMuted{1}, ...
    'EdgeColor', 'none', 'FaceAlpha', 0.7);
hold on;
yLimits = ylim;
plot([metrics.diameter.mean, metrics.diameter.mean] * 1000, yLimits, '--', ...
    'Color', tolMuted{7}, 'LineWidth', 1);
xlabel('Vessel diameter (\mum)', 'FontSize', fontSize, 'FontName', fontName);
ylabel('Frequency', 'FontSize', fontSize, 'FontName', fontName);
title(sprintf('Diameter Distribution\nMean: %.2f \\pm %.2f \\mum', ...
    metrics.diameter.mean * 1000, metrics.diameter.std * 1000), ...
    'FontSize', fontSize, 'FontName', fontName);
box off;
set(gca, 'FontName', fontName, 'FontSize', fontSize, 'TickDir', 'out', 'LineWidth', 0.5);

% --- Panel 3: Segment length distribution --------------------------------
subplot('Position', panelPositions{1, 3});
histogram(segmentLengths * 1000, 20, 'FaceColor', tolMuted{6}, ...
    'EdgeColor', 'none', 'FaceAlpha', 0.7);
xlabel('Segment length (\mum)', 'FontSize', fontSize, 'FontName', fontName);
ylabel('Frequency', 'FontSize', fontSize, 'FontName', fontName);
title(sprintf('Segment Length Distribution\nMean: %.0f \\pm %.0f \\mum', ...
    metrics.segmentLength.mean * 1000, metrics.segmentLength.std * 1000), ...
    'FontSize', fontSize, 'FontName', fontName);
box off;
set(gca, 'FontName', fontName, 'FontSize', fontSize, 'TickDir', 'out', 'LineWidth', 0.5);

% --- Panel 4: Node degree distribution -----------------------------------
subplot('Position', panelPositions{2, 1});
uniqueDegrees = unique(nodeDegree);
degreeCounts  = histcounts(nodeDegree, [uniqueDegrees; max(uniqueDegrees) + 1]);
bar(uniqueDegrees, degreeCounts, 'FaceColor', tolMuted{4}, 'EdgeColor', 'none', ...
    'FaceAlpha', 0.7, 'BarWidth', 0.8);
xlabel('Node degree', 'FontSize', fontSize, 'FontName', fontName);
ylabel('Frequency', 'FontSize', fontSize, 'FontName', fontName);
title('Node Degree Distribution', 'FontSize', fontSize, 'FontName', fontName);
xlim([min(uniqueDegrees) - 0.5, max(uniqueDegrees) + 0.5]);
box off;
set(gca, 'FontName', fontName, 'FontSize', fontSize, 'TickDir', 'out', 'LineWidth', 0.5);

% --- Panels 5–6: Connectivity map (spans two columns) --------------------
% Shifted slightly left and widened to make room for the colour bar.
subplot('Position', [panelPositions{2, 2}(1) - 0.1, panelPositions{2, 2}(2), ...
    colWidth * 2 + hSpacing + 0.04, rowHeight]);
plot(G, 'XData', networkNodes(:, 1), 'YData', networkNodes(:, 2), ...
    'NodeCData', nodeDegree, 'MarkerSize', 2, ...
    'EdgeColor', [0.7, 0.7, 0.7], 'LineWidth', 0.5, 'EdgeAlpha', 0.5);
colormap(gca, jet);
cb = colorbar;
cb.FontSize = fontSize;
cb.FontName = fontName;
cbPosition  = cb.Position;
cb.Position = [cbPosition(1), cbPosition(2), cbPosition(3) * 0.4, cbPosition(4)];
title('Network Connectivity (Node Degree)', 'FontSize', fontSize, 'FontName', fontName);
xlabel('X (mm)', 'FontSize', fontSize, 'FontName', fontName);
ylabel('Y (mm)', 'FontSize', fontSize, 'FontName', fontName);
axis equal tight;
box off;
set(gca, 'FontName', fontName, 'FontSize', fontSize, 'LineWidth', 0.5);

% --- Panel 7: Vessel order distribution ----------------------------------
subplot('Position', panelPositions{3, 1});
if ~isnan(metrics.complexity.maxVesselOrder)
    bar(0:numel(metrics.complexity.orderDistribution) - 1, ...
        metrics.complexity.orderDistribution, ...
        'FaceColor', tolMuted{3}, 'EdgeColor', 'none', 'FaceAlpha', 0.7);
    xlabel('Vessel order', 'FontSize', fontSize, 'FontName', fontName);
    ylabel('Number of nodes', 'FontSize', fontSize, 'FontName', fontName);
    title(sprintf('Hierarchical Order\nMax order: %d', metrics.complexity.maxVesselOrder), ...
        'FontSize', fontSize, 'FontName', fontName);
else
    text(0.5, 0.5, 'No terminal nodes', 'HorizontalAlignment', 'center', ...
        'FontSize', fontSize, 'FontName', fontName);
    axis off;
end
box off;
set(gca, 'FontName', fontName, 'FontSize', fontSize, 'TickDir', 'out', 'LineWidth', 0.5);

% --- Panel 8: Betweenness centrality -------------------------------------
subplot('Position', panelPositions{3, 2});
if ~isnan(metrics.complexity.betweennessMean)
    histogram(betweennessValues, 20, 'FaceColor', tolMuted{7}, ...
        'EdgeColor', 'none', 'FaceAlpha', 0.7);
    xlabel('Betweenness centrality', 'FontSize', fontSize, 'FontName', fontName);
    ylabel('Frequency', 'FontSize', fontSize, 'FontName', fontName);
    title(sprintf('Betweenness Centrality\nMean: %.1f', metrics.complexity.betweennessMean), ...
        'FontSize', fontSize, 'FontName', fontName);
else
    text(0.5, 0.5, 'Network too large', 'HorizontalAlignment', 'center', ...
        'FontSize', fontSize, 'FontName', fontName);
    axis off;
end
box off;
set(gca, 'FontName', fontName, 'FontSize', fontSize, 'TickDir', 'out', 'LineWidth', 0.5);

% --- Panel 9: Mesh–tree character indices --------------------------------
subplot('Position', panelPositions{3, 3});
meshTreeLabels = {'Mesh coef.', 'Alpha', 'Beta - 1', 'Gamma'};
meshTreeValues = [meshCoefficient, alphaIndex, betaIndex - 1, gammaIndex];
bar(meshTreeValues, 'FaceColor', tolMuted{5}, 'EdgeColor', 'none', 'FaceAlpha', 0.7);
set(gca, 'XTickLabel', meshTreeLabels);
ylabel('Index value', 'FontSize', fontSize, 'FontName', fontName);
title(sprintf('Mesh-Tree Character\nOverall: %.3f', meshTreeOverall), ...
    'FontSize', fontSize, 'FontName', fontName);
box off;
set(gca, 'FontName', fontName, 'FontSize', fontSize, 'TickDir', 'out', 'LineWidth', 0.5);


%% --- Save Results -------------------------------------------------------
% Requires ./Statistics/ and ./Model_Images/ (created by S0_setup_dirs.m).
if saveResults == 1
    save(append("./Statistics/", modelName, "_metrics.mat"), 'metrics');
    writetable(summaryTable, append("./Statistics/", modelName, "_summary.csv"));

    exportgraphics(fig, append("./Statistics/Statistics_", modelName, ".png"), ...
        'Resolution', 300);
    exportgraphics(fig, append("./Statistics/Statistics_", modelName, ".eps"), ...
        'ContentType', 'vector');

    fprintf('Metrics saved to: ./Statistics/%s_metrics.mat\n', modelName);
    fprintf('Summary saved to: ./Statistics/%s_summary.csv\n', modelName);
    fprintf('Figure saved to:  ./Statistics/Statistics_%s.png/.eps\n', modelName);
end


%% ========================================================================
%  HELPER FUNCTIONS
%  ========================================================================

function q = percentileValue(x, p)
% PERCENTILEVALUE  p-th percentile (0–100) of x by linear interpolation.

    x = sort(x(:));
    n = numel(x);
    if n == 0
        q = NaN;
        return;
    end

    position = (p / 100) * n + 0.5;            % Fractional index into sorted x
    position = min(max(position, 1), n);
    lowIdx   = floor(position);
    highIdx  = ceil(position);
    q        = x(lowIdx) + (position - lowIdx) * (x(highIdx) - x(lowIdx));
end
