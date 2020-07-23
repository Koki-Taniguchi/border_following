clear; % 変数のオールクリア

ORG=imread('square.png'); % 原画像の入力
ORG=rgb2gray(ORG); % カラー画像を白黒濃淡画像へ変換
IMG = ORG>128; % 白黒画像を2値化
figure; imagesc(IMG); colormap(gray); colorbar;

% 画像サイズを取得
image_size = size(IMG);
height = image_size(1);
width = image_size(2);

result_image = ones(height, width); % メモリの確保
start_point = [1, 1]; % ラスタ走査の初期開始位置


while 1
  hit_point = rasterScan(IMG, result_image, start_point, height, width);
  if isequal(hit_point, [height, width])
    break
  end
  
  [result_image, start_point] = squareScan(IMG, result_image, hit_point, height, width);
end

figure; imagesc(result_image); colormap(gray); colorbar;

% ラスタ走査の関数
function hit_point = rasterScan(scan_image, result_image, start_point, height, width)  
  hit = false;
  s_w = start_point(2);
  for h_i = start_point(1):height
    for w_i = s_w:width
      if isNextOutlinePixel(scan_image, result_image, height, width, h_i, w_i)
        hit_point = [h_i, w_i];
        hit = true;
        break
      end
    end
    
    s_w = 1;
    if hit
      break
    end
  end
  
  if not(hit)
    hit_point = [height, width];
  end
end

% 方形走査の関数
function [result_image, final_scan_point] = squareScan(scan_image, result_image, start_point, height, width)
  h_i = start_point(1);
  w_i = start_point(2);
  result_image(h_i, w_i) = 0;

  v_old = 0;
  while 1
    [h_check, w_check, v_old] = findNextOutlinePixel(scan_image, result_image, height, width, v_old, h_i, w_i);
    if isequal(start_point, [h_check, w_check])
      break
    end
    
    if v_old == 10
      final_scan_point = start_point;
      return
    end
    
    result_image(h_check, w_check) = 0;
    h_i = h_check;
    w_i = w_check;
  end
  
  final_scan_point = [h_i, w_i];
end

% 方形走査時の確認する方角を取得
function [h_check, w_check] = nextCheckPoint(arrow, height, width, h_i, w_i)
  switch arrow
    case 0
      if h_i > 1
        h_check = h_i - 1;
        w_check = w_i;
        return
      end
    case 1
      if h_i > 1 && w_i < width
        h_check = h_i - 1;
        w_check = w_i + 1;
        return
      end
    case 2
      if w_i < width
        h_check = h_i;
        w_check = w_i + 1;
        return
      end
    case 3
      if h_i < height && w_i < width
        h_check = h_i + 1;
        w_check = w_i + 1;
        return
      end
    case 4
      if h_i < height
        h_check = h_i + 1;
        w_check = w_i;
        return
      end
    case 5
      if h_i < height && w_i > 1
        h_check = h_i + 1;
        w_check = w_i - 1;
        return
      end
    case 6
      if w_i > 1
        h_check = h_i;
        w_check = w_i - 1;
        return
      end
    case 7
      if h_i > 1 && w_i > 1
        h_check = h_i - 1;
        w_check = w_i - 1;
        return
      end
  end
  h_check = 0;
  w_check = 0;
end

% 隣接する輪郭画素を探す関数
function [h_check, w_check, v_new] = findNextOutlinePixel(scan_image, result_image, height, width, v_old, h_i, w_i)
  for i = v_old:(v_old + 7)
    v_new = rem(i + 6, 8);
    [h_check, w_check] = nextCheckPoint(v_new, height, width, h_i, w_i);

    if isequal([0, 0], [h_check, w_check])
      continue
    end
    
    if isNextOutlinePixel(scan_image, result_image, height, width, h_check, w_check)
      return
    end
  end
  
  v_new = 10;
  return
end

% 対象の画素が輪郭画素かどうか判定する関数
function bool = isOutlinePixel(scan_image, height, width, scan_point)
  if scan_point(1) == 1 || scan_point(1) == height || scan_point(2) == 1 || scan_point(2) == width
    bool = true;
    return
  end
  
  if scan_point(1) > 1
    top = scan_point(1) - 1;
  else
    top = scan_point(1);
  end

  if scan_point(1) < height
    bottom = scan_point(1) + 1;
  else
    bottom = scan_point(1);
  end
  
  if scan_point(2) > 1
    left = scan_point(2) - 1;
  else
    left = scan_point(2);
  end
  
  if scan_point(2) < width
    right = scan_point(2) + 1;
  else
    right = scan_point(2);
  end
  
  scan_area = scan_image(top:bottom, left:right);
  bool = sum(scan_area, 'all') > 0;
end

% ラスタ走査や方形走査を行うときに次に進める輪郭画素かどうかを判定する関数
function bool = isNextOutlinePixel(scan_image, result_image, height, width, h_i, w_i)
  bool = scan_image(h_i, w_i) == 0 && result_image(h_i, w_i) == 1 && isOutlinePixel(scan_image, height, width, [h_i, w_i]);
end

