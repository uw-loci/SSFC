function [ img_sets ] = SSFC_data_cube_constructor_v3( ...
    img_sets, calibration_map, wavelength_range, band_map, spectral_boundary )
%% SSFC Data Cube Constructor
%   By: Niklas Gahm
%   2018/11/26
%
%   This script recombines the straightened sub-images into individual
%   spectral stacks
%
%
%   2018/09/24 - Started
%   2018/09/24 - Finished Placeholder
%   2018/11/15 - Finished
%   2019/06/19 - Finished Version 3




%% Convert Calibration Map into Spectral Bins 
% Since the Calibration Map is in wavelength with units of nm it is safe to
% assume that spectral binning will be significantly lower than the
% shortest wavelength in the system

% Initialize bin masks
bin_masks = zeros(size(calibration_map, 1), size(calibration_map, 2), ...
    numel(spectral_boundary) + 1);

% Setup bin bounds
if wavelength_range(1) < wavelength_range(2)
    bin_bounds = [wavelength_range(1), sort(spectral_boundary), ...
        wavelength_range(2)];
else
    wavelength_range = flip(wavelength_range);
    bin_bounds = [wavelength_range(1), sort(spectral_boundary, ...
        'descend'), wavelength_range(2)];
end

% Remove the last bound since it is superfluous for the processing
bin_bounds = bin_bounds(1:(end-1));

% Sequentially convert calibration map into bin masks
for i = 1:(numel(spectral_boundary) + 1)
    temp = calibration_map; 
    temp(temp < bin_bounds(end-(i-1))) = 0;
    temp(temp > 0) = 1;
    bin_masks(:,:,i) = temp;
    calibration_map(calibration_map >= bin_bounds(end-(i-1))) = 0;
end

% Sequentally convert the band map into band masks and get the band
% starting index
num_bands = max(max(band_map));
band_masks = zeros(size(band_map, 1), size(band_map, 2), num_bands);
band_start_ind = zeros(1, num_bands);
for i = 1:num_bands
    temp = band_map;
    temp(temp < (num_bands - (i-1))) = 0;
    temp(temp > 0) = 1;
    band_masks(:,:,i) = temp;
    band_map(band_map >= (num_bands - (i-1))) = 0;
    temp = sum(temp,1);
    for j = 1:numel(temp)
        if temp(j) > 0 
            band_start_ind(i) = j;
            break;
        end
    end
end


%% Separate Each Sub-Image Into the Binned Components 
sub_img_waitbar = waitbar((1/numel(img_sets)), 'Constructing Data Cubes');
for i = 1:numel(img_sets)
    waitbar((i/numel(img_sets)), sub_img_waitbar);
    % Initialize Output Image
    img_sets(i).images_reconstructed = ...
        zeros(size(img_sets(i).images_straightened{1}, 1), ...
        size(img_sets(i).images_straightened{1}, 2), 1, ...
        (numel(spectral_boundary) + 1));
    
    % Process Each Sub-Image
    for j = 1:numel(img_sets(i).images_straightened)
        for k = 1:(numel(spectral_boundary) + 1)
            temp = img_sets(i).images_straightened{j} .* bin_masks(:,:,k);
            for m = 1:num_bands
                temp_2 = temp .* band_masks(:,:,m);
                temp_2 = temp_2(:,any(temp_2,1));
                img_sets(i).images_reconstructed(:, ((j-1) + ...
                    band_start_ind(m)), 1, k) = mean(temp_2, 2);
            end
        end
    end
    
end
close(sub_img_waitbar);


%% Clean Memory Usage
% img_sets.images is not used after this point, but still hogs memory so 
% deleting it is advantageous. 
img_sets = rmfield(img_sets, 'images_straightened');

end
