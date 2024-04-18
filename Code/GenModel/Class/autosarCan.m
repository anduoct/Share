classdef autosarCan < handle

    properties
        tx_normal_dict
        rx_normal_dict
        msg_class
        current_path
        dd_sht_tbl
        in_xls_opt
        asr_mbd
        output_model_path
        output_code_path
    end

    methods
        function obj = autosarCan(dd_xls_path, model_path, code_path)
            bdclose all

            obj.output_model_path = model_path;
            obj.output_code_path = code_path;

            obj.tx_normal_dict = containers.Map();
            obj.rx_normal_dict = containers.Map();
            obj.msg_class = ["TxNormal"; "RxNormal"];

            m_file = mfilename('fullpath');
            [obj.current_path, ~, ~] =  fileparts(m_file);

            dd_var_names = {'Content', 'E.Level', 'Unit', 'Min', 'Max', 'Resolution', 'Element', 'Eng Stall', 'EEPROM', 'INCA monitoring name', 'Label', 'numerator', 'LSB', 'denominator', 'Min（Internal）', 'Max（Internal）', 'Attribute', 'Bit No.', 'BLD Raster', 'BLD Offset', 'BLD ID', 'Section', 'Module', 'SCR'};
            dd_var_types = {'string', 'string', 'string', 'string', 'string', 'string','string', 'string', 'string', 'string', 'string', 'string', 'string', 'string','string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string'};
            dd_var_namerules = 'preserve';
            dd_var_range = 'C3';
            dd_row_names_range = 'B3';
            dd_var_nums = 26;
            dd_xls_opt = spreadsheetImportOptions("NumVariables", dd_var_nums, "VariableNames", dd_var_names, "VariableTypes", dd_var_types, "VariableNamingRule", dd_var_namerules, "DataRange", dd_var_range, "RowNamesRange", dd_row_names_range);
            obj.dd_sht_tbl = readtable(dd_xls_path, dd_xls_opt);

            in_var_names = {'Factor', 'Offset', 'Max', 'Min', 'Invalid Status', 'Error Indicator Value', 'Output', 'Elevel'};
            in_var_types = {'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string'};
            in_var_namerules = 'preserve';
            in_var_range = 'B2';
            in_row_names_range = 'A2';
            in_var_nums = 8;
            obj.in_xls_opt = spreadsheetImportOptions("NumVariables", in_var_nums, "VariableNames", in_var_names, "VariableTypes", in_var_types, "VariableNamingRule", in_var_namerules, "DataRange", in_var_range, "RowNamesRange", in_row_names_range);

            obj.asr_mbd = autosarMBD(obj.dd_sht_tbl);
        end

        function load(obj, in_xls_path)

            in_sht_names = sheetnames(in_xls_path);
            for i_name = 1: length(in_sht_names)
                if ismember(in_sht_names(i_name), obj.msg_class)
                    id_flag = in_sht_names(i_name);
                    continue
                end
                obj.in_xls_opt.Sheet = in_sht_names(i_name);
                in_sht_tbl = readtable(in_xls_path, obj.in_xls_opt);
            
                for i_row = 1:length(in_sht_tbl.Row)
                    row_name = in_sht_tbl.Row(i_row);
                    lsb_str = join([obj.dd_sht_tbl(row_name, 'numerator').Variables  '/'  obj.dd_sht_tbl(row_name, 'denominator').Variables], '');
                    resolution_str = obj.dd_sht_tbl(row_name, 'Resolution').Variables;
                    in_lsb_str = in_sht_tbl(row_name, 'Factor').Variables;
                    if ~(strcmp(in_lsb_str, lsb_str) || strcmp(in_lsb_str, resolution_str))
                        me = MException('CAN:noSuchLSB', '%s lsb not equal to DD', row_name{1});
                        throw(me)
                    end
                    in_sht_tbl(row_name,'Elevel') = obj.dd_sht_tbl(row_name,'E.Level');
                end
                
            
                if strcmp(id_flag, "TxNormal")
                    obj.tx_normal_dict(in_sht_names(i_name)) = in_sht_tbl;
                elseif strcmp(id_flag, "RxNormal")
                    obj.rx_normal_dict(in_sht_names(i_name)) = in_sht_tbl;
                end
            end
        end

        function gen_model(obj)
            for i_key = keys(obj.tx_normal_dict)
                model_path = obj.output_model_path;
                model_name = ['cantx_0x' i_key{1}];
                model_info = obj.tx_normal_dict(i_key{1});
                per_save_path = [model_path '\' model_name];
                obj.asr_mbd.gen_tx_normal_model(per_save_path, model_name, model_info)
            end
        end

        function gen_code(obj)
            for i_key = keys(obj.tx_normal_dict)
                model_path = obj.output_model_path;
                model_name = ['cantx_0x' i_key{1}];
                per_save_path = [model_path '\' model_name];
                obj.asr_mbd.gen_tx_normal_code(per_save_path, model_name);
            end
        end

    end
end