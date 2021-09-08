% SSFC Imaging Position File Generator
% By: Niklas Gahm



%% Variables
filename = '2021-04-18 BPAE Mosaic 2.xy'; 

x_start = -14431;
y_start = 1163;
z_start = 5; 

x_step = 100;
y_step = 100;
z_step = -1;

x_num = 5;
y_num = 5;
z_num = 10;


down_and_back_flag = 0;




%% Initialize File
fileID = fopen(filename,'w');
fprintf(fileID, '<?xml version="1.0" encoding="utf-8"?>\n');
fprintf(fileID, '<StageLocations>\n');


%% Fill File
counter = 0;
for i = 1:z_num
    z_pos = z_start + (z_step * (i-1));
    for j = 1:y_num
        y_pos = y_start + (y_step * (j-1));
        for k = 1:x_num
            x_pos = x_start + (x_step * (k-1));
            fprintf(fileID, '<StageLocation index="%s" x="%s" y="%s" z="%s, -75" />\n', num2str(counter), num2str(x_pos), num2str(y_pos), num2str(z_pos));
            counter = counter + 1;
        end
    end
end

if down_and_back_flag == 1
    for i = 1:z_num
        z_pos = z_start + (z_step*z_num) - (z_step * (i-1));
        for j = 1:y_num
            y_pos = y_start + (y_step * (j-1));
            for k = 1:x_num
                x_pos = x_start + (x_step * (k-1));
                fprintf(fileID, '<StageLocation index="%s" x="%s" y="%s" z="%s, -75" />\n', num2str(counter), num2str(x_pos), num2str(y_pos), num2str(z_pos));
                counter = counter + 1;
            end
        end
    end
end


%% Close File
fprintf(fileID, '</StageLocations>');
fclose(fileID);
