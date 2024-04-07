bdclose all
clc
clear

m_file = mfilename('fullpath');
[current_path, ~, ~] =  fileparts(m_file);
addpath(current_path)
addpath([current_path '\Class\'])
addpath([current_path '\Lib\'])

asr_can = autosarCan();
asr_can.load([current_path '\..\GenFootage\Output\ecuCanFrame.xlsx']);
asr_can.gen_model([current_path '\Output\'])


bdclose all
clc
clear