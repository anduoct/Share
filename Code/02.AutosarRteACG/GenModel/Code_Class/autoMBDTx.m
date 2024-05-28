classdef autoMBDTx < autoMBD
    properties
        can_info
        can_sldd

        normal_sub_base_pos
        normal_sub_interval
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

            obj.normal_sub_base_pos = [70 1500 710 1570];
            obj.normal_sub_interval = 100;
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
                normal_sub_pos = obj.normal_sub_base_pos + [0 obj.normal_sub_interval*i_sig 0 obj.normal_sub_interval*i_sig];
                if strcmp(sig_info.("Invalid Status"), '(always FALSE)')
                    add_block('user_lib/IFLayer_Send_Write_xxx(normal)', normal_sub_path, 'Position', normal_sub_pos);
                else
                    add_block('user_lib/IFLayer_Send_Write_xxx', normal_sub_path, 'Position', normal_sub_pos);
                    in_hdl = get_param(normal_sub_path, 'PortHandles').Inport(1);
                    in_pos = get_param(in_hdl, 'Position');
                    inport_pos =  [in_pos(1)-200, in_pos(2)-7, in_pos(1)-170, in_pos(2)+7];
                    if isempty(find_system(model_name,'SearchDepth', 1, 'BlockType', 'Inport', 'Name', sig_info.("Invalid Status")))
                        add_block('simulink/Sources/In1', strcat(model_name, '/', sig_info.("Invalid Status")), 'Name', sig_info.("Invalid Status"), 'Position', inport_pos)
                    end
                    add_line(model_name, strcat(sig_info.("Invalid Status"),'/1'), strcat(sig_info.Interface, '/1'), 'autorouting','on');  
                end
            end
            %% 配置 tx normal model 缩放大小
            set_param(normal_mdl, 'ZoomFactor', '100');
            %% 保存并关闭 tx normal model
            save_system(normal_mdl, [save_path, '\' , model_name, '.slx']);
            close_system(normal_mdl);
            %% 关闭并清除所有
            obj.clear_all();
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
            %% 绑定Can Frame信号
            obj.add_inport_dd_resolve_on_line(model_name, design_data, 'ImportedExtern');
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