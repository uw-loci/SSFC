function [ img_cube ] = SSFC_img_tiling_TXYZ( ...
    img_sets, xyz_map, spectral_bins, num_x, num_y, num_z, num_t, ...
    unique_x_sorted, unique_y_sorted, unique_z_sorted, ...
    x_direction, y_direction, x_offset, y_offset, pad_start, pad_end )
%% SSFC Image Tiler in XYZT
%   By: Niklas Gahm
%   2020/10/20
%
%   This script tiles the ssfc images to generate an image cube. 
%   Input Dimensions are 'TXYZ' 
%   Output Dimensions are XYZCT
% 
%   Specifically this script is one of the sub-functions of SSFC_img_tiling
%   that handles the data order case 'TXYZ'. Based on the structure of the 
%   input data, there is no true way of doing feathered tiling, since
%   neighboring tiles will be significantly different time points. So the
%   only functional way of presenting the data in a meaningful and accurate
%   manner is to simply treat each image as it's own fully tiled image and
%   then splitting it in post.
%
%
%   2020/10/20 - Started
%   2020/10/25 - Finished
% 
% 
%   TO DO:
%       - Incorporate Splitting Here as a XYZCTG data set where G is Group
%       - Propogate split mode through the rest of the framework.





%% Iteratively add temporal layers
img_cube = zeros( size(img_sets(1).images_reconstructed,1), ...
    size(img_sets(1).images_reconstructed,2), num_z, spectral_bins, ...
    numel(img_sets));
tiling_waitbar = waitbar(0, 'Tiling Images');
for t = 1:numel(img_sets)
    waitbar(((t-1)/numel(img_sets)), tiling_waitbar);
    img_cube(:,:,1,:, img_sets(t).t_point) = ...
        img_sets(t).images_reconstructed;
end
close(tiling_waitbar);

end