% bdclose all
clc
clear

m_file = mfilename('fullpath');
[current_path, ~, ~] =  fileparts(m_file);
addpath(current_path)
addpath([current_path '\Class\'])
addpath([current_path '\Lib\'])

dd_xls_path = 'D:\00.Me\DL\Share\Code\GenModel\test\test.xlsx';
in_xls_path = [current_path '\..\GenFootage\Output\ecuCanFrame.xlsx'];
asr_can = autosarCan(dd_xls_path, [current_path '\Model'], [current_path '\Code']);
asr_can.load(in_xls_path);
asr_can.gen_model()
asr_can.gen_code()

% 
% bdclose all
% clc
% clear