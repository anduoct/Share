function currentPath = addFilePath

%   Copyright 2024 FNST.

currentPath = pwd;

% Add  current Path and its subfolders to the search path.
addpath(genpath(currentPath))
