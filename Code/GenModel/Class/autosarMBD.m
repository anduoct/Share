classdef autosarMBD < handle
    properties
        dd_sht_tbl

        case_key
        case_value
        case_dict

        cantx_info
        cantx_sldd
        cantx_normal
        cantx_error
        cantx_noerror

        canrx_info
        canrx_sldd
        canrx_normal
        canrx_error

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
        case_subsystem_interval
        case_subsystem_port_interval
        case_subsystem_port_offset

        sig_base_pos
        sig_sub_interval

        extract_base_pos
        extract_interval
        preprocess_subsystem_base_pos
        preprocess_subsystem_port_interval

        case_str

    end

    methods
        function obj = autosarMBD(dd_sht_tbl)
            obj.dd_sht_tbl = dd_sht_tbl;
            obj.case_key = {'INIT', '2X', '4X', '8X', '16X', '25X', '32X', '64X', '128X', '200X', '250X', '256X', 'REF'};
            obj.case_value = {'PLCANI_APCNTL_SET_INF_INIT', 'PLCANI_APCNTL_SET_INF_2X', 'PLCANI_APCNTL_SET_INF_4X', 'PLCANI_APCNTL_SET_INF_8X', 'PLCANI_APCNTL_SET_INF_16X', 'PLCANI_APCNTL_SET_INF_25X', 'PLCANI_APCNTL_SET_INF_32X', 'PLCANI_APCNTL_SET_INF_64X', 'PLCANI_APCNTL_SET_INF_128X', 'PLCANI_APCNTL_SET_INF_200X', 'PLCANI_APCNTL_SET_INF_250X', 'PLCANI_APCNTL_SET_INF_256X', 'PLCANI_APCNTL_SET_INF_REF'};
            obj.case_dict = containers.Map(obj.case_key, obj.case_value);
            obj.cantx_normal = 'Lib/cantx_normal';
            obj.cantx_error = 'Lib/cantx_error';
            obj.cantx_noerror = 'Lib/cantx_noerror';
            obj.cantx_sldd = which('cantx.sldd');
            obj.canrx_normal = 'Lib/canrx_normal';
            obj.canrx_error = 'Lib/canrx_error';
            obj.canrx_sldd = which('canrx.sldd');
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
            obj.case_subsystem_interval = 70;
            obj.case_subsystem_port_interval = 30;
            obj.case_subsystem_port_offset = 10;
            obj.sig_base_pos = [-125 25 530 85];
            obj.sig_sub_interval = 90;
            obj.preprocess_subsystem_base_pos = [215 100 470 200];
            obj.preprocess_subsystem_port_interval = 30;
            obj.extract_base_pos = [310 20 390 60];
            obj.extract_interval = 70;
            obj.case_str = '';
        end

        function gen_tx_normal_model(obj, save_path, model_name, model_info)
            %% 获取 cantx info
            obj.cantx_info = model_info;
            %% 配置生成模型路径及拷贝 sldd
            Simulink.data.dictionary.closeAll('-discard');
            if exist(save_path,'dir')
                rmdir(save_path, 's')
            end
            mkdir(save_path);
            addpath(save_path)
            sldd_path = [save_path '\' model_name '.sldd'];
            copyfile(obj.cantx_sldd, sldd_path);
            %% 新建并打开 tx normal model
            tx_normal_model = new_system(model_name);
            open_system(tx_normal_model);
            %% 配置 tx normal model 代码导出方式 sldd 及 缩放率
            set_param(tx_normal_model, 'SetExecutionDomain', 'on','ExecutionDomainType', 'ExportFunction', 'IsExportFunctionModel', 'on');
            set_param(tx_normal_model, 'Datadictionary',[model_name '.sldd'])
            %% 添加 tx normal subsystem
            main_subsystem_path = [model_name '/' model_name '_main'];
            obj.add_tx_normal_subsystem(main_subsystem_path);
            % 配置 tx normal subsystem 位置
            port_num = length(get_param(main_subsystem_path, 'PortHandles').Inport);
            obj.main_base_down = obj.main_base_up + obj.main_port_interval*port_num + obj.main_port_offset;
            set_param(main_subsystem_path, 'Position', [obj.main_base_width(1) obj.main_base_up obj.main_base_width(2) obj.main_base_down])
            % 添加 tx normal model 输入
            obj.add_subsystem_port(main_subsystem_path);
            %% 配置 tx normal model 缩放大小
            set_param(tx_normal_model, 'ZoomFactor', '100');
            %% 保存并关闭 tx normal model
            save_system(tx_normal_model, [save_path, '\' , model_name, '.slx']);
            close_system(tx_normal_model);
        end

        function system_hdl = add_tx_normal_subsystem(obj, subsystem_path)
            %% 初始化 case subsystem 位置
            obj.case_subsystem_base_up = 150;
            obj.case_subsystem_base_down = 0;
            %% 添加 cantx_normal 模板
            system_hdl = add_block(obj.cantx_normal, subsystem_path);
            %% 获取 system name
            subsystem_name = get_param(subsystem_path, 'Name');
            %% 计算 tx case 数
            tx_case_list = obj.case_key(ismember(obj.case_key, unique(obj.cantx_info.Elevel)));
            %% 设置 Switch Case 参数
            swt_blk_path = [subsystem_path '/Switch Case'];            
            obj.swt_base_down = obj.swt_base_up + length(tx_case_list) * obj.swt_port_interval + obj.swt_port_offset;
            obj.case_str = 'PLCANI_APCNTL_SET_INF_TYPE.PLCANI_APCNTL_SET_INF_INIT';
            for i_case = 1:length(tx_case_list)
                tx_case_cell = tx_case_list(i_case);
                obj.case_str = [obj.case_str ',' 'PLCANI_APCNTL_SET_INF_TYPE.' obj.case_dict(tx_case_cell{1})];
            end
            set_param(swt_blk_path, 'CaseConditions' , ['{' obj.case_str '}'], 'Position', [obj.swt_base_width(1), obj.swt_base_up, obj.swt_base_width(2), obj.swt_base_down]);
            %% 设置 ArgIn 参数
            arg_in_path = [subsystem_path '/trigger'];
            swt_in_pos = get_param(get_param(swt_blk_path, 'PortHandles').Inport(1), 'Position');
            arg_in_pos =  [swt_in_pos(1)-170, swt_in_pos(2)-7, swt_in_pos(1)-120, swt_in_pos(2)+7];
            set_param(arg_in_path, 'Position', arg_in_pos, 'OutDataTypeStr', 'Enum: PLCANI_APCNTL_SET_INF_TYPE');
            %% 设置 Trigger Port 参数
            trg_port_path = [subsystem_path '/cantx_normal'];
            trg_port_pos = [swt_in_pos(1)-155, swt_in_pos(2)-150, swt_in_pos(1)-135, swt_in_pos(2)-135];
            set_param(trg_port_path, 'Position', trg_port_pos, 'FunctionName', subsystem_name, 'FunctionPrototype', [subsystem_name '(trigger)']);
            %% 获取 Swicth Case 输出端口
            swt_blk_hdls = get_param(swt_blk_path, 'PortHandles');
            %%  添加 Init Case Subsystem
            init_case_subsystem_path = [subsystem_path '/' subsystem_name(1:end-5) '_Init'];
            obj.add_tx_sig_case_subsystem(init_case_subsystem_path, obj.cantx_info);
            init_case_subsystem_port_hdls = get_param(init_case_subsystem_path, 'PortHandles');
            init_case_subsystem_port_num = length(init_case_subsystem_port_hdls.Inport);
            % 配置 Init Case Subsystem 位置
            obj.case_subsystem_base_down = obj.case_subsystem_base_up + (obj.case_subsystem_port_interval+25)*init_case_subsystem_port_num + obj.case_subsystem_port_offset;
            init_case_subsystem_pos =  [obj.case_subsystem_base_width(1) obj.case_subsystem_base_up obj.case_subsystem_base_width(2) obj.case_subsystem_base_down];
            obj.case_subsystem_base_up = obj.case_subsystem_base_down + obj.case_subsystem_interval;
            set_param(init_case_subsystem_path, 'Position', init_case_subsystem_pos);
            % Switch 与 Init Case Subsystem 连线
            add_line(subsystem_path, swt_blk_hdls.Outport(1), init_case_subsystem_port_hdls.Ifaction(1), 'autorouting','on');
            % 添加 Init Case Subsystem 输入端口
            obj.add_subsystem_inport(init_case_subsystem_path);
            %% 循环添加非 Init Case Subsystem
            for i_case = 1:length(tx_case_list)
                case_name = tx_case_list(i_case);
                sig_case_subsystem_path = [subsystem_path '/' subsystem_name(1:end-5) '_' case_name{1}];
                sig_case_info = obj.cantx_info(strcmp(obj.cantx_info.Elevel, case_name),:);
                obj.add_tx_sig_case_subsystem(sig_case_subsystem_path, sig_case_info);
                case_subsystem_port_hdls = get_param(sig_case_subsystem_path, 'PortHandles');
                case_subsystem_port_num = length(case_subsystem_port_hdls.Inport);
                % 配置非 Init Case Subsystem 位置
                obj.case_subsystem_base_down = obj.case_subsystem_base_up + obj.case_subsystem_port_interval*case_subsystem_port_num + obj.case_subsystem_port_offset;
                sig_case_subsystem_pos =  [obj.case_subsystem_base_width(1) obj.case_subsystem_base_up obj.case_subsystem_base_width(2) obj.case_subsystem_base_down];
                obj.case_subsystem_base_up = obj.case_subsystem_base_down + obj.case_subsystem_interval;
                set_param(sig_case_subsystem_path, 'Position', sig_case_subsystem_pos);
                % Switch 与非 Init Case Subsystem 连线
                add_line(subsystem_path, swt_blk_hdls.Outport(1+i_case), case_subsystem_port_hdls.Ifaction(1), 'autorouting','on');
                % 添加 Init Case Subsystem 输入端口
                obj.add_subsystem_inport(sig_case_subsystem_path);
                % 合并 Case Subsystem 共有输出端口
                obj.add_subsystem_merge_outport(init_case_subsystem_path, sig_case_subsystem_path);
            end
            %% 配置 tx normal subsystem 缩放大小
            set_param(subsystem_path, 'ZoomFactor', '100')
        end

        function system_hdl = add_tx_sig_case_subsystem(obj, subsystem_path, sig_case_info)
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
                sig_subsystem_path = [subsystem_path '/sig_' sig_name];
                sig_subsystem_pos = [obj.sig_base_pos(1), obj.sig_base_pos(2) + i_sig * obj.sig_sub_interval, obj.sig_base_pos(3), obj.sig_base_pos(4) + i_sig * obj.sig_sub_interval];
                % 添加 sig subsystem
                obj.add_tx_sig_subsystem(sig_subsystem_path, sig_subsystem_pos, sig_info);
                % 配置 sig subsystem 端口
                obj.add_subsystem_port(sig_subsystem_path);
            end
            %% 设置 swtich case subsystem 缩放大小及代码生成格式
            set_param(subsystem_path, 'ZoomFactor', '100');
            set_param(subsystem_path, 'RTWSystemCode', 'Reusable function', 'RTWFcnNameOpts', 'Use subsystem name');
        end

        function system_hdl = add_tx_sig_subsystem(obj, subsystem_path, subsystem_pos, sig_case_info)
            %% 通过表格判读添加 sig subsystem 类型
            sig_name = sig_case_info.Row{1};
            if contains(sig_case_info.("Invalid Status"), 'always FALSE')
                system_hdl = add_block(obj.cantx_noerror, subsystem_path, 'Position', subsystem_pos);
            else
                system_hdl = add_block(obj.cantx_error, subsystem_path, 'Position', subsystem_pos);
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

        function gen_rx_normal_model(obj, save_path, model_name, model_info)
            %% 获取 canrx info
            obj.canrx_info = model_info;      
            %% 配置生成模型路径及拷贝 sldd
            Simulink.data.dictionary.closeAll('-discard');
            if exist(save_path,'dir')
                rmdir(save_path, 's')
            end
            mkdir(save_path);
            addpath(save_path)
            sldd_path = [save_path '\' model_name '.sldd'];
            copyfile(obj.canrx_sldd, sldd_path);
            %% 新建并打开 rx normal model
            rx_normal_model = new_system(model_name);
            open_system(rx_normal_model);            
            %% 配置 rx normal model 代码导出方式 sldd 及 缩放率
            set_param(rx_normal_model, 'SetExecutionDomain', 'on','ExecutionDomainType', 'ExportFunction', 'IsExportFunctionModel', 'on');
            set_param(rx_normal_model, 'Datadictionary',[model_name '.sldd'])
            %% 添加 rx normal subsystem
            main_subsystem_path = [model_name '/' model_name '_main'];
            obj.add_rx_normal_subsystem(main_subsystem_path);
            % 配置 rx normal subsystem 位置
            port_num = length(get_param(main_subsystem_path, 'PortHandles').Outport);
            obj.main_base_down = obj.main_base_up + obj.main_port_interval*port_num + obj.main_port_offset;
            set_param(main_subsystem_path, 'Position', [obj.main_base_width(1) obj.main_base_up obj.main_base_width(2) obj.main_base_down]);
            % 添加 tx normal model 输入
            obj.add_subsystem_port(main_subsystem_path);
            %% 配置 tx normal model 缩放大小
            set_param(rx_normal_model, 'ZoomFactor', '100');
            %% 保存并关闭 rx normal model
            save_system(rx_normal_model, [save_path, '\' , model_name, '.slx']);
            close_system(rx_normal_model);
        end

        function system_hdl = add_rx_normal_subsystem(obj, subsystem_path)
            %% 添加 cantx_normal 模板
            system_hdl = add_block(obj.canrx_normal, subsystem_path);
            %% 获取 system name
            subsystem_name = get_param(subsystem_path, 'Name');
            %% 设置 Trigger Port 参数
            trg_port_path = [subsystem_path '/canrx_normal'];
            set_param(trg_port_path, 'FunctionName', subsystem_name, 'FunctionPrototype', [subsystem_name '(channel, canframe, time)']);
            %% 添加 cantx preprocess
            rx_sig_prepocess_subsystem_ori_path = [subsystem_path '/canframe_preprocess'];
            rx_sig_prepocess_subsystem_name = [subsystem_name(1:end-5) '_preprocess'];
            rx_sig_prepocess_subsystem_dst_path = [subsystem_path '/' rx_sig_prepocess_subsystem_name];
            set_param(rx_sig_prepocess_subsystem_ori_path, 'Name', rx_sig_prepocess_subsystem_name)
            obj.add_rx_sig_prepocess_subsystem(rx_sig_prepocess_subsystem_dst_path);
            %% 添加 canrx postprocess
            rx_sig_postprocess_subsystem_name = [subsystem_name(1:end-5) '_postprocess'];
            rx_sig_postprocess_subsystem_path = [subsystem_path '/' rx_sig_postprocess_subsystem_name];
            obj.add_rx_sig_postpocess_subsystem(rx_sig_postprocess_subsystem_path);
            %% 配置 canrx preprocess/postprocess subsystem 位置
            pre_out_hdls = get_param(rx_sig_prepocess_subsystem_dst_path, 'PortHandles').Outport;
            post_in_hdls = get_param(rx_sig_postprocess_subsystem_path, 'PortHandles').Inport;
            inport_num = length(post_in_hdls);
            rx_sig_prepocess_subsystem_pos = obj.preprocess_subsystem_base_pos + [0 0 0 obj.preprocess_subsystem_port_interval*inport_num];
            set_param(rx_sig_prepocess_subsystem_dst_path, 'Position', rx_sig_prepocess_subsystem_pos);
            rx_sig_postpocess_subsystem_pos = rx_sig_prepocess_subsystem_pos + [500 0 500 0];
            set_param(rx_sig_postprocess_subsystem_path, 'Position', rx_sig_postpocess_subsystem_pos);
            %% 配置 canframe 及 Bus Selector 位置
            pre_in_hdls = get_param(rx_sig_prepocess_subsystem_dst_path, 'PortHandles').Inport;
            pre_in_pos = get_param(pre_in_hdls(1), 'Position');
            frame_pos = [pre_in_pos(1)-240, pre_in_pos(2)-15, pre_in_pos(1)-160, pre_in_pos(2)+15];
            set_param([subsystem_path '/canframe'], 'Position', frame_pos)
            sel_pos = [pre_in_pos(1)-70, pre_in_pos(2)-15, pre_in_pos(1)-65, pre_in_pos(2)+15];
            set_param([subsystem_path '/Bus Selector'], 'Position', sel_pos)
            %% 配置 canrx preprocess/postprocess subsystem 连线
            for i_sig = 1:length(obj.canrx_info.Row)
                sig_name = ['CanRx_' obj.canrx_info.Row{i_sig}];
                pre_sig_path = [rx_sig_prepocess_subsystem_dst_path '/' sig_name];
                post_sig_path = [rx_sig_postprocess_subsystem_path '/' sig_name];
                pre_sig_num = str2double(get_param(pre_sig_path, 'Port'));
                post_sig_num = str2double(get_param(post_sig_path, 'Port'));
                add_line(subsystem_path, pre_out_hdls(pre_sig_num), post_in_hdls(post_sig_num), 'autorouting','on'); 
            end
            %% 配置 canrx postprocess subsystem 端口
            obj.add_subsystem_port(rx_sig_postprocess_subsystem_path);
        end

        function system_hdl = add_rx_sig_prepocess_subsystem(obj, subsystem_path)
            system_hdl = get_param(subsystem_path, 'Handle');
            for i_sig = 1:length(obj.canrx_info.Row)
                sig_name = ['CanRx_' obj.canrx_info.Row{i_sig}];
                sig_start_bit = str2double(obj.canrx_info.("Start Bit"){i_sig});
                sig_len = str2double(obj.canrx_info.Length{i_sig});
                sig_extract_str = ['[' num2str(sig_start_bit) ' ' num2str(sig_start_bit+sig_len-1) ']'];

                extract_pos = obj.extract_base_pos + [0 obj.extract_interval*i_sig 0 obj.extract_interval*i_sig];
                extract_hdl = add_block('simulink/Logic and Bit Operations/Extract Bits', [subsystem_path '/Extract Bits'], 'MakeNameUnique', 'on', 'Position', extract_pos);
                extract_name = get_param(extract_hdl, 'Name');
                conversion_pos = extract_pos + [150 0 150 0];
                conversion_hdl = add_block('simulink/Signal Attributes/Data Type Conversion', [subsystem_path '/Data Type Conversion'], 'MakeNameUnique', 'on', 'Position', conversion_pos);
                conversion_name = get_param(conversion_hdl, 'Name');
                set_param(extract_hdl, 'bitsToExtract', 'Range of bits', 'bitIdxRange', sig_extract_str, 'outScalingMode', 'Treat bit field as an integer');

                out_pos = get_param(get_param(conversion_hdl, 'PortHandles').Outport(1), 'Position'); 
                outport_pos =  [out_pos(1)+170, out_pos(2)-7, out_pos(1)+200, out_pos(2)+7];
                add_block('simulink/Sinks/Out1', [subsystem_path '/' sig_name], 'Name', sig_name, 'Position', outport_pos)

                add_line(subsystem_path, 'canframe/1', [extract_name '/1'], 'autorouting','on'); 
                add_line(subsystem_path, [extract_name '/1'], [conversion_name '/1'], 'autorouting','on'); 
                add_line(subsystem_path, [conversion_name '/1'], [sig_name '/1'], 'autorouting','on');
            end
            %% 配置 cantx preprocess subsystem 缩放大小
            set_param(subsystem_path, 'ZoomFactor', '100')
            set_param(subsystem_path, 'TreatAsAtomicUnit', 'on', 'RTWSystemCode', 'Reusable function', 'RTWFcnNameOpts', 'Use subsystem name')
        end

        function system_hdl = add_rx_sig_postpocess_subsystem(obj, subsystem_path)
            %% 添加 subsystem
            system_hdl = add_block('simulink/Ports & Subsystems/Subsystem', subsystem_path);
            %% 删除原有的 in out line
            del_in_hdl = getSimulinkBlockHandle([subsystem_path '/In1']);
            del_out_hdl = getSimulinkBlockHandle([subsystem_path '/Out1']);
            del_line_hdl = get_param(del_in_hdl, 'LineHandles');
            delete_block([del_in_hdl, del_out_hdl]);
            delete_line(del_line_hdl.Outport(1));
            %% 批量添加 sig subsystem
            for i_sig = 1:length(obj.canrx_info.Row)
                sig_info = obj.canrx_info(i_sig,:);
                sig_name = sig_info.Row{1};
                sig_subsystem_path = [subsystem_path '/sig_' sig_name];
                sig_subsystem_pos = [obj.sig_base_pos(1), obj.sig_base_pos(2) + i_sig * obj.sig_sub_interval, obj.sig_base_pos(3), obj.sig_base_pos(4) + i_sig * obj.sig_sub_interval];
                % 添加 sig subsystem
                obj.add_rx_sig_subsystem(sig_subsystem_path, sig_info);
                set_param(sig_subsystem_path, 'Position', sig_subsystem_pos);
                % 配置 sig subsystem 端口
                obj.add_subsystem_port(sig_subsystem_path)
            end
            %% 配置 cantx postprocess subsystem 缩放大小
            set_param(subsystem_path, 'ZoomFactor', '100')
            set_param(subsystem_path, 'TreatAsAtomicUnit', 'on', 'RTWSystemCode', 'Reusable function', 'RTWFcnNameOpts', 'Use subsystem name')
        end

        function system_hdl = add_rx_sig_subsystem(obj, subsystem_path, sig_info)
            %% 通过表格判读添加 sig subsystem 类型
            sig_name = sig_info.Row{1};
            inport_name = ['CanRx_' sig_name];
            inv_name = convertStringsToChars(sig_info.('Invalid Status'));
            system_hdl = add_block(obj.canrx_error, subsystem_path);
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

        function modify_port_line_name(~, port_dire, subsystem_path, ori_name, dst_name)
            %% 修改 Port Name
            set_param([subsystem_path '/' ori_name], 'Name', dst_name);
            %% 连线上若存在 Port 名则同步修改
            if strcmp(port_dire, 'In')
                line_handle = get_param([subsystem_path '/' dst_name], 'LineHandles').Outport;
            elseif strcmp(port_dire, 'Out')
                line_handle = get_param([subsystem_path '/' dst_name], 'LineHandles').Inport;
            end
            if get_param(line_handle, 'Name')
                set_param(line_handle, 'Name', dst_name);
            end
        end

        function add_subsystem_port(obj, subsystem_path)
            %% 添加 subsystem inport
            obj.add_subsystem_inport(subsystem_path)
            %% 添加 subsystem outport
            obj.add_subsystem_outport(subsystem_path)
        end

        function add_subsystem_inport(~, subsystem_path)
            parent_path = get_param(subsystem_path, 'Parent');
            subsystem_name = get_param(subsystem_path, 'Name');
            inport_names = get_param(find_system(subsystem_path, 'SearchDepth', 1, 'BlockType', 'Inport'), 'Name');
            in_handles = get_param(subsystem_path, 'PortHandles').Inport;
            for i_in = 1:length(in_handles)
                in_hdl = get_param(subsystem_path, 'PortHandles').Inport(i_in);
                if get_param(in_hdl, 'Line') == -1
                    in_pos = get_param(in_hdl, 'Position');
                    inport_pos =  [in_pos(1)-200, in_pos(2)-7, in_pos(1)-170, in_pos(2)+7];
                    if isempty(find_system(parent_path,'SearchDepth', 1, 'BlockType', 'Inport', 'Name', inport_names{i_in}))
                        add_block('simulink/Sources/In1', [parent_path '/' inport_names{i_in}], 'Name', inport_names{i_in}, 'Position', inport_pos)
                    end
                    add_line(parent_path, [inport_names{i_in} '/1'], [subsystem_name '/' num2str(i_in)], 'autorouting','on');     
                end
            end
        end

        function add_subsystem_outport(~, subsystem_path)
            parent_path = get_param(subsystem_path, 'Parent');
            subsystem_name = get_param(subsystem_path, 'Name');
            outport_names = get_param(find_system(subsystem_path, 'SearchDepth', 1, 'BlockType', 'Outport'), 'Name');
            out_handles = get_param(subsystem_path, 'PortHandles').Outport;
            for i_out = 1:length(out_handles)
                out_hdl = get_param(subsystem_path, 'PortHandles').Outport(i_out);
                if get_param(out_hdl, 'Line') == -1
                    out_pos = get_param(out_hdl, 'Position');
                    outport_pos =  [out_pos(1)+170, out_pos(2)-7, out_pos(1)+200, out_pos(2)+7];
                    add_block('simulink/Sinks/Out1', [parent_path '/' outport_names{i_out}], 'Name',outport_names{i_out},'Position', outport_pos)
                    add_line(parent_path, [subsystem_name '/' num2str(i_out)], [outport_names{i_out} '/1'], 'autorouting','on');
                end
            end
        end

        function add_subsystem_merge_outport(~, subsystem1_path, subsystem2_path)
            parent_path = get_param(subsystem1_path, 'Parent');
            sub1_port_hdl = get_param(subsystem1_path, 'PortHandles').Outport;
            sub2_port_hdl = get_param(subsystem2_path, 'PortHandles').Outport;
            outport_names = get_param(find_system({subsystem1_path, subsystem2_path}, 'SearchDepth', 1, 'BlockType', 'Outport'), 'Name');
            [~,diff_idx] = unique(outport_names, "stable");
            outport_names(diff_idx) = [];
            for i_port = 1:length(outport_names)
                sub1_port_cell = get_param([subsystem1_path '/' outport_names{i_port}], 'Port');
                sub1_port_num = str2double(sub1_port_cell);
                sub1_port_pos = get_param(sub1_port_hdl(sub1_port_num), 'Position');
                sub2_port_cell = get_param([subsystem2_path '/' outport_names{i_port}], 'Port');
                sub2_port_num = str2double(sub2_port_cell);
                merge_pos = [sub1_port_pos(1)+100, sub1_port_pos(2)-10, sub1_port_pos(1)+140, sub1_port_pos(2)+30];
                merge_hdl = add_block('simulink/Signal Routing/Merge', [parent_path '/Merge' ], 'MakeNameUnique', 'on', 'Position', merge_pos);
                merge_port_hdl = get_param(merge_hdl, 'PortHandles');
                add_line(parent_path, sub1_port_hdl(sub1_port_num), merge_port_hdl.Inport(1), 'autorouting','on');
                add_line(parent_path, sub2_port_hdl(sub2_port_num), merge_port_hdl.Inport(2), 'autorouting','on');
                merge_port_pos = get_param(get_param(merge_hdl, 'PortHandles').Outport(1), 'Position');
                outport_pos =  [merge_port_pos(1)+100, merge_port_pos(2)-7, merge_port_pos(1)+130, merge_port_pos(2)+7];
                outport_hdl = add_block('simulink/Sinks/Out1', [parent_path '/' outport_names{i_port}], 'Name',outport_names{i_port},'Position', outport_pos);
                outport_port_hdl = get_param(outport_hdl, 'PortHandles');
                add_line(parent_path, merge_port_hdl.Outport(1), outport_port_hdl.Inport(1));
            end
        end





        function gen_tx_normal_code(obj, save_path, model_name)
            Simulink.data.dictionary.closeAll('-discard');
            cd(save_path)
            open_system(model_name)
            sldd_path = [save_path '\' model_name '.sldd'];
            tx_sldd_obj = Simulink.data.dictionary.open(sldd_path);
            tx_design_data = getSection(tx_sldd_obj,'Design Data');

            obj.modify_model_config(model_name)

            trg_sig = Simulink.Signal;
            trg_sig.DataType = 'Enum: PLCANI_APCNTL_SET_INF_TYPE';
            mdl_wks = get_param(model_name, 'ModelWorkspace');
            assignin(mdl_wks, "trigger", trg_sig);

            obj.add_subsystem_port_resolve(model_name, obj.cantx_info, tx_design_data)

            save_system(model_name);
            tx_sldd_obj.saveChanges()
            tx_sldd_obj.close()
            Simulink.data.dictionary.closeAll('-save');
            close_system(model_name);

        end

        function gen_rx_normal_code(obj, save_path, model_name)
            Simulink.data.dictionary.closeAll('-discard');
            cd(save_path)
            open_system(model_name)
            sldd_path = [save_path '\' model_name '.sldd'];
            rx_sldd_obj = Simulink.data.dictionary.open(sldd_path);
            rx_design_data = getSection(rx_sldd_obj,'Design Data');

            obj.modify_model_config(model_name)


            rx_sig_prepocess_subsystem_name = [model_name '/' model_name '_main/' model_name '_preprocess'];
            obj.add_outport_resolve_on_line(rx_sig_prepocess_subsystem_name, obj.canrx_info, rx_design_data)
            obj.add_subsystem_port_resolve(model_name, obj.canrx_info, rx_design_data)

            save_system(model_name);
            rx_sldd_obj.saveChanges()
            rx_sldd_obj.close()
            Simulink.data.dictionary.closeAll('-save');
            close_system(model_name);

        end

        function modify_model_config(~, model_name)
            sldd_cfg = Simulink.ConfigSetRef;
            set_param(sldd_cfg, 'Name', 'SLDD_CFG', 'SourceName', 'SLDD_CFG')
            attachConfigSet(model_name, sldd_cfg);
            setActiveConfigSet(model_name,'SLDD_CFG');
        end

        function add_subsystem_port_resolve(obj, subsystem_path, can_info, design_data)
            obj.add_inport_resolve_on_line(subsystem_path, can_info, design_data);
            obj.add_outport_resolve_on_port(subsystem_path, can_info, design_data);
        end

        function add_inport_resolve_on_line(obj, subsystem_path, can_info, design_data)
            inport_path_list = find_system(subsystem_path, 'SearchDepth', 1, 'BlockType', 'Inport');
            inport_name_list = get_param(inport_path_list, 'NAME');
            inport_line_hdls = get_param(inport_path_list, 'LineHandles');
            for i_hdl = 1:length(inport_line_hdls)
                set_param(inport_line_hdls{i_hdl}.Outport, 'Name', inport_name_list{i_hdl});
                set(inport_line_hdls{i_hdl}.Outport, 'MustResolveToSignalObject', 1);
                obj.add_signal_to_sldd(inport_name_list{i_hdl}, can_info, design_data);
            end
        end

        function add_outport_resolve_on_line(obj, subsystem_path, can_info, design_data)
            outport_path_list = find_system(subsystem_path, 'SearchDepth', 1, 'BlockType', 'Outport');
            outport_name_list = get_param(outport_path_list, 'NAME');
            outport_line_hdls = get_param(outport_path_list, 'LineHandles');
            for i_hdl = 1:length(outport_line_hdls)
                set_param(outport_line_hdls{i_hdl}.Inport, 'Name', outport_name_list{i_hdl});
                set(outport_line_hdls{i_hdl}.Inport, 'MustResolveToSignalObject', 1);
                obj.add_signal_to_sldd(outport_name_list{i_hdl}, can_info, design_data);
            end
        end

        function add_outport_resolve_on_port(obj, subsystem_path, can_info, design_data)
            outport_path_list = find_system(subsystem_path, 'SearchDepth', 1, 'BlockType', 'Outport');
            outport_name_list = get_param(outport_path_list, 'NAME');
            for i_hdl = 1:length(outport_path_list)
                set_param(outport_path_list{i_hdl}, 'SignalName', outport_name_list{i_hdl});
                hdl = get_param(outport_path_list{i_hdl}, 'Handle');
                set(hdl, 'MustResolveToSignalObject', 1);
                obj.add_signal_to_sldd(outport_name_list{i_hdl}, can_info, design_data);
            end
        end

        function add_signal_to_sldd(obj, signal_name, can_info, design_data)
            sig = Simulink.Signal;
            sig.CoderInfo.StorageClass = "ExportedGlobal";
            sig_info = obj.dd_sht_tbl(signal_name,:);
%             strcmp(signal_name(1:6), "CanTx_") || strcmp(signal_name(1:6), "CanRx_")
            if strcmp(sig_info.Resolution, "1")
                sig.DataType = sig_info.Attribute;
            else
                tx_info = can_info(signal_name,:);
                if strcmp(sig_info.Attribute, "UB")
                    sig.DataType = strcat("fixdt(0, 8, ", sig_info.numerator , "/" , sig_info.denominator, ", ", tx_info.Offset, ")");
                elseif strcmp(sig_info.Attribute, "UW")
                    sig.DataType = strcat("fixdt(0, 16, ", sig_info.numerator , "/" , sig_info.denominator, ", ", tx_info.Offset, ")");
                elseif strcmp(sig_info.Attribute, "UD")
                    sig.DataType = strcat("fixdt(0, 32, ", sig_info.numerator , "/" , sig_info.denominator, ", ", tx_info.Offset, ")");
                elseif strcmp(sig_info.Attribute, "SB")
                    sig.DataType = strcat("fixdt(0, 8, ", sig_info.numerator , "/" , sig_info.denominator, ", ", tx_info.Offset, ")");
                elseif strcmp(sig_info.Attribute, "SW")
                    sig.DataType = strcat("fixdt(0, 16, ", sig_info.numerator , "/" , sig_info.denominator, ", ", tx_info.Offset, ")");
                elseif strcmp(sig_info.Attribute, "SD")
                    sig.DataType = strcat("fixdt(0, 32, ", sig_info.numerator , "/" , sig_info.denominator, ", ", tx_info.Offset, ")");
                end
            end
            sig.Max = str2double(sig_info.("Max（Internal）"));
            sig.Min = str2double(sig_info.("Min（Internal）"));
            addEntry(design_data, signal_name, sig)
        end
    end
end