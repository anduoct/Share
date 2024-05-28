bdclose all
clc
clear

m_file = mfilename('fullpath');
[current_path, ~, ~] =  fileparts(m_file);
restoredefaultpath()
addpath(current_path)
addpath([current_path '\Class\'])
addpath([current_path '\Class\autoMBD'])
addpath([current_path '\Lib\'])
cd(current_path)

dd_xls_path = [current_path '\test.xlsx'];
in_xls_path = [current_path '\..\GenFootage\Output\ecuCanFrame.xlsx'];
auto_can = autoCan(dd_xls_path, [current_path '\Model'], [current_path '\Code']);
auto_can.load(in_xls_path);
auto_can.gen_model()
auto_can.gen_code()

% bdclose all
% clc
% clear