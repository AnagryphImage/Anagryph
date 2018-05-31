clear all;
head; % ヘッダファイルの読み込み（設定値）

%% 画像読み込み
disp('原画像を選択してください．');
filename = uigetfile('*');
ORG = imread(filename);
imagesc(ORG);
axis image; xlabel('x'); ylabel('y');
disp('原画像を表示しました．');

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
    
    [H,L]=size(ORG) % 画像の縦幅取得0
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

imshow(ORG)
%{
disp('地面の領域画像を作成します．');
DetectHor;
%}
disp('地面領域画像を指定してください．');
filename = uigetfile('*');
IMG_g = imread(filename); % 地面領域の読み込み

for j=1:1:H % 水平線を検出
    B=IMG_g(j,:);
    
    if all(B<200)
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
%被写体の深度値が変化して、5人分の正確な深度値が分かる部分。(2018/5/28)
for k=1:1:N % 被写体の深度値変更
    D(k)=Di(k)*T+C;
    C=D(k);
end
%{
disp('地面領域画像を指定してください．');
filename = uigetfile('*');
IMG_h = imread(filename); % 地面領域の読み込み
%}
IMG_h=im2double(IMG_g);


%どうやって背景を貼り付けるんだろう、、、


IMG_c = IMGS(:,:,N-1)*D(N-1);

for i=N:-1:1
    IMG_c = IMG_c + IMG_h+(IMG_c==0 & IMGS(:,:,i))*D(i);
end

IMG_c = IMG_c +IMG_h+(IMG_c==256 & IMGS(:,:,i))*D(i); % 背景の深度は255
disp('変更後の人物深度画像を表示しました．深度画像を保存します．');
imagesc(IMG_c); colormap(gray); colorbar;
axis image; xlabel('x'); ylabel('y');
pause;
imwrite(uint8(IMG_c),'de.jpg');
%{
%対数変換により深度マップ作成(地面のグラデーションができたら削除)
IMG_d=log(IMG_c)
disp('変更後の人物深度画像を表示しました．深度画像を保存します．');
imagesc(IMG_d); colormap(gray); colorbar;
axis image; xlabel('x'); ylabel('y');
pause;

imwrite(uint8(IMG_d),'dep.jpg'); % 画像の保存
%}



% %% 左眼用画像生成
% CLPS = zeros(size(ORG,1),size(ORG,2),(N-1)*3);
% MSKS = zeros(size(ORG,1),size(ORG,2),N-1);
% for i=1:N-1
%     mv_x = fix(MV_MAX*(255-D(i))/255);
%     IMG_c = ORG;
%     IMG_c(:,:,1) = IMGS(:,:,i); IMG_c(:,:,2) = IMGS(:,:,i); IMG_c(:,:,3) = IMGS(:,:,i);
%     IMG_c = IMG_c.*ORG;
%     IMG_c = imtranslate(IMG_c,[mv_x, 0]);
%     CLPS(:,:,(i-1)*3+1) = IMG_c(:,:,1);
%     CLPS(:,:,(i-1)*3+2) = IMG_c(:,:,2);
%     CLPS(:,:,(i-1)*3+3) = IMG_c(:,:,3);
%     MSKS(:,:,i) = imtranslate(IMGS(:,:,i),[mv_x, 0]);
% end
%
% % 画像の合成
% ORG2 = ORG;
% CLP = ORG;
% for i=N-1:-1:1
%     CLP(:,:,1) = CLPS(:,:,(i-1)*3+1);
%     CLP(:,:,2) = CLPS(:,:,(i-1)*3+2);
%     CLP(:,:,3) = CLPS(:,:,(i-1)*3+3);
%     MSK = (IMGS(:,:,i)+MSKS(:,:,i))==0;
%     IMG_c(:,:,1) = MSK; IMG_c(:,:,2) = MSK; IMG_c(:,:,3) = MSK;
%     ORG2 = IMG_c.*ORG2+CLP;
% end
% disp('左眼画像を表示しました．');
% imagesc(ORG2);
% axis image; xlabel('x'); ylabel('y');
% pause;
%
% IMG_L = ORG2;
% imwrite(IMG_L,'left.png'); % 画像の保存
%
% %% 右眼用画像生成
% CLPS = zeros(size(ORG,1),size(ORG,2),(N-1)*3);
% MSKS = zeros(size(ORG,1),size(ORG,2),N-1);
% for i=1:N-1
%     mv_x = fix(MV_MAX*(255-D(1))/255)*-1;
%     IMG_d = ORG;
%     IMG_d(:,:,1) = IMGS(:,:,i); IMG_d(:,:,2) = IMGS(:,:,i); IMG_d(:,:,3) = IMGS(:,:,i);
%     IMG_d = IMG_d.*ORG;
%     IMG_d = imtranslate(IMG_d,[mv_x, 0]);
%     CLPS(:,:,(i-1)*3+1) = IMG_d(:,:,1);
%     CLPS(:,:,(i-1)*3+2) = IMG_d(:,:,2);
%     CLPS(:,:,(i-1)*3+3) = IMG_d(:,:,3);
%     MSKS(:,:,i) = imtranslate(IMGS(:,:,i),[mv_x, 0]);
% end
%
% % 画像の合成
% ORG2 = ORG;
% CLP = ORG;
% for i=N-1:-1:1
%     CLP(:,:,1) = CLPS(:,:,(i-1)*3+1);
%     CLP(:,:,2) = CLPS(:,:,(i-1)*3+2);
%     CLP(:,:,3) = CLPS(:,:,(i-1)*3+3);
%     MSK = (IMGS(:,:,i)+MSKS(:,:,i))==0;
%     IMG_d(:,:,1) = MSK; IMG_d(:,:,2) = MSK; IMG_d(:,:,3) = MSK;
%     ORG2 = IMG_d.*ORG2+CLP;
% end
% disp('右眼画像を表示しました．');
% imagesc(ORG2);
% axis image; xlabel('x'); ylabel('y');
% pause;
%
% IMG_R = ORG2;
% imwrite(IMG_R,'right.png'); % 画像の保存
%
% %% アナグリフ画像の生成
% IMG_e = stereoAnaglyph(IMG_L, IMG_R);
% imwrite(IMG_e,'anaglyph.png'); % 画像の保存
% disp('アナグリフ画像を表示しました．');
% imagesc(IMG_e);
% axis image; xlabel('x'); ylabel('y');
