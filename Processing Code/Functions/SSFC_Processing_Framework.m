function [ ] = SSFC_Processing_Framework( ...
    proc_mode, spectral_binning, save_intermediaries_flag, ...
    img_save_type, bit_depth, file_path, overlap_percent, ...
    threshold_percent, pos_file_path, calibration_path, num_line, ...
    wavelength_range )
%% Spectrally-Split Swept Field Confocal Processing Framework
%   By: Niklas Gahm
%   2018/08/01
%
%   This is a framework that loads up the needed images to be processed and
%   reconstructed for a spectrally-split swept field confocal system.
% 
%   2018/08/01 - Started 
% 
%   To-Do:
%       - Enable 3D video processing. 




%% Setup the Workspace
format longe; 


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
    img_loader_SSFC( file_path, num_line, pos_file_path );


%% Generate Calibration Map
fprintf('\nGenerating Calibration Map\n');
[ calibration_map ] = SSFC_calibration_spectra_constructor_v2( ...
    wavelength_range, calibration_path );


%% Reconstruct  
fprintf('\nConstructing Data Cubes\n');
[ img_sets ] = SSFC_data_cube_constructor_v3( img_sets, ...
    spectral_binning, calibration_map, wavelength_range ); 


%% Save Individual Spectral Image Stacks
if save_intermediaries_flag == 1
    fprintf('\nSaving Individual Spectral Stacks\n');
    spectral_stack_saver_SSFC(img_sets, file_path, img_save_type, ...
        bit_depth);
end


% %% Tiling
% img_cube = 0;
% if strcmp(proc_mode, 'Image Stack') || strcmp(proc_mode, 'Video')
%     fprintf('\nTiling Images\n');
%     [img_cube] = SSFC_img_tiling(img_sets, xyz_map, overlap_percent, ...
%         file_path, home_path);
% end
% 
% 
% %% Render False Color Images 
% fprintf('\nRendering False Color Images\n');
% [ img_cube_false, img_sets ] = SSFC_false_color_renderer( ...
%     img_cube, img_sets, proc_mode, wavelength_range );
% 
% 
% %% Save Images
% fprintf('\nSaving False Color Images\n');
% SSFC_false_color_saver( img_cube_false, img_sets, proc_mode, file_path, ...
%     bit_depth);

%% Confirm Completion
fprintf('\nProcessing Complete\n\n');

%% Return to Starting Point
cd(home_path);
end

