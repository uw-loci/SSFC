function [ img_sets ] = SSFC_data_cube_constructor_v3( ...
    img_sets, spectral_binning, calibration_map, wavelength_range )
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
    spectral_binning);

% Calculate bin bounds
bin_bounds = linspace(wavelength_range(1), wavelength_range(2), ...
    (spectral_binning + 1));

% Remove the last bound since it is superfluous for the processing
bin_bounds = bin_bounds(1:(end-1));

% Sequentially convert calibration map into bin masks
for i = 1:spectral_binning
    bin_masks(:,:,i) = calibration_map;
    bin_masks(bin_masks(:,:,i)<bin_bounds(end-(i-1))) = 0;
    bin_masks(bin_masks(:,:,i)>0) = 1;
    calibration_map(calibration_map >= bin_bounds(end-(i-1))) = 0;
end



%% Separate Each Sub-Image Into the Binned Components 
for i = 1:numel(img_sets)
    % Initialize Output Image
    img_sets(i).images_reconstructed = ...
        zeros(size(img_sets(i).images{1}, 1), ...
        size(img_sets(i).images{1}, 2), 1, spectral_binning);
    
    % Process Each Sub-Image
    for j = 1:numel(img_sets(i).images)
        for k = 1:spectral_binning
            img_sets(i).images_reconstructed(:,:,:,k) = img_sets(i).images_reconstructed(:,:,:,k) + (bin_masks(:,:,k).*img_sets(i).images(j));
        end
    end
    
end


%% Clean Memory Usage
% img_sets.images is not used after this point, but still hogs memory so 
% deleting it is advantageous. 
img_sets = rmfield(img_sets, 'images');

end
