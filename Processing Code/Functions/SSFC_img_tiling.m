function [img_cube] = SSFC_img_tiling(img_sets, xyz_map, pixel_size)
%% SSFC Image Tiler
%   By: Niklas Gahm
%   2018/11/26
%
%   This script tiles the ssfc images to generate an image cube. 
%   Dimensions are XYZCT
%
%
%   2018/12/05 - Started
%   




%% Variables
num_pos = numel(xyz_map);
spectral_bins = size(img_sets(1).images_reconstructed, 4);
num_t = numel(img_sets)/numel(xyz_mapmap);


%% Calculate Number of Unique X Y Z Positions
unique_x = {};
unique_y = {};
unique_z = {};
for i = 1:num_pos
    unique_x_flag = 1;
    for j = 1:numel(unique_x)
        if xyz_map(i).x_pos == unique_x{j}
            unique_x_flag = 0;
        end
    end
    if unique_x_flag == 1
        unique_x = [unique_x, xyz_map(i).x_pos]; %#ok<*AGROW>
    end
    
    unique_y_flag = 1;
    for j = 1:numel(unique_y)
        if xyz_map(i).y_pos == unique_y{j}
            unique_y_flag = 0;
        end
    end
    if unique_y_flag == 1
        unique_y = [unique_y, xyz_map(i).y_pos]; %#ok<*AGROW>
    end
    
    unique_z_flag = 1;
    for j = 1:numel(unique_z)
        if xyz_map(i).z_pos == unique_z{j}
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

% Sort Unique Positions
unique_x_sorted = sort(unique_x);
unique_y_sorted = sort(unique_y);
unique_z_sorted = sort(unique_z);



%% Calculate Pixel Offsets and Direction
% All offsets are inherently positive due to sorting 
x_offset = mean(unique_x_sorted(2:end) - unique_x_sorted(1:(end-1))) ...
    / pixel_size;
y_offset = mean(unique_y_sorted(2:end) - unique_y_sorted(1:(end-1))) ...
    / pixel_size;


%%%%%%%%%%%%%%%%%%% NEED TO DETERMINE  DIRECTION.%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




%% Tiling 
img_cube = [];

% Iteratively add temporal layers
for t = 1:num_t
    
    % Iteratively Build XYZ Cube at time point t
    
    % Split the set being worked with out and remove from the img_set
    % struct (saves memory)
    cube_tiles = img_sets(1:numel(xyz_map));
    img_sets = img_sets((numel(xyz_map)+1):end);
    
    % Order Tile Set
    cube_tiles_ordered = cell(num_x, num_y, num_z);
    for i = 1:numel(cube_tiles)
        ind = [0,0,0];
        
        % Find X-Coordinate
        for x = 1:num_x
            if cube_tiles(i).x_pos == unique_x_sorted(x)
                ind(1) = x;
                break;
            end
        end
        
        % Find Y-Coordinate
        for y = 1:num_y
            if cube_tiles(i).y_pos == unique_y_sorted(y)
                ind(2) = y;
                break;
            end
        end
        
        % Find Z-Coordinate
        for z = 1:num_z
            if cube_tiles(i).z_pos == unique_z_sorted(z)
                ind(3) = z;
                break;
            end
        end
        
        % Place Tile Data in Slot
        cube_tile_ordered{ind(1), ind(2), ind(3)} = ...
            cube_tiles(i).images_reconstructed;
    end
    
    % Clean up Cube Tiles for Memory Purposes
    clear cube_tiles;
    
    % Build Mosaic Grid
    % Z is easy to fill since due to the nature of this microscopy modality
    % there is no true overlap between Z-planes which would require being
    % accounted for and corrected by feathering
    for z = 1:num_z
        mosaic = [];
        
        
        % Tiling in X
        x_tiles = cell(1, num_y);
        for y = 1:num_y
            x_growth = cube_tile_ordered{1, y, z};
            for x = 2:num_x
                x_tile = cube_tile_ordered{x, y, z};
                % Offset is generally not pixel perfect and therefore must
                % be corrected for
                if (x_offset/round(x_offset)) ~= 1
                    
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Will probably need to linshift 
                    
                    
                % In the off case that it is pixel perfect 
                else
                    growth_bound = size(x_growth, 1) - x_offset;
                    tile_bound = x_offset + 1;
                    
                end
                
                % Generate the row components
                growth_part = x_growth(1:growth_bound, :, :, :);
                feathered_part = feathering_function(x_growth((growth_bound+1):end, :, :, :), x_tile(1:tile_bound, :, :, :)); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NEED TO WRITE FEATHERING FUNCTION
                tile_part = x_tile((tile_bound+1):end, :, :, :);
                
                % Combine components into new x_growth
                x_growth = [growth_part, feathered_part, tile_part];
                
            end
            
            % Add tiled x-row to cell vector for usage in the y-dimension
            x_tiles{y} = x_growth;
        end
        
        
        
        
        
        %%%%%%%%%%% DO XY TILING HERE!
        
        
        
        
        
        % Check if first Z-plane
        if z == 1
            mosaic = zeros( size(xy_growth,1), size(xy_growth,2), ...
                num_z, spectral_bins);
        end
        
        % Add Z-Plane
        mosaic(:,:,z,:) = xy_growth;
    end
    
    % Check if it's the first temporal layer
    if t == 1
        img_cube = zeros(size(mosaic,1), size(mosaic,2), ...
            size(mosaic,3), size(mosaic,4), num_t);
    end
    
    % Add temporal layer
    img_cube(:,:,:,:,t) = mosaic;
end
end

