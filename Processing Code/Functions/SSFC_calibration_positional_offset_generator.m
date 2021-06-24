function [ positional_offsets ] = ...
    SSFC_calibration_positional_offset_generator( ...
    loc_ref, avg_dist_btw_bands, avg_starting_offset, calibration_set, ...
    offsets, strongest_line_ind)
%% SSFC Calibration Spectra Positional Offset Generator
%   By: Niklas Gahm
%   2021/06/20
%
%   This script use the "true" band starting positions from the calibration
%   files to build the positional offset vector, which is used for
%   generating the spectral band map.
%
%
%   2021/06/20 - Started
%   2021/06/20 - Finished



%% Calculate Useful Constants
starting_offset = avg_starting_offset - fix(avg_starting_offset);
img_dim = size(calibration_set(1).image_rot, 1);

strongest_line_ind = strongest_line_ind + 1; 
% This accounts for the addition of the interpolated end-point wavelengths
% to the wavelengths vector. 

loc_ref = round(loc_ref + offsets(strongest_line_ind)); 
% Moves the location reference vector to the band start



%% Iteratively Fill the Positional Offset Vector
positional_offsets = ones(1, img_dim) * (avg_dist_btw_bands^2);
for i = 1:numel(loc_ref)
    
    % Check for Overlap
    overlap_flag = 0;
    overlap_region = 0;
    if positional_offsets(loc_ref(i)) ~= (avg_dist_btw_bands^2)
        overlap_flag = 1;
        overlap_region = loc_ref(i) : 1 : ...
            (loc_ref(i-1) + floor(avg_dist_btw_bands));
    end
    
    
    positional_offsets( ...
        loc_ref(i) : ((loc_ref(i) - 1) + floor(avg_dist_btw_bands))) = ...
        starting_offset:1:floor(avg_dist_btw_bands);
    
    
    
    %% Remove Overlapping Band Positions 
    if overlap_flag == 1
        positional_offsets(overlap_region) = avg_dist_btw_bands^2;
    end
end



%% Verify Size
positional_offsets = positional_offsets(1:img_dim);
end