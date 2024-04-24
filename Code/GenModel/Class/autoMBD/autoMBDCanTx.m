classdef autoMBDCanTx < autoMBD
    properties
        can_info
        can_sldd
        normal_mdl
        error_sub
        noerror_sub
        normal_sub_base_pos
        normal_sub_port_interval
        case_key
        case_dict
        case_str
        swt_blk_base_pos
        swt_blk_port_interval
        case_sub_base_pos
        case_sub_interval
        case_sub_port_interval
        sig_sub_base_pos
        sig_sub_interval
    end
    methods
        function obj = autoMBDCanTx(dd_sht_tbl)
            obj = obj@autoMBD(dd_sht_tbl);
            obj.can_sldd = which('cantx.sldd');
            obj.normal_mdl = 'Lib/cantx_normal';
            obj.error_sub = 'Lib/cantx_error';
            obj.noerror_sub = 'Lib/cantx_noerror';
            obj.normal_sub_base_pos = [240 25 650 45];
            obj.normal_sub_port_interval = 30;
            obj.case_key = {'INIT', '2X', '4X', '8X', '16X', '25X', '32X', '64X', '128X', '200X', '250X', '256X', 'REF'};
            case_value = {'PLCANI_APCNTL_SET_INF_INIT', 'PLCANI_APCNTL_SET_INF_2X', 'PLCANI_APCNTL_SET_INF_4X', 'PLCANI_APCNTL_SET_INF_8X', 'PLCANI_APCNTL_SET_INF_16X', 'PLCANI_APCNTL_SET_INF_25X', 'PLCANI_APCNTL_SET_INF_32X', 'PLCANI_APCNTL_SET_INF_64X', 'PLCANI_APCNTL_SET_INF_128X', 'PLCANI_APCNTL_SET_INF_200X', 'PLCANI_APCNTL_SET_INF_250X', 'PLCANI_APCNTL_SET_INF_256X', 'PLCANI_APCNTL_SET_INF_REF'};
            obj.case_dict = containers.Map(obj.case_key, case_value);
            obj.case_str = '';
            obj.swt_blk_base_pos = [240 25 445 10];
            obj.swt_blk_port_interval = 25;
            obj.case_sub_base_pos = [1000 150 1510 10];
            obj.case_sub_interval = 70;
            obj.case_sub_port_interval = 30;
            obj.sig_sub_base_pos = [-125 25 530 85];
            obj.sig_sub_interval = 90;
        end
        function gen_normal_model(obj, save_path, model_name, model_info)
            %% 关闭并清除所有
            obj.clear_all();
            %% 获取 cantx info
            obj.can_info = model_info;
            %% 配置生成模型路径及拷贝 sldd
            if exist(save_path,'dir')
                rmdir(save_path, 's')
            end
            mkdir(save_path);
            addpath(save_path)
            sldd_path = [save_path '\' model_name '.sldd'];
            copyfile(obj.can_sldd, sldd_path);
            %% 新建并打开 tx normal model
            tx_normal_model = new_system(model_name);
            open_system(tx_normal_model);
            %% 配置 tx normal model 代码导出方式 sldd 及 缩放率
            set_param(tx_normal_model, 'SetExecutionDomain', 'on','ExecutionDomainType', 'ExportFunction', 'IsExportFunctionModel', 'on');
            set_param(tx_normal_model, 'Datadictionary',[model_name '.sldd'])
            %% 添加 tx normal subsystem
            main_subsystem_path = [model_name '/' model_name '_main'];
            obj.add_normal_subsystem(main_subsystem_path);
            % 配置 tx normal subsystem 位置
            port_num = length(get_param(main_subsystem_path, 'PortHandles').Inport);
            normal_sub_pos = obj.normal_sub_base_pos + [0 0 0 obj.normal_sub_port_interval*port_num];
            set_param(main_subsystem_path, 'Position', normal_sub_pos)
            % 添加 tx normal model 输入
            obj.add_subsystem_port(main_subsystem_path);
            %% 配置 tx normal model 缩放大小
            set_param(tx_normal_model, 'ZoomFactor', '100');
            %% 保存并关闭 tx normal model
            save_system(tx_normal_model, [save_path, '\' , model_name, '.slx']);
            close_system(tx_normal_model);
            %% 关闭并清除所有
            obj.clear_all();
        end

        function system_hdl = add_normal_subsystem(obj, subsystem_path)
            %% 初始化 case subsystem 位置
            obj.case_sub_base_pos = [1000 150 1510 10];
            %% 添加 cantx_normal 模板
            system_hdl = add_block(obj.normal_mdl, subsystem_path);
            %% 获取 system name
            sub_name = get_param(subsystem_path, 'Name');
            %% 计算 tx case 数
            case_list = obj.case_key(ismember(obj.case_key, unique(obj.can_info.Elevel)));
            case_num = length(case_list);
            %% 设置 Switch Case 参数
            swt_blk_path = [subsystem_path '/Switch Case'];
            obj.case_str = 'PLCANI_APCNTL_SET_INF_TYPE.PLCANI_APCNTL_SET_INF_INIT';
            for i_case = 1:case_num
                tx_case_cell = case_list(i_case);
                obj.case_str = [obj.case_str ',' 'PLCANI_APCNTL_SET_INF_TYPE.' obj.case_dict(tx_case_cell{1})];
            end
            swt_blk_pos = obj.swt_blk_base_pos + [0 0 0 case_num*obj.swt_blk_port_interval];
            set_param(swt_blk_path, 'CaseConditions' , ['{' obj.case_str '}'], 'Position', swt_blk_pos);
            %% 设置 ArgIn 参数
            arg_in_path = [subsystem_path '/trigger'];
            swt_in_pos = get_param(get_param(swt_blk_path, 'PortHandles').Inport(1), 'Position');
            arg_in_pos =  [swt_in_pos(1)-170, swt_in_pos(2)-7, swt_in_pos(1)-120, swt_in_pos(2)+7];
            set_param(arg_in_path, 'Position', arg_in_pos, 'OutDataTypeStr', 'Enum: PLCANI_APCNTL_SET_INF_TYPE');
            %% 设置 Trigger Port 参数
            trg_port_path = [subsystem_path '/cantx_normal'];
            trg_port_pos = [swt_in_pos(1)-155, swt_in_pos(2)-150, swt_in_pos(1)-135, swt_in_pos(2)-135];
            set_param(trg_port_path, 'Position', trg_port_pos, 'FunctionName', sub_name, 'FunctionPrototype', [sub_name '(trigger)']);
            %% 获取 Swicth Case 输出端口
            swt_blk_hdls = get_param(swt_blk_path, 'PortHandles');
            %%  添加 Init Case Subsystem
            init_case_sub_path = [subsystem_path '/' sub_name(1:end-5) '_Init'];
            obj.add_sig_case_subsystem(init_case_sub_path, obj.can_info);
            init_case_sub_port_hdls = get_param(init_case_sub_path, 'PortHandles');
            init_case_sub_port_num = length(init_case_sub_port_hdls.Inport);
            % 配置 Init Case Subsystem 位置
            obj.case_sub_base_pos(4) = obj.case_sub_base_pos(2) + (obj.case_sub_port_interval+25)*init_case_sub_port_num;
            init_case_sub_pos =  obj.case_sub_base_pos;
            obj.case_sub_base_pos(2) = obj.case_sub_base_pos(4) + obj.case_sub_interval;
            set_param(init_case_sub_path, 'Position', init_case_sub_pos);
            % Switch 与 Init Case Subsystem 连线
            add_line(subsystem_path, swt_blk_hdls.Outport(1), init_case_sub_port_hdls.Ifaction(1), 'autorouting','on');
            % 添加 Init Case Subsystem 输入端口
            obj.add_subsystem_inport(init_case_sub_path);
            %% 循环添加非 Init Case Subsystem
            for i_case = 1:case_num
                case_name = case_list(i_case);
                sig_case_sub_path = [subsystem_path '/' sub_name(1:end-5) '_' case_name{1}];
                sig_case_info = obj.can_info(strcmp(obj.can_info.Elevel, case_name),:);
                obj.add_sig_case_subsystem(sig_case_sub_path, sig_case_info);
                case_sub_port_hdls = get_param(sig_case_sub_path, 'PortHandles');
                case_sub_port_num = length(case_sub_port_hdls.Inport);
                % 配置非 Init Case Subsystem 位置
                obj.case_sub_base_pos(4) = obj.case_sub_base_pos(2) + obj.case_sub_port_interval*case_sub_port_num;
                sig_case_sub_pos =  obj.case_sub_base_pos;
                obj.case_sub_base_pos(2) = obj.case_sub_base_pos(4) + obj.case_sub_interval;
                set_param(sig_case_sub_path, 'Position', sig_case_sub_pos);
                % Switch 与非 Init Case Subsystem 连线
                add_line(subsystem_path, swt_blk_hdls.Outport(1+i_case), case_sub_port_hdls.Ifaction(1), 'autorouting','on');
                % 添加 Init Case Subsystem 输入端口
                obj.add_subsystem_inport(sig_case_sub_path);
                % 合并 Case Subsystem 共有输出端口
                obj.add_subsystem_merge_outport(init_case_sub_path, sig_case_sub_path);
            end
            %% 配置 tx normal subsystem 缩放大小
            set_param(subsystem_path, 'ZoomFactor', '100')
        end

        function system_hdl = add_sig_case_subsystem(obj, subsystem_path, sig_case_info)
            %% 添加 swtich case subsystem
            system_hdl = add_block('simulink/Ports & Subsystems/Switch Case Action Subsystem', subsystem_path);
            %% 删除原有的 in out line
            del_in_hdl = getSimulinkBlockHandle([subsystem_path '/In1']);
            del_out_hdl = getSimulinkBlockHandle([subsystem_path '/Out1']);
            del_line_hdl = get_param(del_in_hdl, 'LineHandles');
            delete_block([del_in_hdl, del_out_hdl]);
            delete_line(del_line_hdl.Outport(1));
            %% 批量添加 sig subsystem
            for i_sig = 1:length(sig_case_info.Row)
                sig_info = sig_case_info(i_sig,:);
                sig_name = sig_info.Row{1};
                sig_sub_path = [subsystem_path '/sig_' sig_name];
                sig_sub_pos = [obj.sig_sub_base_pos(1), obj.sig_sub_base_pos(2) + i_sig * obj.sig_sub_interval, obj.sig_sub_base_pos(3), obj.sig_sub_base_pos(4) + i_sig * obj.sig_sub_interval];
                % 添加 sig subsystem
                obj.add_sig_subsystem(sig_sub_path, sig_sub_pos, sig_info);
                % 配置 sig subsystem 端口
                obj.add_subsystem_port(sig_sub_path);
            end
            %% 设置 swtich case subsystem 缩放大小及代码生成格式
            set_param(subsystem_path, 'ZoomFactor', '100');
            set_param(subsystem_path, 'RTWSystemCode', 'Reusable function', 'RTWFcnNameOpts', 'Use subsystem name');
        end

        function system_hdl = add_sig_subsystem(obj, subsystem_path, subsystem_pos, sig_case_info)
            %% 通过表格判读添加 sig subsystem 类型
            sig_name = sig_case_info.Row{1};
            if contains(sig_case_info.("Invalid Status"), 'always FALSE')
                system_hdl = add_block(obj.noerror_sub, subsystem_path, 'Position', subsystem_pos);
            else
                system_hdl = add_block(obj.error_sub, subsystem_path, 'Position', subsystem_pos);
                % 修改 can error status 名
                error_name = ['CanTx_Err_' sig_name];
                obj.modify_port_line_name('In', subsystem_path, 'cantx_inv_status', error_name);
            end
            %% 修改 can in 名
            obj.modify_port_line_name('In', subsystem_path, 'cantx_phy', sig_name);
            %% 修改 can out 名
            outport_name = ['CanTx_' sig_name];
            obj.modify_port_line_name('Out', subsystem_path, 'cantx_raw', outport_name);
            %% 配置 LSB Offset
            % mask_values = {sig_case_info.Offset, sig_case_info.Factor};
            % set_param([subsystem_path '/Phy2Raw'], 'MaskValues', mask_values);
            %% 配置上下限
            max_value = strcat("(", sig_case_info.Max, "- (", sig_case_info.Offset, ")) / (", sig_case_info.Factor, ")");
            min_value = strcat("(", sig_case_info.Min, "- (", sig_case_info.Offset, ")) / (", sig_case_info.Factor, ")");
            set_param([subsystem_path '/Max'], 'Value', max_value);
            set_param([subsystem_path '/Min'], 'Value', min_value);
            %% 配置 sig subsystem 缩放大小及代码生成格式
            set_param(subsystem_path, 'ZoomFactor', '100')
            set_param(subsystem_path, 'TreatAsAtomicUnit', 'on', 'RTWSystemCode', 'Reusable function', 'RTWFcnNameOpts', 'Use subsystem name')
        end

        function gen_normal_code(obj, save_path, model_name)
            %% 关闭并清除所有
            obj.clear_all();
            %% 打开并配置模型
            cd(save_path)
            open_system(model_name)
            obj.modify_model_config(model_name, 'SLDD_CFG')
            %% 绑定信号
            sldd_path = [save_path '\' model_name '.sldd'];
            sldd_obj = Simulink.data.dictionary.open(sldd_path);
            design_data = getSection(sldd_obj,'Design Data');
            obj.add_subsystem_port_resolve(model_name, obj.can_info, design_data)
            %% 保存并关闭模型
            save_system(model_name);
            sldd_obj.saveChanges()
            sldd_obj.close()
            close_system(model_name);
            %% 关闭并清除所有
            obj.clear_all();
        end
    end
end