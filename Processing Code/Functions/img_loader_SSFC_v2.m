function [ img_sets, xml_name, env_name, img_file_type, xyz_map ] ...
    = img_loader_SSFC_v2( file_path )
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



%%%% TEMPORARY FORM TO GET ANYTHING EVEN WORKING


%% Setup Navigation
hpath = pwd;
cd(file_path);


%% Get Directory List 
dir_list = dir;
dir_list = dir_list(3:end); % Removes system folders


%% Handle/Load in Position File
% Check if position file is in current directory 
pos_file_flag = 0;
for i = 1:numel(dir_list)
    if strcmp('.xy', dir_list(i).name(end-2:end))
        pos_file_path = [file_path '\' dir_list(i).name];
        dir_list = dir_list([1:i-1, i+1:end]);
        pos_file_flag = 1;
        break;
    end
end

% Load in Position File Also handles the single position case
xyz_map = [];
if pos_file_flag == 1
    xyz_map = SSFC_position_file_loader(pos_file_path);
end


%% Account for .env file, .xml file, MIP folder, References Folder)
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
bf_reader_element = bfopen(dir_list(1).name);
for i = 1:250 %%%% TEMPORARY TO SPEED UP PROCESSING.
% for i = 1:(size(bf_reader_element,1)/2)
    temp = bf_reader_element{(1+((i-1)*2)), 1};
    for j = 1:size(temp,1)
        img_sets(i).images{j} = double(temp{j,1});
    end
end

% Remove reader element and the Java handles that falsely keep it open
clear bf_reader_element;


%% Clean Navigation
cd(hpath);

end