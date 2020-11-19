function [ img_sets ] = SSFC_spatiotemporal_assignment( ...
    img_sets, xyz_map, data_order )
%% SSFC Spatio Temporal Assignment
%   By: Niklas Gahm
%   2020/02/03
%
%   This script populates the img_sets struct with correct positional and
%   timepoint assignments
%
%
%   2020/02/03 - Started
%   2020/02/03 - Finished


switch data_order
    case 'XYZT'
        %% Iterate on Time Points
        for i = 1:(numel(img_sets)/numel(xyz_map))
            offset = numel(xyz_map)*(i-1);
            
            % Iterate through the Positions
            for j = 1:numel(xyz_map)
                img_sets(j+offset).x_pos = xyz_map(j).x_pos;
                img_sets(j+offset).y_pos = xyz_map(j).y_pos;
                img_sets(j+offset).z_pos = xyz_map(j).z_pos;
                img_sets(j+offset).t_point = i;
            end
        end
    case 'TXYZ'
        %% Iterate on Positions
        for i = 1:numel(xyz_map)
            offset = (numel(img_sets)/numel(xyz_map))*(i-1);
            
            % Iterate on Time Points
            for j = 1:(numel(img_sets)/numel(xyz_map))
                img_sets(j+offset).x_pos = xyz_map(i).x_pos;
                img_sets(j+offset).y_pos = xyz_map(i).y_pos;
                img_sets(j+offset).z_pos = xyz_map(i).z_pos;
%                 img_sets(j+offset).t_point = j;
                img_sets(j+offset).t_point = j + offset;
            end
        end
    otherwise
        error(...
            '\nUnsupported Data Structure. Needs to be XYZT or TXYZ\n\n');
end
end