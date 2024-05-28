classdef autoMBDTx < autoMBD
    properties
        can_info
        can_sldd

        normal_sub_base_pos
        normal_sub_port_interval
        case_key
        case_dict
        case_str
        preprocess_sub_base_pos
        preprocess_sub_port_interval
        swt_blk_base_pos
        swt_blk_port_interval
        case_sub_base_pos
        case_sub_interval
        case_sub_port_interval
        sig_sub_base_pos
        sig_sub_interval
        post_sub_inport_base_pos
        post_sub_convert_base_pos
        post_sub_shift_base_pos
        post_sub_or_base_pos
        post_sub_interval
    end
    methods
        function obj = autoMBDTx(ram_sht_tbl, rom_sht_tbl)
            obj = obj@autoMBD(ram_sht_tbl, rom_sht_tbl);
            obj.can_sldd = which('cantx.sldd');


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
            normal_mdl = new_system(model_name);
            open_system(normal_mdl);
            %% 配置 tx normal model 代码导出方式 sldd 及 缩放率
            set_param(normal_mdl, 'Datadictionary',[model_name '.sldd'])
            %% 添加 tx normal subsystem
            for i_sig = 1:length(obj.can_info.Row)
                sig_info = obj.can_info(i_sig,:);
                normal_sub_path = strcat(model_name,'/', sig_info.Interface);
                if strcmp(sig_info.("Invalid Status"), '(always FALSE)')
                    add_block('user_lib/IFLayer_Send_Write_xxx(normal)', normal_sub_path);
                else
                    add_block('user_lib/IFLayer_Send_Write_xxx', normal_sub_path);
                    in_hdl = get_param(normal_sub_path, 'PortHandles').Inport(1);
                    in_pos = get_param(in_hdl, 'Position');
                    inport_pos =  [in_pos(1)-200, in_pos(2)-7, in_pos(1)-170, in_pos(2)+7];
                    add_block('simulink/Sources/In1', strcat(model_name,'/',sig_info.Signal), 'Name', sig_info.Signal, 'Position', inport_pos)
                    add_line(model_name, strcat(sig_info.Signal,'/1'), strcat(sig_info.Interface, '/1'), 'autorouting','on');  
                end
                % 配置 tx normal subsystem 位置
                port_num = length(get_param(normal_sub_path, 'PortHandles').Inport);
                normal_main_pos = obj.normal_sub_base_pos + [0 0 0 obj.normal_sub_port_interval*port_num];
                set_param(normal_sub_path, 'Position', normal_main_pos);
                % 添加 tx normal model 输入
                obj.add_subsystem_port(normal_sub_path);
            end
            %% 配置 tx normal model 缩放大小
            set_param(normal_mdl, 'ZoomFactor', '100');
            %% 保存并关闭 tx normal model
            save_system(normal_mdl, [save_path, '\' , model_name, '.slx']);
            close_system(normal_mdl);
            %% 关闭并清除所有
            obj.clear_all();
        end

%         function system_hdl = add_normal_subsystem(~, subsystem_path, sig_info)
%             %% 添加 cantx_normal 模板

%             %% 获取 system name
%             sub_name = get_param(subsystem_path, 'Name');
%             %% 设置 Trigger Port 参数
%             trg_port_path = [subsystem_path '/cantx_normal'];
%             set_param(trg_port_path, 'FunctionName', sub_name, 'FunctionPrototype', [sub_name '(trigger)']);
%             %% 设置 ArgIn 参数
%             arg_in_path = [subsystem_path '/trigger'];
%             set_param(arg_in_path, 'OutDataTypeStr', 'Enum: PLCANI_APCNTL_SET_INF_TYPE');
%             %% 添加 cantx preprocess
%             sig_prepocess_sub_ori_path = [subsystem_path '/canframe_preprocess'];
%             sig_prepocess_sub_name = [sub_name(1:end-5) '_preprocess'];
%             sig_prepocess_sub_dst_path = [subsystem_path '/' sig_prepocess_sub_name];
%             set_param(sig_prepocess_sub_ori_path, 'Name', sig_prepocess_sub_name)
%             obj.add_sig_prepocess_subsystem(sig_prepocess_sub_dst_path);
%             %% 添加 canrx postprocess
%             sig_postprocess_sub_name = [sub_name(1:end-5) '_postprocess'];
%             sig_postprocess_sub_path = [subsystem_path '/' sig_postprocess_sub_name];
%             obj.add_sig_postpocess_subsystem(sig_postprocess_sub_path);
%             %% 配置 canrx preprocess/postprocess subsystem 位置
%             pre_out_hdls = get_param(sig_prepocess_sub_dst_path, 'PortHandles').Outport;
%             post_in_hdls = get_param(sig_postprocess_sub_path, 'PortHandles').Inport;
%             inport_num = length(post_in_hdls);
%             sig_prepocess_sub_pos = obj.preprocess_sub_base_pos + [0 0 0 obj.preprocess_sub_port_interval*inport_num];
%             set_param(sig_prepocess_sub_dst_path, 'Position', sig_prepocess_sub_pos);
%             sig_postpocess_pos = sig_prepocess_sub_pos + [300 0 300 0];
%             set_param(sig_postprocess_sub_path, 'Position', sig_postpocess_pos);
%             %% 配置 canframe 及 Bus Selector 位置
%             pre_in_hdls = get_param(sig_prepocess_sub_dst_path, 'PortHandles').Inport;
%             pre_in_pos = get_param(pre_in_hdls(1), 'Position');
%             trigger_pos = [pre_in_pos(1)-240, pre_in_pos(2)-15, pre_in_pos(1)-160, pre_in_pos(2)+15];
%             set_param([subsystem_path '/trigger'], 'Position', trigger_pos)
%             %% 配置 canrx preprocess/postprocess subsystem 连线
%             for i_sig = 1:length(obj.can_info.Row)
%                 sig_name = obj.can_info.Input{i_sig};
%                 pre_sig_path = [sig_prepocess_sub_dst_path '/' sig_name];
%                 post_sig_path = [sig_postprocess_sub_path '/' sig_name];
%                 pre_sig_num = str2double(get_param(pre_sig_path, 'Port'));
%                 post_sig_num = str2double(get_param(post_sig_path, 'Port'));
%                 add_line(subsystem_path, pre_out_hdls(pre_sig_num), post_in_hdls(post_sig_num), 'autorouting','on'); 
%             end
%             %% 配置 canrx preprocess/postprocess subsystem 端口
%             obj.add_subsystem_port(sig_prepocess_sub_dst_path);
%             obj.add_subsystem_port(sig_postprocess_sub_path);
%             %% 设置 canframe 参数
%             canframe_path = [subsystem_path '/canframe'];
%             set_param(canframe_path, 'name', [sub_name(1:end-5) '_canframe']);
%             %% 配置 tx normal subsystem 缩放大小
%             set_param(subsystem_path, 'ZoomFactor', '100')
%         end

%         function system_hdl = add_sig_prepocess_subsystem(obj, subsystem_path)
%             %% 初始化 case subsystem 位置
%             obj.case_sub_base_pos = [1000 150 1510 10];
%             %% 获取句柄
%             system_hdl = get_param(subsystem_path, 'Handle');
%             system_name = get_param(subsystem_path, 'Name');
%             %% 计算 tx case 数
%             case_list = obj.case_key(ismember(obj.case_key, unique(obj.can_info.Elevel)));
%             case_num = length(case_list);
%             %% 设置 Switch Case 参数
%             swt_blk_path = [subsystem_path '/Switch Case'];
%             obj.case_str = 'PLCANI_APCNTL_SET_INF_TYPE.PLCANI_APCNTL_SET_INF_INIT';
%             for i_case = 1:case_num
%                 tx_case_cell = case_list(i_case);
%                 obj.case_str = [obj.case_str ',' 'PLCANI_APCNTL_SET_INF_TYPE.' obj.case_dict(tx_case_cell{1})];
%             end
%             swt_blk_pos = obj.swt_blk_base_pos + [0 0 0 case_num*obj.swt_blk_port_interval];
%             set_param(swt_blk_path, 'CaseConditions' , ['{' obj.case_str '}'], 'Position', swt_blk_pos);
%             %% 设置 inport 参数
%             trigger_path = [subsystem_path '/trigger'];
%             swt_in_pos = get_param(get_param(swt_blk_path, 'PortHandles').Inport(1), 'Position');
%             trigger_pos =  [swt_in_pos(1)-170, swt_in_pos(2)-7, swt_in_pos(1)-120, swt_in_pos(2)+7];
%             set_param(trigger_path, 'Position', trigger_pos)
%             %% 获取 Swicth Case 输出端口
%             swt_blk_hdls = get_param(swt_blk_path, 'PortHandles');
%             %%  添加 Init Case Subsystem
%             init_case_sub_path = [subsystem_path '/' system_name(1:end-11) '_Init'];
%             obj.add_sig_case_subsystem(init_case_sub_path, obj.can_info);
%             init_case_sub_port_hdls = get_param(init_case_sub_path, 'PortHandles');
%             init_case_sub_port_num = length(init_case_sub_port_hdls.Inport);
%             % 配置 Init Case Subsystem 位置
%             obj.case_sub_base_pos(4) = obj.case_sub_base_pos(2) + (obj.case_sub_port_interval+25)*init_case_sub_port_num;
%             init_case_sub_pos =  obj.case_sub_base_pos;
%             obj.case_sub_base_pos(2) = obj.case_sub_base_pos(4) + obj.case_sub_interval;
%             set_param(init_case_sub_path, 'Position', init_case_sub_pos);
%             % Switch 与 Init Case Subsystem 连线
%             add_line(subsystem_path, swt_blk_hdls.Outport(1), init_case_sub_port_hdls.Ifaction(1), 'autorouting','on');
%             % 添加 Init Case Subsystem 输入端口
%             obj.add_subsystem_inport(init_case_sub_path);
%             %% 循环添加非 Init Case Subsystem
%             for i_case = 1:case_num
%                 case_name = case_list(i_case);
%                 sig_case_sub_path = [subsystem_path '/' system_name(1:end-11) '_' case_name{1}];
%                 sig_case_info = obj.can_info(strcmp(obj.can_info.Elevel, case_name),:);
%                 obj.add_sig_case_subsystem(sig_case_sub_path, sig_case_info);
%                 case_sub_port_hdls = get_param(sig_case_sub_path, 'PortHandles');
%                 case_sub_port_num = length(case_sub_port_hdls.Inport);
%                 % 配置非 Init Case Subsystem 位置
%                 obj.case_sub_base_pos(4) = obj.case_sub_base_pos(2) + obj.case_sub_port_interval*case_sub_port_num;
%                 sig_case_sub_pos =  obj.case_sub_base_pos;
%                 obj.case_sub_base_pos(2) = obj.case_sub_base_pos(4) + obj.case_sub_interval;
%                 set_param(sig_case_sub_path, 'Position', sig_case_sub_pos);
%                 % Switch 与非 Init Case Subsystem 连线
%                 add_line(subsystem_path, swt_blk_hdls.Outport(1+i_case), case_sub_port_hdls.Ifaction(1), 'autorouting','on');
%                 % 添加 Init Case Subsystem 输入端口
%                 obj.add_subsystem_inport(sig_case_sub_path);
%                 % 合并 Case Subsystem 共有输出端口
%                 obj.add_subsystem_merge_outport(init_case_sub_path, sig_case_sub_path);
%             end
%             %% 按照 Init Case Subsystem 的端口顺序输出
%             port_hdls = find_system(init_case_sub_path, 'SearchDepth', 1, 'BlockType', 'Outport');
%             port_name = get_param(port_hdls, 'Name');
%             for i_name = 1:length(port_name)
%                 port_path = [subsystem_path '/' port_name{i_name}];
%                 set_param(port_path, 'Port', get_param([init_case_sub_path '/' port_name{i_name}], 'Port'));
%             end
%         end
% 
%         function system_hdl = add_sig_postpocess_subsystem(obj, subsystem_path)
%             %% 添加 subsystem
%             system_hdl = add_block('simulink/Ports & Subsystems/Subsystem', subsystem_path);
%             %% 删除原有的 in out line
%             del_in_hdl = getSimulinkBlockHandle([subsystem_path '/In1']);
%             del_out_hdl = getSimulinkBlockHandle([subsystem_path '/Out1']);
%             del_line_hdl = get_param(del_in_hdl, 'LineHandles');
%             delete_block([del_in_hdl, del_out_hdl]);
%             delete_line(del_line_hdl.Outport(1));
%             %% 批量添加移位操作
%             sig_num = length(obj.can_info.Row);
%             mid_pos = (obj.post_sub_inport_base_pos * 2 + (sig_num - 1) * obj.post_sub_interval)/2;
%             mid_point = (mid_pos(2)+mid_pos(4))/2;
%             mid_len = ((sig_num - 1) * obj.post_sub_interval)/2;
%             or_blk_pos = obj.post_sub_or_base_pos + [0 mid_point-mid_len 0 mid_point+mid_len];
%             or_blk_hdl = add_block('simulink/Logic and Bit Operations/Bitwise Operator', [subsystem_path '/Bitwise Operator'], 'Position', or_blk_pos, 'UseBitMask', 'off', 'logicop', 'OR', 'NumInputPorts', num2str(sig_num));
%             for i_sig = 1:sig_num
%                 frame_name = obj.can_info.Input{i_sig};
%                 frame_start = num2str(64 - str2double(obj.can_info.('Start Bit'){i_sig}) - str2double(obj.can_info.('Length'){i_sig}));
%                 inport_path = [subsystem_path '/' frame_name];
%                 inport_pos = obj.post_sub_inport_base_pos + [0 obj.post_sub_interval*i_sig 0 obj.post_sub_interval*i_sig];
%                 convert_pos = obj.post_sub_convert_base_pos + [0 obj.post_sub_interval*i_sig 0 obj.post_sub_interval*i_sig];
%                 shift_pos = obj.post_sub_shift_base_pos + [0 obj.post_sub_interval*i_sig 0 obj.post_sub_interval*i_sig];
%                 inport_hdl = add_block('simulink/Sources/In1', inport_path, 'Position', inport_pos);
%                 convert_hdl = add_block('simulink/Signal Attributes/Data Type Conversion', [subsystem_path '/Data Type Conversion'], 'ConvertRealWorld', 'Stored Integer (SI)', 'Position', convert_pos, 'MakeNameUnique', 'on', 'OutDataTypeStr', 'uint64');
%                 shift_hdl = add_block('simulink/Logic and Bit Operations/Shift Arithmetic', [subsystem_path '/Shift Arithmetic'], 'Position', shift_pos, 'MakeNameUnique', 'on', 'BitShiftDirection', 'Left', 'BitShiftNumber', frame_start);
%                 inport_name = get_param(inport_hdl, 'Name');
%                 convert_name = get_param(convert_hdl, 'Name');
%                 shift_name = get_param(shift_hdl, 'Name');
%                 add_line(subsystem_path, [inport_name '/1'], [convert_name '/1'], 'autorouting','on');
%                 add_line(subsystem_path, [convert_name '/1'], [shift_name '/1'], 'autorouting','on');
%                 add_line(subsystem_path, [shift_name '/1'], ['Bitwise Operator/' num2str(i_sig)], 'autorouting','on');
%             end
%             or_blk_out_pos = get_param(get_param(or_blk_hdl, 'PortHandles').Outport(1), 'Position');
%             frame_merge_pos = [or_blk_out_pos(1)+100 or_blk_out_pos(2)-60 or_blk_out_pos(1)+280 or_blk_out_pos(2)+60];
%             add_block(obj.lib_frame_merge, [subsystem_path '/frame_merge'], 'Position', frame_merge_pos);
%             add_line(subsystem_path, 'Bitwise Operator/1', 'frame_merge/1', 'autorouting','on');
%             outport_pos =  [or_blk_out_pos(1)+360 or_blk_out_pos(2)-7 or_blk_out_pos(1)+390 or_blk_out_pos(2)+7];
%             add_block('simulink/Sinks/Out1', [subsystem_path '/canframe'], 'Position', outport_pos);
%             add_line(subsystem_path, 'frame_merge/1', 'canframe/1', 'autorouting','on');
%         end
% 
%         function system_hdl = add_sig_case_subsystem(obj, subsystem_path, sig_case_info)
%             %% 添加 swtich case subsystem
%             system_hdl = add_block('simulink/Ports & Subsystems/Switch Case Action Subsystem', subsystem_path);
%             %% 删除原有的 in out line
%             del_in_hdl = getSimulinkBlockHandle([subsystem_path '/In1']);
%             del_out_hdl = getSimulinkBlockHandle([subsystem_path '/Out1']);
%             del_line_hdl = get_param(del_in_hdl, 'LineHandles');
%             delete_block([del_in_hdl, del_out_hdl]);
%             delete_line(del_line_hdl.Outport(1));
%             %% 批量添加 sig subsystem
%             for i_sig = 1:length(sig_case_info.Row)
%                 sig_info = sig_case_info(i_sig,:);
%                 sig_name = sig_info.Row{1};
%                 sig_sub_path = [subsystem_path '/' sig_name '_subsystem'];
%                 sig_sub_pos = [obj.sig_sub_base_pos(1), obj.sig_sub_base_pos(2) + i_sig * obj.sig_sub_interval, obj.sig_sub_base_pos(3), obj.sig_sub_base_pos(4) + i_sig * obj.sig_sub_interval];
%                 % 添加 sig subsystem
%                 obj.add_sig_subsystem(sig_sub_path, sig_info);
%                 set_param(sig_sub_path, 'Position', sig_sub_pos);
%                 % 配置 sig subsystem 端口
%                 obj.add_subsystem_port(sig_sub_path);
%             end
%             %% 设置 swtich case subsystem 缩放大小及代码生成格式
%             set_param(subsystem_path, 'ZoomFactor', '100');
%             set_param(subsystem_path, 'RTWSystemCode', 'Reusable function', 'RTWFcnNameOpts', 'Use subsystem name');
%         end
% 
%         function system_hdl = add_sig_subsystem(obj, subsystem_path, sig_info)
%             %% 通过表格判读添加 sig subsystem 类型
%             sig_name = sig_info.Row{1};
%             frame_name = sig_info.Input{1};
%             if contains(sig_info.("Invalid Status"), 'always FALSE')
%                 system_hdl = add_block(obj.lib_noerror_sub, subsystem_path);
%             else
%                 system_hdl = add_block(obj.lib_error_sub, subsystem_path);
%                 % 修改 can error status 名
%                 inv_name = convertStringsToChars(sig_info.('Invalid Status'));
%                 obj.modify_port_line_name('In', subsystem_path, 'cantx_inv_status', inv_name);
%             end
%             %% 修改 can in 名
%             obj.modify_port_line_name('In', subsystem_path, 'cantx_phy', sig_name);
%             %% 修改 can out 名
%             obj.modify_port_line_name('Out', subsystem_path, 'cantx_raw', frame_name);
%             %% 配置 LSB Offset
%             % mask_values = {sig_case_info.Offset, sig_case_info.Factor};
%             % set_param([subsystem_path '/Phy2Raw'], 'MaskValues', mask_values);
%             %% 配置上下限
%             % max_value = strcat("(", sig_info.Max, "- (", sig_case_info.Offset, ")) / (", sig_case_info.Factor, ")");
%             % min_value = strcat("(", sig_info.Min, "- (", sig_case_info.Offset, ")) / (", sig_case_info.Factor, ")");
%             max_value = sig_info.Max;
%             min_value = sig_info.Min;
%             set_param([subsystem_path '/Max'], 'Value', max_value);
%             set_param([subsystem_path '/Min'], 'Value', min_value);
%             %% 配置 sig subsystem 缩放大小及代码生成格式
%             set_param(subsystem_path, 'ZoomFactor', '100')
%             set_param(subsystem_path, 'TreatAsAtomicUnit', 'on', 'RTWSystemCode', 'Reusable function', 'RTWFcnNameOpts', 'Use subsystem name')
%         end

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
            %% 绑定Can Frame信号
            sig_prepocess_subsystem_name = [model_name '/' model_name '_main/' model_name '_preprocess'];
            obj.add_outport_canframe_resolve_on_line(sig_prepocess_subsystem_name, obj.can_info, design_data, "Model default")
            sig_main_subsystem_name = [model_name '/' model_name '_main'];
            obj.add_inport_dd_resolve_on_line(sig_main_subsystem_name, design_data, 'ImportedExtern');
            can_frame_name = [model_name '_canframe'];
            can_frame = Simulink.Signal;
            can_frame.CoderInfo.StorageClass = 'ExportedGlobal';
            can_frame.DataType = 'Bus: canframe';
            addEntry(design_data, can_frame_name, can_frame)
            can_frame_path =  [model_name '/' model_name '_main/' can_frame_name];
            line_hdl = get_param(can_frame_path, 'LineHandles').Inport(1);
            set_param(line_hdl, 'Name', can_frame_name);
            set(line_hdl, 'MustResolveToSignalObject', 1);
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