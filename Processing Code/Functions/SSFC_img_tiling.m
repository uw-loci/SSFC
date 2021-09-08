function [ img_cube ] = SSFC_img_tiling( ...
    img_sets, xyz_map, pixel_size, band_map, data_order)
%% SSFC Image Tiler
%   By: Niklas Gahm
%   2018/11/26
%
%   This script tiles the ssfc images to generate an image cube. 
%   Input Dimensions are 'XYZT' or 'TXYZ'
%   Output Dimensions are XYZCT
% 
%   Specifically this script calculates some global variables then switches
%   the tiling algorithm used based on the order of the input dimensions.
%
%
%   2018/12/05 - Started
%   2020/10/20 - Updated for TXYZ




%% Variables
num_pos = numel(xyz_map);
spectral_bins = size(img_sets(1).images_reconstructed, 4);
num_t = numel(img_sets)/numel(xyz_map);


%% Calculate Number of Unique X Y Z Positions
unique_x = [];
unique_y = [];
unique_z = [];
for i = 1:num_pos
    unique_x_flag = 1;
    for j = 1:numel(unique_x)
        if xyz_map(i).x_pos == unique_x(j)
            unique_x_flag = 0;
        end
    end
    if unique_x_flag == 1
        unique_x = [unique_x, xyz_map(i).x_pos]; %#ok<*AGROW>
    end
    
    unique_y_flag = 1;
    for j = 1:numel(unique_y)
        if xyz_map(i).y_pos == unique_y(j)
            unique_y_flag = 0;
        end
    end
    if unique_y_flag == 1
        unique_y = [unique_y, xyz_map(i).y_pos]; %#ok<*AGROW>
    end
    
    unique_z_flag = 1;
    for j = 1:numel(unique_z)
        if xyz_map(i).z_pos == unique_z(j)
            unique_z_flag = 0;
        end
    end
    if unique_z_flag == 1
        unique_z = [unique_z, xyz_map(i).z_pos]; %#ok<*AGROW>
    end
end
num_x = numel(unique_x);
num_y = numel(unique_y);
num_z = numel(unique_z);

% Determine Direction and Sort Unique Positions
x_direction = '+X';
if sum(unique_x(2:end) - unique_x(1:(end-1))) < 0
    x_direction = '-X';
end
y_direction = '+Y';
if sum(unique_y(2:end) - unique_y(1:(end-1))) < 0
    y_direction = '-Y';
end
    
unique_x_sorted = sort(unique_x);
unique_y_sorted = sort(unique_y);
unique_z_sorted = sort(unique_z);



%% Determine 0 Padded Region in the X Dimension
% In case Final Band goes all the way to the Image Edge
pad_end = size(band_map,1);
pad_start = 0;
for i = 2:size(band_map,2)
    if (band_map(floor(size(band_map,1)/2), (i-1)) == 0) ...
            && (band_map(floor(size(band_map,1)/2), i) == 1)
        pad_start = i-1;
        
    elseif (band_map(floor(size(band_map,1)/2), (i-1)) == ...
            max(max(band_map))) ...
            && (band_map(floor(size(band_map,1)/2), i) == 0)
        pad_end = i;
        
    end
end



%% Calculate Pixel Offsets 
x_offset = abs(mean(unique_x_sorted(2:end) - unique_x_sorted(1:(end-1)))...
    / pixel_size) - abs(pad_start + (size(band_map,2) - pad_end));
y_offset = abs(mean(unique_y_sorted(2:end) - unique_y_sorted(1:(end-1)))...
    / pixel_size);



%% Tiling 
img_cube = [];

% Switch Tiling Algorithm Based on Data Order
switch data_order
    case 'XYZT'
        img_cube = SSFC_img_tiling_XYZT(img_sets, xyz_map, ...
            spectral_bins, num_x, num_y, num_z, num_t, unique_x_sorted, ...
            unique_y_sorted, unique_z_sorted, x_direction, y_direction, ...
            x_offset, y_offset, pad_start, pad_end);
    case 'TXYZ'
        img_cube = SSFC_img_tiling_TXYZ(img_sets, xyz_map, ...
            spectral_bins, num_x, num_y, num_z, num_t, unique_x_sorted, ...
            unique_y_sorted, unique_z_sorted, x_direction, y_direction, ...
            x_offset, y_offset, pad_start, pad_end);
        
    otherwise
        error('\nUnsupported Data Order.\n\n');
end
end