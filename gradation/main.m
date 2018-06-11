clear all;
head; % �w�b�_�t�@�C���̓ǂݍ��݁i�ݒ�l�j

%% �摜�ǂݍ���
disp('���摜��I�����Ă��������D');
filename = uigetfile('*');
ORG = imread(filename);
imagesc(ORG);
axis image; xlabel('x'); ylabel('y');
disp('���摜��\�����܂����D');
pause;

%% ��F��
bodyDetector = vision.CascadeObjectDetector('FrontalFaceCART');
bodyDetector.MinSize = [MIN_FACE MIN_FACE];
bodyDetector.MergeThreshold = SENSITIVITY;
bboxBody = step(bodyDetector, ORG);
IBody = insertObjectAnnotation(ORG, 'rectangle',bboxBody,'Upper Body');
imagesc(IBody); axis image;

N = size(bboxBody,1);
disp(strcat(num2str(N),'���̊炪������܂����D'));

for i=1:N % ��ʐώZ�o�ƃ\�[�e�B���O
    bboxBody(i,5) = bboxBody(i,3)*bboxBody(i,4);
end
bboxBody = sortrows(bboxBody,5);
bboxBody = flipud(bboxBody);


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

N = size(bboxBody,1);
for i=1:N % ��T�C�Y�̓o�^
    F(i) = bboxBody(i,5);
end

disp('�{����\�����܂��D�i�Ŕw�l����1�Ƃ����Ƃ��́j');
M = F/F(N)
disp('�[�x��\�����܂��D');
D = 255./M

bboxBody(:,5)= [];
IBody = insertObjectAnnotation(ORG, 'rectangle',bboxBody,'Upper Body');
imagesc(IBody); axis image;
pause;

%% �̈�摜�̎擾
ORG = imread(filename); % ���摜�̍ēǂݍ���
IMGS = zeros(size(ORG,1),size(ORG,2),N-1);
for i=1:N
    IMG = imcrop(ORG,bboxBody(i,1:4));
    imagesc(IMG);
    axis image; xlabel('x'); ylabel('y');
    q = input('�\������Ă��郁���o�[�̗̈�摜���쐬���܂����H�͂�1�C������0�F');
    if(q==1)
        clipping;
    end
    disp('�l���̈�摜���w�肵�Ă��������D');
    filename = uigetfile('*');
    IMG_a = imread(filename); % ��ʑ�1�̓ǂݍ���
    IMGS(:,:,i) = IMG_a(:,:)>128;
    
    [H,L]=size(ORG) % �摜�̏c���擾
    L=length(ORG)   % �摜�̉����擾
    
    for j=H:-1:1    % ���ꂼ��̐l���̈�̑��������o
        A=IMG_a(j,:);
        
        if all(A<200)
        else % �z��v�f��255�̏ꍇ�C�s���擾���J��Ԃ����I��
            F(i)=j
            break
        end
    end
end


%% �[�x�̎Z�o
IMG_b = IMGS(:,:,N-1)*D(N-1);
for i=N-2:-1:1
    IMG_b = IMG_b + (IMG_b==0 & IMGS(:,:,i))*D(i);
end
IMG_b = IMG_b + (IMG_b==0)*255; % �w�i�̐[�x��255

disp('�l���̐[�x�摜��\�����܂����D');
imagesc(IMG_b); colormap(gray); colorbar;
axis image; xlabel('x'); ylabel('y');
pause;


%% �n�ʗ̈�̎擾
imshow(ORG)
disp('�n�ʂ̗̈�摜���쐬���܂��D');
Horizon;

disp('�n�ʗ̈�摜���w�肵�Ă��������D');
filename = uigetfile('*');
IMG_g = imread(filename); % �n�ʗ̈�̓ǂݍ���

for j=1:1:H % �����������o
    B=IMG_g(j,:);
    
    if all(B<200)==1;
    else
        Ho=j; % �z��v�f��255�̏ꍇ�C�s���擾���J��Ԃ����I��
        break
    end
end

W=H-Ho;    % �摜���[���琅�����܂ł̗�

T=255/W;

for l=1:1:N+1 % ��ʑ̊Ԃ̗񐔎擾
    if l==1 % �摜���[����őO�l��
        Di(l)=H-F(l);
    elseif l==N+1   % �Ŕw�l�����琅����
        Di(l)=F(l-1)-Ho;
    else % �l����
        Di(l)=F(l-1)-F(l);
    end
end

C=0;
for k=1:1:N % ��ʑ̂̐[�x�l�ύX
    D(k)=Di(k)*T+C;
    C=D(k);
end

IMG_c = IMGS(:,:,N-1)*D(N-1);
for i=N:-1:1
    IMG_c = IMG_c + (IMG_c==0 & IMGS(:,:,i))*D(i);
end
IMG_c = IMG_c + (IMG_c==0)*255; % �w�i�̐[�x��255

disp('�ύX��̐l���[�x�摜��\�����܂����D�[�x�摜��ۑ����܂��D');
imagesc(IMG_c); colormap(gray); colorbar;
axis image; xlabel('x'); ylabel('y');
pause;

% imwrite(uint8(IMG_c),'depth.jpg'); % �摜�̕ۑ�


%% �m�C�Y���� ��ʑ̓�l���摜�Ŕ���f���d�Ȃ镔��������
for a=1:N
    if a==1
        IMG0=IMGS(:,:,a);
    else
        IMG0 = IMG0+IMGS(:,:,a); % ��ʑ̓�l���摜�̑��a
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


%% �n�ʐ[�x
% �ړ���
for w=1:1:N
    mv(w)= fix(MV_MAX*(255-D(N+1-w))/255);
end

for m=N+1:-1:1
    if m==1 %�摜���[����őO
        D1=D(m)/Di(m);  % ��f���̈ړ�
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
    elseif m==N+1 %����������Ŕw
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
    else %���̑��l����
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

disp('�[�x�摜��\�����܂����D�[�x�摜��ۑ����܂��D');
imagesc(IMG_c); colormap(gray); colorbar;
axis image; xlabel('x'); ylabel('y');
pause;

imwrite(uint8(IMG_c),'depth.jpg'); % �摜�̕ۑ�


%% ����p�摜����
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

% �ړ���
for w=1:1:N
    mv(w)= fix(MV_MAX*(255-D(N+1-w))/255);
end

for m=N+1:-1:1
    if m==1 %�摜���[����őO
        S1=(MV_MAX-mv(N+1-m))/Di(m);  % ��f���̈ړ�
        SS=fix(mv_xx+S1);
        
        for o=F(m)+1:1:H
            E=imcrop(IMG_L,[1 o L 0]);
            E2=imcrop(IMG1,[1 o L 0]);
            E=imtranslate(E,[SS,0]);   %�z������炷
            E2=imtranslate(E2,[SS,0]);   %�z������炷
            IMG_BL2=vertcat(IMG_BL2,E);
            MSK01=vertcat(MSK01,E2);
            
            J=o-F(m);
            SS=mv_xx+S1*J;
            SS=fix(SS);
        end
    elseif m==N+1 %����������Ŕw
        S1=mv(1)/Di(m);
        SS=fix(S1);
        for o=Ho+1:1:F(m-1)
            E=imcrop(IMG_L,[1 o L 0]);
            E2=imcrop(IMG1,[1 o L 0]);
            E=imtranslate(E,[SS,0]);   %�z������炷
            E2=imtranslate(E2,[SS,0]);   %�z������炷
            IMG_BL2=vertcat(IMG_BL2,E);
            MSK01=vertcat(MSK01,E2);
            J=o-Ho;
            SS=S1*J;
            SS=fix(SS);
        end
        mv_xx=mv(1);
    else %���̑��l����
        S1=(mv(N+1-m+1)-mv(N+1-m))/Di(m);
        SS=fix(mv_xx+S1);
        for o=F(m)+1:1:F(m-1)
            E=imcrop(IMG_L,[1 o L 0]);
            E2=imcrop(IMG1,[1 o L 0]);
            E=imtranslate(E,[SS,0]);   %�z������炷
            E2=imtranslate(E2,[SS,0]);   %�z������炷
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
MSK = (IMG1+MSK01)==0; % �ړ��O��̃}�X�N�𑍘a�C�̈�ȊO�̗̈撊�o�i���j
IMG_L(:,:,1) = MSK; IMG_L(:,:,2) = MSK; IMG_L(:,:,3) = MSK; % �J���[�摜��
IMG_BL = IMG_L.*ORG_BL+IMG_BL2; % �̈�ȊO�̗̈�i���j�ƈړ���̗̈��A��


%% �摜�̍���
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

disp('����摜��\�����܂����D');
imagesc(ORG1);
axis image; xlabel('x'); ylabel('y');
pause;

IMG_L = ORG1;
imwrite(IMG_L,'left.png'); % �摜�̕ۑ�


%% �E��p�摜����
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

% �ړ���
for w=1:1:N
    mv(w)= fix(MV_MAX*(255-D(N+1-w))/255);
end

for m=N+1:-1:1
    if m==1 %�摜���[����őO
        S1=(MV_MAX-mv(N+1-m))/Di(m);  % ��f���̈ړ�
        SS=fix(mv_xx+S1);
        
        for o=F(m)+1:1:H
            E=imcrop(IMG_R,[1 o L 0]);
            E2=imcrop(IMG2,[1 o L 0]);
            E=imtranslate(E,[-SS,0]);   %�z������炷
            E2=imtranslate(E2,[-SS,0]);   %�z������炷
            IMG_BR2=vertcat(IMG_BR2,E);
            MSK02=vertcat(MSK02,E2);
            
            J=o-F(m);
            SS=mv_xx+S1*J;
            SS=fix(SS);
        end
    elseif m==N+1 %����������Ŕw
        S1=mv(1)/Di(m);
        SS=fix(S1);
        for o=Ho+1:1:F(m-1)
            E=imcrop(IMG_R,[1 o L 0]);
            E2=imcrop(IMG2,[1 o L 0]);
            E=imtranslate(E,[-SS,0]);   %�z������炷
            E2=imtranslate(E2,[-SS,0]);   %�z������炷
            IMG_BR2=vertcat(IMG_BR2,E);
            MSK02=vertcat(MSK02,E2);
            J=o-Ho;
            SS=S1*J;
            SS=fix(SS);
        end
        mv_xx=mv(1);
    else %���̑��l����
        S1=(mv(N+1-m+1)-mv(N+1-m))/Di(m);
        SS=fix(mv_xx+S1);
        for o=F(m)+1:1:F(m-1)
            E=imcrop(IMG_R,[1 o L 0]);
            E2=imcrop(IMG2,[1 o L 0]);
            E=imtranslate(E,[-SS,0]);   %�z������炷
            E2=imtranslate(E2,[-SS,0]);   %�z������炷
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
MSK = (IMG2+MSK02)==0; % �ړ��O��̃}�X�N�𑍘a�C�̈�ȊO�̗̈撊�o�i���j
IMG_R(:,:,1) = MSK; IMG_R(:,:,2) = MSK; IMG_R(:,:,3) = MSK; % �J���[�摜��
IMG_BR = IMG_R.*ORG_BR+IMG_BR2; % �̈�ȊO�̗̈�i���j�ƈړ���̗̈��A��


%% �摜�̍���
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

disp('����摜��\�����܂����D');
imagesc(ORG3);
axis image; xlabel('x'); ylabel('y');
pause;

IMG_R = ORG3;
imwrite(IMG_R,'right.png'); % �摜�̕ۑ�


%% �A�i�O���t�摜�̐���
IMG_e = stereoAnaglyph(IMG_L, IMG_R);
imwrite(IMG_e,'anaglyph.png'); % �摜�̕ۑ�
disp('�A�i�O���t�摜��\�����܂����D');
imagesc(IMG_e);
axis image; xlabel('x'); ylabel('y');
