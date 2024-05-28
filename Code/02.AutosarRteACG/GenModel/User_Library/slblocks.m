function blkStruct = slblocks

%   Copyright 2024 FNST.

blkStruct.Name = sprintf('User Defined');
blkStruct.OpenFcn = 'user_lib';
blkStruct.MaskInitialization = '';
blkStruct.MaskDisplay = 'disp(''User Defined'')';

Browser.Library = 'user_lib';
Browser.Name    = 'User Defined for IFLayer';

blkStruct.Browser = Browser;  

% open the lib and run this command
% set_param(gcs,'EnableLBRepository','on')