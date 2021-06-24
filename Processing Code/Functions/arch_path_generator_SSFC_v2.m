function [ run_name, file_path, arch_path ] = ...
    arch_path_generator_SSFC_v2( fpath )
%% Arch Path Generator   
%   By: Niklas Gahm
%   2018/07/10
%
%   This code generates all path references and structure needed for
%   starting a run.
%
%   2018/07/10 - Started
%   2018/07/10 - Finished
%   2018/08/12 - Adapted from SETI project to SSFC project
%   2019/06/21 - Reworked to fit the calibration map SSFC approach


%% Setup Navigation
hpath = pwd;
cd(fpath);


%% Generate Run Name and Arch Path
[~, run_name, ~] = fileparts(fpath);
arch_path = fpath;


%% Check if Folder Already Sorted 
dir_list = dir;
if numel(dir_list) == 4
    proc_found = 0;
    unproc_found = 0;
    for i = 3:4
        if strcmp(dir_list(i).name, 'Processed Data')
            proc_found = 1;
        elseif strcmp(dir_list(i).name, 'Unprocessed Data')
            unproc_found = 1;
        end
    end
    
    % Folder Partially Sorted
    if unproc_found && ~proc_found
        fprintf('\nCopying Files, This may take a while.\n');
        copyfile('Unprocessed Data', 'Processed Data');
        file_path = [arch_path '\Processed Data'];
        % Clean Navigation
        cd(hpath);
        return;
    end
    
    % Folder Already Sorted
    if proc_found && unproc_found
        % Get Confirmation Before Overwriting Previously Processed Data
        confirmation_response = questdlg(['Are you sure you want to ' ...
            'overwrite previously processed data in this folder?'], ...
            'Overwrite Confirmation', 'Yes', 'No', 'No');
        switch confirmation_response
            case 'Yes'
                fprintf('\nCopying Files, This may take a while.\n');
                rmdir('Processed Data', 's');
                copyfile('Unprocessed Data', 'Processed Data');
                file_path = [arch_path '\Processed Data'];
                % Clean Navigation
                cd(hpath);
                return;
            case 'No'
                % Clean Navigation
                cd(hpath);
                error(['No overwrite permission given. Please select ' ...
                    'a different folder to process.']);
            otherwise
                % Clean Navigation
                cd(hpath);
                error('No overwrite confirmation given.');
        end
    end
end


%% Sort Folder Appropriately
fprintf('\nCopying Files, This may take a while.\n');
movefile('*', 'Unprocessed Data');
copyfile('Unprocessed Data', 'Processed Data');
file_path = [arch_path '\Processed Data'];


%% Clean Navigation
cd(hpath);
end