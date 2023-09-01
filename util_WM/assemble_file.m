function [filename, filedir] = assemble_file(pathToDataFolder, folderName, filenameSuffix, participantID) 

filename        = ['sub-' num2str(participantID) filenameSuffix];  
subjectFolder   = ['sub-' num2str(participantID)];
filedir         = fullfile(pathToDataFolder, folderName, subjectFolder); 

end