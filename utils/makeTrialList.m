function trialList = makeTrialList(params, in)
% MAKETRIALLIST - Generate a list of trials based on provided parameters and input data.
%
%   trialList = MAKETRIALLIT(params, in) generates a list of trials using
%   parameters stored in the 'params' structure and input data stored in
%   the 'in' structure. It reads a stimulus list file, duplicates the list
%   based on the specified number of repetitions, randomizes trials as
%   required, adds run numbers, calculates ideal stimulus onset times, and
%   fills the trial list structure with relevant information.
%   It also keeps any extra variable contained in the .tsv file containing
%   the list of trials that you provide with 'params.stimListFile', and 
%   saves it with its original name in the output.
%
%   Input:
%       - params: A structure containing parameters required to generate
%                 the trial list. It must include fields: 'stimListFile',
%                 'numRuns', 'prePost', 'trialDur', 'numRepetitions',
%                 'stimRandomization'.
%       - in: A structure containing input data, such as subject number.
%
%   Output:
%       - trialList: A structure array containing information about each trial,
%                    including trial number, run number, button mapping,
%                    subject number, ideal stimulus onset time, and placeholders
%                    for subject response and actual stimulus onset.
%
%   Example:
%       params.stimListFile = 'stimuli.tsv';
%       params.numRuns = 4;
%       params.prePost = 2;
%       params.trialDur = 4;
%       params.numRepetitions = 2;
%       params.stimRandomization = 'run';
%       in.subNum = 1;
%       trialList = makeTrialList(params, in);
% 
%   Author
%   Tim Maniquet [7/3/24]

% Check if the required fields are present in the params structure
requiredFields = {'stimListFile', 'numRepetitions', 'numRuns', 'prePost', 'trialDur'};
missingFields = setdiff(requiredFields, fieldnames(params));
if ~isempty(missingFields)
    error('makeTrialList:paramsMissing', 'Required field(s) %s missing in the params structure.', strjoin(missingFields, ', '));
end


% Fetch the stimulus list file and read it
try
    % Read the TSV file
    stimListTable = readtable(params.stimListFile, 'Delimiter', '\t', 'FileType', 'text');
    
catch exception
    % Display an error message
    fprintf('Error reading stimuli list from the TSV file: %s\n', exception.message);
    
end

% Duplicate the list of stimuli based on the declared number of repetitions
stimList = repmat(stimListTable, params.numRepetitions, 1);

% If the total number of trials isn't divisible by the number of runs, 
% raise an error
if ~ mod(height(stimList), params.numRuns) == 0
    error(['Your list of %d trials cannot be divided into %d runs of equal length.', ...
        height(stimList), params.numRuns]);
end


% Calculate how many trials we have per run
trialsPerRun = floor(height(stimList) / params.numRuns);

% Randomize trials if required, per run or across the task
if isfield(params, 'stimRandomization')
    if strcmp(params.stimRandomization, 'run')
        % Randomize within each run
        for i = 1:params.numRuns
            % Find the index of the trials of the current run
            idx = 1 + (trialsPerRun * (i-1)) : trialsPerRun + (trialsPerRun * (i-1));
            % Create a new random index for these trials
            randIdx = idx(randperm(length(idx)));
            % Re-attribute the run rows randomly
            stimList(idx,:) = stimList(randIdx,:);
        end
    elseif strcmp(params.stimRandomization, 'all')
        % Create a random index for all stimuli
        randIdx = randperm(height(stimList));
        % Randomize the rows across all runs
        stimList = stimList(randIdx, :);
    end
end



% If not present yet, add the run number information to the list
if ismember('run', stimList.Properties.VariableNames)
    % Extract the existing list of run numbers
    runList = stimList.run;
elseif ~ismember('run', stimList.Properties.VariableNames)
    % Make a list of run numbers corresponding to the trials
    runList = repelem(1:params.numRuns, trialsPerRun)';
    % Convert the runList to a table
    runTable = array2table(runList, 'VariableNames', {'run'});
    % Concatenate the runTable with the stimList table
    stimList = [stimList, runTable];
end


% Calculate the ideal stimulus onset times for one run
stimOnsetRun= params.prePost:params.trialDur: ...
    (trialsPerRun*params.trialDur)+(params.prePost-params.trialDur);
% Make a list to extend to the complete trial list
stimOnsetList = stimOnsetRun;
for i = 2:params.numRuns
    stimOnsetList = [stimOnsetList stimOnsetRun];
end

% Initiate the trial list as a structure and fill it with information
trialList = table2struct(stimList);

% Add relevant columns to the trial list structure
for i = 1:numel(trialList)
    % Declare a trial number
    trialList(i).trialNb = i;
    % Declare a run number
    trialList(i).run = runList(i);
    % Declare a button mapping based on subject and run number
    trialList(i).butMap = determineButtonMapping(params, in.subNum, trialList(i).run).mapNumber;
    trialList(i).respKey1 = determineButtonMapping(params, in.subNum, trialList(i).run).respKey1;
    trialList(i).respKey2 = determineButtonMapping(params, in.subNum, trialList(i).run).respKey2;
    trialList(i).respInst1 = determineButtonMapping(params, in.subNum, trialList(i).run).respInst1;
    trialList(i).respInst2 = determineButtonMapping(params, in.subNum, trialList(i).run).respInst2;
    % Declare a subject number
    trialList(i).subNum = in.subNum;
    % Declare the ideal stimulus onset times
    trialList(i).idealStimOnset = stimOnsetList(i);
    % Declare a placeholder for subject response
    trialList(i).response = NaN;
    % Declare a placeholder for actual stimulus onset
    trialList(i).stimOnset= NaN;
end

end
