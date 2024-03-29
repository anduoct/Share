classdef autosarCan < handle

    properties
        tx_normal_celllist
        rx_normal_celllist
        id_strlist
        current_path
    end

    methods
        function obj = autosarCan()
            obj.tx_normal_celllist = [];
            obj.rx_normal_celllist = [];
            obj.id_strlist = ["TxNormal"; "RxNormal"];

            m_file = mfilename('fullpath');
            [obj.current_path, ~, ~] =  fileparts(m_file);
        end

        function load(obj, xls_file_path)
            sheet_strlist = sheetnames(xls_file_path);
            for i_str = 1: length(sheet_strlist)
                if ismember(sheet_strlist(i_str), obj.id_strlist)
                    id_flag = sheet_strlist(i_str);
                    continue
                end
                sht_tbl = readtable(xls_file_path, 'Sheet', i_str, 'VariableNamingRule','preserve');
                if strcmp(id_flag, "TxNormal")
                    obj.tx_normal_celllist = [obj.tx_normal_celllist, {sht_tbl}];
                elseif strcmp(id_flag, "RxNormal")
                    obj.rx_normal_celllist = [obj.rx_normal_celllist, {sht_tbl}];
                end
            end
        end

        function gen_model(obj)

        end

    end
end