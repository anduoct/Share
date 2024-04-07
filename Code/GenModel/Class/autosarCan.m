classdef autosarCan < handle

    properties
        tx_normal_dict
        rx_normal_dict
        id_strlist
        current_path
        xls_opt
        asr_mbd
    end

    methods
        function obj = autosarCan()
            bdclose all

            obj.tx_normal_dict = containers.Map();
            obj.rx_normal_dict = containers.Map();
            obj.id_strlist = ["TxNormal"; "RxNormal"];

            m_file = mfilename('fullpath');
            [obj.current_path, ~, ~] =  fileparts(m_file);
            
            var_nums = 8;
            var_names = {'Signal', 'Factor', 'Offset', 'Max', 'Min', 'Invalid Status', 'Error Indicator Value', 'Output'};
            var_types = {'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string'};
            var_namerules = 'preserve';
            var_range = 'A2';

            obj.xls_opt = spreadsheetImportOptions("NumVariables", var_nums, "VariableNames", var_names, "VariableTypes", var_types, "VariableNamingRule", var_namerules, "DataRange", var_range);

            obj.asr_mbd = autosarMBD();
        end

        function load(obj, xls_file_path)
            sheet_strlist = sheetnames(xls_file_path);
            for i_str = 1: length(sheet_strlist)
                if ismember(sheet_strlist(i_str), obj.id_strlist)
                    id_flag = sheet_strlist(i_str);
                    continue
                end

                obj.xls_opt.Sheet = sheet_strlist(i_str);

                sht_tbl = readtable(xls_file_path, obj.xls_opt);
                if strcmp(id_flag, "TxNormal")
                    obj.tx_normal_dict(sheet_strlist(i_str)) = sht_tbl;
                elseif strcmp(id_flag, "RxNormal")
                    obj.rx_normal_dict(sheet_strlist(i_str)) = sht_tbl;
                end
            end
        end

        function gen_model(obj, output_path)
            for i_key = keys(obj.tx_normal_dict)
                obj.asr_mbd.gen_tx_normal_model(output_path, i_key{1}, obj.tx_normal_dict(i_key{1}))
            end
        end

    end
end