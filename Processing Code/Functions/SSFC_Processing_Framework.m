function [ ] = SSFC_Processing_Framework( proc_mode, ...
        save_intermediaries_flag, img_save_type, bit_depth, file_path, ...
        pixel_size, pos_file_path, calibration_folder, wavelength_range )
%% Spectrally-Split Swept Field Confocal Processing Framework
%   By: Niklas Gahm
%   2018/08/01
%
%   This is a framework that loads up the needed images to be processed and
%   reconstructed for a spectrally-split swept field confocal system.
% 
%   2018/08/01 - Started 
%   2020/11/02 - Updated for Basic TXYZ Data Handling
% 
%   To-Do:
%       - Potentially add a splitting mode for TXYZ data




%% Setup the Workspace
format longe; 

automated_spectral_finding_flag = 0;
spectral_finding_granularity = 10;
% spectral_boundary = [490,570];
spectral_boundary = [500, 580];

automated_line_detection_flag = 0;
num_bands = 32;

data_order = 'TXYZ'; % Supports 'XYZT and TXYZ' Default is 'XYZT'


%% Calculated Variables
max_int = (2^bit_depth)-1;


%% Navigation Setup
fprintf('\n\nGenerating Paths\n');
addpath('Functions');
addpath('Functions\bfmatlab');
home_path = pwd;


%% Generate Necessary Arch Paths and Extract Information from Folder Name
[ run_name, file_path, arch_path] = ...
    arch_path_generator_SSFC_v2( file_path );


%% Load in Images
fprintf('\nLoading Sub-Images\n');
[ img_sets, xml_name, env_name, img_file_type, xyz_map ] = ...
    img_loader_SSFC_v2( file_path, pos_file_path );


%% Calibration Spectra Map Constructor 
fprintf('\nGenerating Calibration Map\n');
[calibration_map, prism_angle, band_map, wavelength_range] = ...
    SSFC_calibration_spectra_constructor_v2( wavelength_range, ...
    calibration_folder, automated_line_detection_flag, num_bands);


%% Sub Image Straightener 
fprintf('\nStraightening Sub Images\n');
img_sets = SSFC_straightener_v4( img_sets, prism_angle );


%% Spectral Boundary Finding
if automated_spectral_finding_flag == 1
    fprintf('\nFinding Spectral Bounds\n');
    spectral_boundary = spectral_boundary_finder(img_sets, ...
        calibration_map, spectral_finding_granularity);
end


%% Reconstruct  
fprintf('\nConstructing Data Cubes\n');
[ img_sets ] = SSFC_data_cube_constructor_v3( ...
    img_sets, calibration_map, wavelength_range, band_map, ...
    spectral_boundary );


%% Assign Positional and Temporal Information 
fprintf('\nAssigning Spatio Temporal Information to Data Cubes\n');
[ img_sets ] = SSFC_spatiotemporal_assignment( img_sets, xyz_map, ...
    data_order);


%% Save Individual Spectral Image Stacks
if save_intermediaries_flag == 1
    fprintf('\nSaving Individual Spectral Stacks\n');
    spectral_stack_saver_SSFC(img_sets, file_path, img_save_type, ...
        bit_depth);
end


%% Tiling
img_cube = 0;
if strcmp(proc_mode, 'Image Stack') || strcmp(proc_mode, 'Video')
    fprintf('\nTiling Images\n');
    [img_cube] = SSFC_img_tiling(img_sets, xyz_map, pixel_size, ...
        band_map, data_order);
    
    
%% Save Tiled Raw Data
    fprintf('\nSaving Tiled Images\n');
    SSFC_tiled_saver(img_cube, file_path, bit_depth);
end


%% Render False Color Images 
fprintf('\nRendering False Color Images\n');
[ img_cube_false, img_sets ] = SSFC_false_color_renderer( ...
    img_cube, img_sets, proc_mode, wavelength_range );


%% Save Images
fprintf('\nSaving False Color Images\n');
SSFC_false_color_saver( img_cube_false, img_sets, proc_mode, file_path, ...
    bit_depth);


%% Confirm Completion
fprintf('\nProcessing Complete\n\n');


%% Return to Starting Point
cd(home_path);
end