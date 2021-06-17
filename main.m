Diretoria = 'pulmao';
S = dir(fullfile(Diretoria,'fig*.jpg'));

lungVolumeTotal = 0;
newLungVolumeTotal = 0;

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
%     I = imgaussfilt(I,10);
    
%     Binariza
    I = im2gray(I);
    BW = imbinarize(I, 0.1);
    BW = bwareaopen(BW, 1000);
    
%     imwrite(BW, "pulmao/relatorio/fig" +i + "_bin.jpg");
    
%     Erosão
    se = strel('disk',1);
    opening = imerode(BW,se);
    
%     se = strel('disk',5);
%     opening = imdilate(opening,se);
    
%     imwrite(opening, "pulmao/relatorio/fig" +i + "_morph2.jpg");
    
    
    
    
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

%     Deteção de Pulmão Para apagar pequenas areas sem morfologia
%     matematica
    labeledBw = bwlabel(opening);
    measurements = regionprops(labeledBw, "Solidity", "Area"); 
    
   
    solidity = [measurements.Solidity];
    area = [measurements.Area];  
    hiSolid = solidity > 0.1; 
    maxArea = max(area(hiSolid)); 
    
    lungLabel = find(area==maxArea);  
    lung = ismember(labeledBw, lungLabel);
    
    
    [bbb,lll] = bwboundaries(lung);  
   
    [r, c] = find(lll > 1);    
    rc = [r c];
    
    [row, col] = size(opening);
    newLung = logical(ones(row,col));
 
    
    [rrr, ccc] = size(rc);
    
    
    for k = 1:rrr
      primeira = 0 ;
      segunda = 0;
        for j = 1:ccc
            primeira = rc(k);
            segunda = rc(k, j);
        end
        
        newLung(primeira, segunda) = 0;
    end
    
    
    labledBw2 = bwlabel(newLung);
    

    [B2,L2, N2, A2] = bwboundaries(labledBw2);
    rp = regionprops(L2, "Area"); 
    area2 = [rp.Area]; 
    smallAreasLabels = find(area2 > 5000);
    smallBlackPoints = ismember(L2, smallAreasLabels);
    

  
  
  blackbg = nnz(lung == 1);
  if blackbg < 25000
      if i >= 103
          diffLung = newLung;
      else
          diffLung = newLung - smallBlackPoints;
      end
      
     
  else
      diffLung = newLung;
  end
  
  duplicateDiffLung = diffLung;

%    Morfologia Matermatica
   se = strel('disk',9);
   diffLung = imdilate(diffLung,se);
   
   se = strel('disk',13);
   diffLung = imerode(diffLung,se);
   
   se = strel('disk',6);
   diffLung = imdilate(diffLung,se);
   
  
    
%     Busca por pontos pentro dentro da área branca
    [B,L] = bwboundaries(lung);  
    blackPixelsCount = nnz(L > 1);
    
    
%     Calcula Volume Pulmao 1 Antes da Morfologia
    lungVolume = blackPixelsCount * 7;
    totalL = lungVolume / 1000000;
    lungVolumeTotal = lungVolumeTotal + totalL;
    
%     Calcula Volume Pulmao 2 Depois de Morfologia
    blackPNewLung = nnz(diffLung == 0);
    diffLungVolume = blackPNewLung * 7;
    newLungtotal = diffLungVolume / 1000000;
    newLungVolumeTotal = newLungVolumeTotal + newLungtotal;
    
    
   
%     Print
    figure(1)
    set(gcf,'Position',[100 100 1500 700])
    subplot(2,3,1); imshow(original), title("Original " + "fig" +i + ".jpg")
    subplot(2,3,2); imshow(opening, []); title("Volume Atual do pulmão" + totalL + "L / Volume Total ==> " + lungVolumeTotal + "L")
   
   
    hold on
    for i = 1:length(B)
        plot(B{i}(:,2), B{i}(:,1), 'y', 'linewidth', 2.5);
    end
    hold off
    
    subplot(2,3,3); imshow(newLung, []); title("Volume Atual do pulmão" + totalL + "L / Volume Total ==> " + lungVolumeTotal + "L")
    
   
    subplot(2,3,4)
    imshow(newLung); hold on;
    colors=['b' 'g' 'r' 'c' 'm' 'y'];
    for k=1:length(B2)
      boundary = B2{k};
      cidx = mod(k,length(colors))+1;
      plot(boundary(:,2), boundary(:,1),...
           colors(cidx),'LineWidth',2);

      %randomize text position for better visibility
      rndRow = ceil(length(boundary)/(mod(rand*k,7)+1));
      col = boundary(rndRow,2); row = boundary(rndRow,1);
      h = text(col+1, row-1, num2str(L(row,col)));
      set(h,'Color',colors(cidx),'FontSize',14,'FontWeight','bold');
    end
   hold off;
   
   subplot(2,3,5); imshow(duplicateDiffLung, []); 
   subplot(2,3,6); imshow(diffLung, []); title("Volume Atual do pulmão" + newLungtotal + "L / Volume Total ==> " + newLungVolumeTotal + "L")
  
    

 
end
