Img = ORG;%read the 2D image
%Convert the image to Grayscale
I=rgb2gray(Img);

%Edge Detection
Ie=edge(I,'sobel');

%Hough Transform
[H,theta,rho] = hough(Ie);

% Finding the Hough peaks (number of peaks is set to 5)
P = houghpeaks(H, 5,'threshold',ceil(0.5*max(H(:))));
x = theta(P(:,2));
y = rho(P(:,1));
%Vanishing lines
lines = houghlines(I,theta,rho,P,'FillGap',170,'MinLength',400);
[rows, columns] = size(Ie);
figure, imshow(Ie)

hold on
xy_1 = zeros([2,2]);
for k = 1:length(lines)
   xy = [lines(k).point1; lines(k).point2];
   % Get the equation of the line
   x1 = xy(1,1);
   y1 = xy(1,2);
   x2 = xy(2,1);
   y2 = xy(2,2);
   slope = (y2-y1)/(x2-x1);
   xLeft = 1; % x is on the left edge
   yLeft = slope * (xLeft - x1) + y1;
   xRight = columns; % x is on the reight edge.
   yRight = slope * (xRight - x1) + y1;
   plot([xLeft, xRight], [yLeft, yRight], 'LineWidth',1,'Color','blue');

   %intersection of two lines (the current line and the previous one)
   slopee = @(line) (line(2,2) - line(1,2))/(line(2,1) - line(1,1));
   m1 = slopee(xy_1);
   m2 = slopee(xy);
   intercept = @(line,m) line(1,2) - m*line(1,1);
   b1 = intercept(xy_1,m1);
   b2 = intercept(xy,m2);
   xintersect = (b2-b1)/(m1-m2);
   yintersect = m1*xintersect + b1;
   plot(xintersect,yintersect,'m*','markersize',8, 'Color', 'red')
   xy_1 = xy;

   % Plot original points on the lines .
   plot(xy(1,1),xy(1,2),'x','markersize',8,'Color','yellow'); 
   plot(xy(2,1),xy(2,2),'x','markersize',8,'Color','green');    
end
disp('�������̌�_���N���b�N���Ă��������D')
[M,I] = ginput(1);  % �N���b�N�|�C���g��y���W���擾
I=round(I); % �z��͐��̐����Ȃ̂Ŋۂߍ���

[H,L]=size(ORG) % �摜�̏c���擾

L=length(ORG)   % �摜�̉����擾
figure, imshow(Img)
hold on, plot([0 L],[I I],'r')
disp('�n������ݒ肵�܂����D')

G=zeros(H,L);   % ORG�Ɠ����T�C�Y�̔z��𐶐�
for i=H:-1:I % �摜���[���琅�����܂ł𔒂ɂ���
    B=G(i,:);
    if all(B<200)==1 % �v���O�����̍�������
        G(i,:)=255;
    else
    end
end
pause;

imagesc(G); axis image; colorbar('off')
disp('�n�ʗ̈�摜��ۑ����܂����D');
imwrite(G,'ground.png') % �摜�̕ۑ�
