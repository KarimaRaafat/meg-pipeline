
% Vpixx BOOLS

VPIXX_USE = 0; % 0 if vpixx is not conected
TRIGGER_TEST = 1;


%Trigger header

if VPIXX_USE == 1
    %VIEW PIXX SETUP
    Datapixx('Open');
    Datapixx('EnablePixelMode');  % to use topleft pixel to code trigger information, see https://vpixx.com/vocal/pixelmode/
    Datapixx('RegWr');

    % Define trigger pixels for all usable MEG channels
    trig.ch224 = [4  0  0]; %224 meg channel
    trig.ch225 = [16  0  0];  %225 meg channel
    trig.ch226 = [64 0 0]; % 226 meg channel
    trig.ch227 = [0  1 0]; % 227 meg channel
    trig.ch228 = [0  4 0]; % 228 meg channel
    trig.ch229 = [0 16 0]; % 229 meg channel
    trig.ch230 = [0 64 0]; % 230 meg channel
    trig.ch231 = [0 0  1]; % 231 meg channel

    % Trigger example

    % Top left pixel that controls triggers in PixelMode
    if TRIGGER_TEST == 0
        trigRect = [0 0 1 1];
        %centeredRect_trigger = CenterRectOnPointd(trigRect, 0.5, 0.5);
    elseif TRIGGER_TEST == 1
        trigRect = [0 0 100 100];
        %centeredRect_trigger = CenterRectOnPointd(trigRect, 25, 25);
    end
    

    % Ensure that the initial trigRect is black, means all triggers are off
    Screen('FillRect', window, black, trigRect);
    Screen('Flip', window);

end



%% script to generate simple attention task - adjusted for MEG
% written September 2024, by Karima Raafat (kar618@nyu.edu) & Hadi Zaatiti (hz3752@nyu.edu)

%% initialize variables 
clearvars; clc
mainDir = '/MEG_Demo'; 
%addpath(genpath(mainDir))
%addpath(genpath('/Applications/Psychtoolbox')); sca
PsychDebugWindowConfiguration(0, 1); % 1 for running exp; 0.5 for debugging
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 2);
screenNum = max(Screen('Screens'));

% define some keys for keyboard input 
KbName('UnifyKeyNames'); % this command switches keyboard mappings to the OSX naming scheme, regardless of computer.
space = KbName('space'); % to start & respond 
escape = KbName('ESCAPE'); 
textSize = 25; 

% define screen parameters
white = [255 255 255];
gray = (white/2)/255;
red = [255 0 0];
black = [0 0 0];
alpha = 0.03; % transparency
targetColor = [gray, alpha]; % combine color with alpha

% for saving later
subject = input('subject number: '); subject = int2strz(subject,2);  
session = input('session number: '); session = int2strz(session,2);

[window, windowRect] = PsychImaging('OpenWindow', screenNum, gray); % open a gray window
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
[xCenter, yCenter] = RectCenter(windowRect); % get the center of the screen

% define attention target parameters 
targetEccentricity = xCenter/2; % to the left or right 
targetSize = 30; 
targetRect = [xCenter - targetSize/2, yCenter - targetSize/2, ...
    xCenter + targetSize/2, yCenter + targetSize/2];
centerLeft = CenterRectOnPointd(targetRect,xCenter-targetEccentricity,yCenter); % left
centerRight = CenterRectOnPointd(targetRect,xCenter+targetEccentricity,yCenter); % right
targetPosition = [centerLeft; centerRight];

% define conditions and cue parameters 
numOfConditions = 2; 
leftID = 1; rightID = 2;
cueSize = 35; 
loadLeftArrow = imread('arrowLeft.png'); 
cueArrowLeft = Screen('MakeTexture', window, loadLeftArrow);
loadRightArrow = imread('arrowRight.png'); 
cueArrowRight = Screen('MakeTexture', window, loadRightArrow);
cueType = {cueArrowLeft cueArrowRight};
cueRect = [xCenter, yCenter, xCenter + cueSize, yCenter + cueSize]; % Define the size and position
cueRect = CenterRectOnPointd(cueRect, xCenter, yCenter); 

% define task timings in seconds
initialCenterFixation = 1.5; % duration to fixate on the center at first and in between
cueDuration = .5; % 35ms in paper 
delay = 1; %1000ms in paper
targetDuration = 1; % 85ms; time they have to respond 
delayInBetween = 2; % between target appearing on each side within block
blockDuration = 30;
% work out how many times targets appear in total based on above timings
timesTargetsAppear = blockDuration/sum([targetDuration,delayInBetween]); % per block 
totalTaskDuration = blockDuration*2; % total duration of the experiment in seconds
blockITI = 2;

% create attendion condition matrix to use within each block 
leftVector = repmat(leftID, 1, timesTargetsAppear/numOfConditions);
rightVector = repmat(rightID, 1, timesTargetsAppear/numOfConditions);
blockAttentionCondition = [leftID rightID]; 
% conditionSet = [leftVector rightVector];

conditionSet = cell(length(blockAttentionCondition),1); 
for b = 1:length(blockAttentionCondition)
    tempConditionVector = [leftVector rightVector]; 
    conditionSet{b,1} = tempConditionVector(randperm(length(tempConditionVector))); % shuffle
end

responses = cell(length(blockAttentionCondition),1);

%% start task loop
clc
Screen('TextSize', window, textSize);
welcomeText = 'Welcome to our experiment! \n Press the spacebar to begin.';
DrawFormattedText(window, welcomeText, 'center', 'center');
Screen('FillRect', window, black, trigRect);
Screen('Flip', window);
continueKeyPressed = 0;
while ~continueKeyPressed 
    [keyIsPressed,secs, keyCode, deltaSecs] = KbCheck();
    if keyIsPressed
        if keyCode(space)
            continueKeyPressed = 1; 
        end
    end
end 
 
for b = 1:length(blockAttentionCondition) % 2 blocks, one side each
    % initial central fixation
    DrawFixation()
    Screen('FillRect', window, black, trigRect);
    Screen('Flip', window)
    WaitSecs(initialCenterFixation) % wait for fixation duration

    % attend left. leave on screen for 35ms
    % Screen('TextSize', window, cueSize);
    % DrawFormattedText(window, cell2mat(cueType(b)), xCenter-cueSize/2, yCenter+cueSize/2, cueColor);
    Screen('DrawTexture', window, cell2mat(cueType(b)), [], cueRect);
    Screen('FillRect', window, black, trigRect);
    Screen('Flip', window)
    WaitSecs(cueDuration)

    % blank screen for delay
    DrawFixation()
    Screen('FillRect', window, black, trigRect);
    Screen('Flip', window)
    WaitSecs(delay)

    startCondition = GetSecs();
    while GetSecs()-startCondition < blockDuration
        for t = 1:timesTargetsAppear
            
            targetSide = conditionSet{b,:}; 
            % peripheral target with central fixation
            DrawFixation()
            Screen('FillOval', window, targetColor, targetPosition(targetSide(t),:))
            Screen('FillRect', window, black, trigRect);
            Screen('Flip', window)
            % WaitSecs(targetDuration)

            startResponse = GetSecs();
            
            keypresses = 0;
            responseKeyPressed = 0; 
            while GetSecs()-startResponse < targetDuration

                % record button press (here, space)
                [keyIsPressed,secs,keyCode,deltaSecs]=KbCheck;
                if keyIsPressed && keyCode(space)
                    responseKeyPressed = 1; 
                    % check if target side matches attention cue side
                    % if conditionSet(t) == leftID ...
                    %         && blockAttentionCondition(b) == leftID
                    if targetSide(t) == blockAttentionCondition(b)
                        R = 1;
                    else
                        R = 0;
                    end

                end

            end
            % if no response is made
            if responseKeyPressed == 0
                R = nan;
            end
            responses{b,1} = [responses{b,1} R];

            DrawFixation()
            Screen('FillRect', window, black, trigRect);
            Screen('Flip', window)
            WaitSecs(delayInBetween)
        end
    end
    if b < length(blockAttentionCondition)
        endBlockText = sprintf('End of block %s \n Press the spacebar to proceed to the next block. \n\n', num2str(b));
        DrawFormattedText(window, endBlockText, 'center', 'center')
        Screen('FillRect', window, black, trigRect);
        Screen('Flip', window)
        % WaitSecs(blockITI)
        % wait for space press to continue to the next block
        continueKeyPressed = 0;
        while ~continueKeyPressed
            [keyIsPressed,secs, keyCode, deltaSecs] = KbCheck( );
            if keyIsPressed
                if keyCode(space)
                    continueKeyPressed = 1;
                end
            end
        end
    end   
end
endSessionText = sprintf('This is the end of the experiment. \n Thank you for participating! Please wait for the experimenter.'); 
DrawFormattedText(window, endSessionText, 'center', 'center')
Screen('FillRect', window, black, trigRect);
Screen('Flip', window)

exitKeyPressed = 0;
while ~exitKeyPressed 
    [keyIsPressed,secs, keyCode, deltaSecs] = KbCheck();
    if keyIsPressed
        if keyCode(escape)
            exitKeyPressed = 1; 
            sca
        end
    end
end 
params.performance = responses; 
params.blockCondition = conditionSet; 
save([mainDir '/data/performance_' subject session '.mat'], 'params')



if VPIXX_USE == 1
    %VIEW PIXX SETUP
    Datapixx('Close');
end
