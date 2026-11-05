% S0_setup_dirs.m
% =========================================================================
% Creates all required output directories for the µVasGen pipeline
% (stages S1–S7) and analysis utilities (A1–A3).
% Run this script once after cloning or downloading the repository.
%
% Usage:
%   >> S0_setup_dirs
% =========================================================================

dirs = {'Models', 'Electrical', 'Model_Images', 'COMSOL_API', ...
        'Hybrid_END_CFD', 'GDS', 'OpenSCAD', 'Statistics'};

for i = 1:numel(dirs)
    if ~exist(dirs{i}, 'dir')
        mkdir(dirs{i});
        fprintf('Created directory: %s\n', dirs{i});
    else
        fprintf('Directory already exists: %s\n', dirs{i});
    end
end

fprintf('\nSetup complete. All required directories are present.\n');
fprintf('Next step: run S1_Model_Generator.m to generate a network.\n');
