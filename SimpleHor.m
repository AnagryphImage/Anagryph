disp('原画像を選択してください．');
filename = uigetfile('*');
ORG = imread(filename);
imagesc(ORG);
axis image; xlabel('x'); ylabel('y');
disp('原画像を表示しました．');

disp('地平線をクリックしてください．')
[M,MyHeight] = ginput(1);  % クリックポイントのy座標を取得
MyHeight=round(MyHeight); % 配列は正の整数なので丸め込み MyHeight:= 水平線位置(height,px)

[H,L]=size(ORG) % 画像の縦幅取得

L=length(ORG)   % 画像の横幅取得
hold on, plot([0 L],[MyHeight MyHeight],'b')
disp('地平線を設定しました．')

G=zeros(H,L);   % ORGと同じサイズの零行列を生成

%grad = 1;
for i=H:-1:1 %画像上端から下端まで縦のサイズを-1ずつ下げて行く
    %B=G(i,:);
    if find(i <= MyHeight)
        G(i,:)=255;
    else G(I,:)=0;
        %G(i,:)=grad;
        %if (grad < 128)
        %    grad = grad +1; 
        %end
        %G(i,:) = convDepth(i,MyHeight);
    end
end
pause;
disp('変更後の人物深度画像を表示しました．深度画像を保存します．');
imagesc(G); colormap(gray); colorbar;
axis image; xlabel('x'); ylabel('y');
pause;
imwrite(uint8(G),'place.png');% 画像の保存
