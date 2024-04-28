classdef autoCan < handle

    properties
        tx_normal_dict
        rx_normal_dict
        msg_class
        current_path
        ram_sht_tbl
        rom_sht_tbl
        cantx_xls_opt
        canrx_xls_opt
        mbd_cantx
        mbd_canrx
        output_model_path
        output_code_path
    end

    methods
        function obj = autoCan(dd_xls_path, model_path, code_path)
            bdclose all

            obj.output_model_path = model_path;
            obj.output_code_path = code_path;

            obj.tx_normal_dict = containers.Map();
            obj.rx_normal_dict = containers.Map();
            obj.msg_class = ["TxNormal"; "RxNormal"];

            m_file = mfilename('fullpath');
            [obj.current_path, ~, ~] =  fileparts(m_file);

            ram_var_names = {'Content', 'E.Level', 'Unit', 'Min', 'Max', 'Resolution', 'Element', 'Eng Stall', 'EEPROM', 'INCA monitoring name', 'Label', 'numerator', 'LSB', 'denominator', 'Min（Internal）', 'Max（Internal）', 'Attribute', 'Bit No.', 'BLD Raster', 'BLD Offset', 'BLD ID', 'Section', 'Module', 'SCR'};
            ram_var_types = {'string', 'string', 'string', 'string', 'string', 'string','string', 'string', 'string', 'string', 'string', 'string', 'string', 'string','string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string'};
            ram_var_namerules = 'preserve';
            ram_var_range = 'C3';
            ram_row_names_range = 'B3';
            ram_var_nums = 24;
            ram_sht_name = 'RAM';
            ram_xls_opt = spreadsheetImportOptions("Sheet",ram_sht_name,"NumVariables", ram_var_nums, "VariableNames", ram_var_names, "VariableTypes", ram_var_types, "VariableNamingRule", ram_var_namerules, "DataRange", ram_var_range, "RowNamesRange", ram_row_names_range);
            obj.ram_sht_tbl = readtable(dd_xls_path, ram_xls_opt);
            
            rom_var_names = {'Content', 'Unit', 'Min', 'Max', 'Resolution', 'Element', 'Initial', 'Label', 'numerator', 'LSB', 'denominator', 'Min（Internal）', 'Max（Internal）', 'Initial（Internal）', 'Attribute', 'Direction', 'BLD ID', 'Section', 'Module', 'SCR'};
            rom_var_types = {'string', 'string', 'string', 'string', 'string', 'string','string', 'string', 'string', 'string', 'string', 'string', 'string', 'string','string', 'string', 'string', 'string', 'string', 'string'};
            rom_var_namerules = 'preserve';
            rom_var_range = 'C3';
            rom_row_names_range = 'B3';
            rom_var_nums = 20;
            rom_sht_name = 'ROM';
            rom_xls_opt = spreadsheetImportOptions("Sheet",rom_sht_name,"NumVariables", rom_var_nums, "VariableNames", rom_var_names, "VariableTypes", rom_var_types, "VariableNamingRule", rom_var_namerules, "DataRange", rom_var_range, "RowNamesRange", rom_row_names_range);
            obj.rom_sht_tbl = readtable(dd_xls_path, rom_xls_opt);

            canrx_var_names = {'Factor', 'Offset', 'Max', 'Min', 'Invalid Status', 'Error Indicator Value', 'Input', 'Start Bit', 'Length'};
            canrx_var_types = {'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string'};
            canrx_var_namerules = 'preserve';
            canrx_var_range = 'B2';
            canrx_row_names_range = 'A2';
            canrx_var_nums = 9;
            obj.canrx_xls_opt = spreadsheetImportOptions("NumVariables", canrx_var_nums, "VariableNames", canrx_var_names, "VariableTypes", canrx_var_types, "VariableNamingRule", canrx_var_namerules, "DataRange", canrx_var_range, "RowNamesRange", canrx_row_names_range);

            cantx_var_names = {'Factor', 'Offset', 'Max', 'Min', 'Invalid Status', 'Error Indicator Value', 'Output', 'Elevel'};
            cantx_var_types = {'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string'};
            cantx_var_namerules = 'preserve';
            cantx_var_range = 'B2';
            cantx_row_names_range = 'A2';
            cantx_var_nums = 8;
            obj.cantx_xls_opt = spreadsheetImportOptions("NumVariables", cantx_var_nums, "VariableNames", cantx_var_names, "VariableTypes", cantx_var_types, "VariableNamingRule", cantx_var_namerules, "DataRange", cantx_var_range, "RowNamesRange", cantx_row_names_range);

            obj.mbd_cantx = autoMBDCanTx(obj.ram_sht_tbl, obj.rom_sht_tbl);
            obj.mbd_canrx = autoMBDCanRx(obj.ram_sht_tbl, obj.rom_sht_tbl);
        end

        function load(obj, in_xls_path)

            in_sht_names = sheetnames(in_xls_path);
            for i_name = 1: length(in_sht_names)
                if ismember(in_sht_names(i_name), obj.msg_class)
                    id_flag = in_sht_names(i_name);
                    continue
                end

                if strcmp(id_flag, "TxNormal")
                    obj.cantx_xls_opt.Sheet = in_sht_names(i_name);
                    cantx_sht_tbl = readtable(in_xls_path, obj.cantx_xls_opt);
                    for i_row = 1:length(cantx_sht_tbl.Row)
                        row_name = cantx_sht_tbl.Row(i_row);
                        lsb_str = join([obj.ram_sht_tbl(row_name, 'numerator').Variables  '/'  obj.ram_sht_tbl(row_name, 'denominator').Variables], '');
                        resolution_str = obj.ram_sht_tbl(row_name, 'Resolution').Variables;
                        in_lsb_str = cantx_sht_tbl(row_name, 'Factor').Variables;
                        if ~(strcmp(in_lsb_str, lsb_str) || strcmp(in_lsb_str, resolution_str))
                            me = MException('CAN:noSuchLSB', '%s lsb not equal to DD', row_name{1});
                            throw(me)
                        end
                        cantx_sht_tbl(row_name,'Elevel') = obj.ram_sht_tbl(row_name,'E.Level');
                    end
                    obj.tx_normal_dict(in_sht_names(i_name)) = cantx_sht_tbl;
                elseif strcmp(id_flag, "RxNormal")
                    obj.canrx_xls_opt.Sheet = in_sht_names(i_name);
                    canrx_sht_tbl = readtable(in_xls_path, obj.canrx_xls_opt);
                    for i_row = 1:length(canrx_sht_tbl.Row)
                        row_name = canrx_sht_tbl.Row(i_row);
                        lsb_str = join([obj.ram_sht_tbl(row_name, 'numerator').Variables  '/'  obj.ram_sht_tbl(row_name, 'denominator').Variables], '');
                        resolution_str = obj.ram_sht_tbl(row_name, 'Resolution').Variables;
                        in_lsb_str = canrx_sht_tbl(row_name, 'Factor').Variables;
                        if ~(strcmp(in_lsb_str, lsb_str) || strcmp(in_lsb_str, resolution_str))
                            me = MException('CAN:noSuchLSB', '%s lsb not equal to DD', row_name{1});
                            throw(me)
                        end
                    end
                    obj.rx_normal_dict(in_sht_names(i_name)) = canrx_sht_tbl;
                end
            end
        end

        function gen_model(obj)
%             for i_key = keys(obj.tx_normal_dict)
%                 model_path = obj.output_model_path;
%                 model_name = ['cantx_0x' i_key{1}];
%                 model_info = obj.tx_normal_dict(i_key{1});
%                 per_save_path = [model_path '\' model_name];
%                 obj.mbd_cantx.gen_normal_model(per_save_path, model_name, model_info)
%             end
            for i_key = keys(obj.rx_normal_dict)
                model_path = obj.output_model_path;
                model_name = ['canrx_0x' i_key{1}];
                model_info = obj.rx_normal_dict(i_key{1});
                per_save_path = [model_path '\' model_name];
                obj.mbd_canrx.gen_normal_model(per_save_path, model_name, model_info)
            end
        end

        function gen_code(obj)
%             for i_key = keys(obj.tx_normal_dict)
%                 model_path = obj.output_model_path;
%                 model_name = ['cantx_0x' i_key{1}];
%                 per_save_path = [model_path '\' model_name];
%                 obj.mbd_cantx.gen_normal_code(per_save_path, model_name);
%             end
            for i_key = keys(obj.rx_normal_dict)
                model_path = obj.output_model_path;
                model_name = ['canrx_0x' i_key{1}];
                per_save_path = [model_path '\' model_name];
                obj.mbd_canrx.gen_normal_code(per_save_path, model_name);
            end
        end

    end
end