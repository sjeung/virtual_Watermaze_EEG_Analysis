function [outMatrix] = rfpt_read(inputFilePaths, varargin)
% read in RFPT data recorded on Labvanced and return a matrix containing 
% classes and turner points. 
% (assumes data is exported as UTF-8 encoded tsv)
%
% Usage  
%   rfpt_read(inputFilePaths)
%               : assumes that each file is for a single participant
%                 N different file paths should be provided
%   rfpt_read(inputFilePaths, IDs)
%               : assumes multiple participants in the same file 
%                 and searches by ID given in RFPT
% 
% 
% Inputs 
%       inputFilePaths [N cell array of strings] 
%               : full paths to the RFPT files 
%               example     {'P:\Project_Watermaze\Data\0_raw-data\MWM_RFPT'}
%
% 
% Optional Inputs
%       IDs [ 1xN cell array of strings]
%               : IDs entered in RFPT 
%               example     {'VN_TUB_XX','VN_TUB_YY','VN_TUB_ZZ'}
%
% 
% Output
%       outMatrix [Nx2 matrix]
%               : matrix containing class indices in column 1
%                 and turner points in column 2 for each pariticipant
%                 (class index 0 : unclassified, 1: turner, 2: nonturner)
%               example     [1,12;  1,11;  2,0;  2,2]
%
% author : Sein Jeung
%--------------------------------------------------------------------------

disp('Reading in RFPT results.')

% input check 
if nargin == 1
    disp(['No ID strings given: assuming ' num2str(numel(inputFilePaths)) ' participants (= number of files)'])
    searchByID = false; 
elseif nargin == 2
    disp(['Searching participant data by ID strings - ' num2str(numel(varargin{2}))])
    IDs = varargin{2}; 
    searchByID = true;
else
    error('Invalid number of input arguments')
end 

% index of columns of interest in the table
% (was manually searched for...)
IDColumnIndex               = 63; % does not matter unless searching by ID
ClassColumnIndex            = 9;
TurnerPointsColumnIndex     = 34;

% colors to code classes 
turnerColor     = [.7, .3, .2]; 
nonturnerColor  = [.2, .3, .7]; 
noClassColor    = [.5, .5, .5]; 

% number of files to be read in 
nFiles          = numel(inputFilePaths); 

% number of participants
if searchByID 
    nSubjects       = size(IDs,1);
else
    nSubjects       = numel(inputFilePaths); 
end
    
% initialize a matrix to store turner points and classification 
outMatrix       = NaN(nSubjects,2); 

% read in the csv files 
%--------------------------------------------------------------------------
for filei = 1:nFiles
    
    filename = inputFilePaths{filei}; 
    dataTable = readtable(filename, 'ReadVariableNames',false); 
    dataArray = table2array(dataTable); 
    
    % iterate over all rows
    if searchByID
        
        % iterate over participants 
        for subjecti = 1:nSubjects
            
            % initialize the class and max turner point variable
            maxTurnerPoints     = 0;
            classFlag            = NaN;
            
            % iterate over all rows to find a matching row
            % if the participant data is not in file, break 
            rowsForSubject = [];
            for rowi = 1:size(dataArray,1)
                IDCell  = dataArray(rowi,IDColumnIndex);
                ID      = IDCell{1};
                if strcmp(ID, IDs{subjecti})
                    rowsForSubject = [rowsForSubject, rowi]; 
                end
            end
            
            if isempty(rowsForSubject)
                % skip the next part if subject data is not in this file
                break; 
            end
            
            for rowi = rowsForSubject
                
                % find class and turner point 
                class           = dataArray(rowi,ClassColumnIndex);
                turnerPoint     = str2double(dataArray(rowi,TurnerPointsColumnIndex));
                
                % define class if info is present in that row
                if strcmp(class, 'turner')
                    
                    disp(['Participant ' IDs{subjecti} ' classified as turner.'])
                    classFlag  = 1;
                    
                elseif strcmp(class, 'nonturner')
                    
                    disp(['Participant ' IDs{subjecti} ' classified as nonturner.'])
                    classFlag = 2;
                    
                elseif strcmp(class, 'noPreference')
                    
                    disp(['Participant ' IDs{subjecti} ' has no preference.'])
                    classFlag = 0;
                end
                
                
                % update turner point if it exceeds the previous value
                if turnerPoint > maxTurnerPoints
                    
                    maxTurnerPoints = turnerPoint;
                    
                end
                
                % write data in the output matrix
                outMatrix(subjecti,1) = classFlag;
                outMatrix(subjecti,2) = maxTurnerPoints;
            end
            
        end
        
    else
        
        % in case not searching by ID, file index is participant index
        subjecti = filei;
        
        % initialize the class and max turner point variable
        maxTurnerPoints     = 0;
        classFlag            = NaN;
        
        % iterate over all rows in the file 
        for rowi = 1:size(dataArray,1)
            
            % find class and turner point 
            class           = dataArray(rowi,ClassColumnIndex);
            turnerPoint     = str2double(dataArray(rowi,TurnerPointsColumnIndex));
            
            % define class if info is present in that row
            if strcmp(class, 'turner')
                
                disp(['Participant ' IDs{subjecti} ' classified as turner.'])
                classFlag  = 1;
                
            elseif strcmp(class, 'nonturner')
                
                disp(['Participant ' IDs{subjecti} ' classified as nonturner.'])
                classFlag = 2;
                
            elseif strcmp(class, 'noPreference')
                
                disp(['Participant ' IDs{subjecti} ' has no preference.'])
                classFlag = 0;
            end
            
            
            % update turner point if it exceeds the previous value
            if turnerPoint > maxTurnerPoints
                
                maxTurnerPoints = turnerPoint;
                
            end
            
            % write data in the output matrix
            outMatrix(subjecti,1) = classFlag;
            outMatrix(subjecti,2) = maxTurnerPoints;
           
        end
    end 
    
    
end 


end
