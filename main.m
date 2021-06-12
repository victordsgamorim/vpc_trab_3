Diretoria = 'pulmao';
S = dir(fullfile(Diretoria,'fig*.jpg'));

new_crop=[
    117.510000000000,199.510000000000,436.980000000000,140.980000000000;...
    117.510000000000,199.510000000000,436.980000000000,140.980000000000; ...
115.510000000000,197.510000000000,440.980000000000,140.980000000000; ...
113.510000000000,195.510000000000,443.980000000000,139.980000000000; ...
110.510000000000,189.510000000000,450.980000000000,143.980000000000;...
109.510000000000,184.510000000000,452.980000000000,144.980000000000;...
107.510000000000,183.510000000000,456.980000000000,145.980000000000;...
104.510000000000,178.510000000000,463.980000000000,146.980000000000];

crop_decision = 103;
index = 1;

for i = 1:numel(S)
    
%     Le imagem
    I=imread("pulmao/fig" +i + ".jpg");
    original = I;
     
%     Filtro Gaussiano
    I = imgaussfilt(I,10);
    
%     Binariza
    I = im2gray(I);
    BW = imbinarize(I, 0.1);
   

%     Erosão + Dilatação
    se = strel('disk',5);
    closing = imerode(BW,se);
    
    se = strel('disk',5);
    opening = imopen(closing,se);
    
%     Erosão
    se = strel('disk',4);
    opening = imerode(opening,se);
    

%     Adiciona BoundingBox
    bounding_box = vision.BlobAnalysis('BoundingBoxOutputPort', true, 'AreaOutputPort', false, 'CentroidOutputPort', false, 'MinimumBlobArea', 10000);
    box = step(bounding_box, opening);
    detected_lung = insertShape(original, 'Rectangle', box(2,:), 'Color', 'green');
    
    opening;
    if i >= crop_decision
        opening = imcrop(opening, new_crop(index,:) );
        index = index + 1;
    elseif i < crop_decision
        opening = imcrop(opening, box(2,:));
    end

%     Deteção de Pulmão para calcular volume
    labeledBw = logical(opening);
    measurements = regionprops(labeledBw, "Solidity", "Area"); 
    
    
    solidity = [measurements.Solidity];
    area = [ measurements.Area];  
    hiSolid= solidity > 0.1; 
    maxArea = max( area(hiSolid));  
    lungLabel = find(area==maxArea);  
    lung = ismember(labeledBw, lungLabel);
    
    
%     Busca por pontos pentro dentro da área branca
    [B,L] = bwboundaries(lung);  
    blackPixelsCount = nnz(L > 1);
    
    
%     Calcula Volume
    lungVolume = blackPixelsCount * 7;
   
%     Print
    figure(1)
    set(gcf,'Position',[100 100 1500 700])
    subplot(1,2,1); imshow(original), title("Original " + "fig" +i + ".jpg")
    subplot(1,2,2); imshow(opening, []); title("Volume ===> " + lungVolume + "mm³")
    
   
    hold on
    for i = 1:length(B)
        plot(B{i}(:,2), B{i}(:,1), 'y', 'linewidth', 2.5);
    end
    hold off
    

 
end
