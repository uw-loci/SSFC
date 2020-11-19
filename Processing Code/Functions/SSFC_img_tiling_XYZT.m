function [ img_cube ] = SSFC_img_tiling_XYZT( ...
    img_sets, xyz_map, spectral_bins, num_x, num_y, num_z, num_t, ...
    unique_x_sorted, unique_y_sorted, unique_z_sorted, ...
    x_direction, y_direction, x_offset, y_offset, pad_start, pad_end )
%% SSFC Image Tiler in XYZT
%   By: Niklas Gahm
%   2020/10/20
%
%   This script tiles the ssfc images to generate an image cube. 
%   Input Dimensions are 'XYZT' 
%   Output Dimensions are XYZCT
% 
%   Specifically this script is one of the sub-functions of SSFC_img_tiling
%   that handles the data order case 'XYZT' 
%
%
%   2020/10/20 - Started
%   2020/10/20 - Finished



%% Iteratively add temporal layers
img_cube = [];
for t = 1:num_t
    
    % Iteratively Build XYZ Cube at time point t
    
    % Split the set being worked with out and remove from the img_set
    % struct (saves memory)
    cube_tiles = img_sets(1:numel(xyz_map));
    img_sets = img_sets((numel(xyz_map)+1):end);
    
    %% Order Tile Set
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
            cube_tiles(i).images_reconstructed( :, ...
            (pad_start+1):(pad_end-1), :, : );
    end
    
    % Clean up Cube Tiles for Memory Purposes
    clear cube_tiles;
    
    
    
    %% Build Mosaic Grid
    % Z is easy to fill since due to the nature of this microscopy modality
    % there is no true overlap between Z-planes which would require being
    % accounted for and corrected by feathering
    mosaic = [];
    for z = 1:num_z
        
        %% Tiling in X
        x_tiled = cell(1, num_y);
        for y = 1:num_y
            x_growth = cube_tiles_ordered{1, y, z};
            for x = 2:num_x
                x_tile = cube_tiles_ordered{x, y, z};
                if strcmp('+X', x_direction)
                    % Offset is generally not pixel perfect and therefore
                    % must be corrected for
                    if (x_offset/round(x_offset)) ~= 1
                        % Conceptually this is effectively taking an
                        % interpolation of the tile away from the growth
                        % position, and then removing the last column of
                        % pixels since they are interpolated into nothing.
                        
                        shift_factor = x_offset - floor(x_offset);
                        ref_cord_x = repmat(linspace(1, size(x_tile,2), ...
                            size(x_tile,2)), size(x_tile,1), 1);
                        ref_cord_y = repmat(linspace(1, size(x_tile,1), ...
                            size(x_tile,1))', 1, size(x_tile,2));
                        
                        interp_cord_x = ref_cord_x + shift_factor;
                        
                        for i = 1:size(x_tile, 4)
                            x_tile(:,:,:,i) = interp2(...
                                ref_cord_x, ref_cord_y, ...
                                x_tile(:,:,:,i), ...
                                interp_cord_x, ref_cord_y);
                        end
                        
                        x_tile = x_tile(:, 1:(end-1), :, :);
                        
                        % So the region of overlap will appear smaller than
                        % prior to this transformation
                        tile_bound = size(x_tile, 2) - floor(x_offset);
                        growth_bound = size(x_growth,2) - tile_bound;
                        
                        % In the off case that it is pixel perfect
                    else
                        tile_bound = size(x_tile, 2) - x_offset;
                        growth_bound = size(x_growth,2) - tile_bound;
                    end
                    
                    % Generate the row components
                    growth_part = x_growth(:, 1:growth_bound, :, :);
                    feathered_part = region_feathering_ssfc( ...
                        x_growth(:, (growth_bound+1):end, :, :), ...
                        x_tile(:, 1:tile_bound, :, :), x_direction);
                    tile_part = x_tile(:, (tile_bound+1):end, :, :);
                    
                    % Combine components into new x_growth
                    x_growth = [growth_part, feathered_part, tile_part];
                    
                    
                    
                % The case where tiles are added on the image left    
                else
                    % Offset is generally not pixel perfect and therefore
                    % must be corrected for
                    if (x_offset/round(x_offset)) ~= 1
                        % Conceptually this is effectively taking an
                        % interpolation of the tile away from the growth
                        % position, and then removing the last column of
                        % pixels since they are interpolated into nothing.
                        
                        shift_factor = x_offset - floor(x_offset);
                        ref_cord_x = repmat(linspace(1, size(x_tile,2), ...
                            size(x_tile,2)), size(x_tile,1), 1);
                        ref_cord_y = repmat(linspace(1, size(x_tile,1), ...
                            size(x_tile,1))', 1, size(x_tile,2));
                        
                        interp_cord_x = ref_cord_x + shift_factor;
                        
                        for i = 1:size(x_tile, 4)
                            x_tile(:,:,:,i) = interp2(...
                                ref_cord_x, ref_cord_y, ...
                                x_tile(:,:,:,i), ...
                                interp_cord_x, ref_cord_y);
                        end
                        
                        x_tile = x_tile(:, 1:(end-1), :, :);
                        
                        % So the region of overlap will appear smaller than
                        % prior to this transformation
                        growth_bound = size(x_tile, 2) - floor(x_offset);
                        tile_bound = floor(x_offset);
                        
                        % In the off case that it is pixel perfect
                    else
                        growth_bound = size(x_tile, 2) - x_offset;
                        tile_bound = x_offset;
                    end
                    
                    % Generate the row components
                    growth_part = x_growth(:, growth_bound:end, :, :);
                    feathered_part = region_feathering_ssfc( ...
                        x_growth(:, 1:(growth_bound+1), :, :), ...
                        x_tile(:, tile_bound:end, :, :), ...
                        x_direction);
                    tile_part = x_tile(:, 1:(tile_bound-1), :, :);
                    
                    % Combine components into new x_growth
                    x_growth = [tile_part, feathered_part, growth_part];
                    
                end
            end
            
            % Add tiled x-row to cell vector for usage in
            % the y-dimension
            x_tiled{y} = x_growth;
        end
        
        
        %% Tiling in Y
        xy_growth = x_tiled{1};
        for y = 2:num_y
            xy_tile = x_tiled{y};
            if strcmp(y_direction, '-Y')
                % Offset is generally not pixel perfect, and therefore must
                % be corrected for
                if (y_offset/round(y_offset)) ~= 1
                    % Conceptually this is effectively taking an 
                    % interpolation of the tile away from the growth 
                    % position, and then removing the last row of pixels 
                    % since they are interpolated into nothing and 
                    % extrapolation is adding information that is not 
                    % present.
                    
                    shift_factor = y_offset - floor(y_offset);
                    ref_cord_x = repmat(linspace(1, size(xy_tile,2), ...
                        size(xy_tile,2)), size(xy_tile,1), 1);
                    ref_cord_y = repmat(linspace(1, size(xy_tile,1), ...
                        size(xy_tile,1))', 1, size(xy_tile,2));
                    
                    interp_cord_y = ref_cord_y + shift_factor;
                    
                    for i = 1:size(xy_tile, 4)
                        xy_tile(:,:,:,i) = interp2(...
                            ref_cord_x, ref_cord_y, xy_tile(:,:,:,i), ...
                            ref_cord_x, interp_cord_y);
                    end
                    
                    xy_tile = xy_tile(1:(end-1), :, :, :);
                    
                    % So the region of overlap will appear smaller than
                    % prior to this transformation
                    tile_bound = size(xy_tile,1) - floor(y_offset);
                    growth_bound = size(xy_growth, 1) - tile_bound;
                    
                % In the off case that the offset is pixel perfect
                else
                    tile_bound = size(xy_tile,1) - y_offset;
                    growth_bound = size(xy_growth, 1) - tile_bound;
                end
                
                % Generate the xy components
                growth_part = xy_growth(1:growth_bound, :, :, :);
                feathered_part = region_feathering_ssfc( ...
                    xy_growth((growth_bound+1):end, :, :, :), ...
                    xy_tile(1:tile_bound, :, :, :), y_direction);
                tile_part = xy_tile((tile_bound+1):end, :, :, :);
                
                % Combine components into new xy_growth
                xy_growth = [growth_part; feathered_part; tile_part];
                
                
                
            % Case where Y tiles are added above the previous tile
            else
                % Offset is generally not pixel perfect, and therefore must
                % be corrected for
                if (y_offset/round(y_offset)) ~= 1
                    % Conceptually this is effectively taking an 
                    % interpolation of the tile away from the growth 
                    % position, and then removing the last row of pixels 
                    % since they are interpolated into nothing and 
                    % extrapolation is adding information that is not 
                    % present.
                    
                    shift_factor = y_offset - floor(y_offset);
                    ref_cord_x = repmat(linspace(1, size(xy_tile,2), ...
                        size(xy_tile,2)), size(xy_tile,1), 1);
                    ref_cord_y = repmat(linspace(1, size(xy_tile,1), ...
                        size(xy_tile,1))', 1, size(xy_tile,2));
                    
                    interp_cord_y = ref_cord_y + shift_factor;
                    
                    for i = 1:size(xy_tile, 4)
                        xy_tile(:,:,:,i) = interp2(...
                            ref_cord_x, ref_cord_y, xy_tile(:,:,:,i), ...
                            ref_cord_x, interp_cord_y);
                    end
                    
                    xy_tile = xy_tile(1:(end-1), :, :, :);
                    
                    % So the region of overlap will appear smaller than
                    % prior to this transformation
                    growth_bound = size(xy_tile,1) - floor(y_offset);
                    tile_bound = floor(y_offset);
                    
                % In the off case that the offset is pixel perfect
                else
                    growth_bound = size(xy_tile,1) - y_offset;
                    tile_bound = y_offset;
                end
                
                % Generate the xy components
                growth_part = xy_growth((growth_bound+1):end, :, :, :);
                feathered_part = region_feathering_ssfc( ...
                    xy_growth(1:growth_bound, :, :, :), ...
                    xy_tile((tile_bound+1):end, :, :, :), y_direction);
                tile_part = xy_tile(1:tile_bound, :, :, :);
                
                % Combine components into new xy_growth
                xy_growth = [tile_part; feathered_part; growth_part];
                
                
            end
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