IMG_z = ORG;
%スーパーピクセルの生成
n = input('生成するスーパーピクセルの個数を入力してください（100以上の整数）:');
[L1,M] = superpixels(IMG_z,n);
BW = boundarymask(L1);
IMG_SP = imoverlay(IMG_z,BW,'cyan');
%imagesc(IMG_SP); axis image; colorbar;
%pause;

%IMG_SP = zeros(size(IMG),'like',IMG);
%idx = label2idx(L);
%numRows = size(IMG,1);
%numCols = size(IMG,2);
%for labelVal = 1:N
%    redIdx = idx{labelVal};
%    greenIdx = idx{labelVal}+numRows*numCols;
%    blueIdx = idx{labelVal}+2*numRows*numCols;
%    IMG_SP(redIdx) = median(IMG(redIdx));
%    IMG_SP(greenIdx) = median(IMG(greenIdx));
%    IMG_SP(blueIdx) = median(IMG(blueIdx));
%end

imagesc(IMG_SP); axis image; colorbar;
R = zeros(size(IMG_z,1),size(IMG_z,2));
while(1)
    disp('スーパピクセルをクリックしてください．終了は枠外（左側）をクリック．');
    p = ginput(1);
    p = fix(p);
    if(p(1)<0 | p(2)<0 ) break; end
    pp = L1(p(2),p(1));
    TMP = (L1==L1(p(2),p(1)));
    
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
    imagesc(IMG_SP); axis image; colorbar;
end

R = imfill(R,'holes');
imagesc(R);

disp('保存先を指定してください．');
filename = uiputfile('*');
imagesc(R);
imwrite(R*255,filename);

