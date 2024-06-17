classdef autoMBDRx < autoMBD
    properties
        model_info
        can_sldd
        getdata_tlc
        indfunccall_tlc
        indfunc_call_base_pos
        normal_main_base_pos
        normal_main_interval
        normal_sub_base_pos
    end
    methods
        function obj = autoMBDRx(ram_sht_tbl, rom_sht_tbl)
            obj = obj@autoMBD(ram_sht_tbl, rom_sht_tbl);
            obj.can_sldd = which('canrx.sldd');
            obj.getdata_tlc = which('tlc\GetData.tlc');
            obj.indfunccall_tlc = which('tlc\IndFunc.tlc');
            obj.indfunc_call_base_pos = [240 0 650 70];
            obj.normal_main_base_pos = [240 110 650 130];
            obj.normal_main_interval = 40;
            obj.normal_sub_base_pos = [70 1500 710 1570];
        end

        function gen_normal_model(obj, save_path, model_name, model_info)
            %% 关闭并清除所有
            obj.clear_all();
            %% 获取 cantx info
            obj.model_info = model_info;
            %% 配置生成模型路径及拷贝 sldd
            if exist(save_path,'dir')
                rmdir(save_path, 's')
            end
            mkdir(save_path);
            addpath(save_path)
            sldd_path = [save_path '\' model_name '.sldd'];
            copyfile(obj.can_sldd, sldd_path);
            copyfile(obj.getdata_tlc, save_path);
            copyfile(obj.indfunccall_tlc, save_path);
            %% 新建并打开 rx normal model
            normal_mdl = new_system(model_name);
            open_system(normal_mdl);
            %% 配置 rx normal model 代码导出方式 sldd 及 缩放率
            set_param(normal_mdl, 'Datadictionary',[model_name '.sldd'])
            %% 添加 rx indfunc call
            indfunc_call_path = [model_name '/' model_name '_ind'];
            obj.add_indfunc_call_subsystem(indfunc_call_path, model_info);
            set_param(indfunc_call_path, 'Position', obj.indfunc_call_base_pos);
            %% 添加 rx normal subsystem
            normal_main_path = [model_name '/' model_name '_main'];
            obj.add_normal_main_subsystem(normal_main_path, model_info);
            % 配置 rx normal main 位置
            port_num = length(get_param(normal_main_path, 'PortHandles').Outport);
            normal_main_pos = obj.normal_main_base_pos + [0 0 0 obj.normal_main_interval*port_num];
            set_param(normal_main_path, 'Position', normal_main_pos);
            % 添加 tx normal model 输入
            obj.add_subsystem_port(normal_main_path);
            %% 配置 tx normal model 缩放大小
            set_param(normal_mdl, 'ZoomFactor', '100');
            %% 保存并关闭 tx normal model
            save_system(normal_mdl, [save_path, '\' , model_name, '.slx']);
            close_system(normal_mdl);
            %% 关闭并清除所有
            obj.clear_all();
        end

        function system_hdl = add_indfunc_call_subsystem(~, subsystem_path, model_info)
            %% 添加 ind subsystem
            system_hdl = add_block('simulink/Ports & Subsystems/Subsystem', subsystem_path);
            % 删除原有的 in out line
            del_in_hdl = getSimulinkBlockHandle([subsystem_path '/In1']);
            del_out_hdl = getSimulinkBlockHandle([subsystem_path '/Out1']);
            del_line_hdl = get_param(del_in_hdl, 'LineHandles');
            delete_block([del_in_hdl, del_out_hdl]);
            delete_line(del_line_hdl.Outport(1));
            %% 添加 main subsystem
            msg_summary = model_info.summary;
            msg_detail = model_info.detail;
            block_path = [subsystem_path '/IndFunc_Call_'  char(msg_summary.("FrameID"))];
            add_block('user_lib/IndFunc_Call', block_path);
            mask_value{1} = 'Test';
            mask_value{2} = msg_summary.("FrameID");
            table_str = '';
            for i_sig = 1:length(msg_detail.Row)
                signal_info = msg_detail(i_sig,:);
                table_str =  [table_str ';''' char(signal_info.("Data Type")) ''',''' char(signal_info.IFLayer_Signal) ''',''' char(signal_info.("Signal Index")) ''''];
            end
            mask_value{3} = ['{'  table_str(2:end) '}'];
            if strcmp(msg_summary.("Timeout flag"), "1")
                mask_value{4} = 'on';
            else
                mask_value{4} = 'off';
            end
            if strcmp(msg_summary.("J1939/ISO"), "J1939")
                mask_value{5} = 'on';
            else
                mask_value{5} = 'off';
            end
            set_param(block_path, 'MaskValues', mask_value);
        end

        function system_hdl = add_normal_main_subsystem(obj, subsystem_path, model_info)
            %% 添加 main subsystem
            system_hdl = add_block('simulink/Ports & Subsystems/Subsystem', subsystem_path);
            % 删除原有的 in out line
            del_in_hdl = getSimulinkBlockHandle([subsystem_path '/In1']);
            del_out_hdl = getSimulinkBlockHandle([subsystem_path '/Out1']);
            del_line_hdl = get_param(del_in_hdl, 'LineHandles');
            delete_block([del_in_hdl, del_out_hdl]);
            delete_line(del_line_hdl.Outport(1));
            %% 添加 process subsystem
            msg_info = model_info.detail;
            ref_pos = obj.normal_sub_base_pos;
            ref_delata = 0;
            for i_sig = 1:length(msg_info.Row)
                signal_info = msg_info(i_sig,:);
                iflayer_sub_path = [subsystem_path '/IFLayer_Receive_Write_' char(signal_info.("Signal Index"))];
                obj.add_iflayer_subsystem(iflayer_sub_path, signal_info);   
                receive_254_path = [subsystem_path '/2-5-4Receive_' char(signal_info.("Signal Index"))];
                obj.add_receive_254_subsystem(receive_254_path, signal_info);
                select_311_path = [subsystem_path '/Select_Input_' char(signal_info.("Signal Index"))];
                obj.add_select_311_subsystem(select_311_path, signal_info);

                iflayer_sub_pos = ref_pos + [0 100+ref_delata 0 100+ref_delata];
                ref_pos = iflayer_sub_pos;
                receive_254_port_num = length(get_param(receive_254_path, 'PortHandles').Inport);
                if receive_254_port_num == 2
                    receive_254_pos = iflayer_sub_pos + [700 0 700 0];
                    select_311_pos = receive_254_pos + [700 0 700 0];
                    ref_delata = 0;
                elseif receive_254_port_num == 4
                    receive_254_pos = iflayer_sub_pos + [700 1 700 69];
                    select_311_pos = receive_254_pos + [700 2 700 3];
                    ref_delata = 70;
                end
                set_param(iflayer_sub_path, 'Position', iflayer_sub_pos);
                set_param(receive_254_path, 'Position', receive_254_pos);
                set_param(select_311_path, 'Position', select_311_pos);

                obj.add_line_between_subsystem(iflayer_sub_path, receive_254_path);
                obj.add_line_between_subsystem(receive_254_path, select_311_path);

                obj.add_subsystem_inport(iflayer_sub_path);
                obj.add_subsystem_inport(receive_254_path);
                obj.add_subsystem_outport(select_311_path);
            end
        end

        function system_hdl = add_iflayer_subsystem(~, subsystem_path, signal_info)
            error_num = randi([0,2]);
            if error_num == 0
                system_hdl = add_block('template/IFLayer_Receive_Write_xxx', subsystem_path);
            elseif error_num == 1
                system_hdl = add_block('template/IFLayer_Receive_Write_xxx(invalid1)', subsystem_path);
            elseif error_num == 2
                system_hdl = add_block('template/IFLayer_Receive_Write_xxx(invalid2)', subsystem_path);
            end
            set_param([subsystem_path '/inv_xxxx'], 'Name', signal_info.("Invalid Status"));
            set_param([subsystem_path '/can_gmlan_rx_invalid_xxxx'], 'Name', signal_info.("Receive Parameter Invalid Status"));
            set_param([subsystem_path '/can_gmlan_rx_xxxx'], 'Name', signal_info.("Receive Parameter"));
            set_param([subsystem_path '/K_CAN_GMLAN_RX_INVALID_SELECT'], 'Value', "K_CAN_GMLAN_RX_INVALID_SELECT");
            set_param([subsystem_path '/K_CAN_GMLAN_RX_DEFAULT_xxxx'], 'Name', signal_info.("Error Indicator Value"));
            set_param([subsystem_path '/GetData'], 'MaskValues', {signal_info.("Signal Index"); signal_info.("Data Type")});
            set_param([subsystem_path '/Data Type Conversion'], 'OutDataTypeStr', signal_info.("Data Type"));
            set_param([subsystem_path '/Max'], 'Value', signal_info.Max);
            set_param([subsystem_path '/Min'], 'Value', signal_info.Min);
        end

        function system_hdl = add_receive_254_subsystem(~, subsystem_path, signal_info)
            type_num = double(signal_info.("2-5-4 Requeset Paramter Select Flag"));
            if type_num == 1
                system_hdl = add_block('template/2-5-4receive_equal', subsystem_path);
            elseif type_num == 2
                system_hdl = add_block('template/2-5-4receive_slect', subsystem_path);
                set_param([subsystem_path '/can_J1939_rx_invalid_xxxx'], 'Name', signal_info.("Receive Parameter Invalid Status 2"));
                set_param([subsystem_path '/can_J1939_rx_xxxx'], 'Name', signal_info.("Receive Parameter 2"));
                set_param([subsystem_path '/PLCANC_APCNTL_RQST_SEL_J1939'], 'Value', "PLCANC_APCNTL_RQST_SEL_J1939");
                set_param([subsystem_path '/PLCANC_APCNTL_RQST_SEL_GMLAN'], 'Value', "PLCANC_APCNTL_RQST_SEL_GMLAN");
                set_param([subsystem_path '/K_CAN_RX_SEL_XXX'], 'Name', signal_info.("K_CAN_RX_SEL_XXX"));
            end
            set_param([subsystem_path '/can_gmlan_rx_invalid_xxxx'], 'Name', signal_info.("Receive Parameter Invalid Status"));
            set_param([subsystem_path '/can_gmlan_rx_xxxx'], 'Name', signal_info.("Receive Parameter"));
            set_param([subsystem_path '/can_invalid_can_rx_xxxx'], 'Name', signal_info.("RxSel Parameter Invalid Status"));
            set_param([subsystem_path '/can_rx_xxxx'], 'Name', signal_info.("RxSel Parameter"));
        end

        function system_hdl = add_select_311_subsystem(~, subsystem_path, signal_info)
            type_num = double(signal_info.("3-1-1 Requeset Paramter Select Flag"));
            if type_num == 1
                system_hdl = add_block('template/Select_Input_1', subsystem_path);
                set_param([subsystem_path '/K_CAN_RQST_SEL_XXX'], 'Name', signal_info.("K_CAN_RQST_SEL_XXX"));
            elseif type_num == 2
                system_hdl = add_block('template/Select_Input_2', subsystem_path);
                set_param([subsystem_path '/K_CAN_RQST_SEL_XXX'], 'Name', signal_info.("K_CAN_RQST_SEL_XXX"));
                set_param([subsystem_path '/K_RQST_DRCT_XXX'], 'Name', signal_info.("K_RQST_DRCT_XXX"));
            elseif type_num == 3
                system_hdl = add_block('template/Select_Input_3', subsystem_path);
            end

            set_param([subsystem_path '/can_invalid_can_rx_xxx'], 'Name', signal_info.("RxSel Parameter Invalid Status"));
            set_param([subsystem_path '/can_rx_xxx'], 'Name', signal_info.("RxSel Parameter"));
            set_param([subsystem_path '/can_invalid_can_rqst_xxx'], 'Name', signal_info.("can_invalid_can_rqst_xxx"));
            set_param([subsystem_path '/can_rqst_xxx'], 'Name', signal_info.("can_rqst_xxx"));
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
            %% 绑定信号及cali
            obj.add_inport_dd_resolve_on_line(model_name, design_data, 'ImportedExtern');
            obj.add_outport_dd_resolve_on_line(model_name, design_data, 'ExportedGlobal');
            obj.add_subsystem_external_resolve(model_name, design_data);
            obj.add_constant_resolve(model_name, design_data, 'ImportedExtern');
            %% 保存并关闭模型
            save_system(model_name);
            sldd_obj.saveChanges()
            sldd_obj.close()
            close_system(model_name);
            %% 关闭并清除所有
            obj.clear_all();
        end

        function add_subsystem_external_resolve(obj, subsystem_path,  design_data)
            iflayer_subsystem_names = get_param(find_system(subsystem_path,'regexp','on', 'SearchDepth', 2, 'Name', '^IFLayer_Receive_Write_'), 'Name');
            for i_sub = 1:length(iflayer_subsystem_names)
                obj.add_outport_dd_resolve_on_line([subsystem_path '/' subsystem_path '_main/' iflayer_subsystem_names{i_sub}], design_data, 'ExportedGlobal')

                cov_path = [subsystem_path '/' subsystem_path '_main/' iflayer_subsystem_names{i_sub} '/Data Type Conversion'];
                data_type = get_param(cov_path, 'OutDataTypeStr');
                temp_cell = split(iflayer_subsystem_names{i_sub}, '_rx_');

                min_path = [subsystem_path '/' subsystem_path '_main/' iflayer_subsystem_names{i_sub} '/Min'];
                min_value = get_param(min_path, 'Value');
                min_name = ['D_' upper(temp_cell{2}) '_MIN'];
                set_param(min_path, 'Value', min_name);
                min_param = Simulink.Parameter;
                min_param.CoderInfo.StorageClass = 'Custom';
                min_param.CoderInfo.CustomStorageClass = "Define";
                min_param.DataType = data_type;
                min_param.Value = str2double(min_value);
                addEntry(design_data, min_name, min_param)

                max_path = [subsystem_path '/' subsystem_path '_main/' iflayer_subsystem_names{i_sub} '/Max'];
                max_value = get_param(max_path, 'Value');
                max_name = ['D_' upper(temp_cell{2}) '_MAX'];
                set_param(max_path, 'Value', max_name);
                max_param = Simulink.Parameter;
                max_param.CoderInfo.StorageClass = 'Custom';
                max_param.CoderInfo.CustomStorageClass = "Define";
                max_param.DataType = data_type;
                max_param.Value = str2double(max_value);
                addEntry(design_data, max_name, max_param)
            end
            

            receive_subsystem_names = get_param(find_system(subsystem_path,'regexp','on', 'SearchDepth', 2, 'Name', '^2-5-4Receive_'), 'Name');
            for i_sub = 1:length(iflayer_subsystem_names)
                obj.add_outport_dd_resolve_on_line([subsystem_path '/' subsystem_path '_main/' receive_subsystem_names{i_sub}], design_data, 'ExportedGlobal')
            end
        end

  

    end
end