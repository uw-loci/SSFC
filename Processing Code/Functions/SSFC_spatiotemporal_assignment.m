function [ img_sets ] = SSFC_spatiotemporal_assignment( img_sets, xyz_map )
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
end
