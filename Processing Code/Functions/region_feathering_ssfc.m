function feathered_region = region_feathering_ssfc( ...
    mosaic_side, tile_side, feathering_dim)
%% SSFC Image Tiler
%   By: Niklas Gahm
%   2018/11/26
%
%   This script feathers overlapping regions.
%   Regions need to be selected apriori.
% 
%   SSFC Data Dimensions are XYZC
%   This feathering was adapted specifically to feather across all of the
%   data in the 4th dimension of the regions 
%
%   Inputs:
%       mosaic_side - fixed portion of data set that is being grown upon
%       tile_side   - portion of the new tile that is being added on
%       feathering_dim  - '-X', '+X', '-Y', '+Y' direction and dimension to
%                           feather across and order of component data
% 
%   2020/02/04 - Started
%   2020/02/05 - Finished



%% Check Input Dimensions
if size(mosaic_side, 1) ~= size(tile_side, 1) || ...
        size(mosaic_side, 2) ~= size(tile_side, 2) || ...
        size(mosaic_side, 3) ~= size(tile_side, 3) || ...
        size(mosaic_side, 4) ~= size(tile_side, 4)
    error(['Input Mosaic Region and Input Tile Region need to be ' ...
        'the same size.']);
end


%% Switch Between Dimension and Direction Cases and Perform Feathering

% Initialize output
feathered_region = zeros(size(mosaic_side,1), size(mosaic_side,2), ...
    size(mosaic_side,3), size(mosaic_side,4));

switch feathering_dim
    % X Descending (Tile on the left, Mosaic on the Right)
    case '-X'
        feathering_gradient = repmat(linspace(0,1,size(mosaic_side,2)), ...
            size(mosaic_side,1), 1, size(mosaic_side,3));
        for i = 1:size(mosaic_side,4)
            feathered_region(:,:,:,i) = (mosaic_side(:,:,:,i) .* ...
                fliplr(feathering_gradient)) ...
                + (tile_side(:,:,:,i) .* feathering_gradient);
        end
        
    % X Ascending (Mosaic on the left, Tile on the right)
    case '+X'
        feathering_gradient = repmat(linspace(0,1,size(mosaic_side,2)), ...
            size(mosaic_side,1), 1, size(mosaic_side,3));
        for i = 1:size(mosaic_side,4)
            feathered_region(:,:,:,i) = (mosaic_side(:,:,:,i) .* ...
                feathering_gradient) + (tile_side(:,:,:,i) .* ...
                fliplr(feathering_gradient));
        end
        
    % Y Descending (Tile on bottom, Mosaic on top) 
    case '-Y'
        feathering_gradient = repmat(...
            linspace(0,1,size(mosaic_side,1))', 1, size(mosaic_side,2), ...
            size(mosaic_side,3));
        for i = 1:size(mosaic_side,4)
            feathered_region(:,:,:,i) = (mosaic_side(:,:,:,i) .* ...
                flipud(feathering_gradient)) + ...
                (tile_side(:,:,:,i) .* feathering_gradient);
        end
        
    % Y Ascending (Mosaic on bottom, Tile on top)
    case '+Y'
        feathering_gradient = repmat(...
            linspace(0,1,size(mosaic_side,1))', 1, size(mosaic_side,2), ...
            size(mosaic_side,3));
        for i = 1:size(mosaic_side,4)
            feathered_region(:,:,:,i) = (mosaic_side(:,:,:,i) .* ...
                feathering_gradient) + (tile_side(:,:,:,i) .* ...
                flipud(feathering_gradient));
        end
        
    otherwise
        error(['\nInvalid Feathering Dimension and Direction Input.' ...
            'Only -X, +X, -Y, +Y are currently supported.\n']);
end
end