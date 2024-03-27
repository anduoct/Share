% m_file = mfilename('fullpath');
% [current_path, ~, ~] =  fileparts(m_file);
current_path = pwd;


% app = actxserver('excel.application');
% xw = app.Workbooks;
% workbook = xw.Open([current_path '/ecuCanFrame.xlsx']);
%%


sheets = sheetnames([current_path '/ecuCanFrame.xlsx'])