%�摜�ǂݍ���
 ORG = imread('*');
 imagesc(ORG);
 
%��F���{�b�N�X�ݒu�@Figure(b)
bodyDetector = vision.CascadeObjectDetector('UpperBody');
   bodyDetector.MinSize = [90 90];
   bodyDetector.MergeThreshold = 6;
   bboxBody = step(bodyDetector, ORG);
   IBody = insertObjectAnnotation(ORG, 'rectangle',bboxBody,'Upper Body');
   figure, imshow(IBody), title('Detected upper bodies');
  
%�㌟�obox���폜
disp('�댟�o���N���b�N���Ă��������D�I���͘g�O�i�����j���N���b�N�D');
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


%��F���{�b�N�X�s�񒊏o
n=6;
for k=1:n
a_k=bboxBody(k,1);
b_k=bboxBody(k,2);
c_k=bboxBody(k,3)+20;
d_k=bboxBody(k,4)+200;
bbb_koxBody=[a_k b_k c_k d_k];
I_kBody = insertObjectAnnotation(ORG, 'rectangle', bbb_koxBody, 'Face');
figure, imshow(I_kBody), title('Detected faces');
 
%�g���~���O��Ɓ@figure(c)
I2 = imcrop(ORG,bbb_koxBody);
imshow(I2);
 
%HSV�F��Ԃɕϊ�
RGB = I2;
HSV = rgb2hsv(RGB);
H=HSV(:,:,1); %HSV�F��Ԃ�H�̂ݒ���(3��������1�����ɕϊ�)
%imshow(H); 

%3�����ɖ߂�����S��V�̍s����s��Ƃ��ėp�ӂ���.
S=zeros(d_k+1,c_k+1,1); 
V=zeros(d_k+1,c_k+1,1); 
K=cat(3,H,S,V);
%MATLAB��k-means�@�𗘗p�ł���F��Ԃ�l*a*b��Ԃ̂���,
%��xHSV�F��Ԃ���RGB�F��Ԃɕϊ�����.
%imshow(K);

%�X�[�p�[�s�N�Z���̈�̕���
Ilab = rgb2lab(K); %l*a*b��Ԃɕϊ�
[Ls,N] = superpixels(Ilab,10);
%figure;
BW = boundarymask(Ls);
%figure(f)
%imshow(imoverlay(Ilab,BW,'r'),'InitialMagnification',50);
 
%�X�[�p�[�s�N�Z�����Ƃ̕��ϒl���Z�o
pixIdxList = label2idx(Ls);    % �e���x���̈�̍s��C���f�b�N�X���擾
sz = numel(Ls);                % ��f��
superLab = zeros(N,3);
for  i = 1:N    
  superLab(i,1) = mean(Ilab(pixIdxList{i}      ));  % L* mean
  %superLab(i,2) = mean(Ilab(pixIdxList{i}+   sz));  % a* mean
  %superLab(i,3) = mean(Ilab(pixIdxList{i}+ 2*sz));  % b* mean
end
I3= label2rgb(Ls, lab2rgb(superLab));
 
%figure; % figure(g)
%imshowpair(I2, imoverlay(I3, boundarymask(Ls),'r'), 'montage'); %Figure4
 
%K-means�ŐF�̗ގ��x��p�����N���X�^�����O
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
 
%�Ώە����݂̂𒊏o
maskA = (Lc == 1);
maskA_filled = imfill(maskA, 'holes');       % �}�X�N�̌��𖄂߂�
Iout = imoverlay(I4b, maskA_filled, 'r');
 
figure; 
%�}�X�N�摜�쐬
imshow(Iout); 
I5=imshowpair(I4b,I2);

pause;

R = zeros(size(I5,1),size(I5,2));
while(1)
    disp('�X�[�p�s�N�Z�����N���b�N���Ă��������D�I���͘g�O�i�����j���N���b�N�D');
    p = ginput(1);
    p = fix(p);
    if(p(1)<0 || p(2)<0 ) break; end
    pp = Ls(p(2),p(1));
    TMP = (Ls==Ls(p(2),p(1)));
    
    TMP0 = R & TMP; % �C���p�����i�Q��I���ŃL�����Z���j
    idx = label2idx(uint8(TMP0));
    if(size(idx,2)~=0)
        R = R & (TMP0==0);
    else
        R = R|TMP;
    end
    
    imagesc(R); axis image; colormap(gray); colorbar;
    disp('������x�C�ǂ������N���b�N���Ă��������D');
    p = ginput(1);
    imagesc(I4); axis image; colorbar;

end

disp('�ۑ�����w�肵�Ă��������D');
filename = uiputfile('*');
imagesc(R);
imwrite(R*255,filename);
end