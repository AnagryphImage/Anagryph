%画像読み込み
 ORG = imread('*');
 imagesc(ORG);
 
%顔認識ボックス設置　Figure(b)
bodyDetector = vision.CascadeObjectDetector('UpperBody');
   bodyDetector.MinSize = [90 90];
   bodyDetector.MergeThreshold = 6;
   bboxBody = step(bodyDetector, ORG);
   IBody = insertObjectAnnotation(ORG, 'rectangle',bboxBody,'Upper Body');
   figure, imshow(IBody), title('Detected upper bodies');
  
%後検出boxを削除
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


%顔認識ボックス行列抽出
n=6;
for k=1:n
a_k=bboxBody(k,1);
b_k=bboxBody(k,2);
c_k=bboxBody(k,3)+20;
d_k=bboxBody(k,4)+200;
bbb_koxBody=[a_k b_k c_k d_k];
I_kBody = insertObjectAnnotation(ORG, 'rectangle', bbb_koxBody, 'Face');
figure, imshow(I_kBody), title('Detected faces');
 
%トリミング作業　figure(c)
I2 = imcrop(ORG,bbb_koxBody);
imshow(I2);
 
%HSV色空間に変換
RGB = I2;
HSV = rgb2hsv(RGB);
H=HSV(:,:,1); %HSV色空間のHのみ注目(3次元から1次元に変換)
%imshow(H); 

%3次元に戻すためSとVの行列を零行列として用意する.
S=zeros(d_k+1,c_k+1,1); 
V=zeros(d_k+1,c_k+1,1); 
K=cat(3,H,S,V);
%MATLABでk-means法を利用できる色空間はl*a*b空間のため,
%一度HSV色空間からRGB色空間に変換する.
%imshow(K);

%スーパーピクセル領域の分類
Ilab = rgb2lab(K); %l*a*b空間に変換
[Ls,N] = superpixels(Ilab,10);
%figure;
BW = boundarymask(Ls);
%figure(f)
%imshow(imoverlay(Ilab,BW,'r'),'InitialMagnification',50);
 
%スーパーピクセルごとの平均値を算出
pixIdxList = label2idx(Ls);    % 各ラベル領域の行列インデックスを取得
sz = numel(Ls);                % 画素数
superLab = zeros(N,3);
for  i = 1:N    
  superLab(i,1) = mean(Ilab(pixIdxList{i}      ));  % L* mean
  %superLab(i,2) = mean(Ilab(pixIdxList{i}+   sz));  % a* mean
  %superLab(i,3) = mean(Ilab(pixIdxList{i}+ 2*sz));  % b* mean
end
I3= label2rgb(Ls, lab2rgb(superLab));
 
%figure; % figure(g)
%imshowpair(I2, imoverlay(I3, boundarymask(Ls),'r'), 'montage'); %Figure4
 
%K-meansで色の類似度を用いたクラスタリング
numColors = 6;       
[idx, cLab] = kmeans(superLab, numColors);
Lc = zeros(size(Ls));
for i = 1:N                        
    Lc(pixIdxList{i}) = idx(i);    
end
 
I4  = label2rgb(Lc, lab2rgb(cLab)); 
I4b = imoverlay(I4, boundarymask(Lc), 'r');      
%figure;
%imshow(I4b); colorbar
%figure(h)
 
%対象部分のみを抽出
maskA = (Lc == 1);
maskA_filled = imfill(maskA, 'holes');       % マスクの穴を埋める
Iout = imoverlay(I4b, maskA_filled, 'r');
 
figure; 
%マスク画像作成
imshow(Iout); 
I5=imshowpair(I4b,I2);

pause;

R = zeros(size(I5,1),size(I5,2));
while(1)
    disp('スーパピクセルをクリックしてください．終了は枠外（左側）をクリック．');
    p = ginput(1);
    p = fix(p);
    if(p(1)<0 || p(2)<0 ) break; end
    pp = Ls(p(2),p(1));
    TMP = (Ls==Ls(p(2),p(1)));
    
    TMP0 = R & TMP; % 修正用処理（２回選択でキャンセル）
    idx = label2idx(uint8(TMP0));
    if(size(idx,2)~=0)
        R = R & (TMP0==0);
    else
        R = R|TMP;
    end
    
    imagesc(R); axis image; colormap(gray); colorbar;
    disp('もう一度，どこかをクリックしてください．');
    p = ginput(1);
    imagesc(I4); axis image; colorbar;

end

disp('保存先を指定してください．');
filename = uiputfile('*');
imagesc(R);
imwrite(R*255,filename);
end