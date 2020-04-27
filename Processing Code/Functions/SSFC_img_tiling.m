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
        cube_tiles_ordered{ind(1), ind(2), ind(3)} = ...
            cube_tiles(i).images_reconstructed;
    end
    
    % Clean up Cube Tiles for Memory Purposes
    clear cube_tiles;
    
    
    
    % Build Mosaic Grid
    % Z is easy to fill since due to the nature of this microscopy modality
    % there is no true overlap between Z-planes which would require being
    % accounted for and corrected by feathering
    mosaic = [];
    for z = 1:num_z
        
        % Tiling in X
        x_tiled = cell(1, num_y);
        for y = 1:num_y
            x_growth = cube_tiles_ordered{1, y, z};
            for x = 2:num_x
                x_tile = cube_tiles_ordered{x, y, z};
                % Offset is generally not pixel perfect and therefore must
                % be corrected for
                if (x_offset/round(x_offset)) ~= 1
                    % Conceptually this is effectively taking an
                    % interpolation of the tile away from the growth
                    % position, and then removing the last column of pixels
                    % since they are interpolated into nothing.
                    
                    shift_factor = x_offset - floor(x_offset);
                    ref_cord_x = repmat(linspace(1, size(x_tile,2), ...
                        size(x_tile,2)), size(x_tile,1), 1);
                    ref_cord_y = repmat(linspace(1, size(x_tile,1), ...
                        size(x_tile,1))', 1, size(x_tile,2));
                    
                    interp_cord_x = ref_cord_x + shift_factor; 
                    
                    for i = 1:size(x_tile, 4)
                        x_tile(:,:,:,i) = interp2(...
                            ref_cord_x, ref_cord_y, x_tile(:,:,:,i), ...
                            interp_cord_x, ref_cord_y);
                    end
                    
                    x_tile = x_tile(:, 1:(end-1), :, :);
                    
                    % So the region of overlap will appear smaller than
                    % prior to this transformation
                    growth_bound = size(x_growth, 2) - floor(x_offset);
                    tile_bound = floor(x_offset) + 1;
                    
                % In the off case that it is pixel perfect 
                else
                    growth_bound = size(x_growth, 2) - x_offset;
                    tile_bound = x_offset + 1;
                end
                
                % Generate the row components
                growth_part = x_growth(:, 1:growth_bound, :, :);
                feathered_part = region_feathering_ssfc( ...
                    x_growth(:, (growth_bound+1):end, :, :), ...
                    x_tile(:, 1:tile_bound, :, :), '+X'); 
                tile_part = x_tile(:, (tile_bound+1):end, :, :);
                
                % Combine components into new x_growth
                x_growth = [growth_part, feathered_part, tile_part];
                
            end
            
            % Add tiled x-row to cell vector for usage in the y-dimension
            x_tiled{y} = x_growth;
        end
        
        
        % Tiling in Y
        xy_growth = x_tiled{1};
        for y = 2:num_y
            xy_tile = x_tiled{y};
            % Offset is generally not pixel perfect, and therefore must be
            % corrected for
            if (y_offset/round(y_offset)) ~= 1
                % Conceptually this is effectively taking an interpolation 
                % of the tile away from the growth position, and then 
                % removing the last row of pixels since they are 
                % interpolated into nothing and extrapolation is adding
                % information that is not present.
                
                shift_factor = y_offset - floor(y_offset);
                ref_cord_x = repmat(linspace(1, size(xy_growth,2), ...
                    size(xy_growth,2)), size(xy_growth,1), 1);
                ref_cord_y = repmat(linspace(1, size(xy_growth,1), ...
                    size(xy_growth,1))', 1, size(xy_growth,2));
                
                interp_cord_y = ref_cord_y + shift_factor;
                
                for i = 1:size(xy_tile, 4)
                    xy_tile(:,:,:,i) = interp2(...
                        ref_cord_x, ref_cord_y, xy_tile(:,:,:,i), ...
                        ref_cord_x, interp_cord_y);
                end
                
                xy_tile = xy_tile(1:(end-1), :, :, :);
                
                % So the region of overlap will appear smaller than
                % prior to this transformation
                growth_bound = size(xy_growth, 2) - floor(y_offset);
                tile_bound = floor(y_offset) + 1;
                
                
                % In the off case that the offset is pixel perfect
            else
                growth_bound = size(xy_growth,1) - y_offset;
                tile_bound = y_offset + 1;
            end
            
            % Generate the xy components
            growth_part = xy_growth(1:growth_bound, :, :, :);
            feathered_part = region_feathering_ssfc( ...
                xy_growth((growth_bound+1):end, :, :, :), ...
                xy_tile(1:tile_bound, :, :, :), '-Y');
            tile_part = xy_tile((tile_bound+1):end, :, :, :);
            
            % Combine components into new xy_growth
            xy_growth = [growth_part; feathered_part; tile_part];
        end
        
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