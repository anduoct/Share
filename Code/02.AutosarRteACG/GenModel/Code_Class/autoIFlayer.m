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
            obj.mbd_canrx = autoMBDRx(ram_sht_tbl, rom_sht_tbl);
        end

        function tbl = load_tx_normal_sum(obj, sht_name)
            var_nums = 2;
            var_names = {'No.', 'E.Level'};
            var_types = {'string', 'string'};
            var_namerules = 'preserve';
            var_range = 'A2';
            row_names_range = 'A2';
            xls_opt = spreadsheetImportOptions("NumVariables", var_nums, "VariableNames", var_names, "VariableTypes", var_types, "VariableNamingRule", var_namerules, "DataRange", var_range, "RowNamesRange", row_names_range);
            xls_opt.Sheet = sht_name;
            tbl = readtable(obj.in_xls_path, xls_opt);
        end

        function tbl = load_tx_normal(obj, sht_name)
            var_nums = 10;
            var_names = {'Interface', 'IFlayer Name', 'Signal', 'Data Type', 'Invalid Status', 'Factor', 'Offset', 'Min', 'Max', 'SignalId'};
            var_types = {'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string'};
            var_namerules = 'preserve';
            var_range = 'A2';
            row_names_range = 'A2';
            xls_opt = spreadsheetImportOptions("NumVariables", var_nums, "VariableNames", var_names, "VariableTypes", var_types, "VariableNamingRule", var_namerules, "DataRange", var_range, "RowNamesRange", row_names_range);
            xls_opt.Sheet = sht_name;
            tbl = readtable(obj.in_xls_path, xls_opt);
        end

        function tbl = load_rx_normal_timeout_sum(obj, sht_name)
            var_nums = 9;
            var_names = {'No.', 'FrameID', 'J1939/ISO', 'Timeout flag', 'SIGNALGROUP NAME', 'IFLayer_rx_cmplt_xxx', 'IFLayer_rx_timeout_xxx', 'can_gmlan_cmplt_xxx', 'can_gmlan_rx_timeout_xxx'};
            var_types = {'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string'};
            var_namerules = 'preserve';
            var_range = 'A2';
            row_names_range = 'A2';
            xls_opt = spreadsheetImportOptions("NumVariables", var_nums, "VariableNames", var_names, "VariableTypes", var_types, "VariableNamingRule", var_namerules, "DataRange", var_range, "RowNamesRange", row_names_range);
            xls_opt.Sheet = sht_name;
            tbl = readtable(obj.in_xls_path, xls_opt);
        end

        function tbl = load_rx_normal_timeout(obj, sht_name)
            var_nums = 23;
            var_names = {'Signal Index', 'IFLayer_Signal', 'Data Type', 'Factor', 'Offset', 'Min', 'Max', 'Invalid Status', 'Error Indicator Value', 'Receive Parameter Invalid Status', 'Receive Parameter', '2-5-4 Requeset Paramter Select Flag', 'K_CAN_RX_SEL_XXX',  'Receive Parameter Invalid Status 2', 'Receive Parameter 2', 'RxSel Parameter Invalid Status', 'RxSel Parameter', '3-1-1 Requeset Paramter Select Flag', 'K_CAN_RQST_SEL_XXX', 'K_RQST_DRCT_XXX', 'can_rqst_xxx', 'can_invalid_can_rqst_xxx', 'interface'};
            var_types = {'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string'};
            var_namerules = 'preserve';
            var_range = 'A2';
            row_names_range = 'A2';
            xls_opt = spreadsheetImportOptions("NumVariables", var_nums, "VariableNames", var_names, "VariableTypes", var_types, "VariableNamingRule", var_namerules, "DataRange", var_range, "RowNamesRange", row_names_range);
            xls_opt.Sheet = sht_name;
            tbl = readtable(obj.in_xls_path, xls_opt);
        end

        function load(obj, in_xls_path)
            obj.in_xls_path = in_xls_path;
            %% TX Normal
            tx_normal_sum_tbl = obj.load_tx_normal_sum('TxNormal');
            for i_row = 1:length(tx_normal_sum_tbl.Row)
                sht_name = tx_normal_sum_tbl.("E.Level")(i_row);
                sht_info.detail = obj.load_tx_normal(sht_name);
                obj.tx_normal_dict(sht_name) = sht_info;
            end
            %% RX Normal & RX TIMEOUT
            rx_normal_sum_tbl = obj.load_rx_normal_timeout_sum('RxNormal&RxTimeout');
            for i_row = 1:length(rx_normal_sum_tbl.Row)
                sht_name = rx_normal_sum_tbl.("FrameID")(i_row);
                sht_info.summary = rx_normal_sum_tbl(i_row,:);
                sht_info.detail = obj.load_rx_normal_timeout(sht_name);
                obj.rx_normal_dict(sht_name) = sht_info;
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
            for i_key = keys(obj.rx_normal_dict)
                model_path = obj.output_model_path;
                model_name = ['canrx_0x' i_key{1}];
                model_info = obj.rx_normal_dict(i_key{1});
                per_save_path = [model_path '\' model_name];
                obj.mbd_canrx.gen_normal_model(per_save_path, model_name, model_info)
            end
        end

        function gen_code(obj)
            for i_key = keys(obj.tx_normal_dict)
                model_path = obj.output_model_path;
                model_name = ['cantx_' i_key{1}];
                per_save_path = [model_path '\' model_name];
                obj.mbd_cantx.gen_normal_code(per_save_path, model_name);
            end
            for i_key = keys(obj.rx_normal_dict)
                model_path = obj.output_model_path;
                model_name = ['canrx_0x' i_key{1}];
                per_save_path = [model_path '\' model_name];
                obj.mbd_canrx.gen_normal_code(per_save_path, model_name);
            end
        end

    end
end