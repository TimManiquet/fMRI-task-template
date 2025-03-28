function params = parseParameterFile(filename, fmriMode)
% PARSEPARAMETERFILE Parses a custom text file containing MATLAB parameters.
% 
%   This function reads the specified text file and extracts MATLAB parameters
%   while ignoring commented-out text, evaluating the content of the text
%   file just as if it were a matlab script. It creates a structure called
%   'params', which should correspond to the content of the parameter file.
%
%   INPUT:
%       filename: The name of the text file to parse.
%       fmriMode: A boolean flag indicating whether the function is operating 
%       in fMRI mode. This will determine some screen & keyboard options.
%
%   OUTPUT:
%       params: A MATLAB structure containing the extracted parameters.
%
%   Example:
%       params = parseParameterFile('parameters.txt', true);
% 
%   Author
%   Tim Maniquet [27/3/24]

% Check if the file exists
if exist(filename, 'file') ~= 2
    error(['Your parameter file "', filename, '" does not exist.']);
end

% Read the contents of the text file
fileID = fopen(filename, 'r');
scriptCode = fread(fileID, '*char').';
fclose(fileID);

% Declare an empty parameter structure that will be filled in
params = struct();

% Evaluate and execute the script code, filling in the params structure
eval(scriptCode);


% MODE-SPECIFIC SCREEN & KEY PARAMETERS

% Here we set some settings based on the fmriMode mode. First check whether
% a fmri mode has been set, otherwise raise an error
if ~exist("fmriMode", "var")
    error(['No fmriMode mode has been defined. Set fmriMode to true or false' ...
        ' before parsing parameters.']);
end

% Check if the relevant key and screen settings are present
if fmriMode == 1
    requiredFields = {'scrDistMRI','scrWidthMRI','respKeyMRI1','respKeyMRI2','triggerKeyMRI','escapeKey'};
elseif fmriMode == 0
    requiredFields = {'scrDistPC','scrWidthPC','respKeyPC1','respKeyPC2','triggerKeyPC','escapeKey'};
end

% Check if fields are missing
missingFields = setdiff(requiredFields, fieldnames(params));
if ~isempty(missingFields)
    error('makeTrialList:paramsMissing', 'Required field(s) %s missing in the params structure.', strjoin(missingFields, ', '));
end

% If fmri mode is selected, choose these settings
if fmriMode == true
    % Extract the mri screen settings
    params.scrDist = params.scrDistMRI; % screen distance
    params.scrWidth = params.scrWidthMRI; % screen width
    % Extract the mri response key settings, make sure they are strings
    params.respKey1 = num2str(params.respKeyMRI1); % response key 1
    params.respKey2 = num2str(params.respKeyMRI2); % response key 2
    params.triggerKey = num2str(params.triggerKeyMRI); % trigger key
    params.escapeKey = num2str(params.escapeKey); % escape key
    % Instruction fields are declared for mri by default
% If fmri mode is off, choose these settings
elseif fmriMode == false
    % Extract computer screen settings
    params.scrDist = params.scrDistPC; % screen distance
    params.scrWidth = params.scrWidthPC; % screen width
    % Extract computer response key settings, make sure they are strings
    params.respKey1 = num2str(params.respKeyPC1); % response key 1
    params.respKey2 = num2str(params.respKeyPC2); % response key 2
    params.triggerKey = num2str(params.triggerKeyPC); % trigger key
    params.escapeKey = num2str(params.escapeKey); % escape key
    % Adapt the instruction fields which are mri by default
    params.respInst1 = num2str(params.respKeyPC1); % button1 instructions
    params.respInst2 = num2str(params.respKeyPC2); % button2 instructions
end

% Calculate a total trial duration: sum of stimulus presentation and fixation cross presentation times
params.trialDur = params.stimDur + params.fixDur;

% Display a message
disp(['Parameters imported from "', filename, '".']);

end
