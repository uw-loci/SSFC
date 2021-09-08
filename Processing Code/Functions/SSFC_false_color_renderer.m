function [ img_cube_false, img_sets ] = SSFC_false_color_renderer( ...
    img_cube, img_sets, proc_mode, wavelength_range )
%% SSFC False Color Renderer
%   By: Niklas Gahm
%   2018/12/05
%
%   This script generates false color renderings of the reconstructed or
%   tiled SSFC images. Conversion from wavelengths is done using the
%   Spectral and XYZ Color Functions package (https://www.mathworks.com/matlabcentral/fileexchange/7021-spectral-and-xyz-color-functions).
%
%
%   2018/12/05 - Started
%   2018/12/06 - Finished



%% Navigation Setup
addpath('.\Functions\spectral_color_1');


%% Generate Colors
spectral_bins = size(img_sets(1).images_reconstructed, 4);
false_color_wavelengths = linspace(wavelength_range(1), ...
    wavelength_range(2), spectral_bins);
false_color_RGB = zeros(numel(false_color_wavelengths), 3);
for i = 1:numel(false_color_wavelengths)
    false_color_RGB(i,:) = spectrumRGB(false_color_wavelengths(i));
end


%% Apply Colors 
img_cube_false = 0;
switch proc_mode
    case 'Individual Images'
        for i = 1:numel(img_sets)
            img_sets(i).image_false_color = zeros( ...
                size(img_sets(i).images_reconstructed, 1), ...
                size(img_sets(i).images_reconstructed, 2), ...
                size(img_sets(i).images_reconstructed, 3), 3);
            for j = 1:spectral_bins
                img_sets(i).image_false_color(:,:,:,1) = ...
                    img_sets(i).image_false_color(:,:,:,1) + ...
                    (img_sets(i).images_reconstructed(:,:,:,j) * ...
                    false_color_RGB(j,1));
                img_sets(i).image_false_color(:,:,:,2) = ...
                    img_sets(i).image_false_color(:,:,:,2) + ...
                    (img_sets(i).images_reconstructed(:,:,:,j) * ...
                    false_color_RGB(j,2));
                img_sets(i).image_false_color(:,:,:,3) = ...
                    img_sets(i).image_false_color(:,:,:,3) + ...
                    (img_sets(i).images_reconstructed(:,:,:,j) * ...
                    false_color_RGB(j,3));
            end
            % Normalize RGB to the 0:1 scale
            max_false = max(max(max(max(img_sets(i).image_false_color))));
            min_false = min(min(min(min(img_sets(i).image_false_color))));
            img_sets(i).image_false_color = ...
                (img_sets(i).image_false_color - min_false) / ...
                (max_false - min_false);
        end
        
        
    case 'Image Stack'
        img_cube_false = zeros(size(img_cube, 1), size(img_cube, 2), ...
            size(img_cube, 3), 3);
        for i = 1:spectral_bins
            img_cube_false(:,:,:,1) = img_cube_false(:,:,:,1) + ...
                (img_cube(:,:,:,i) * false_color_RGB(i,1));
            img_cube_false(:,:,:,2) = img_cube_false(:,:,:,2) + ...
                (img_cube(:,:,:,i) * false_color_RGB(i,2));
            img_cube_false(:,:,:,3) = img_cube_false(:,:,:,3) + ...
                (img_cube(:,:,:,i) * false_color_RGB(i,3));
        end
        max_false = max(max(max(max(img_cube_false))));
        min_false = min(min(min(min(img_cube_false))));
        img_cube_false = (img_cube_false - min_false) / ...
            (max_false - min_false);
        
        
    case 'Video'
        img_cube_false = zeros(size(img_cube, 1), size(img_cube, 2), ...
            size(img_cube, 3), 3, size(img_cube, 5));
        for i = 1:spectral_bins
            img_cube_false(:,:,:,1,:) = img_cube_false(:,:,:,1,:) + ...
                (img_cube(:,:,:,i,:) * false_color_RGB(i,1));
            img_cube_false(:,:,:,2,:) = img_cube_false(:,:,:,2,:) + ...
                (img_cube(:,:,:,i,:) * false_color_RGB(i,2));
            img_cube_false(:,:,:,3,:) = img_cube_false(:,:,:,3,:) + ...
                (img_cube(:,:,:,i,:) * false_color_RGB(i,3));
        end
        max_false = max(img_cube_false, [], 'all');
        min_false = min(img_cube_false, [], 'all');
        img_cube_false = (img_cube_false - min_false) / ...
            (max_false - min_false);
end

end

