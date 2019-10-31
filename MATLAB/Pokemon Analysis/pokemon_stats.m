function [ID, CP, HP, stardust, level, cir_center] = pokemon_stats (img, model)
% Please DO NOT change the interface
% INPUT: image; model(a struct that contains your classification model, detector, template, etc.)
% OUTPUT: ID(pokemon id, 1-201); level(the position(x,y) of the white dot in the semi circle); cir_center(the position(x,y) of the center of the semi circle)

%img = imread("./train/046_CP62_HP16_SD400_4863_9.jpeg");
img = rgb2gray(img);
%img = imgaussfilt(img2);
%model = load ('./model.mat');

img1 = img;


[y2,x2] = size(img);

%ID Detection
%img1 = img1(x/10:x/2.4,1:y/3,:);
img1 = imcrop(img1, [0, 0, x2, 0.3*y2]); 
img1 = imresize(img1,[600 600]);
[r, c] = size(img1);
I = reshape(img1, [r*c, 1]);
test_image_difference = double(I)-model.image_mean;
fisherImage = model.eigenvector * test_image_difference;
index =0;
min_dist = inf;
[len, ~] = size(model.eigenvectorfeature);
for i=1:len   
    eigenface = model.eigenvectorfeature(:,i);
    eigenface = eigenface-fisherImage;
    eigenface = eigenface.*eigenface;
    eigenface =sqrt(sum(eigenface));
    if(eigenface~=0 && min_dist>eigenface)
        min_dist=eigenface;
        index = i;
    end  
end
ID = model.ID_label(index);



%CP Detection
word = " ";
CP = "123";
cp_img = imcrop(img, [0.2*x2, 0.05*y2, 0.5*x2, 0.1*y2]); 
cp_img = imgaussfilt(cp_img);
%cp_img = imsharpen(img);
cp_img = imbinarize(cp_img, 'adaptive', 'ForegroundPolarity', 'bright', 'Sensitivity', 0.5);
cp_img = imcomplement(cp_img);
%cp_img = imbinarize(cp_img);
%cp_img = imcomplement(cp_img);
%[(0.33*x2), (0.1*y2), (0.33*x2), (0.25*y2)]
cp_ocr = ocr(cp_img, 'CharacterSet', 'CcPpoO123456789');
cp_result = cp_ocr.Words;
for i=1:(size(cp_result, 1))
    word = cp_result(i);
    if(contains(cp_result(i), 'CP', 'IgnoreCase',true))
        word = string(cp_result(i));
        %disp("here");
        SI = regexpi(word,'\d*o*\d*o*\d*o*\d*o*\d*o*','match','once');
        CP = string(SI);
        break;
    end
end
CP = regexprep(CP, 'o', '0', 'ignorecase'); 
CP = double(CP);
disp(CP);



%HP Detection
hp_img = imcrop(img, [0.25*x2, 0.33*y2, 0.75*x2, 0.66*y2]); 
hp_img = imbinarize(hp_img);
HP = "26";
hp_ocr = ocr(hp_img);
hp_result = hp_ocr.Words;
for i=1:(size(hp_result, 1))
    word = string(hp_result(i));
    if(contains(word, 'HP'))
        word = string(hp_result(i-1));
        break;
    end
end
HP = regexprep(HP, 'o', '0', 'ignorecase');
HP2 = split(word, '/');
HP = str2double(HP2(1));
disp(HP);



%Stardust Detection
stardust = "600";
sta_img = imsharpen(img);
sta_img = imcrop(sta_img, [0.5*x2, ((0.75*y2)), (0.25*x2), (0.1*y2)]);
sta_img = imbinarize(sta_img);
sta_ocr = ocr(sta_img, 'CharacterSet', '0123456789');
sta_result = sta_ocr.Words;
%word = string(sta_result(1));
for i=1:(size(sta_result, 1))
    word = string(sta_result(i));
    if(regexpi(word, '\d*\d*\d*\d*\d*\d*\d*\d*'))
        word = string(sta_result(i));
        break;
    end
end
word = regexpi(word,'\d*o*\d*o*\d*o*\d*o*\d*o*\d*o*\d*o*\d*o*','match','once');
word = regexprep(word, 'o', '0', 'ignorecase'); 
stardust = str2double(word);
disp(stardust);



%Level Detection and Center Detection
level = [327,165];
cir_center = [355,457]; 
lvl_img = imcrop(img, [(0.1*x2), 10, (0.38*x2), y2]);
[cent,~] = imfindcircles(lvl_img,[4 17]);
if (size(cent,2)>0 || size(cent,1)>0)
    x3= cent(1,1)+10;
    y3 = cent(1,2)+(x2/10);
else
    lvl_img = imbinarize(img);
    lvl_img = bwareaopen(lvl_img,30);
    se = strel('disk',5);
    lvl_img = imclose(lvl_img,se);
    lvl_img = imfill(lvl_img,'holes'); 
    edge_one = edge(lvl_img, 'sobel',0.45);
    [Gx, Gy] = imgradientxy(edge_one,'prewitt');
    edge_one=imgradient(Gx.*Gy, Gy);
    [labeledImage, ~] = bwlabel(edge_one);
    blobMeasurements = regionprops(labeledImage, 'area', 'Centroid');
    allAreas = [blobMeasurements.Area];
    [~, sortIndexes] = sort(allAreas, 'descend');
    if(size(sortIndexes)>0)
        biggestBlob = ismember(labeledImage, sortIndexes(1:2));
        binaryImage = biggestBlob > 0;
        [rows,cols] = find(binaryImage==1);
        x3 = cols(size(cols,1));
        y3 = rows(size(rows,1));
        x4 = cols(1);
        y4 = rows(1);
        x5 = cols(3);
        y5 = rows(3);
        mr = (y5-y4)/(x2-x4);
        mt = (y3-y5)/(x3-x2);
        x6 = (((mr*mt)*(y3-y4)) +(mr*(x5+x3))-(mt*(x4+x5)))/(2*(mr-mt));
        y6 =-((1/mr)*(x6-((x4+x5)/2))) +((y4+y5)/2);
        y_cen = x6+10;
        x_cen = y6+(x6/10);
        if(y_cen>0)
            y_cen = ((y2/1.85) + (y2/1.9))/2;
        end
        if(x_cen>0)
            x_cen = ((x2/3.5) + (x2/3))/2;
        end
        level = [x3 y3];
        cir_center=[x_cen y_cen];
    else
        level = [327,165];
    end
end
end
