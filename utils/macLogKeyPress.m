function [firstPressedKey, in] = macLogKeyPress(params, in, logFile, triggerKeyBreaks, otherKeysBreak, conditionFunc, keyboardID) 
% MACLOGKEYPRESS - Function for logging key presses on a mac
%
%   This function logs key press events and writes to logFile. It continues
%   until the conditionFunc returns true, or when the specific key events occur.
%   The function logs either a meaningful key name (in most cases), or an
%   integer (in case of escape key or trigger key) corresponding to the key code
%   of the first pressed key. It also returns a meaningful key name if the first
%   pressed key is included in the array params.respKey (i.e., if the key pressed
%   is one of the assigned keys for the task).
%   This function is exactly similar to logKeyPress, except that it solves a
%   problem present on mac systems which has to do with detecting keyboard 
%   input. It takes one extra argument as compared to the normal logKeyPress 
%   function, which is the ID of a detected keyboard.
%
%   Args:
%    params (struct): A structure containing key codes.
%    in (struct): A structure containing script start time and other information.
%    logFile (file): The file to write logs to.
%    triggerKeyBreaks (logical, optional): Whether pressing the trigger key breaks the loop.
%    otherKeysBreak (logical, optional): Whether pressing any key other than the trigger or escape key breaks the loop.
%    conditionFunc (function, optional): The function to evaluate for loop exit.
%    keyboardID (integer): The ID of the detected keyboard (use detectKeyboard to find it).
%
%   Example:
%       [firstPressedKey, in] = logKeyPress(p, logFile, in, true, false, @(keyCode) keyCode <= 4, 25)
%       [~, in] = logKeyPress(p, logFile, in, true, false, @(x) true, 25) i.e., the loop continues indefinitely unless a key event breaks it.
%
%
%   Author
%   Tim Maniquet [12/3/24]

firstPressedKey = []; % Initialize return value

% flush keyboard queue
KbQueueFlush(keyboardID);

% start logging loop
while conditionFunc(true)
    
    [pressed, firstPress] = KbQueueCheck(keyboardID); % check keyboard queue
    keyCode = find(firstPress); % find the first key that was pressed
    keyName = KbName(keyCode); % turn the key code into a key name

    % log the trigger key
    if pressed && firstPress(KbName(params.triggerKey))
        logEvent(logFile, 'PULSE', 'Trigger', dateTimeStr, '-', GetSecs-in.scriptStart, '-', keyName);
        if triggerKeyBreaks
            break
        end

    % log and return if the escape key is pressed
    elseif pressed && firstPress(KbName(params.escapeKey))
        logEvent(logFile, 'RESP', 'Escape', dateTimeStr, '-', GetSecs-in.scriptStart, '-', keyName);
        in.pressedAbortKey = true; % Assign the pressed key
        %break
        error('ScriptExecution:ManuallyAborted', 'Script execution manually aborted.');

        % log any other key press and break if the condition is met
    elseif pressed
        % Log this more meaningful key name
        logEvent(logFile, 'RESP', 'KeyPress', dateTimeStr, '-', GetSecs-in.scriptStart, '-', keyName);
        % If the key was one of the expected keys, return it
        if isempty(firstPressedKey) && any(ismember(KbName(keyCode), num2str(params.respKeys)))
            firstPressedKey = keyName; % Assign the pressed key
        end
        % If other keys break is useful to pass screens like instructions
        if otherKeysBreak
            break
        end
    end
end

end
