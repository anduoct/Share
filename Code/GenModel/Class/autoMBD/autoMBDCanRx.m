classdef autoMBDCanRx < autoMBD
    properties
        can_info
        can_sldd
        lib_normal_mdl
        lib_error_sub
        normal_sub_base_pos
        normal_port_interval
        ext_blk_base_pos
        ext_blk_interval
        preprocess_sub_base_pos
        preprocess_sub_port_interval
        sig_sub_base_pos
        sig_sub_interval
    end

    methods
        function obj = autoMBDCanRx(dd_sht_tbl)
            obj = obj@autoMBD(dd_sht_tbl);
            obj.can_sldd = which('canrx.sldd');
            obj.lib_normal_mdl = 'Lib/canrx_normal';
            obj.lib_error_sub = 'Lib/canrx_error';
            obj.normal_sub_base_pos = [240 25 650 45];
            obj.normal_port_interval = 30;
            obj.ext_blk_base_pos = [310 20 390 60];
            obj.ext_blk_interval = 70;
            obj.preprocess_sub_base_pos = [215 100 470 200];
            obj.preprocess_sub_port_interval = 30;
            obj.sig_sub_base_pos = [-125 25 530 85];
            obj.sig_sub_interval = 90;
        end

        function gen_normal_model(obj, save_path, model_name, model_info)            
            %% 关闭并清除所有
            obj.clear_all();
            %% 获取 canrx info
            obj.can_info = model_info;      
            %% 配置生成模型路径及拷贝 sldd
            Simulink.data.dictionary.closeAll('-discard');
            if exist(save_path,'dir')
                rmdir(save_path, 's')
            end
            mkdir(save_path);
            addpath(save_path)
            sldd_path = [save_path '\' model_name '.sldd'];
            copyfile(obj.can_sldd, sldd_path);
            %% 新建并打开 rx normal model
            normal_mdl = new_system(model_name);
            open_system(normal_mdl);            
            %% 配置 rx normal model 代码导出方式 sldd 及 缩放率
            set_param(normal_mdl, 'SetExecutionDomain', 'on','ExecutionDomainType', 'ExportFunction', 'IsExportFunctionModel', 'on');
            set_param(normal_mdl, 'Datadictionary',[model_name '.sldd'])
            %% 添加 rx normal subsystem
            normal_sub_path = [model_name '/' model_name '_main'];
            obj.add_normal_subsystem(normal_sub_path);
            % 配置 rx normal subsystem 位置
            port_num = length(get_param(normal_sub_path, 'PortHandles').Outport);
            normal_sub_pos = obj.normal_sub_base_pos + [0 0 0 obj.normal_sub_port_interval*port_num];
            set_param(normal_sub_path, 'Position', normal_sub_pos);
            % 添加 tx normal model 输入
            obj.add_subsystem_port(normal_sub_path);
            %% 配置 tx normal model 缩放大小
            set_param(normal_mdl, 'ZoomFactor', '100');
            %% 保存并关闭 rx normal model
            save_system(normal_mdl, [save_path, '\' , model_name, '.slx']);
            close_system(normal_mdl);           
            %% 关闭并清除所有
            obj.clear_all();
        end

        function system_hdl = add_normal_subsystem(obj, subsystem_path)
            %% 添加 cantx_normal 模板
            system_hdl = add_block(obj.lib_normal_mdl, subsystem_path);
            %% 获取 system name
            sub_name = get_param(subsystem_path, 'Name');
            %% 设置 Trigger Port 参数
            trg_port_path = [subsystem_path '/canrx_normal'];
            set_param(trg_port_path, 'FunctionName', sub_name, 'FunctionPrototype', [sub_name '(channel, canframe, time)']);
            %% 添加 cantx preprocess
            sig_prepocess_sub_ori_path = [subsystem_path '/canframe_preprocess'];
            sig_prepocess_sub_name = [sub_name(1:end-5) '_preprocess'];
            sig_prepocess_sub_dst_path = [subsystem_path '/' sig_prepocess_sub_name];
            set_param(sig_prepocess_sub_ori_path, 'Name', sig_prepocess_sub_name)
            obj.add_sig_prepocess_subsystem(sig_prepocess_sub_dst_path);
            %% 添加 canrx postprocess
            sig_postprocess_sub_name = [sub_name(1:end-5) '_postprocess'];
            sig_postprocess_sub_path = [subsystem_path '/' sig_postprocess_sub_name];
            obj.add_sig_postpocess_subsystem(sig_postprocess_sub_path);
            %% 配置 canrx preprocess/postprocess subsystem 位置
            pre_out_hdls = get_param(sig_prepocess_sub_dst_path, 'PortHandles').Outport;
            post_in_hdls = get_param(sig_postprocess_sub_path, 'PortHandles').Inport;
            inport_num = length(post_in_hdls);
            sig_prepocess_sub_pos = obj.preprocess_sub_base_pos + [0 0 0 obj.preprocess_sub_port_interval*inport_num];
            set_param(sig_prepocess_sub_dst_path, 'Position', sig_prepocess_sub_pos);
            sig_postpocess_pos = sig_prepocess_sub_pos + [500 0 500 0];
            set_param(sig_postprocess_sub_path, 'Position', sig_postpocess_pos);
            %% 配置 canframe 及 Bus Selector 位置
            pre_in_hdls = get_param(sig_prepocess_sub_dst_path, 'PortHandles').Inport;
            pre_in_pos = get_param(pre_in_hdls(1), 'Position');
            frame_pos = [pre_in_pos(1)-240, pre_in_pos(2)-15, pre_in_pos(1)-160, pre_in_pos(2)+15];
            set_param([subsystem_path '/canframe'], 'Position', frame_pos)
            sel_pos = [pre_in_pos(1)-70, pre_in_pos(2)-15, pre_in_pos(1)-65, pre_in_pos(2)+15];
            set_param([subsystem_path '/Bus Selector'], 'Position', sel_pos)
            %% 配置 canrx preprocess/postprocess subsystem 连线
            for i_sig = 1:length(obj.can_info.Row)
                sig_name = ['CanRx_' obj.can_info.Row{i_sig}];
                pre_sig_path = [sig_prepocess_sub_dst_path '/' sig_name];
                post_sig_path = [sig_postprocess_sub_path '/' sig_name];
                pre_sig_num = str2double(get_param(pre_sig_path, 'Port'));
                post_sig_num = str2double(get_param(post_sig_path, 'Port'));
                add_line(subsystem_path, pre_out_hdls(pre_sig_num), post_in_hdls(post_sig_num), 'autorouting','on'); 
            end
            %% 配置 canrx postprocess subsystem 端口
            obj.add_subsystem_port(sig_postprocess_sub_path);
        end

        function system_hdl = add_sig_prepocess_subsystem(obj, subsystem_path)
            system_hdl = get_param(subsystem_path, 'Handle');
            %% 循环添加 Extract Block 解析逻辑
            for i_sig = 1:length(obj.can_info.Row)
                sig_name = ['CanRx_' obj.can_info.Row{i_sig}];
                % 添加 Extract Block 并配置其属性
                sig_start_bit = str2double(obj.can_info.("Start Bit"){i_sig});
                sig_len = str2double(obj.can_info.Length{i_sig});
                sig_extract_str = ['[' num2str(sig_start_bit) ' ' num2str(sig_start_bit+sig_len-1) ']'];
                ext_pos = obj.ext_blk_base_pos + [0 obj.ext_blk_interval*i_sig 0 obj.ext_blk_interval*i_sig];
                ext_hdl = add_block('simulink/Logic and Bit Operations/Extract Bits', [subsystem_path '/Extract Bits'], 'MakeNameUnique', 'on', 'Position', ext_pos);
                ext_name = get_param(ext_hdl, 'Name');
                % 添加 Conversion Block 并配置其属性
                conversion_pos = ext_pos + [150 0 150 0];
                conversion_hdl = add_block('simulink/Signal Attributes/Data Type Conversion', [subsystem_path '/Data Type Conversion'], 'MakeNameUnique', 'on', 'Position', conversion_pos);
                conversion_name = get_param(conversion_hdl, 'Name');
                set_param(ext_hdl, 'bitsToExtract', 'Range of bits', 'bitIdxRange', sig_extract_str, 'outScalingMode', 'Treat bit field as an integer');
                out_pos = get_param(get_param(conversion_hdl, 'PortHandles').Outport(1), 'Position'); 
                outport_pos =  [out_pos(1)+170, out_pos(2)-7, out_pos(1)+200, out_pos(2)+7];
                add_block('simulink/Sinks/Out1', [subsystem_path '/' sig_name], 'Name', sig_name, 'Position', outport_pos)
                % 添加连线
                add_line(subsystem_path, 'canframe/1', [ext_name '/1'], 'autorouting','on'); 
                add_line(subsystem_path, [ext_name '/1'], [conversion_name '/1'], 'autorouting','on'); 
                add_line(subsystem_path, [conversion_name '/1'], [sig_name '/1'], 'autorouting','on');
            end
            %% 配置 cantx preprocess subsystem 缩放大小
            set_param(subsystem_path, 'ZoomFactor', '100')
            set_param(subsystem_path, 'TreatAsAtomicUnit', 'on', 'RTWSystemCode', 'Reusable function', 'RTWFcnNameOpts', 'Use subsystem name')
        end

        function system_hdl = add_sig_postpocess_subsystem(obj, subsystem_path)
            %% 添加 subsystem
            system_hdl = add_block('simulink/Ports & Subsystems/Subsystem', subsystem_path);
            %% 删除原有的 in out line
            del_in_hdl = getSimulinkBlockHandle([subsystem_path '/In1']);
            del_out_hdl = getSimulinkBlockHandle([subsystem_path '/Out1']);
            del_line_hdl = get_param(del_in_hdl, 'LineHandles');
            delete_block([del_in_hdl, del_out_hdl]);
            delete_line(del_line_hdl.Outport(1));
            %% 批量添加 sig subsystem
            for i_sig = 1:length(obj.can_info.Row)
                sig_info = obj.can_info(i_sig,:);
                sig_name = sig_info.Row{1};
                sig_sub_path = [subsystem_path '/sig_' sig_name];
                sig_subsystem_pos = [obj.sig_sub_base_pos(1), obj.sig_sub_base_pos(2) + i_sig * obj.sig_sub_interval, obj.sig_sub_base_pos(3), obj.sig_sub_base_pos(4) + i_sig * obj.sig_sub_interval];
                % 添加 sig subsystem
                obj.add_sig_subsystem(sig_sub_path, sig_info);
                set_param(sig_sub_path, 'Position', sig_subsystem_pos);
                % 配置 sig subsystem 端口
                obj.add_subsystem_port(sig_sub_path)
            end
            %% 配置 cantx postprocess subsystem 缩放大小
            set_param(subsystem_path, 'ZoomFactor', '100')
            set_param(subsystem_path, 'TreatAsAtomicUnit', 'on', 'RTWSystemCode', 'Reusable function', 'RTWFcnNameOpts', 'Use subsystem name')
        end

        function system_hdl = add_sig_subsystem(obj, subsystem_path, sig_info)
            %% 通过表格判读添加 sig subsystem 类型
            sig_name = sig_info.Row{1};
            inport_name = ['CanRx_' sig_name];
            inv_name = convertStringsToChars(sig_info.('Invalid Status'));
            system_hdl = add_block(obj.lib_error_sub, subsystem_path);
            %% 修改 can in 名
            obj.modify_port_line_name('In', subsystem_path, 'canrx_raw', inport_name)   
            %% 修改 can out 名
            obj.modify_port_line_name('Out', subsystem_path, 'canrx_phy', sig_name)
            %% 修改 can error 名
            obj.modify_port_line_name('In', subsystem_path, 'canrx_inv_status', inv_name)
            %% 配置上下限
            max_value = strcat("(", sig_info.Max, "- (", sig_info.Offset, ")) / (", sig_info.Factor, ")");
            min_value = strcat("(", sig_info.Min, "- (", sig_info.Offset, ")) / (", sig_info.Factor, ")");
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
            rx_sldd_obj = Simulink.data.dictionary.open(sldd_path);
            rx_design_data = getSection(rx_sldd_obj,'Design Data');
            %% 绑定CanRx信号
            rx_sig_prepocess_subsystem_name = [model_name '/' model_name '_main/' model_name '_preprocess'];
            obj.add_outport_resolve_on_line(rx_sig_prepocess_subsystem_name, obj.can_info, rx_design_data)
            obj.add_subsystem_port_resolve(model_name, obj.can_info, rx_design_data)
            %% 保存并关闭模型
            save_system(model_name);
            rx_sldd_obj.saveChanges()
            rx_sldd_obj.close()
            close_system(model_name);
            %% 关闭并清除所有
            obj.clear_all();
        end
    end
end