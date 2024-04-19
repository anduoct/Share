classdef autosarMBD < handle
    properties
        dd_sht_tbl
        case_key
        case_value
        case_dict
        cantx_normal
        cantx_error
        cantx_noerror
        cantx_info
        cantx_sldd
        main_base_width
        main_base_up
        main_base_down
        main_port_interval
        main_port_offset
        swt_base_width
        swt_base_up
        swt_base_down
        swt_port_interval
        swt_port_offset
        case_subsystem_base_width
        case_subsystem_base_up
        case_subsystem_base_down
        elvl_sub_interval
        case_subsystem_port_interval
        case_subsystem_port_offset
        sig_base_pos
        sig_sub_interval
        case_str
        sldd_obj
        design_data
    end

    methods
        function obj = autosarMBD(dd_sht_tbl)
            obj.dd_sht_tbl = dd_sht_tbl;
            obj.case_key = {'2X', '4X', '8X', '16X', '25X', '32X', '64X', '128X', '200X', '250X', '256X', 'REF'};
            obj.case_value = {'PLCANI_APCNTL_SET_INF_2X', 'PLCANI_APCNTL_SET_INF_4X', 'PLCANI_APCNTL_SET_INF_8X', 'PLCANI_APCNTL_SET_INF_16X', 'PLCANI_APCNTL_SET_INF_25X', 'PLCANI_APCNTL_SET_INF_32X', 'PLCANI_APCNTL_SET_INF_64X', 'PLCANI_APCNTL_SET_INF_128X', 'PLCANI_APCNTL_SET_INF_200X', 'PLCANI_APCNTL_SET_INF_250X', 'PLCANI_APCNTL_SET_INF_256X', 'PLCANI_APCNTL_SET_INF_REF'};
            obj.case_dict = containers.Map(obj.case_key, obj.case_value);



            obj.cantx_normal = 'Lib/cantx_normal';
            obj.cantx_error = 'Lib/cantx_error';
            obj.cantx_noerror = 'Lib/cantx_noerror';
            obj.cantx_sldd = which('Lib.sldd');

            obj.main_base_width = [240 650];
            obj.main_base_up = 25;
            obj.main_base_down = 0;
            obj.main_port_interval = 30;
            obj.main_port_offset = 20;

            obj.swt_base_width = [240 445];
            obj.swt_base_up = 25;
            obj.swt_base_down = 0;
            obj.swt_port_interval = 25;
            obj.swt_port_offset = 10;

            obj.case_subsystem_base_width = [1000 1510];
            obj.case_subsystem_base_up = 150;
            obj.case_subsystem_base_down = 0;
            obj.elvl_sub_interval = 70;
            obj.case_subsystem_port_interval = 30;
            obj.case_subsystem_port_offset = 10;

            obj.sig_base_pos = [-125 25 530 85];
            obj.sig_sub_interval = 90;

            obj.case_str = '';
        end


        function gen_tx_normal_model(obj, save_path, model_name, model_info)
            obj.cantx_info = model_info;
            
            rmdir(save_path, 's')
            mkdir(save_path);
            addpath(save_path)

            sldd_path = [save_path '\' model_name '.sldd'];
            copyfile(obj.cantx_sldd, sldd_path);

            tx_normal_model = new_system(model_name);
            set_param(tx_normal_model, 'Datadictionary',[model_name '.sldd'])
            set_param(tx_normal_model, 'SetExecutionDomain', 'on','ExecutionDomainType', 'ExportFunction', 'IsExportFunctionModel', 'on');

            open_system(tx_normal_model);

            main_subsystem_path = [model_name '/' model_name '_main'];
            obj.add_tx_normal_subsystem(main_subsystem_path);
            obj.add_subsystem_port(main_subsystem_path);


%             set_param(main_subsystem_path, 'FunctionInterfaceSpec', 'Allow arguments (Optimized)', 'RTWFileNameOpts', 'Use subsystem name');
            set_param(tx_normal_model, 'ZoomFactor', '100');
            save_system(tx_normal_model, [save_path, '\' , model_name, '.slx']);
            close_system(tx_normal_model);
        end


        function system_hdl = add_tx_normal_subsystem(obj, subsystem_path)
            % 初始化 case subsystem 位置
            obj.case_subsystem_base_up = 150;
            obj.case_subsystem_base_down = 0;
            % 新增 cantx_normal 模板
            system_hdl = add_block(obj.cantx_normal, subsystem_path);
            % 获取 system name
            subsystem_name = get_param(subsystem_path, 'Name');
            % 计算 tx case 数
            tx_case_list = obj.case_key(ismember(obj.case_key, unique(obj.cantx_info.Elevel)));
            % 设置 Switch Case 参数
            swt_blk_path = [subsystem_path '/Switch Case'];            
            obj.swt_base_down = obj.swt_base_up + length(tx_case_list) * obj.swt_port_interval + obj.swt_port_offset;
            obj.case_str = '';
            for i_case = 1:length(tx_case_list)
                tx_case_cell = tx_case_list(i_case);
                if i_case ~= length(tx_case_list)
                    obj.case_str = [obj.case_str 'PLCANI_APCNTL_SET_INF_TYPE.' obj.case_dict(tx_case_cell{1}) ','];
                else
                    obj.case_str = [obj.case_str 'PLCANI_APCNTL_SET_INF_TYPE.' obj.case_dict(tx_case_cell{1})];
                end
            end
            set_param(swt_blk_path, 'CaseConditions' , ['{' obj.case_str '}'], 'Position', [obj.swt_base_width(1), obj.swt_base_up, obj.swt_base_width(2), obj.swt_base_down]);
            % 设置 ArgIn 参数
            arg_in_path = [subsystem_path '/trigger'];
            swt_in_pos = get_param(get_param(swt_blk_path, 'PortHandles').Inport(1), 'Position');
            arg_in_pos =  [swt_in_pos(1)-170, swt_in_pos(2)-7, swt_in_pos(1)-120, swt_in_pos(2)+7];
            set_param(arg_in_path, 'Position', arg_in_pos, 'OutDataTypeStr', 'Enum: PLCANI_APCNTL_SET_INF_TYPE');
            % 设置 Trigger Port 参数
            trg_port_path = [subsystem_path '/cantx_normal'];
            trg_port_pos = [swt_in_pos(1)-155, swt_in_pos(2)-150, swt_in_pos(1)-135, swt_in_pos(2)-135];
            set_param(trg_port_path, 'Position', trg_port_pos, 'FunctionName', subsystem_name, 'FunctionPrototype', [subsystem_name '(trigger)']);
            % 获取 Swicth Case 输出端口
            swt_blk_hdls = get_param(swt_blk_path, 'PortHandles');
            % 循环增加sig_case_subsystem
            for i_case = 1:length(tx_case_list)
                case_name = tx_case_list(i_case);
                sig_case_subsystem_path = [subsystem_path '/' subsystem_name '_' case_name{1}];

                sig_case_info = obj.cantx_info(strcmp(obj.cantx_info.Elevel, case_name),:);
                obj.add_tx_sig_case_subsystem(sig_case_subsystem_path, sig_case_info);

                case_subsystem_port_hdls = get_param(sig_case_subsystem_path, 'PortHandles');
                case_subsystem_port_num = length(case_subsystem_port_hdls.Inport);
                obj.case_subsystem_base_down = obj.case_subsystem_base_up + obj.case_subsystem_port_interval*case_subsystem_port_num + obj.case_subsystem_port_offset;
                sig_case_subsystem_pos =  [obj.case_subsystem_base_width(1) obj.case_subsystem_base_up obj.case_subsystem_base_width(2) obj.case_subsystem_base_down];
                obj.case_subsystem_base_up = obj.case_subsystem_base_down + obj.elvl_sub_interval;

                set_param(sig_case_subsystem_path, 'Position', sig_case_subsystem_pos);

                add_line(subsystem_path, swt_blk_hdls.Outport(i_case), case_subsystem_port_hdls.Ifaction(1), 'autorouting','on');

                obj.add_subsystem_port(sig_case_subsystem_path);

                set_param(sig_case_subsystem_path, 'ZoomFactor', '100')
                set_param(sig_case_subsystem_path, 'RTWSystemCode', 'Reusable function')
            end
            port_num = length(get_param(subsystem_path, 'PortHandles').Inport);
            obj.main_base_down = obj.main_base_up + obj.main_port_interval*port_num + obj.main_port_offset;
            set_param(subsystem_path, 'Position', [obj.main_base_width(1) obj.main_base_up obj.main_base_width(2) obj.main_base_down])
        end

        function system_hdl = add_tx_sig_case_subsystem(obj, subsystem_path, sig_case_info)
            % 新增 swtich case subsystem
            system_hdl = add_block('simulink/Ports & Subsystems/Switch Case Action Subsystem', subsystem_path);
            % 删除原有的 in out line
            del_in_hdl = getSimulinkBlockHandle([subsystem_path '/In1']);
            del_out_hdl = getSimulinkBlockHandle([subsystem_path '/Out1']);
            del_line_hdl = get_param(del_in_hdl, 'LineHandles');
            delete_block([del_in_hdl, del_out_hdl]);
            delete_line(del_line_hdl.Outport(1));
            % 批量新增 sig subsystem
            for i_sig = 1:length(sig_case_info.Row)
                sig_info = sig_case_info(i_sig,:);
                sig_name = sig_info.Row{1};
                sig_subsystem_path = [subsystem_path '/sig_' sig_name];
                sig_subsystem_pos = [obj.sig_base_pos(1), obj.sig_base_pos(2) + i_sig * obj.sig_sub_interval, obj.sig_base_pos(3), obj.sig_base_pos(4) + i_sig * obj.sig_sub_interval];
                % 新增 sig subsystem
                obj.add_tx_sig_subsystem(sig_subsystem_path, sig_subsystem_pos, sig_info);
                % 配置 sig subsystem 端口
                obj.add_subsystem_port(sig_subsystem_path)
                % 配置 sig subsystem 属性
                set_param(sig_subsystem_path, 'ZoomFactor', '100')
                set_param(sig_subsystem_path, 'RTWSystemCode', 'Reusable function', 'TreatAsAtomicUnit', 'on')
            end
        end


        function subsystem_hdl = add_tx_sig_subsystem(obj, subsystem_path, subsystem_pos, sig_case_info)
            % 通过表格判读新增 sig subsystem 类型
            sig_name = sig_case_info.Row{1};
            if contains(sig_case_info.("Invalid Status"), 'always FALSE')
                subsystem_hdl = add_block(obj.cantx_noerror, subsystem_path, 'Position', subsystem_pos);
            else
                subsystem_hdl = add_block(obj.cantx_error, subsystem_path, 'Position', subsystem_pos);
                % 修改 can error status 名
                error_name = ['CanTx_Err_' sig_name];
                obj.modify_port_name('In', subsystem_path, 'cantx_inv_status', error_name)
            end
            % 修改 can in 名
            obj.modify_port_name('In', subsystem_path, 'cantx_phy', sig_name)   
            % 修改 can out 名
            outport_name = ['CanTx_' sig_name];
            obj.modify_port_name('Out', subsystem_path, 'cantx_raw', outport_name)
            % 配置 LSB Offset
%             mask_values = {sig_case_info.Offset, sig_case_info.Factor};
%             set_param([subsystem_path '/Phy2Raw'], 'MaskValues', mask_values); 
            % 配置上下限
            set_param([subsystem_path '/Max'], 'Value', sig_case_info.Max);
            set_param([subsystem_path '/Min'], 'Value', sig_case_info.Min);
        end

        function modify_port_name(~, port_dire, subsystem_path, ori_name, dst_name)
            if strcmp(port_dire, 'In')
                line_handle = get_param([subsystem_path '/' ori_name], 'LineHandles').Outport;
            elseif strcmp(port_dire, 'Out')
                line_handle = get_param([subsystem_path '/' ori_name], 'LineHandles').Inport;
            end
            set_param([subsystem_path '/' ori_name], 'Name', dst_name);
            set_param(line_handle, 'Name', dst_name);
        end

        function add_subsystem_port(~, subsystem_path)
            parent_path = get_param(subsystem_path, 'Parent');
            subsystem_name = get_param(subsystem_path, 'Name');
            inport_names = get_param(find_system(subsystem_path, 'SearchDepth', 1, 'BlockType', 'Inport'), 'Name');
            in_handles = get_param(subsystem_path, 'PortHandles').Inport;
            for i_in = 1:length(in_handles)
                in_pos = get_param(get_param(subsystem_path, 'PortHandles').Inport(i_in), 'Position');
                inport_pos =  [in_pos(1)-230, in_pos(2)-7, in_pos(1)-200, in_pos(2)+7];
                add_block('simulink/Sources/In1', [parent_path '/' inport_names{i_in}], 'Name', inport_names{i_in},'Position', inport_pos)
                add_line(parent_path, [inport_names{i_in} '/1'], [subsystem_name '/' num2str(i_in)]);     
            end
            outport_names = get_param(find_system(subsystem_path, 'SearchDepth', 1, 'BlockType', 'Outport'), 'Name');
            out_handles = get_param(subsystem_path, 'PortHandles').Outport;
            for i_out = 1:length(out_handles)
                out_pos = get_param(get_param(subsystem_path, 'PortHandles').Outport(i_out), 'Position');
                outport_pos =  [out_pos(1)+200, out_pos(2)-7, out_pos(1)+230, out_pos(2)+7];
                add_block('simulink/Sinks/Out1', [parent_path '/' outport_names{i_out}], 'Name',outport_names{i_out},'Position', outport_pos)
                add_line(parent_path, [subsystem_name '/' num2str(i_out)], [outport_names{i_out} '/1']);
            end
        end

        function gen_tx_normal_code(obj, save_path, model_name)
            cd(save_path)
            open_system(model_name)
            sldd_path = [save_path '\' model_name '.sldd'];
            obj.sldd_obj = Simulink.data.dictionary.open(sldd_path);
            obj.design_data = getSection(obj.sldd_obj,'Design Data');

            obj.modify_model_config(model_name)

            trg_sig = Simulink.Signal;
            trg_sig.DataType = 'Enum: PLCANI_APCNTL_SET_INF_TYPE';
            mdl_wks = get_param(model_name, 'ModelWorkspace');
            assignin(mdl_wks, "trigger", trg_sig);

            obj.add_subsystem_port_resolve(model_name)

            obj.sldd_obj.saveChanges()
            obj.sldd_obj.close()
            save_system(model_name);
        end

        function modify_model_config(~, model_name)
            sldd_cfg = Simulink.ConfigSetRef;
            set_param(sldd_cfg, 'Name', 'SLDD_CFG', 'SourceName', 'SLDD_CFG')
            attachConfigSet(model_name, sldd_cfg);
            setActiveConfigSet(model_name,'SLDD_CFG');
        end

        function add_subsystem_port_resolve(obj, subsystem_path)
            obj.add_inport_resolve(subsystem_path);
            obj.add_outport_resolve(subsystem_path);
        end

        function add_inport_resolve(obj, subsystem_path)
            inport_path_list = find_system(subsystem_path, 'SearchDepth', 1, 'BlockType', 'Inport');
            inport_name_list = get_param(inport_path_list, 'NAME');
            inport_line_hdls = get_param(inport_path_list, 'LineHandles');
            for i_hdl = 1:length(inport_line_hdls)
                set_param(inport_line_hdls{i_hdl}.Outport, 'Name', inport_name_list{i_hdl});
                set(inport_line_hdls{i_hdl}.Outport, 'MustResolveToSignalObject', 1);
                obj.add_signal_to_sldd(inport_name_list{i_hdl});
            end
        end

        function add_outport_resolve(obj, subsystem_path)
            outport_path_list = find_system(subsystem_path, 'SearchDepth', 1, 'BlockType', 'Outport');
            outport_name_list = get_param(outport_path_list, 'NAME');
            for i_hdl = 1:length(outport_path_list)
                set_param(outport_path_list{i_hdl}, 'SignalName', outport_name_list{i_hdl});
                hdl = get_param(outport_path_list{i_hdl}, 'Handle');
                set(hdl, 'MustResolveToSignalObject', 1);
                obj.add_signal_to_sldd(outport_name_list{i_hdl});
            end
        end

        function add_signal_to_sldd(obj, signal_name)
            sig = Simulink.Signal;
            sig.CoderInfo.StorageClass = "ExportedGlobal";
            sig_info = obj.dd_sht_tbl(signal_name,:);
            if strcmp(sig_info.Resolution, "1")
                sig.DataType = sig_info.Label;
            else
                tx_info = obj.cantx_info(signal_name,:);
                if strcmp(sig_info.Label, "UB")
                    sig.DataType = strcat("fixdt(0, 8, ", sig_info.numerator , "/" , sig_info.denominator, ", ", tx_info.Offset, ")");
                elseif strcmp(sig_info.Label, "UW")
                    sig.DataType = strcat("fixdt(0, 16, ", sig_info.numerator , "/" , sig_info.denominator, ", ", tx_info.Offset, ")");
                elseif strcmp(sig_info.Label, "UD")
                    sig.DataType = strcat("fixdt(0, 32, ", sig_info.numerator , "/" , sig_info.denominator, ", ", tx_info.Offset, ")");
                elseif strcmp(sig_info.Label, "SB")
                    sig.DataType = strcat("fixdt(0, 8, ", sig_info.numerator , "/" , sig_info.denominator, ", ", tx_info.Offset, ")");
                elseif strcmp(sig_info.Label, "SW")
                    sig.DataType = strcat("fixdt(0, 16, ", sig_info.numerator , "/" , sig_info.denominator, ", ", tx_info.Offset, ")");
                elseif strcmp(sig_info.Label, "SD")
                    sig.DataType = strcat("fixdt(0, 32, ", sig_info.numerator , "/" , sig_info.denominator, ", ", tx_info.Offset, ")");
                end
            end
            addEntry(obj.design_data, signal_name, sig)
        end

    end

end