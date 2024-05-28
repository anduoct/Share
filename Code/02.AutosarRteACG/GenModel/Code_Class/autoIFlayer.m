classdef autoIFlayer < handle

    properties
        tx_normal_dict
        rx_normal_dict
        current_path
        mbd_cantx
        mbd_canrx
        output_model_path
        output_code_path
        in_xls_path
    end

    methods
        function obj = autoIFlayer(dd_xls_path, model_path, code_path)
            bdclose all
            m_file = mfilename('fullpath');
            [obj.current_path, ~, ~] =  fileparts(m_file);

            obj.output_model_path = model_path;
            obj.output_code_path = code_path;
            obj.tx_normal_dict = containers.Map();
            obj.rx_normal_dict = containers.Map();

            ram_var_names = {'Content', 'E.Level', 'Unit', 'Min', 'Max', 'Resolution', 'Element', 'ECM ON', 'Eng Stall', 'EEPROM', 'INCA monitoring name', 'Label', 'numerator', 'LSB', 'denominator', 'Min（Internal）', 'Max（Internal）', 'Attribute', 'Bit No.', 'BLD Raster', 'BLD Offset', 'BLD ID', 'Section', 'Module', 'SCR'};
            ram_var_types = {'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string','string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string'};
            ram_var_namerules = 'preserve';
            ram_var_range = 'C3';
            ram_row_names_range = 'B3';
            ram_var_nums = 25;
            ram_sht_name = 'RAM';
            ram_xls_opt = spreadsheetImportOptions("Sheet",ram_sht_name,"NumVariables", ram_var_nums, "VariableNames", ram_var_names, "VariableTypes", ram_var_types, "VariableNamingRule", ram_var_namerules, "DataRange", ram_var_range, "RowNamesRange", ram_row_names_range);
            ram_sht_tbl = readtable(dd_xls_path, ram_xls_opt);

            rom_var_names = {'Content', 'Unit', 'Min', 'Max', 'Resolution', 'Element', 'Initial', 'Label', 'numerator', 'LSB', 'denominator', 'Min（Internal）', 'Max（Internal）', 'Initial（Internal）', 'Attribute', 'Direction', 'BLD ID', 'Section', 'Module', 'SCR'};
            rom_var_types = {'string', 'string', 'string', 'string', 'string', 'string','string', 'string', 'string', 'string', 'string', 'string', 'string', 'string','string', 'string', 'string', 'string', 'string', 'string'};
            rom_var_namerules = 'preserve';
            rom_var_range = 'C3';
            rom_row_names_range = 'B3';
            rom_var_nums = 20;
            rom_sht_name = 'ROM';
            rom_xls_opt = spreadsheetImportOptions("Sheet",rom_sht_name,"NumVariables", rom_var_nums, "VariableNames", rom_var_names, "VariableTypes", rom_var_types, "VariableNamingRule", rom_var_namerules, "DataRange", rom_var_range, "RowNamesRange", rom_row_names_range);
            rom_sht_tbl = readtable(dd_xls_path, rom_xls_opt);

            obj.mbd_cantx = autoMBDTx(ram_sht_tbl, rom_sht_tbl);
%             obj.mbd_canrx = autoMBDCanRx(ram_sht_tbl, rom_sht_tbl);
        end

        function tx_normal_sht_tbl = load_tx_normal(obj, sht_name)
            disp(sht_name)
            var_nums = 9;
            var_names = {'Interface', 'IFlayer Name', 'Signal', 'Invalid Status', 'Factor', 'Offset', 'Min', 'Max', 'SignalId'};
            var_types = {'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string'};
            var_namerules = 'preserve';
            var_range = 'A2';
            row_names_range = 'A2';
            tx_normal_xls_opt = spreadsheetImportOptions("NumVariables", var_nums, "VariableNames", var_names, "VariableTypes", var_types, "VariableNamingRule", var_namerules, "DataRange", var_range, "RowNamesRange", row_names_range);
            tx_normal_xls_opt.Sheet = sht_name;
            tx_normal_sht_tbl = readtable(obj.in_xls_path, tx_normal_xls_opt);
        end

        function load(obj, in_xls_path)
            obj.in_xls_path = in_xls_path;
            msg_class = ["TxNormal"; "RxNormal"];
            in_sht_names = sheetnames(in_xls_path);
            for i_name = 1: length(in_sht_names)
                if ismember(in_sht_names(i_name), msg_class)
                    id_flag = in_sht_names(i_name);
                    continue
                end

                if strcmp(id_flag, "TxNormal")
                    obj.tx_normal_dict(in_sht_names(i_name)) = obj.load_tx_normal(in_sht_names(i_name));
                elseif strcmp(id_flag, "RxNormal")
                    % TBD
                end
            end
        end



        function gen_model(obj)
            for i_key = keys(obj.tx_normal_dict)
                model_path = obj.output_model_path;
                model_name = ['cantx_' i_key{1}];
                model_info = obj.tx_normal_dict(i_key{1});
                per_save_path = [model_path '\' model_name];
                obj.mbd_cantx.gen_normal_model(per_save_path, model_name, model_info)
            end
%             for i_key = keys(obj.rx_normal_dict)
%                 model_path = obj.output_model_path;
%                 model_name = ['canrx_0x' i_key{1}];
%                 model_info = obj.rx_normal_dict(i_key{1});
%                 per_save_path = [model_path '\' model_name];
%                 obj.mbd_canrx.gen_normal_model(per_save_path, model_name, model_info)
%             end
        end

        function gen_code(obj)
            for i_key = keys(obj.tx_normal_dict)
                model_path = obj.output_model_path;
                model_name = ['cantx_' i_key{1}];
                per_save_path = [model_path '\' model_name];
                obj.mbd_cantx.gen_normal_code(per_save_path, model_name);
            end
%             for i_key = keys(obj.rx_normal_dict)
%                 model_path = obj.output_model_path;
%                 model_name = ['canrx_0x' i_key{1}];
%                 per_save_path = [model_path '\' model_name];
%                 obj.mbd_canrx.gen_normal_code(per_save_path, model_name);
%             end
        end

    end
end