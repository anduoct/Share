classdef autoMBDTx < autoMBD
    properties
        model_info
        can_sldd
        getdata_tlc
        invalid_tlc
        sendsignal_tlc
        normal_sub_base_pos
        normal_sub_interval
    end
    methods
        function obj = autoMBDTx(ram_sht_tbl, rom_sht_tbl)
            obj = obj@autoMBD(ram_sht_tbl, rom_sht_tbl);
            obj.can_sldd = which('cantx.sldd');
            obj.getdata_tlc = which('tlc\GetData.tlc');
            obj.invalid_tlc = which('tlc\InvalidSendSignal.tlc');
            obj.sendsignal_tlc = which('tlc\Com_SendSignal.tlc');
            obj.normal_sub_base_pos = [70 1500 710 1570];
            obj.normal_sub_interval = 100;
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
            copyfile(obj.invalid_tlc, save_path);
            copyfile(obj.sendsignal_tlc, save_path);
            %% 新建并打开 tx normal model
            normal_mdl = new_system(model_name);
            open_system(normal_mdl);
            %% 配置 tx normal model 代码导出方式 sldd 及 缩放率
            set_param(normal_mdl, 'Datadictionary',[model_name '.sldd'])
            %% 添加 tx normal subsystem
            for i_sig = 1:length(obj.model_info.detail.Row)
                sig_info = obj.model_info.detail(i_sig,:);
                normal_sub_path = [model_name '/' char(sig_info.Interface)];
                normal_sub_pos = obj.normal_sub_base_pos + [0 obj.normal_sub_interval*i_sig 0 obj.normal_sub_interval*i_sig];
                obj.add_signal_subsystem(normal_sub_path, sig_info);
                set_param(normal_sub_path, 'Position', normal_sub_pos);
                obj.add_subsystem_inport(normal_sub_path);
            end
            %% 配置 tx normal model 缩放大小
            set_param(normal_mdl, 'ZoomFactor', '100');
            %% 保存并关闭 tx normal model
            save_system(normal_mdl, [save_path, '\' , model_name, '.slx']);
            close_system(normal_mdl);
            %% 关闭并清除所有
            obj.clear_all();
        end

        function system_hdl = add_signal_subsystem(~, subsystem_path, signal_info)
            if strcmp(signal_info.("Invalid Status"), '(always FALSE)')
                system_hdl = add_block('template/IFLayer_Send_Write_xxx(normal)', subsystem_path);
                normal_path = subsystem_path;
            else
                system_hdl = add_block('template/IFLayer_Send_Write_xxx', subsystem_path);
                normal_path = [subsystem_path '/If Action Subsystem1'];
                set_param([subsystem_path '/IFLayer_inv_Signal_xxx'], 'Name', signal_info.("Invalid Status"));
                set_param([subsystem_path '/If Action Subsystem/Com_InvalidSendSignal'], 'MaskValues', {signal_info.SignalId});
            end
            set_param([normal_path '/GetData'], 'MaskValues', {signal_info.Interface;signal_info.("Data Type")});
            set_param([normal_path '/Max'], 'Value', signal_info.Max);
            set_param([normal_path '/Min'], 'Value', signal_info.Min);
            set_param([normal_path '/Com_SendSignal_call'], 'MaskValues', {signal_info.SignalId});
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