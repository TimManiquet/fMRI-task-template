function [firstPressedKey, in] = logKeyPress(params, in, logFile, triggerKeyBreaks, otherKeysBreak, conditionFunc)
% LOGKEYPRESS - Function for logging key press
% 
%   This function logs key press events and writes to logFile. It continues
%   until the conditionFunc returns true, or when the specific key events occur.
%   The function returns  an integer corresponding to key code of the first 
%   pressed key, if the first pressed key is included in the array params.respKey
%   (i.e., if the key pressed is one of the assigned keys for the task)
%
%   Args:
%    params (struct): A structure containing key codes.
%    in (struct): A structure containing script start time and other information.
%    logFile (file): The file to write logs to.
%    triggerKeyBreaks (logical, optional): Whether pressing the trigger key breaks the loop.
%    otherKeysBreak (logical, optional): Whether pressing any key other than the trigger or escape key breaks the loop.
%    conditionFunc (function, optional): The function to evaluate for loop exit.
%
%   Example:
%    [firstPressedKey, in] = logKeyPress(p, logFile, in, true, false, @(keyCode) keyCode <= 4)
%    [~, in] = logKeyPress(p, logFile, in, true, false, @(x) true) i.e., the loop continues indefinitely unless a key event breaks it.
% 
%   Author
%   Andrea Costantino [16/6/23]

firstPressedKey = []; % Initialize return value

% flush keyboard queue
KbQueueFlush;

% start logging loop
while conditionFunc(true)
    
    [pressed, firstPress] = KbQueueCheck(); % check keyboard queue
    
    keyCode = find(firstPress); % find the first key that was pressed

    % log the trigger key
    if pressed && firstPress(params.triggerKey)
        logEvent(logFile, 'PULSE', 'Trigger', dateTimeStr, '-', GetSecs-in.scriptStart, '-', keyCode);
        if triggerKeyBreaks
            break
        end

        % log and return if the escape key is pressed
    elseif pressed && firstPress(params.escapeKey)
        logEvent(logFile, 'RESP', 'Escape', dateTimeStr, '-', GetSecs-in.scriptStart, '-', keyCode);
        in.pressedAbortKey = true; % Assign the pressed key
        %break
        error('ScriptExecution:ManuallyAborted', 'Script execution manually aborted.');

        % log any other key press and break if the condition is met
    elseif pressed
        logEvent(logFile, 'RESP', 'KeyPress', dateTimeStr, '-', GetSecs-in.scriptStart, '-', keyCode);
        % Check if firstPressedKey is still empty and pressed key is any of the response keys
        if isempty(firstPressedKey) && any(ismember(KbName(keyCode), params.respKeys))
            firstPressedKey = keyCode; % Assign the pressed key
        end
        if otherKeysBreak
            break
        end
    end
end

end
