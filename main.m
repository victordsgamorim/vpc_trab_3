Diretoria = 'pulmao';
S = dir(fullfile(Diretoria,'fig*.jpg'));

lungVolumeTotal = 0;

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
    
%     imwrite(BW, "pulmao/relatorio/fig" +i + "_bin.jpg");
   

%     Erosão + Dilatação
    se = strel('disk',5);
    closing = imerode(BW,se);
    
    se = strel('disk',5);
    opening = imopen(closing,se);
    
%     imwrite(opening, "pulmao/relatorio/fig" +i + "_morph.jpg");
    
%     Erosão
    se = strel('disk',4);
    opening = imerode(opening,se);
    
    
%     imwrite(opening, "pulmao/relatorio/fig" +i + "_gauss.jpg");
    

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
    
  
%     imwrite(opening, "pulmao/relatorio/fig" +i + "_crop.jpg");

%     Deteção de Pulmão para calcular volume
    labeledBw = bwlabel(opening);
    measurements = regionprops(labeledBw, "Solidity", "Area"); 
    
   
    solidity = [measurements.Solidity];
    area = [ measurements.Area];  
    hiSolid= solidity > 0.1; 
    maxArea = max(area(hiSolid)); 
    
    lungLabel = find(area==maxArea);  
    lung = ismember(labeledBw, lungLabel);
    
    
    [bbb,lll] = bwboundaries(lung);  
   
    [r, c] = find(lll > 1);
    rc = [r c];
    
    [row, col] = size(opening);
    s = logical(ones(row,col));
 
    
    [rrr, ccc] = size(rc);
    
    
    for k = 1:rrr
      primeira = 0 ;
      segunda = 0;
        for j = 1:ccc
            primeira = rc(k);
            segunda = rc(k, j);
     

        end
        
        s(primeira, segunda) = 0;
    end
  
  
   
    
%     Busca por pontos pentro dentro da área branca
    [B,L] = bwboundaries(lung);  
    blackPixelsCount = nnz(L > 1);
    
    
%     Calcula Volume
    lungVolume = blackPixelsCount * 7;
    totalL = lungVolume / 1000000;
    lungVolumeTotal = lungVolumeTotal + totalL;
    
    
   
%     Print
    figure(1)
    set(gcf,'Position',[100 100 1500 700])
    subplot(1,3,1); imshow(original), title("Original " + "fig" +i + ".jpg")
    subplot(1,3,2); imshow(opening, []); title("Volume Atual do pulmão" + totalL + "L / Volume Total ==> " + lungVolumeTotal + "L")
   
   
    hold on
    for i = 1:length(B)
        plot(B{i}(:,2), B{i}(:,1), 'y', 'linewidth', 2.5);
    end
    hold off
    
    subplot(1,3,3); imshow(s, []); title("Volume Atual do pulmão" + totalL + "L / Volume Total ==> " + lungVolumeTotal + "L")
    

 
end
