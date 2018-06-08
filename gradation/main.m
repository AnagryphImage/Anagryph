clear all;
head; % ヘッダファイルの読み込み（設定値）

%% 画像読み込み
disp('原画像を選択してください．');
filename = uigetfile('*');
ORG = imread(filename);
imagesc(ORG);
axis image; xlabel('x'); ylabel('y');
disp('原画像を表示しました．');
pause;

%% 顔認識
bodyDetector = vision.CascadeObjectDetector('FrontalFaceCART');
bodyDetector.MinSize = [MIN_FACE MIN_FACE];
bodyDetector.MergeThreshold = SENSITIVITY;
bboxBody = step(bodyDetector, ORG);
IBody = insertObjectAnnotation(ORG, 'rectangle',bboxBody,'Upper Body');
imagesc(IBody); axis image;

N = size(bboxBody,1);
disp(strcat(num2str(N),'名の顔が見つかりました．'));

for i=1:N % 顔面積算出とソーティング
    bboxBody(i,5) = bboxBody(i,3)*bboxBody(i,4);
end
bboxBody = sortrows(bboxBody,5);
bboxBody = flipud(bboxBody);


disp('誤検出をクリックしてください．終了は枠外（左側）をクリック．');
while(1)
    p = ginput(1);
    if(p(1)<0 | p(2)<0 ) break; end
    j=0;
    for i=1:size(bboxBody,1)
        if(bboxBody(i,1)<p(1) & bboxBody(i,2)<p(2) & ...
                bboxBody(i,1)+bboxBody(i,3)>p(1) & ...
                bboxBody(i,2)+bboxBody(i,4)>p(2))
            j=i;
        end
    end
    if(j>0)
        bboxBody(j,:) = [];
    end
end

N = size(bboxBody,1);
for i=1:N % 顔サイズの登録
    F(i) = bboxBody(i,5);
end

disp('倍率を表示します．（最背人物を1としたときの）');
M = F/F(N)
disp('深度を表示します．');
D = 255./M

bboxBody(:,5)= [];
IBody = insertObjectAnnotation(ORG, 'rectangle',bboxBody,'Upper Body');
imagesc(IBody); axis image;
pause;

%% 領域画像の取得
ORG = imread(filename); % 原画像の再読み込み
IMGS = zeros(size(ORG,1),size(ORG,2),N-1);
for i=1:N
    IMG = imcrop(ORG,bboxBody(i,1:4));
    imagesc(IMG);
    axis image; xlabel('x'); ylabel('y');
    q = input('表示されているメンバーの領域画像を作成しますか？はい1，いいえ0：');
    if(q==1)
        clipping;
    end
    disp('人物領域画像を指定してください．');
    filename = uigetfile('*');
    IMG_a = imread(filename); % 被写体1の読み込み
    IMGS(:,:,i) = IMG_a(:,:)>128;
    
    [H,L]=size(ORG) % 画像の縦幅取得
    L=length(ORG)   % 画像の横幅取得
    
    for j=H:-1:1    % それぞれの人物領域の足元を検出
        A=IMG_a(j,:);
        
        if all(A<200)
        else % 配列要素が255の場合，行を取得し繰り返しを終了
            F(i)=j
            break
        end
    end
end


%% 深度の算出
IMG_b = IMGS(:,:,N-1)*D(N-1);
for i=N-2:-1:1
    IMG_b = IMG_b + (IMG_b==0 & IMGS(:,:,i))*D(i);
end
IMG_b = IMG_b + (IMG_b==0)*255; % 背景の深度は255

disp('人物の深度画像を表示しました．');
imagesc(IMG_b); colormap(gray); colorbar;
axis image; xlabel('x'); ylabel('y');
pause;


%% 地面領域の取得
imshow(ORG)
disp('地面の領域画像を作成します．');
Horizon;

disp('地面領域画像を指定してください．');
filename = uigetfile('*');
IMG_g = imread(filename); % 地面領域の読み込み

for j=1:1:H % 水平線を検出
    B=IMG_g(j,:);
    
    if all(B<200)==1;
    else
        Ho=j; % 配列要素が255の場合，行を取得し繰り返しを終了
        break
    end
end

W=H-Ho;    % 画像下端から水平線までの列数

T=255/W;

for l=1:1:N+1 % 被写体間の列数取得
    if l==1 % 画像下端から最前人物
        Di(l)=H-F(l);
    elseif l==N+1   % 最背人物から水平線
        Di(l)=F(l-1)-Ho;
    else % 人物間
        Di(l)=F(l-1)-F(l);
    end
end

C=0;
for k=1:1:N % 被写体の深度値変更
    D(k)=Di(k)*T+C;
    C=D(k);
end

IMG_c = IMGS(:,:,N-1)*D(N-1);
for i=N:-1:1
    IMG_c = IMG_c + (IMG_c==0 & IMGS(:,:,i))*D(i);
end
IMG_c = IMG_c + (IMG_c==0)*255; % 背景の深度は255

disp('変更後の人物深度画像を表示しました．深度画像を保存します．');
imagesc(IMG_c); colormap(gray); colorbar;
axis image; xlabel('x'); ylabel('y');
pause;

% imwrite(uint8(IMG_c),'depth.jpg'); % 画像の保存


%% ノイズ除去 被写体二値化画像で白画素が重なる部分を除去
for a=1:N
    if a==1
        IMG0=IMGS(:,:,a);
    else
        IMG0 = IMG0+IMGS(:,:,a); % 被写体二値化画像の総和
    end
end

IMG_g = xor(IMG0,IMG_g);
for i=1:1:Ho
    B=IMG_g(i,:);
    if all(B>=0)==1;
        IMG_g(i,:)=0;
    else
    end
end

imshow(IMG_g);
pause;


%% 地面深度
% 移動量
for w=1:1:N
    mv(w)= fix(MV_MAX*(255-D(N+1-w))/255);
end

for m=N+1:-1:1
    if m==1 %画像下端から最前
        D1=D(m)/Di(m);  % 画素毎の移動
        D2=D1;
        
        for o=F(m)-1:1:H
            B=IMG_c(o,:);
            if all(B<255)==1;
            else
                B2=IMG_c(o,1:L)==255;
                B3=find(B2==1);
                N2=numel(B3);
                for z=1:1:N2
                    IMG_c(o,B3(z))=D2;
                end
            end
            J=o-F(m);
            D2=D(m)-(D1*J);
        end
    elseif m==N+1 %水平線から最背
        D1=(255-D(m-1))/Di(m);
        D2=D1;
        for o=Ho+1:1:F(m-1)
            B=IMG_c(o,:);
            if all(B<255)==1;
            else
                B2=IMG_c(o,1:L)==255;
                B3=find(B2==1);
                N2=numel(B3);
                for z=1:1:N2
                    IMG_c(o,B3(z))=D2;
                end
            end
            J=o-Ho;
            D2=255-(D1*J);
        end
    else %その他人物間
        D1=(D(m)-D(m-1))/Di(m);
        D2=D1;
        for o=F(m):1:F(m-1)-1
            B=IMG_c(o,:);
            if all(B<255)==1;
            else
                B2=IMG_c(o,1:L)==255;
                B3=find(B2==1);
                N2=numel(B3);
                for z=1:1:N2
                    IMG_c(o,B3(z))=D2;
                end
            end
            J=o-F(m);
            D2=D(m)-(D1*J);
        end
    end
end

disp('深度画像を表示しました．深度画像を保存します．');
imagesc(IMG_c); colormap(gray); colorbar;
axis image; xlabel('x'); ylabel('y');
pause;

imwrite(uint8(IMG_c),'depth.jpg'); % 画像の保存


%% 左眼用画像生成
CLPS = zeros(size(ORG,1),size(ORG,2),(N-1)*3);
MSKS = zeros(size(ORG,1),size(ORG,2),N-1);
for i=1:N-1
    mv_x = fix(MV_MAX*(255-D(i))/255);
    IMG_c = ORG;
    IMG_c(:,:,1) = IMGS(:,:,i); IMG_c(:,:,2) = IMGS(:,:,i); IMG_c(:,:,3) = IMGS(:,:,i);
    IMG_c = IMG_c.*ORG;
    IMG_c = imtranslate(IMG_c,[mv_x, 0]);
    CLPS(:,:,(i-1)*3+1) = IMG_c(:,:,1);
    CLPS(:,:,(i-1)*3+2) = IMG_c(:,:,2);
    CLPS(:,:,(i-1)*3+3) = IMG_c(:,:,3);
    MSKS(:,:,i) = imtranslate(IMGS(:,:,i),[mv_x, 0]);
end

IMG1 = IMG_g(:,:,1)==1;

IMG_L = ORG;
IMG_L(:,:,1) = IMG1; IMG_L(:,:,2) = IMG1; IMG_L(:,:,3) = IMG1;
IMG_L = IMG_L.*ORG;

IMG_BL1=IMG_L;
MSK01=IMG1;
IMG_BL2=imcrop(IMG_L,[1 1 L Ho-1]);
MSK01=imcrop(IMG1,[1 1 L Ho-1]);

% 移動量
for w=1:1:N
    mv(w)= fix(MV_MAX*(255-D(N+1-w))/255);
end

for m=N+1:-1:1
    if m==1 %画像下端から最前
        S1=(MV_MAX-mv(N+1-m))/Di(m);  % 画素毎の移動
        SS=fix(mv_xx+S1);
        
        for o=F(m)+1:1:H
            E=imcrop(IMG_L,[1 o L 0]);
            E2=imcrop(IMG1,[1 o L 0]);
            E=imtranslate(E,[SS,0]);   %配列をずらす
            E2=imtranslate(E2,[SS,0]);   %配列をずらす
            IMG_BL2=vertcat(IMG_BL2,E);
            MSK01=vertcat(MSK01,E2);
            
            J=o-F(m);
            SS=mv_xx+S1*J;
            SS=fix(SS);
        end
    elseif m==N+1 %水平線から最背
        S1=mv(1)/Di(m);
        SS=fix(S1);
        for o=Ho+1:1:F(m-1)
            E=imcrop(IMG_L,[1 o L 0]);
            E2=imcrop(IMG1,[1 o L 0]);
            E=imtranslate(E,[SS,0]);   %配列をずらす
            E2=imtranslate(E2,[SS,0]);   %配列をずらす
            IMG_BL2=vertcat(IMG_BL2,E);
            MSK01=vertcat(MSK01,E2);
            J=o-Ho;
            SS=S1*J;
            SS=fix(SS);
        end
        mv_xx=mv(1);
    else %その他人物間
        S1=(mv(N+1-m+1)-mv(N+1-m))/Di(m);
        SS=fix(mv_xx+S1);
        for o=F(m)+1:1:F(m-1)
            E=imcrop(IMG_L,[1 o L 0]);
            E2=imcrop(IMG1,[1 o L 0]);
            E=imtranslate(E,[SS,0]);   %配列をずらす
            E2=imtranslate(E2,[SS,0]);   %配列をずらす
            IMG_BL2=vertcat(IMG_BL2,E);
            MSK01=vertcat(MSK01,E2);
            J=o-F(m);
            SS=mv_xx+S1*J;
            SS=fix(SS);
        end
        mv_xx=mv(N+1-m+1);
    end
end

ORG_BL = ORG;
MSK = (IMG1+MSK01)==0; % 移動前後のマスクを総和，領域以外の領域抽出（注）
IMG_L(:,:,1) = MSK; IMG_L(:,:,2) = MSK; IMG_L(:,:,3) = MSK; % カラー画像化
IMG_BL = IMG_L.*ORG_BL+IMG_BL2; % 領域以外の領域（注）と移動後の領域を連結


%% 画像の合成
ORG1 = IMG_BL;
CLP = ORG;
for i=N-1:-1:1
    CLP(:,:,1) = CLPS(:,:,(i-1)*3+1);
    CLP(:,:,2) = CLPS(:,:,(i-1)*3+2);
    CLP(:,:,3) = CLPS(:,:,(i-1)*3+3);
    MSK = (IMGS(:,:,i)+MSKS(:,:,i))==0;
    IMG_c(:,:,1) = MSK; IMG_c(:,:,2) = MSK; IMG_c(:,:,3) = MSK;
    ORG1 = IMG_c.*ORG1+CLP;
end

disp('左眼画像を表示しました．');
imagesc(ORG1);
axis image; xlabel('x'); ylabel('y');
pause;

IMG_L = ORG1;
imwrite(IMG_L,'left.png'); % 画像の保存


%% 右眼用画像生成
CLPS = zeros(size(ORG,1),size(ORG,2),(N-1)*3);
MSKS = zeros(size(ORG,1),size(ORG,2),N-1);
for i=1:N-1
    mv_x = fix(MV_MAX*(255-D(i))/255);
    IMG_c = ORG;
    IMG_c(:,:,1) = IMGS(:,:,i); IMG_c(:,:,2) = IMGS(:,:,i); IMG_c(:,:,3) = IMGS(:,:,i);
    IMG_c = IMG_c.*ORG;
    IMG_c = imtranslate(IMG_c,[-mv_x, 0]);
    CLPS(:,:,(i-1)*3+1) = IMG_c(:,:,1);
    CLPS(:,:,(i-1)*3+2) = IMG_c(:,:,2);
    CLPS(:,:,(i-1)*3+3) = IMG_c(:,:,3);
    MSKS(:,:,i) = imtranslate(IMGS(:,:,i),[-mv_x, 0]);
end

IMG2 = IMG_g(:,:,1)==1;

IMG_R = ORG;
IMG_R(:,:,1) = IMG2; IMG_R(:,:,2) = IMG2; IMG_R(:,:,3) = IMG2;
IMG_R = IMG_R.*ORG;

IMG_BR2=IMG_R;
MSK02=IMG2;
IMG_BR2=imcrop(IMG_R,[1 1 L Ho-1]);
MSK02=imcrop(IMG2,[1 1 L Ho-1]);

% 移動量
for w=1:1:N
    mv(w)= fix(MV_MAX*(255-D(N+1-w))/255);
end

for m=N+1:-1:1
    if m==1 %画像下端から最前
        S1=(MV_MAX-mv(N+1-m))/Di(m);  % 画素毎の移動
        SS=fix(mv_xx+S1);
        
        for o=F(m)+1:1:H
            E=imcrop(IMG_R,[1 o L 0]);
            E2=imcrop(IMG2,[1 o L 0]);
            E=imtranslate(E,[-SS,0]);   %配列をずらす
            E2=imtranslate(E2,[-SS,0]);   %配列をずらす
            IMG_BR2=vertcat(IMG_BR2,E);
            MSK02=vertcat(MSK02,E2);
            
            J=o-F(m);
            SS=mv_xx+S1*J;
            SS=fix(SS);
        end
    elseif m==N+1 %水平線から最背
        S1=mv(1)/Di(m);
        SS=fix(S1);
        for o=Ho+1:1:F(m-1)
            E=imcrop(IMG_R,[1 o L 0]);
            E2=imcrop(IMG2,[1 o L 0]);
            E=imtranslate(E,[-SS,0]);   %配列をずらす
            E2=imtranslate(E2,[-SS,0]);   %配列をずらす
            IMG_BR2=vertcat(IMG_BR2,E);
            MSK02=vertcat(MSK02,E2);
            J=o-Ho;
            SS=S1*J;
            SS=fix(SS);
        end
        mv_xx=mv(1);
    else %その他人物間
        S1=(mv(N+1-m+1)-mv(N+1-m))/Di(m);
        SS=fix(mv_xx+S1);
        for o=F(m)+1:1:F(m-1)
            E=imcrop(IMG_R,[1 o L 0]);
            E2=imcrop(IMG2,[1 o L 0]);
            E=imtranslate(E,[-SS,0]);   %配列をずらす
            E2=imtranslate(E2,[-SS,0]);   %配列をずらす
            IMG_BR2=vertcat(IMG_BR2,E);
            MSK02=vertcat(MSK02,E2);
            J=o-F(m);
            SS=mv_xx+S1*J;
            SS=fix(SS);
        end
        mv_xx=mv(N+1-m+1);
    end
end

ORG_BR = ORG;
MSK = (IMG2+MSK02)==0; % 移動前後のマスクを総和，領域以外の領域抽出（注）
IMG_R(:,:,1) = MSK; IMG_R(:,:,2) = MSK; IMG_R(:,:,3) = MSK; % カラー画像化
IMG_BR = IMG_R.*ORG_BR+IMG_BR2; % 領域以外の領域（注）と移動後の領域を連結


%% 画像の合成
ORG3 = IMG_BR;
CLP = ORG;
for i=N-1:-1:1
    CLP(:,:,1) = CLPS(:,:,(i-1)*3+1);
    CLP(:,:,2) = CLPS(:,:,(i-1)*3+2);
    CLP(:,:,3) = CLPS(:,:,(i-1)*3+3);
    MSK = (IMGS(:,:,i)+MSKS(:,:,i))==0;
    IMG_c(:,:,1) = MSK; IMG_c(:,:,2) = MSK; IMG_c(:,:,3) = MSK;
    ORG3 = IMG_c.*ORG3+CLP;
end

disp('左眼画像を表示しました．');
imagesc(ORG3);
axis image; xlabel('x'); ylabel('y');
pause;

IMG_R = ORG3;
imwrite(IMG_R,'right.png'); % 画像の保存


%% アナグリフ画像の生成
IMG_e = stereoAnaglyph(IMG_L, IMG_R);
imwrite(IMG_e,'anaglyph.png'); % 画像の保存
disp('アナグリフ画像を表示しました．');
imagesc(IMG_e);
axis image; xlabel('x'); ylabel('y');
