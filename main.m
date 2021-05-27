% PS: Cada pixel preto multiplicar por 7  para transformar em milimetros
% cubicos

Diretoria = 'pulmao';
S = dir(fullfile(Diretoria,'fig*.jpg'));

for i = 1:numel(S) - 23 % o restante das imagens já não tem mais pulmão, ou seja, as 23 imagens é o quadril
%     Le imagem
    I=imread("pulmao/fig" +i + ".jpg");
    original = I;
     
%     Filtro Gaussiano
    I = imgaussfilt(I,7);
    
%     Binariza
    I = im2gray(I);
    BW = imbinarize(I, 0.1);
   
    
% Inverte imagem binarizada    
%     BW = ~BW;
%     BW = 1-BW;
%     BW = (BW == 0);
    
    se = strel('disk',5);
    opening = imopen(BW,se);

%     closing = imerode(opening,se);

    bounding_box = vision.BlobAnalysis('BoundingBoxOutputPort', true, 'AreaOutputPort', false, 'CentroidOutputPort', false, 'MinimumBlobArea', 10000);
    box = step(bounding_box, opening);
  
 
    detected_lung = insertShape(original, 'Rectangle', box(2,:), 'Color', 'green');
    opening = imcrop(opening, box(2,:));
    
    
    
    figure(1)
    set(gcf,'Position',[100 100 1500 700])
    subplot(1,2,1); imshow(detected_lung), title("Original " + "fig" +i + ".jpg")
    subplot(1,2,2); imshow(opening, [])
%     
    
%   pause();

end
