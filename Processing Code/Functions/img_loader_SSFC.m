function [ img_sets, xml_name, env_name, img_file_type, xyz_map ] ...
    = img_loader_SSFC( file_path, num_line, pos_file_path )
%% Image Loader
%   By: Niklas Gahm
%   2018/07/23
%
%   This code programatically loads in images and generates the apropriate
%   structs needed for the remainder of the processing code
%
%   2018/07/23 - Started
%   2018/07/23 - Finished 
%   2018/08/20 - Adapted from SETI project for the SSFC Project



%% Setup Navigation
hpath = pwd;
cd(file_path);


%% Get Directory List 
dir_list = dir;
dir_list = dir_list(3:end); % Removes system folders


%% Handle/Load in Position File
% Check if position file is in current directory 
for i = 1:numel(dir_list)
    if strcmp('.xy', dir_list(i).name(end-2:end))
        pos_file_path = [file_path '\' dir_list(i).name];
        dir_list = dir_list([1:i-1, i+1:end]);
        break;
    end
end

% Load in Position File Also handles the single position case
xyz_map = SSFC_position_file_loader(pos_file_path);


%% Account for .env file, .xml file, MIP folder, References Folder)
if rem((numel(dir_list) - 4), num_line) == 0
    num_imgs = (numel(dir_list) - 4) / num_line; 
    num_t = num_imgs / numel(xyz_map);
else
    error('Incorrect number of files in the data to be processed folder.');
end

% Remove MIP folder and References Folder
if dir_list(1).isdir
    dir_list = dir_list(3:end);
elseif dir_list(3).isdir
    dir_list = dir_list([1:2, 5:end]);
elseif dir_list(end).isdir
    dir_list = dir_list(1:(end-2));
else
    error('Incorrect Folder Structure');
end

% Get .xml and .env file names
xml_ind = 0; 
env_ind = 0;
for i = 1:numel(dir_list)
    [~, temp_name, temp_type] = fileparts(dir_list(i).name);
    switch temp_type
        case '.xml'
            xml_name = temp_name;
            xml_ind = i;
        case '.env'
            env_name = temp_name;
            env_ind = i;
    end
    % Both Files found
    if xml_ind ~= 0 && env_ind ~= 0
        break;
    end
end

% Check both files were found
if xml_ind == 0 || env_ind == 0
    error('Missing either .xml or .env file.');
end

% Remove from directory list .xml and .env file names
if xml_ind < env_ind
    ind_small = xml_ind;
    ind_large = env_ind;
else
    ind_small = env_ind;
    ind_large = xml_ind;
end
    
dir_list = dir_list([1:(ind_small-1), (ind_small+1):(ind_large-1), ...
    (ind_large+1):end]);

% Get image file type
[~, ~, img_file_type] = fileparts(dir_list(1).name);


%% Setup Img Set Structs and Fill in img_sets.images
img_sets = struct;
% Use Bioformats to Load in Image
for i = 1:num_t
    for j = 1:numel(xyz_map)
        current_img_ind = j + ((i-1) * numel(xyz_map));
        img_sets(current_img_ind).images = cell(1, num_line);
        
        % Assign position
        img_sets(current_img_ind).x_pos = xyz_map(j).x_pos;
        img_sets(current_img_ind).y_pos = xyz_map(j).y_pos;
        img_sets(current_img_ind).z_pos = xyz_map(j).z_pos;
        
        % Assign time point
        img_sets(current_img_ind).t = i; 
        
        % Calculate Starting Point for Loading Image
        start_point = num_line * (current_img_ind - 1);
        
        % Load in Images
        for k = 1:num_line
            bf_reader_element = bfopen(dir_list((start_point + k)).name);
            img_sets(current_img_ind).images{k} = ...
                double(bf_reader_element{1,1}{1,1});
        end
    end
end

% Remove reader element and the Java handles that falsely keep it open
clear bf_reader_element;


%% Clean Navigation
cd(hpath);

end
