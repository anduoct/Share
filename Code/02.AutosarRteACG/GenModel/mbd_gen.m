bdclose all
clc
clear

m_file = mfilename('fullpath');
[current_path, ~, ~] =  fileparts(m_file);
restoredefaultpath()
addpath(genpath(current_path))

cd(current_path)

dd_xls_path = [current_path '\Input_Data\dd.xlsx'];
in_xls_path = [current_path '\Input_Data\Output.xlsx'];
auto_iflayer = autoIFlayer(dd_xls_path, [current_path '\Output_Data\Model'], [current_path '\Output_Data\Code']);
auto_iflayer.load(in_xls_path);
% auto_iflayer.gen_model()
auto_iflayer.gen_code()

% bdclose all
% clc
% clear