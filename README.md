# Microvascular Network Generator and Simulation Pipeline

**Authors:** Aref Valipour, Housley Lab, Georgia Institute of Technology  
**Year:** 2026   
**Repository:** [GitHub TBA]  
**Manuscript:** [DOI — TBA]

---

## Overview

This package is a MATLAB software pipeline that generates synthetic, physiologically realistic microvascular network graphs and propagates them through a complete simulation and fabrication export workflow. The pipeline implements the **Inverse Current to Diameter Trasform (ICDT)** method: vessel diameters are assigned via Murray's Law using an electrical circuit analogy, hydraulic resistance is computed and verified via SPICE simulation, and the resulting geometry is exported to COMSOL Multiphysics, GDSII photolithography masks, and OpenSCAD/STL files for two-photon polymerisation printing.

The seven pipeline scripts run in sequence (S1 → S7) and are designed to be modular — any stage can be re-run independently given the `.mat` file produced by its predecessor.

Three analysis utilities (A1 → A3) run on any network `.mat` file produced by the pipeline. They compute network statistics, draw a segment-index map, and generate COMSOL evaluation points for END-vs-CFD cross-validation.

---

## System Requirements

### Software dependencies

| Software | Version tested | Notes |
|---|---|---|
| MATLAB | R2023b (v23.2) | Older releases ≥ R2021a are expected to work |
| LTspice XVII | 24.x (ADI) | Free; Windows and macOS. Required for S2, S3, S5. |
| COMSOL Multiphysics | 6.x | Required only for import of S4/S5/A3 output files |
| GDS-MATLAB toolbox | Required for S6. See Installation. |
| OpenSCAD | 2021.01 or later | Required only to render S7 output |

No MATLAB toolboxes beyond base MATLAB are required. The Signal Processing Toolbox, Statistics Toolbox, and similar add-ons are **not** needed.

### Third-party MATLAB function (included)

`LTspice2Matlab.m` (Paul Wagner, 2009; Peter Feichtinger, 2015/2019) is included in this package. It is retrieved from MATLAB Central File Exchange (https://www.mathworks.com/matlabcentral/fileexchange/23394) and redistributed under its original BSD-compatible licence. See the file header for full attribution.

### Operating systems tested

- Windows 11

### Hardware

No non-standard hardware is required. All scripts run on a standard desktop or laptop. Networks with > 5,000 segments may require several minutes on lower-end machines (see Demo section for expected run times).

---

## Installation Guide

1. **Clone or download** this repository to a local directory.

2. **Install LTspice XVII** (free) from Analog Devices:  
   https://www.analog.com/en/resources/design-tools-and-calculators/ltspice-simulator.html  
   Note the installation path — you will need to paste it into the `ltspicePath` parameter in S2, S3, and S5 (see *Instructions for Use* below).

3. **Install the GDS-MATLAB toolbox** (required for S6 only):
   ```
   git clone https://github.com/ulfgri/gdsii-toolbox.git
   ```
   Add the toolbox folder and all subfolders to your MATLAB path:
   ```matlab
   addpath(genpath('/path/to/gdsii-toolbox'));
   ```

4. **Create the required output directories** in the repository root:
   ```matlab
   mkdir Models
   mkdir Electrical
   mkdir Model_Images
   mkdir COMSOL_API
   mkdir Hybrid_END_CFD
   mkdir GDS
   mkdir OpenSCAD
   mkdir Statistics
   ```
   A convenience script `S0_setup_dirs.m` is provided that creates all directories automatically.

5. **Add the repository root to your MATLAB path:**

6. Verify installation by running the demo (see Demo section).

**Typical installation time on a normal desktop computer:** 5–10 minutes (dominated by LTspice download and GDS toolbox clone).

---

## Directory Structure

```
µVasGen/
├── README.md                    ← This file
├── LICENSE.txt                  ← Software licence
├── S0_setup_dirs.m              ← Creates all required output directories
├── LTspice2Matlab.m             ← Third-party LTspice parser (included)
│
├── S1_Model_Generator.m         ← Stage 1: Stochastic network generation
├── S2_Automated_ICDT.m          ← Stage 2: Murray's Law diameter assignment (ICDT)
├── S3_Automated_END.m           ← Stage 3: Hydraulic resistance simulation (END)
├── S4_COMSOL_Pipeline.m         ← Stage 4: COMSOL geometry script export
├── S5_Integrated_Hybrid_END_CFD.m ← Stage 5: Hybrid END-CFD 
├── S6_GDS_Pipeline.m            ← Stage 6: GDSII photomask generation
├── S7_OpenSCAD_Pipeline.m       ← Stage 7: OpenSCAD/STL 3-D geometry script export
│
├── A1_Network_Statistics.m      ← Analysis: topological and morphometric statistics
├── A2_Segment_Map.m             ← Analysis: segment-index map (for choosing S5 segments)
├── A3_COMSOL_Eval_Points.m      ← Analysis: COMSOL evaluation points for END-vs-CFD
│
├── Models/                      ← Generated .mat network files
├── Electrical/                  ← SPICE netlists and .raw files
├── Model_Images/                ← Network visualisations, statistics figures, segment maps
├── COMSOL_API/                  ← COMSOL Java API geometry scripts and evaluation points
├── Hybrid_END_CFD/              ← Velocity maps and hybrid COMSOL scripts
├── GDS/                         ← GDSII photomask files
├── OpenSCAD/                    ← OpenSCAD geometry scripts
└── Statistics/                  ← Network metrics (.mat) and summary tables (.csv)
```

---

## Demo

A complete end-to-end demo using the included pre-generated network (`Models/model_0.mat`) is provided. This lets you verify the installation without waiting for S1 to run.

### Quick demo (S2 → S3 only, ~2 minutes)

1. Open `S2_Automated_ICDT.m`. Set:
   ```matlab
   modelName  = "model_0";
   ltspicePath = '"C:/Program Files/ADI/LTspice/LTspice.exe"'; % adjust to your install
   ```
   Run the script. Expected output: a histogram of vessel diameters (range ~5–100 µm) and a saved file `Models/model_0_ICDT.mat`.

2. Open `S3_Automated_END.m`. Set `modelName = "model_0_ICDT"`. Run. Expected output: `circuitResistanceTOhm` printed to the command window and a colour-coded flow map figure.

### Full pipeline demo (S1 → S7, ~10–15 minutes total)

Run each script in order S1 through S7, setting `modelName` consistently across scripts as described in *Instructions for Use*. The analysis utilities A1–A3 can be run at any point after S2.

### Expected outputs (demo network)

| Stage | Output file | Description |
|---|---|---|
| S1 | `Models/model_2.mat` | Network graph, ~300–600 segments |
| S2 | `Models/model_2_ICDT.mat` | Diameter-assigned network |
| S3 | Command window | Total resistance in TΩ; flow map figure |
| S4 | `COMSOL_API/Model_2_ICDT.txt` | COMSOL Java API script |
| S5 | `Hybrid_END_CFD/velocity-*.png` | Velocity map for selected segments |
| S6 | `GDS/FabricationMask_*.gds` | GDSII photomask |
| S7 | `OpenSCAD/*.txt` | OpenSCAD geometry script |
| A1 | `Statistics/*_metrics.mat`, `*_summary.csv`; `Model_Images/Statistics_*.png` | Network metrics and nine-panel summary figure |
| A2 | `Model_Images/SegmentMap_*.png` | Segment-index map and zoomed window |
| A3 | `COMSOL_API/*_EvalPoints_Flow.txt`, `*_EvalPoints_Pressure.txt` | COMSOL cut-point coordinates |

### Expected run time on a normal desktop computer

| Stage | Approximate time |
|---|---|
| S1 (network generation) | 1 s–5 min (depends on `maxIterations` and network density) |
| S2 (LTspice END diameter) | 1–30 s |
| S3 (hydraulic resistance) | 1–30 s |
| S4 (COMSOL export) | < 5 s |
| S5 (hybrid END-CFD) | 10–30 s |
| S6 (GDS mask) | < 10 s |
| S7 (OpenSCAD export) | < 5 s |
| A1 (network statistics) | 5–60 s (dominated by betweenness centrality) |
| A2 (segment map) | < 10 s |
| A3 (COMSOL evaluation points) | < 1 s |

---

## Instructions for Use

### Step 1 — Generate a network (S1)

Open `S1_Model_Generator.m`. Key parameters:

```matlab
experimentID      = 2;       % Integer ID appended to the output filename
saveResults       = 1;       % 1 = save to disk; 0 = preview only
randomSeed        = 0;       % 0 = new random network; nonzero = reproducible

domainSize        = 10;      % Square domain side length (mm)
stepSize          = 0.30;    % Tip advancement per iteration (mm)
branchProbability = 0.3;     % Base bifurcation probability [0, 1]

maxVesselDiameter = 200/1000; % Arteriole diameter at inlet/outlet (mm)
minVesselDiameter =  20/1000; % Capillary diameter at mid-domain (mm)
```

Run the script. Output: `Models/model_<experimentID>.mat`.

### Step 2 — Assign diameters via ICDT (S2)

Open `S2_Automated_ICDT.m`. Key parameters:

```matlab
modelName   = "model_2";     % Must match the output of S1 (without extension)
ltspicePath = '"D:/Program Files/ADI/LTspice/LTspice.exe"';  % ← EDIT THIS

targetMaxDiameter_m = 25;    % Target mean vessel diameter (µm)
murrayExponent      = 3;     % Murray's Law exponent (theoretical: 3)
```

**Important:** Update `ltspicePath` to match your LTspice installation. On Windows the default is `"C:/Program Files/ADI/LTspice/LTspice.exe"`. On macOS it is typically `"/Applications/LTspice.app/Contents/MacOS/LTspice"`.

Output: `Models/model_2_ICDT.mat` with physically scaled diameters.

### Step 3 — Hydraulic resistance simulation (S3)

Open `S3_Automated_END.m`. Set:

```matlab
modelName   = "model_2_ICDT";
ltspicePath = '...';          % Same path as S2
```

Output: `circuitResistanceTOhm` (total network hydraulic resistance) printed to the command window; colour-coded flow speed figure.

### Step 4 — COMSOL geometry export (S4)

Open `S4_COMSOL_Pipeline.m`. Set:

```matlab
modelName = "Model_2_ICDT";
```

Output: `COMSOL_API/Model_2_ICDT.txt`. To import into COMSOL: open COMSOL → Application Builder → paste the script contents into the Script Editor, or use LiveLink for MATLAB and call `model.geom("geom").run()`. To compare the COMSOL solution against S3, generate evaluation points with A3.

### Step 5 — Hybrid END-CFD velocity maps (S5)

Open `S5_Integrated_Hybrid_END_CFD.m`. Set:

```matlab
modelName     = "Model_2_ICDT";
segmentSubset = [22, 26, 30, 31];  % Segment indices to visualise (look these up with A2)
inletFlowRate = 1.67e-12;          % Device inlet flow rate (m³/s)
```

Output: velocity map PNGs and COMSOL scripts in `Hybrid_END_CFD/`.

### Step 6 — GDSII photomask (S6)

Open `S6_GDS_Pipeline.m`. Set `modelName` to match your network. Requires the GDS-MATLAB toolbox on the MATLAB path (see Installation). Output: `GDS/FabricationMask_<modelName>.gds`.

### Step 7 — OpenSCAD/STL export (S7)

Open `S7_OpenSCAD_Pipeline.m`. Set `modelName`. Output: `OpenSCAD/<modelName>.txt`. Open the file in OpenSCAD and export to STL for two-photon polymerisation or FDM printing.

---

## Analysis Utilities

These scripts are independent of the S1–S7 sequence and can be run on any network `.mat` file in `Models/`.

### A1 — Network statistics

Open `A1_Network_Statistics.m`. Set:

```matlab
modelName   = "model_2_ICDT";
saveResults = 1;
```

Computes vessel density, diameter and segment-length distributions, anastomotic loop count, shortest-path statistics, clustering coefficient, mesh–tree indices (mesh coefficient; Kansky alpha, beta, gamma), box-counting fractal dimension, vessel tortuosity (measured between branch points), hierarchical order, lacunarity, and betweenness centrality. Topology metrics are valid at any stage; diameter metrics are meaningful only after S2.

Output: `Statistics/<modelName>_metrics.mat` (full metrics struct), `Statistics/<modelName>_summary.csv` (one row of scalar metrics, convenient for comparing realisations), and a nine-panel figure `Model_Images/Statistics_<modelName>.png/.eps` (180 × 170 mm).

### A2 — Segment-index map

Open `A2_Segment_Map.m`. Set:

```matlab
modelName   = "model_2_ICDT";
zoomXLimits = [6.9, 7.5];    % mm from the inlet wall
zoomYLimits = [-0.3, 0.3];   % mm from the inlet–outlet centreline
```

Draws the network with every segment labelled by its index, plus a zoomed view of the chosen window. The indices of segments inside the zoom window are printed to the command window, ready to paste into `segmentSubset` in S5. Set `flipYAxis = 1` to match the orientation of the S5 velocity maps.

Output: `Model_Images/SegmentMap_<modelName>.png/.eps` and `..._zoom.png/.eps`.

### A3 — COMSOL evaluation points

Open `A3_COMSOL_Eval_Points.m`. Set `modelName` to the same model used in S4.

Writes two coordinate files (µm) for import into COMSOL as Cut Point 3D datasets: segment midpoints for flow evaluation and node positions for pressure evaluation. Row *i* corresponds to segment *i* (flow) or node *i* (pressure), so COMSOL results can be compared directly against the S3 branch currents and nodal voltages.

Output: `COMSOL_API/<modelName>_EvalPoints_Flow.txt` and `COMSOL_API/<modelName>_EvalPoints_Pressure.txt`.

---

## Licence

This software is released under the MIT Licence. See `LICENSE.txt` for full terms.

Third-party component: `LTspice2Matlab.m` is by Paul Wagner (2009) and Peter Feichtinger (2015, 2019), distributed under the terms of the MATLAB Central File Exchange licence. See the file header for details.

---

## Citation

If you use our platform in your research, please cite:

> Valipour A, et al. Integrated Framework for Multiscale Microvascular Models. *[Journal]*. [Year]. DOI: [to be added upon acceptance].
