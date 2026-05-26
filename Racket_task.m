cd('~/Tarefa_raquete');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% configuracoes %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Nome do experimento. Incluir o nome do grupo no codigo
experimento = 'ntt_auto_tar';
%'ntt_auto_apr' - Com instrução sobre o teste (meta de aprendizagem)
%'ntt_auto_tar' - Sem instrução sobre o teste (meta da tarefa)


% Numero do sujeito
sjnum = '16';

% Número de tentativas de pratica
% Será autocontrolado ou yoked, conforme determinado pelo tipo de prática (abaixo)

% Tipo de prática ao qual o participante será submetido
pratica = 'trl';
% 'liv' = autocontrolada com número de tentativas livre
% 'yok' = número de tentativas determinadao pelo sujeito autocontrolado especificado em 'experimento' e 'sjnum'
% 'trl' = executa o teste de transferência (tentativas de prática sem a presença de feedback) para o grupo liv
% 'try' = executa o teste de transferência (tentativas de prática sem a presença de feedback) par ao grupo yok

% Número máximo de tentativas que um participante pode praticar
trial_limit = 1000;

% Caso alguém pergunte (ou para divulgação):
% O teste demora aproximadamente 30 minutos


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% enderecos fisicos %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
myu3_path_x = '/home/coleta/LabJackPython/labjack-LJFuse/root-ljfuse/MyU3/connection/EIO0';
myu3_path_y = '/home/coleta/LabJackPython/labjack-LJFuse/root-ljfuse/MyU3/connection/EIO1';
myu3_path_z = '/home/coleta/LabJackPython/labjack-LJFuse/root-ljfuse/MyU3/connection/EIO2';

line_positions_path = '~/Tarefa_raquete/line_positions.txt';
transfer_trials_path = '~/Tarefa_raquete/transfer_trials.txt';

script_path = '/home/coleta/Tarefa_raquete';

txt_name = sprintf('%s_suj%s.txt', experimento, sjnum); % Nome do arquivo txt para salvar todas as tentativas do sujeito
arquivo_sj_path = sprintf('/home/coleta/Tarefa_raquete/%s/%s_suj%s.txt', experimento, experimento, sjnum);


% Carrega os dados do sujeito autocontrolado se for um experimento yoked
% Ou o número de tentativas a ser praticado caso seja um teste de tr / rt
% O nome dos arquivos também é ajustado caso seja um teste de tr / rt (autocontrolado ou yoked)
if pratica == 'liv'
	% Se ocorrer algum problema durante a aquisição, recupera o número de tentativas
	try
		recuperar_ntt = load(arquivo_sj_path); % [linha_inicial coluna_inicial linha_final coluna_final] % O primeiro índice é igual a 0 (ex.: coluna 1 = 0)
	catch
		recuperar_ntt = [];
	end
	
elseif pratica == 'yok'
	arquivo_sj_auto = load(arquivo_sj_path);
	txt_name = sprintf('%s_yoked_suj%s.txt', experimento, sjnum); % Nome do arquivo txt para sujeitos Yoked
	recuperar_ntt = [];

elseif pratica == 'trl' 
	transfer_trials = load(transfer_trials_path);
	recuperar_ntt = [];
	
elseif pratica == 'try'
	transfer_trials = load(transfer_trials_path);
	txt_name = sprintf('%s_yoked_suj%s.txt', experimento, sjnum); % Nome do arquivo txt para sujeitos Yoked
	recuperar_ntt = [];
end



mkdir(experimento); % Criar uma pasta para armazenar os arquivos deste experimento




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% carrega valores de arquivos externos %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Carrega as posicoes 'aleatorias' para a linha
line_positions = load(line_positions_path);

% Verifica se o Labjack esta habilitado
try
    dlmread(myu3_path_z);
catch
    error('***** O Labjack não está ativado! *****')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Mudar configuração das portas flexiveis (EIO) para output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
system('echo 2 > /home/coleta/LabJackPython/labjack-LJFuse/root-ljfuse/MyU3/connection/EIO0-dir')
system('echo 2 > /home/coleta/LabJackPython/labjack-LJFuse/root-ljfuse/MyU3/connection/EIO1-dir')
system('echo 2 > /home/coleta/LabJackPython/labjack-LJFuse/root-ljfuse/MyU3/connection/EIO2-dir')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% preparar a tela e as cores %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Opens the active window
screenNum = 0;
[wPtr,rect] = Screen('OpenWindow', screenNum); % Using screen number only, the whole screen is used as default

% Color parameters MUST came after openning the window
black = BlackIndex(wPtr);
white = WhiteIndex(wPtr);
red = [255 0 0];
green = [0 255 0];
yellow = [255 255 0];
proj_color = [0 255 0];

% Fills the open window with black
Screen('FillRect',wPtr,black);
Screen('Flip', wPtr); % Flip
HideCursor;
WaitSecs(0.1); % Waits a specified time (in seconds)

% Adquire a frequencia do monitor para calcular o tempo entre tentativas
[ monitorFlipInterval nrValidSamples stddev ] = Screen('GetFlipInterval', wPtr);
% Put functions into memory for speed
GetSecs;
WaitSecs(0.1);





% Variaveis antes do loop de tentativas
desemp = [];
dados_sj = [];
dados_all = [];


if ~isempty(recuperar_ntt)
	trial = size(recuperar_ntt, 1);
else
	trial = 0;
end





escolha = '1';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% loop de tentativas %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
while escolha == '1'
    
    trial = trial + 1;
    
    % Número de tentativas máximo que um participante pode praticar
    if trial > trial_limit
    
    	dados_sj = [0 0 pos_horiz_linha tamanho_tela_em_pixels tamanho_tela_em_cm 0 0];
		
		cd(experimento); % Muda para a pasta do experimento sendo conduzido
		dlmwrite(txt_name, dados_sj, 'delimiter', '\t', '-append');
		cd(script_path); % Retorna para a pasta onde esta o script
    
		WaitSecs(0.2); % Evita que a tecla esteja pressionada no incio da proxima tentativa
    
		break
	end
		
    
    % Encerra a prática do sj yoked quando o número de tentativas é igual ao do auto
    if pratica == 'yok'
		escolha = num2str(arquivo_sj_auto(trial)); % arquivo_sj_auto foi lido após as configurações (antes do loop de tt)
	elseif pratica == 'liv'
		escolha = '1';
	elseif pratica == 'trl' || pratica == 'try'
		escolha = num2str(transfer_trials(trial));
	end
	
	

    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%% interacao com o participante %%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if pratica == 'liv'
        Screen('TextFont',wPtr, 'Ubuntu');
        Screen('TextSize',wPtr, 30);
        Screen('DrawText', wPtr, 'Pressione 1 para a próxima tentativa', rect(RectRight)/4.6, rect(RectBottom)/2.5, [255, 255, 255]);
           
        Screen('DrawText', wPtr, 'Pressione 0 para encerrar a prática', rect(RectRight)/4.6, rect(RectBottom)/2, [255, 255, 255]);
        
        Screen('Flip', wPtr); % Flip
        
        % Faz a perguntar ficar na tela até que uma opção seja escolhida
        time_escolha_ini = GetSecs; % Inicia o cronometro do tempo de escolha
        keyIsDown = 0;
        
        while keyIsDown == 0
            [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
            escolha = KbName(keyCode); % Armazena a opção escolhida
            
            if length(escolha) != 1
                keyIsDown = 0;
                escolha = [];
            end
              
            if (escolha != '0') && (escolha != '1') %just in case...
                keyIsDown = 0;
            end
            
        end
        
        time_escolha_end = GetSecs; % Fecha o cronometro da escolha
    
    elseif (pratica == 'yok' || pratica == 'trl' || pratica == 'try') && escolha != '0'
    
        Screen('TextFont',wPtr, 'Ubuntu');
        Screen('TextSize',wPtr, 30);
        Screen('DrawText', wPtr, 'Pressione 1 para a próxima tentativa', rect(RectRight)/4.6, rect(RectBottom)/2.5, [255, 255, 255]);
        
        Screen('Flip', wPtr); % Flip
        
        % Faz a perguntar ficar na tela até que uma opção seja escolhida
        time_escolha_ini = GetSecs; % Inicia o cronometro do tempo de escolha
        keyIsDown = 0;
        
        while keyIsDown == 0
            [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
            escolha = KbName(keyCode); % Armazena a opção escolhida
            
            if length(escolha) != 1
                keyIsDown = 0;
                escolha = [];
            end
              
            if escolha != '1' %just in case...
                keyIsDown = 0;
                escolha = [];
            end
            
            
            
		end
		
		time_escolha_end = GetSecs; % Fecha o cronometro da escolha
		
    end
    
    time_escolha = time_escolha_end - time_escolha_ini; % Calcula o tempo da tela de escolha
 
 
    % Se o participante auto escolhe parar, o script não entra no loop de animação
    if escolha == '0'
    
		dados_sj = [str2num(escolha) 0 pos_horiz_linha tamanho_tela_em_pixels tamanho_tela_em_cm 0 0];
		
		cd(experimento); % Muda para a pasta do experimento sendo conduzido
		dlmwrite(txt_name, dados_sj, 'delimiter', '\t', '-append');
		cd(script_path); % Retorna para a pasta onde esta o script
    
		WaitSecs(0.2); % Evita que a tecla esteja pressionada no incio da proxima tentativa
		continue
	end
    

    
    
    
    
    
    
    % Verifica se a raquete está na posição vertical
    % A mesma deve ser mantida nessa posição por X segundos (while loop)
    calibracao = 0;
    calibracao_i = 0;
    
    while calibracao_i < 1.5;
        
        accel_z = dlmread(myu3_path_z);
        
        if (accel_z < 1.65 & accel_z > 1.50)
            
            Screen('TextFont',wPtr, 'Ubuntu');
            Screen('TextSize',wPtr, 30);
            Screen('DrawText', wPtr, 'Calibrando...', rect(RectRight)/4.6, rect(RectBottom)/2.5, [255, 255, 255]);
            Screen('Flip', wPtr); % Flip
            
            calibracao_i = calibracao_i + monitorFlipInterval;
            
            
        else
            
            Screen('TextFont',wPtr, 'Ubuntu');
            Screen('TextSize',wPtr, 30);
            Screen('DrawText', wPtr, 'Posicione a raquete na posição inicial', rect(RectRight)/4.6, rect(RectBottom)/2.5, [255, 255, 255]);
            Screen('Flip', wPtr); % Flip
            
            calibracao_i = 0;
            
        end
        
        
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%%%%%%%%%%% variáveis pré-animação %%%%%%%%%%%%%%%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Determina as coordenadas iniciais do alvo
    alvo_left = rect(RectLeft);
    alvo_top = (rect(RectBottom)/2) - (rect(RectBottom)/32); % Determina a distancia entre o alvo e o topo da tela
    alvo_larg = rect(RectBottom)/16;
    alvo_alt = rect(RectBottom)/32;
    
    pos_horiz_linha = rect(RectRight)/line_positions(trial);
    largura_linha_alvo = 1; % Largura da linha final(alvo)

    % Cursor size
    cursor_horiz = rect(RectRight)/35;
    cursor_vert = cursor_horiz;
    
    x_mouse_ini = rect(RectRight) - round(rect(RectRight)/18.2);
    y_mouse_ini = rect(RectBottom)/2 - round((rect(RectRight)/35)/2);  
    
    accel_x_all = [];
    accel_y_all = [];
    accel_z_all = [];
    x_mouse_all = [];
    accel_filt = [];
    
    % Filtro
    Wn= 40/120; % 10 hertz filter here.
    [BB,A] = butter(2,Wn); % filter order
    %Force=filtfilt(BB,A,RHO); % Filtered signal output
    
    time_trial = 0;
    end_animation = 0;
    end_animation_on = 0;
    i = 0;
    
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%%%%%%%%%%%%%%%%%% Animação %%%%%%%%%%%%%%%%%%%%%%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    while end_animation < 1; %o ajuste de tempo pode ser feito no valor de animatio_on, abaixo
      
        end_animation = end_animation + end_animation_on;
       
        %accel_x = dlmread(myu3_path_x);
        %accel_y = dlmread(myu3_path_y);
        accel_z = dlmread(myu3_path_z);
        
        %accel_x_all = [accel_x_all; accel_x];
        %accel_y_all = [accel_y_all; accel_y];
        accel_z_all = [accel_z_all; accel_z];
        
        % Conta as iterações para o if abaixo
        i = i + 1;
        
        if i > 10 % Para que haja posições de mouse a serem consideradas
            
            accel_filt = filtfilt(BB, A, accel_z_all);
            %x_mouse = (x_mouse_ini - (accel_filt(i) * 2000) + 2500); % último valor é o ganho
            %x_mouse_all = [x_mouse_all; x_mouse];
            
            if min(accel_filt) > 1.4
                
                Screen('FillOval', wPtr, green, [x_mouse_ini y_mouse_ini (x_mouse_ini + cursor_horiz) (y_mouse_ini + cursor_vert)]);
            
            else
            
            	%Screen('FillOval', wPtr, red, [x_mouse_ini y_mouse_ini (x_mouse_ini + cursor_horiz) (y_mouse_ini + cursor_vert)]);
				end_animation_on = (monitorFlipInterval)/2;
            
            end
            
        end
        
        % Desenha a linha alvo. A posição é dada por pos_horiz_linha
        Screen('DrawLine', wPtr, white, pos_horiz_linha, rect(RectBottom), pos_horiz_linha, rect(RectTop), largura_linha_alvo);
                
        
        Screen('Flip', wPtr);
    end
    

    
    % Para a conversão entre escalas
    
    % Accel_max = 1.54
    % Accel_min = 0.6
    
    % Monitor_max = rect(RectRight)
    % Monitor_min = rect(RectLeft)
 
 
 
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%%%%%%%%%%%%%%%%%% Feedback %%%%%%%%%%%%%%%%%%%%%%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    
    accel2screen = round(((min(accel_filt) - 0) * rect(RectRight)) / 1.55);
    
    % No teste de transferência não será exibido feedback visual
    if pratica == 'trl' || pratica == 'try'
		
		Screen('TextFont',wPtr, 'Ubuntu');
        Screen('TextSize',wPtr, 30);
        Screen('DrawText', wPtr, 'Pressione qualquer tecla para continuar', rect(RectRight)/1.8, rect(RectBottom)/4, [255, 255, 255]);
		
	% Caso a prática liv ou yok, apresentar feedback visual	
	else
    
        
		if accel2screen < 0 % Caso passe do limite da tela, mostra o feedback "Fora"
			
			Screen('TextFont',wPtr, 'Ubuntu');
			Screen('TextSize',wPtr, 30);
			Screen('DrawText', wPtr, 'Fora', rect(RectRight)/4.6, rect(RectBottom)/2.5, [255, 255, 255]);
			Screen('DrawText', wPtr, 'Pressione qualquer tecla para continuar', rect(RectRight)/1.8, rect(RectBottom)/4, [255, 255, 255]);

			
		elseif accel2screen > 0 % Caso esteja no limite da tela, apresenta a posição da bola em relação à linha
			
			Screen('TextFont',wPtr, 'Ubuntu');
			Screen('TextSize',wPtr, 30);
			
			texto_feedback_numerico = num2str(pos_horiz_linha - (accel2screen + (cursor_horiz / 2)));
			
		   
			%Screen('FillOval', wPtr, red, [accel2screen rect(RectBottom) (accel2screen + cursor_horiz) (rect(RectBottom) + cursor_vert)]);
			Screen('FillOval', wPtr, red, [accel2screen y_mouse_ini (accel2screen + cursor_horiz) (y_mouse_ini + cursor_vert)]);
			Screen('DrawLine', wPtr, white, pos_horiz_linha, rect(RectBottom), pos_horiz_linha, rect(RectTop), largura_linha_alvo);
			%Screen('DrawText', wPtr, texto_feedback_numerico, rect(RectRight)/4.6, rect(RectBottom)/2.5, [255, 255, 255]); % Apresenta o feedback numérico (em pixels)
			Screen('DrawText', wPtr, 'Pressione qualquer tecla para continuar', rect(RectRight)/1.8, rect(RectBottom)/4, [255, 255, 255]);
				  
		end
	
	end
	  
	Screen('Flip', wPtr);
		
    % Mede o tempo em que o sujeito passou olhando o feedback
    time_feedback_ini = GetSecs;
    keyIsDown = 0;
    
    while keyIsDown == 0
        [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
		time_feedback_end = GetSecs; % Valores sao sobrescritos e o ultimo tempo registrado corresponde ao acionamento do mouse
    end
        
    time_feedback = time_feedback_end - time_feedback_ini(1);
	% time_feedback nas tentativas de transferência/retenção é o tempo para iniciar a pŕoxima tentativa
    
    
    
    
    % Meio da bolinha = (accel2screen + (cursor_horiz / 2))
    % Para tratar os dados, o erro é calculado: pos_horiz_linha - (accel2screen + (cursor_horiz / 2))
        
    % Registro da posicao no eixo x, do meio da bolinha, nas tentativas de prática
    desemp = (accel2screen + (cursor_horiz / 2));
    tamanho_tela_em_pixels = rect(RectRight); % Para o calculo do desempenho em cm, caso necessario
    tamanho_tela_em_cm = 47.4; % Para o calculo do desempenho em cm, caso necessario

    dados_sj = [str2num(escolha) desemp pos_horiz_linha tamanho_tela_em_pixels tamanho_tela_em_cm time_escolha time_feedback];
    
    
    cd(experimento); % Muda para a pasta do experimento sendo conduzido
    
    dlmwrite(txt_name, dados_sj, 'delimiter', '\t', '-append');
    
    cd(script_path); % Retorna para a pasta onde esta o script
    
    WaitSecs(0.2); % Evita que a tecla esteja pressionada no incio da proxima tentativa
    
    
    
    
    
    
    
	% Para teste
	dados_all = [dados_all; dados_sj];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% fecha o loop de tentativas %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% agradecimento %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
WaitSecs(0.5);
Screen('TextSize',wPtr, 40);
Screen('DrawText', wPtr, 'OBRIGADO!', 300, 300, [255, 255, 255]);
Screen('Flip', wPtr);
[end_experiment_time, keyCode, deltaSecs] = KbWait;


% Set priority to normal level
ShowCursor;
Screen('CloseAll');



% 28/04/2016
% Checar yoked e recuperação de ntt

% 23/03/2016
% Foi acrescentada a possibilidade de realizar um teste de transferência/retenção
% Sem o fornecimento de feedback visual ao participante.
% Configurações: pratica = 'trl' resulta no teste de transferência para o grupo autocontrolado (liv).
% Configurações: pratica = 'try' resulta no teste de transferência para o grupo yoked (yok).
% Nos dados armazenados, o "tempo observando o feedback" é na verdade o tempo
% Que o participante leva para iniciar a próxima tentativa de prática
% (pressionar a tecla que levará à próxima tentativa).
% Esse dado pode indicar o processamento de informações sensoriais (feedback intrínseco).

% Um linha com escolha = 0 (e os demais dados iguais a zero, exceto valores fixos) é colocada no final
% Da fase de aquisição para permitir localizar a última tentativa de cada participante,
% Tendo em vista que a quantidade de prática é autocontrolada.















