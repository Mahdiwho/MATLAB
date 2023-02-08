
warning('off', 'MATLAB:table:RowsAddedExistingVars');

% clc;

[path] = uigetdir();
cd(path)
all_files = what;
mat_files = all_files.mat;

%%

save_directory = 'C:\Users\vpnl\Desktop\Mahdi - Working Data\Figures\contrast_figures';

sampleRate    = 32000;

SPONT_PERIOD   = 1;

ID_TEST_SCRIPT = 1;

PAR_START_X     = 1;
PAR_Contrast    = 5;
PAR_START_T     = 9;
PAR_DURATION    = 10;

ID_CONTRAST    = 1;
ID_START_F = ID_CONTRAST + 1;
ID_END_F   = ID_START_F + 1;
ID_RAW     = ID_END_F + 1;
ID_SPIKES  = ID_RAW + 1;
ID_BINS    = ID_SPIKES + 1;

contrast_curves                 = zeros([], []);
contrast_spontaneous            = zeros([], []);

contrast_curves_18             = zeros([], []);
contrast_curves_22             = zeros([], []);
contrast_curves_26             = zeros([], []);
contrast_curves_30             = zeros([], []);
contrast_curves_34             = zeros([], []);
contrast_curves_38             = zeros([], []);
contrast_curves_42             = zeros([], []);
contrast_curves_0             = zeros([], []);

spont_curves_18             = zeros([], []);
spont_curves_22             = zeros([], []);
spont_curves_26             = zeros([], []);
spont_curves_30             = zeros([], []);
spont_curves_34             = zeros([], []);
spont_curves_38             = zeros([], []);
spont_curves_42             = zeros([], []);
spont_curves_0             = zeros([], []);

isi_settings.blur             = false;
isi_settings.blur_size        = 51;
isi_settings.blur_spikes      = false;
isi_settings.blur_spikes_size = 3;
isi_settings.subsample        = false;
isi_settings.subsample_size   = 1;

table_cols = {
    'double',   'Animal_Date';
    'double',   'Temperature';
    'double',   'active_unit';
    'double',   'contrast'
    'cell',     'Spikes';
    'cell',     'Spontaneous_spikes';
    'double',   'stim_duration'
    'double',   'stim_end_frame'
    };

step_in = 0;

Mega_matrix = table('Size', [0, height(table_cols)], ...
    'VariableTypes', table_cols(:, 1), ...
    'VariableNames', table_cols(:, 2));

animal_list = toolGrabDirectories();

for count_animal = 1:length(animal_list)
    fprintf('## Date: %s\n', animal_list{count_animal});
    cd(animal_list{count_animal, 1});

    animal_string = animal_list{count_animal, 1};
    animal_date = str2double(extractAfter(animal_string, ('_')));


    deg_list = toolGrabDirectories();
    temperature_list = [];


    temp_row = 1;

    % ## Loop over each temperature set
    
    Small_matrix = table('Size', [0, height(table_cols)], ...
    'VariableTypes', table_cols(:, 1), ...
    'VariableNames', table_cols(:, 2));

    for count_temperature = 1:length(deg_list)
        fprintf('## Temperature: %s\n', deg_list{count_temperature});

        temp_string = deg_list{count_temperature, 1};

        spaces = strfind(temp_string, '_');
        temp_string = temp_string((spaces + 1):end);
        temperature = str2double(extractBefore(temp_string, 'deg'));
        temperature_list = vertcat(temperature_list, temperature);

        cd(deg_list{count_temperature, 1});
        exp_list = toolGrabDirectories();

        % ## Looping over each experiment within a temperature set
        for count_experiment = 1:length(exp_list)
            %             fprintf('## Experiment: %s\n', exp_list{count_experiment, 1});

            % ## Logic to narrow down which experiment it is
            if strfind(exp_list{count_experiment, 1}, 'NT_PROJ')
                clear allParams;
                cd(exp_list{count_experiment, 1});
                step_in = 1;

                all_files = what;
                mat_files = all_files.mat;
                if ~isempty(mat_files)
                    load(mat_files{1, 1}, 'allParams');

                    % ## Check if there is a contrast in the all parameters file... we
                    %    do not know where yet...
                    if ~isempty(cell2mat(strfind(allParams(ID_TEST_SCRIPT, 2:end), 'Con')))  || ~isempty(cell2mat(strfind(allParams(ID_TEST_SCRIPT, 2:end), 'Exp')))

                        good_exp_id = find(contains(allParams(ID_TEST_SCRIPT, 2:end), 'Con'), 1);
                        if nnz(good_exp_id) == 0
                            good_exp_id = find(contains(allParams(ID_TEST_SCRIPT, 2:end), '_R_'), 1);
                        end

                        if good_exp_id <= length(mat_files)
                            %                             fprintf('## - contrast: %d!!\n', good_exp_id);
                            clear active_unit
                            clear plexon_spikes

                            load(mat_files{good_exp_id, 1}, 'active_unit', 'plexon_spikes', 'stim_parameters', 'preStimTime', ...
                                'new_start', 'frameRate');
                            if ~exist('active_unit','var')
                                if ~isinteger('active_unit')
                                    clear active_unit
                                end
                                active_unit = input('what is the active unit?   ');
                                save(mat_files{good_exp_id, 1}, '-append', 'active_unit')
                            end

                            if frameRate > 200
                                pixels_per_degree = 15;
                            elseif frameRate < 200
                                pixels_per_degree = 20;
                            end



                            if exist('plexon_spikes', 'var')
                                spike_times = plexon_spikes(plexon_spikes(:, 1) == active_unit, 2);
                                
                                if ~exist('new_start', 'var')
                                    new_start = stim_parameters(9, 2:end);
                                end
                                
                                if length(stim_parameters) == 21
                                    temp_start_time_f    = new_start;
                                elseif length(stim_parameters) >= 60
                                    contrast_parameters = [];
                                    contrast_positions = 1;
                                    contrast_positions = [contrast_positions, 3:3:61];
                                    contrast_starts = 2:3:60;
                                    temp_start_time_f    = new_start(contrast_starts);
                                    for count_p = 1:length(contrast_positions)
                                        contrast_parameter = stim_parameters(:, contrast_positions(:, count_p));
                                        contrast_parameters = [contrast_parameters, contrast_parameter];
                                    end
                                    stim_parameters = contrast_parameters;
                                end

                                Contrasts = cell2mat(stim_parameters(PAR_Contrast, 2:end));
                                Stimulus = Contrasts;


                                %% ## Find each of the contrast responses
                                for count_stim = 1:length(Contrasts)
                                    fprintf('.');
                                    if mod(count_stim, 50) == 0
                                        fprintf('.?.\n')
                                    end

                                    temp_duration_s       = stim_parameters{PAR_DURATION, count_stim + 1};
                                    temp_end_samples      = temp_start_time_f + (temp_duration_s * sampleRate);
                                    temp_start_time_f          = round(temp_start_time_f);
                                    temp_end_time_f            = round(temp_end_samples);


                                    % ## Calculate start/end times
                                    useful_spikes = plexon_spikes(:, 2) > temp_start_time_f(:, count_stim) & plexon_spikes(:, 2) <= temp_end_time_f(:, count_stim);

                                    temp_spikes = plexon_spikes(useful_spikes, :);
                                    temp_spikes(:, 2) = temp_spikes(:, 2) - temp_start_time_f(:, count_stim);

                                    Small_matrix.Animal_Date(temp_row) = animal_date;
                                    Small_matrix.active_unit(temp_row) = active_unit;
                                    Small_matrix.Temperature(temp_row) = temperature;
                                    Small_matrix.contrast(temp_row)    = Contrasts(count_stim);
                                    Small_matrix.Spikes{temp_row}      = temp_spikes;

                                    Small_matrix.stim_duration(temp_row)     = temp_duration_s;


                                    %spontaneous data
                                    spont_duration_s       = SPONT_PERIOD*sampleRate;
                                    spont_start_time_f          = round(temp_start_time_f) - spont_duration_s;
                                    spont_end_time_f            = round(temp_start_time_f);


                                    % ## Calculate start/end times
                                    useful_spont = plexon_spikes(:, 2) > spont_start_time_f(:, count_stim) & plexon_spikes(:, 2) <= spont_end_time_f(:, count_stim);

                                    temp_spont = plexon_spikes(useful_spont, :);
                                    temp_spont(:, 2) = temp_spont(:, 2) - spont_start_time_f(:, count_stim);

                                    Small_matrix.Spontaneous_spikes{temp_row}      = temp_spont;


                                    temp_row = temp_row + 1;
                                    %                                     end of stimulus loop
                                end
                            end
                        else
                            %                             fprintf('##################################################\n');
                            %                             fprintf('########## WARNING MISSING PLEXON SPIKES #########\n');
                            %                             fprintf('##################################################\n');
                        end
                    end
                end
            end
            if step_in == 1
                cd('..');
                step_in = 0;
            end
            %       end of experiment loop
        end
        cd('..');
        %   end of temperature loop
    end

    Small_matrix = sortrows(Small_matrix, ["Temperature", "contrast"]);
    cd('..');
    %%

    [temp_contrast_curves, temp_spont_curves, wcontrast_scale] = toolQuickCFigure(Small_matrix, temperature_list, Stimulus, ...
    sampleRate, pixels_per_degree, active_unit, save_directory, animal_date);
    good_figure = 1;
%     good_figure = input('should we add this figure? 1 for yes, 2 to remove temperatures and 0 to not add any of it');
%     while good_figure == 2
%         how_many = 1;
%         while how_many == 1
%             which_temp = input('which temperature should we remove? 3 = none');
%             removals = find(Small_matrix.Temperature == which_temp);
%             Small_matrix(removals, :) = [];
%             temp_removal = find(temperature_list == which_temp);
%             temperature_list(temp_removal, :) = [];
%             [temp_contrast_curves, temp_spont_curves, wcontrast_scale] =toolQuickCFigure(Small_matrix, temperature_list, Stimulus, ...
%             sampleRate, pixels_per_degree, active_unit, save_directory, animal_date);
%             how_many = input('are you happy with it now? 2 for yes and 1 for no');
%             if which_temp == 3
%                 how_many = 2;
%             end
%         end
%         if how_many == 2
%             good_figure = 1;
%         end
%     end

    if good_figure == 1
        Mega_matrix = vertcat(Mega_matrix, Small_matrix);
        contrast_curves_18 = [contrast_curves_18, temp_contrast_curves.deg18];
        contrast_curves_22 = [contrast_curves_22, temp_contrast_curves.deg22];
        contrast_curves_26 = [contrast_curves_26, temp_contrast_curves.deg26];
        contrast_curves_30 = [contrast_curves_30, temp_contrast_curves.deg30];
        contrast_curves_34 = [contrast_curves_34, temp_contrast_curves.deg34];
        contrast_curves_38 = [contrast_curves_38, temp_contrast_curves.deg38];
        contrast_curves_42 = [contrast_curves_42, temp_contrast_curves.deg42];
        contrast_curves_0 = [contrast_curves_0, temp_contrast_curves.deg0];

        spont_curves_18 = [spont_curves_18, temp_spont_curves.deg18];
        spont_curves_22 = [spont_curves_22, temp_spont_curves.deg22];
        spont_curves_26 = [spont_curves_26, temp_spont_curves.deg26];
        spont_curves_30 = [spont_curves_30, temp_spont_curves.deg30];
        spont_curves_34 = [spont_curves_34, temp_spont_curves.deg34];
        spont_curves_38 = [spont_curves_38, temp_spont_curves.deg38];
        spont_curves_42 = [spont_curves_42, temp_spont_curves.deg42];
        spont_curves_0 = [spont_curves_0, temp_spont_curves.deg0];
    end

    clear 'figure_check', clear 'good_figure', clear 'remove_temp', clear 'how_many', clear 'removals', clear 'which_temp', clear 'final_check', clear 'Small_matrix';


    %     contrast_scale = [contrast_scale, temp_contrast_scale]
    %%
    % end of animal loop
end
%%

my_temperatures = [18, 22, 26, 30, 34, 38, 42, 0];

%% removing non_temperatures
extract_18 = find(all(contrast_curves_18==0));
contrast_curves_18(:, extract_18) = [];

extract_22 = find(all(contrast_curves_22==0));
contrast_curves_22(:, extract_22) = [];

extract_26 = find(all(contrast_curves_26==0));
contrast_curves_26(:, extract_26) = [];

extract_30 = find(all(contrast_curves_30==0));
contrast_curves_30(:, extract_30) = [];

extract_34 = find(all(contrast_curves_34==0));
contrast_curves_34(:, extract_34) = [];

extract_38 = find(all(contrast_curves_38==0));
contrast_curves_38(:, extract_38) = [];

extract_42 = find(all(contrast_curves_42==0));
contrast_curves_42(:, extract_42) = [];

extract_0 = find(all(contrast_curves_0==0));
contrast_curves_0(:, extract_0) = [];

%%

Mean_contrast_curve_18 = mean(contrast_curves_18, 2);
Mean_contrast_curve_22 = mean(contrast_curves_22, 2);
Mean_contrast_curve_26 = mean(contrast_curves_26, 2);
Mean_contrast_curve_30 = mean(contrast_curves_30, 2);
Mean_contrast_curve_34 = mean(contrast_curves_34, 2);
Mean_contrast_curve_38 = mean(contrast_curves_38, 2);
Mean_contrast_curve_42 = mean(contrast_curves_42, 2);
Mean_contrast_curve_0 = mean(contrast_curves_0, 2);

SEM_contrast_curve_18 = std(contrast_curves_18, 0 , 2)/sqrt(width(contrast_curves_18));
SEM_contrast_curve_22 = std(contrast_curves_22, 0 , 2)/sqrt(width(contrast_curves_22));
SEM_contrast_curve_26 = std(contrast_curves_26, 0 , 2)/sqrt(width(contrast_curves_26));
SEM_contrast_curve_30 = std(contrast_curves_30, 0 , 2)/sqrt(width(contrast_curves_30));
SEM_contrast_curve_34 = std(contrast_curves_34, 0 , 2)/sqrt(width(contrast_curves_34));
SEM_contrast_curve_38 = std(contrast_curves_38, 0 , 2)/sqrt(width(contrast_curves_38));
SEM_contrast_curve_42 = std(contrast_curves_42, 0 , 2)/sqrt(width(contrast_curves_42));
SEM_contrast_curve_0 = std(contrast_curves_0, 0 , 2)/sqrt(width(contrast_curves_0));

SEMs = [SEM_contrast_curve_18, SEM_contrast_curve_22, SEM_contrast_curve_26, SEM_contrast_curve_30, SEM_contrast_curve_34...
    , SEM_contrast_curve_38, SEM_contrast_curve_42, SEM_contrast_curve_0];

Mean_spont_curve_18 = mean(spont_curves_18, 2);
Mean_spont_curve_22 = mean(spont_curves_22, 2);
Mean_spont_curve_26 = mean(spont_curves_26, 2);
Mean_spont_curve_30 = mean(spont_curves_30, 2);
Mean_spont_curve_34 = mean(spont_curves_34, 2);
Mean_spont_curve_38 = mean(spont_curves_38, 2);
Mean_spont_curve_42 = mean(spont_curves_42, 2);
Mean_spont_curve_0 = mean(spont_curves_0, 2);

Sample_Size_18 = width(contrast_curves_18);
Sample_Size_22 = width(contrast_curves_22);
Sample_Size_26 = width(contrast_curves_26);
Sample_Size_30 = width(contrast_curves_30);
Sample_Size_34 = width(contrast_curves_34);
Sample_Size_38 = width(contrast_curves_38);
Sample_Size_42 = width(contrast_curves_42);
Sample_Size_0 = width(contrast_curves_0);

Sample_sizes = [Sample_Size_18, Sample_Size_22, Sample_Size_26, Sample_Size_30, Sample_Size_34, Sample_Size_38, Sample_Size_42, Sample_Size_0];

Mean_curves = [Mean_contrast_curve_18, Mean_contrast_curve_22, Mean_contrast_curve_26, Mean_contrast_curve_30, Mean_contrast_curve_34...
    Mean_contrast_curve_38, Mean_contrast_curve_42, Mean_contrast_curve_0];

Mean_spont_curves = [Mean_spont_curve_18, Mean_spont_curve_22, Mean_spont_curve_26, Mean_spont_curve_30, Mean_spont_curve_34...
    Mean_spont_curve_38, Mean_spont_curve_42, Mean_spont_curve_0];

my_temperatures = [18, 22, 26, 30, 34, 38];

colour = [0.00,0.00,0.53; 0.27,0.60,1.00; 0.53,0.88,0.16; 0.93,0.69,0.13; 1.00,0.28,0.28; 0.64,0.08,0.18; 0, 0, 0; 0.5,0.9,0.2];

%%
for temp_no = 1:length(my_temperatures)
    mean_contrast_tuning = figure(1);

    
    line_handle_contrast = semilogx(wcontrast_scale, Mean_curves(:, temp_no), 'k-', 'DisplayName', horzcat(num2str(my_temperatures(temp_no)), ' °C, N = ', num2str(Sample_sizes(temp_no))));
    set(line_handle_contrast, 'Color', colour(temp_no , :));

    
    axis([0 1.03 0 350])
    xlabel('contrast')
    ylabel('spikes/s')
    title('Contrast Sensitivity')
    hold on

    spont_handle_V = semilogx(wcontrast_scale, Mean_spont_curves(:, temp_no), '--');
    set(spont_handle_V, 'Color', colour(temp_no, :));
    hold on

    legend('location', 'northwest');
    
    er = errorbar(wcontrast_scale, Mean_curves(:, temp_no), SEMs(:, temp_no));
    er.Color = colour(temp_no , :);
    er.LineStyle = 'none';
    
    er.Annotation.LegendInformation.IconDisplayStyle = 'off';
    spont_handle_V.Annotation.LegendInformation.IconDisplayStyle = 'off';
end

hold off
%%
% exportgraphics(mean_contrast_tuning,[save_directory, '\Mean_Contrast_Sensitivity.pdf'],'BackgroundColor','none','ContentType','vector');