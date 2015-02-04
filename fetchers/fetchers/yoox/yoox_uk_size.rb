module YooxUkSize # :nodoc:
  def match_within_womens_bottom(value, item)
    {
      '24W-30L' => '24S',
      '24W-32L' => '24R',
      '24W-34L' => '24L',
      '24W-36L' => '28L',
      '25W-30L' => '25S',
      '25W-32L' => '25R',
      '25W-34L' => '25L',
      '25W-36L' => '28L',
      '26W-30L' => '26S',
      '26W-32L' => '26R',
      '26W-34L' => '26L',
      '26W-36L' => '28L',
      '27W-30L' => '27S',
      '27W-32L' => '27R',
      '27W-34L' => '27L',
      '27W-36L' => '28L',
      '28W-30L' => '28S',
      '28W-32L' => '28R',
      '28W-34L' => '28L',
      '28W-36L' => '28L',
      '29W-30L' => '29S',
      '29W-32L' => '29R',
      '29W-34L' => '29L',
      '29W-36L' => '28L',
      '30W-30L' => '30S',
      '30W-32L' => '30R',
      '30W-34L' => '30L',
      '30W-36L' => '28L',
      '31W-30L' => '31S',
      '31W-32L' => '31R',
      '31W-34L' => '31L',
      '31W-36L' => '28L',
      '32W-30L' => '32S',
      '32W-32L' => '32R',
      '32W-34L' => '32L',
      '32W-36L' => '28L',
      '33W-30L' => '33S',
      '33W-32L' => '33R',
      '33W-34L' => '33L',
      '33W-36L' => '28L',
      '34W-30L' => '34S',
      '34W-32L' => '34R',
      '34W-34L' => '34L',
      '34W-36L' => '28L'
    }[value]
  end

  def match_within_mens_bottom(value, item)
    {
      '26W-32L' => '26',
      '26W-34L' => '26',
      '27W-32L' => '27',
      '27W-34L' => '27',
      '28W-32L' => '28X32',
      '28W-34L' => '28X34',
      '28W-36L' => '28X36',
      '29W-32L' => '29X32',
      '29W-34L' => '29X34',
      '29W-36L' => '29X36',
      '30W-32L' => '30X32',
      '30W-34L' => '30X34',
      '30W-36L' => '30X36',
      '31W-32L' => '31X32',
      '31W-34L' => '31X34',
      '31W-36L' => '31X36',
      '32W-32L' => '32X32',
      '32W-34L' => '32X34',
      '32W-36L' => '32X36',
      '33W-32L' => '33X32',
      '33W-34L' => '33X34',
      '33W-36L' => '33X36',
      '34W-32L' => '34X32',
      '34W-34L' => '34X34',
      '34W-36L' => '34X36',
      '35W-32L' => '35X32',
      '35W-34L' => '35X34',
      '35W-36L' => '35X36',
      '36W-32L' => '36X32',
      '36W-34L' => '36X34',
      '36W-36L' => '36X36',
      '37W-32L' => '37X32',
      '37W-34L' => '37X34',
      '37W-36L' => '37X36',
      '38W-32L' => '38X32',
      '38W-34L' => '38X34',
      '38W-36L' => '38X36',
      '39W-32L' => '39X32',
      '39W-34L' => '39X34',
      '39W-36L' => '39X36',
      '40W-32L' => '40X32',
      '40W-34L' => '40X34',
      '40W-36L' => '40X36',
      '41W-32L' => '41X32',
      '41W-34L' => '41X34',
      '41W-36L' => '41X36',
      '42W-32L' => '42X32',
      '42W-34L' => '42X34',
      '42W-36L' => '42X36',
      '43W-32L' => '43X32',
      '43W-34L' => '43X34',
      '43W-36L' => '43X36',
      '44W-32L' => '44X32',
      '44W-34L' => '44X34',
      '44W-36L' => '44X36',
      '46W-32L' => '46X32',
      '46W-34L' => '46X34',
      '46W-36L' => '46X36'
    }[value]
  end

  def match_within_mens_top(value, item)
    {
      '14Inches' => ['14 32/33','14 34/35'],
      '14½Inches' => ['14.5 32/33','14.5 34/35'],
      '15Inches' => ['15 32/33','15 34/35'],
      '15½Inches' => ['15.5 32/33','15.5 34/35','15.5 36/37'],
      '16Inches' => ['16 32/33','16 34/35','16 36/37'],
      '16½Inches' => ['16.5 32/33','16.5 34/35','16.5 36/37','16.5 38/39'],
      '17Inches' => ['17 32/33','17 34/35','17 36/37','17 38/39'],
      '17½Inches' => ['17.5 32/33','17.5 34/35','17.5 36/37','17.5 38/39'],
      '18Inches' => ['18 32/33','18 34/35','18 36/37','18 38/39'],
      '18½Inches' => ['18.5 32/33','18.5 34/35','18.5 36/37','18.5 38/39'],
      '36Inches' => ['36S','36','36L'],
      '37Inches' => ['37S','37','37L'],
      '38Inches' => ['38S','38','38L'],
      '39Inches' => ['39S','39','39L'],
      '40Inches' => ['40S','40','40L'],
      '41Inches' => ['41S','41','41L'],
      '42Inches' => ['42S','42','42L'],
      '43Inches' => ['43S','43','43L'],
      '44Inches' => ['44S','44','44L'],
      '45Inches' => ['45S','45','45L'],
      '46Inches' => ['46S','46','46L'],
      '47Inches' => ['47S','47','47L'],
      '48Inches' => ['48S','48','48L'],
      '49Inches' => ['49S','49','49L'],
      '50Inches' => ['50S','50','50L'],
      '51Inches' => ['51S','51','51L'],
      '52Inches' => ['52S','52','52L']
    }[value]
  end
  def match_within_mens_shoe(value, item)
    {
      '4½' => '4.5',
      '5½' => '5.5',
      '6½' => '6.5',
      '7½' => '7.5',
      '8½' => '8.5',
      '9½' => '9.5',
      '10½' => '10.5',
      '11½' => '11.5',
      '12½' => '12.5',
      '13½' => '13.5',
      '14½' => '14.5',
      '15½' => '15.5',
      '16½' => '16.5'
    }[value]
  end
  # Yoox lists baby/kid/junior sizes the same for both UK and US,
  # so we need to transform (assuming that those listed are of US sizes)

  BOYS = {
      '3months'=>['0-3MONTHS','3-6MONTHS'],
      '6months'=>['3-6MONTHS','6-12MONTHS'],
      '9months'=>'6-12MONTHS',
      '12months'=>['6-12MONTHS','12-18MONTHS'],
      '18months'=>['12-18MONTHS','18-24MONTHS'],
      '24months'=>['18-24MONTHS','2YEARS'],
      '3years'=>'3YEARS',
      '4years'=>['4YEARS','4SLIM','4HUSKY'],
      '5years'=>['5YEARS','5SLIM','5HUSKY'],
      '6years'=>['6YEARS','6SLIM','6HUSKY'],
      '7years'=>['7YEARS','7SLIM','7HUSKY'],
      '8years'=>['9YEARS','9SLIM','9HUSKY'],
      '9years'=>['10YEARS','10SLIM','10HUSKY'],
      '10years'=>['10YEARS','10SLIM','10HUSKY'],
      '11years'=>['11YEARS','11SLIM','11HUSKY'],
      '12years'=>['11YEARS','11SLIM','11HUSKY'],
      '13years'=>['12YEARS','12SLIM','12HUSKY'],
      '14years'=>['13YEARS','13SLIM','13HUSKY'],
      '15years'=>['14YEARS','14SLIM','14HUSKY'],
      '16years'=>['14YEARS','14SLIM','14HUSKY']
  }
  
  def match_within_boys_top(value, item)
    BOYS[value]
  end

  def match_within_boys_bottom(value, item)
    BOYS[value]
  end
  
  GIRLS = {
      '3months'=>['0-3MONTHS','3-6MONTHS'],
      '6months'=>['3-6MONTHS','6-12MONTHS'],
      '9months'=>'6-12MONTHS',
      '12months'=>['6-12MONTHS','12-18MONTHS'],
      '18months'=>['12-18MONTHS','18-24MONTHS'],
      '24months'=>['18-24MONTHS','2YEARS'],
      '3years'=>'3YEARS',
      '4years'=>['4YEARS','4SLIM','4PLUS'],
      '5years'=>['5YEARS','5SLIM','5PLUS'],
      '6years'=>['6YEARS','6SLIM','6PLUS'],
      '7years'=>['7YEARS','7SLIM','7PLUS'],
      '8years'=>['9YEARS','9SLIM','9PLUS'],
      '9years'=>['10YEARS','10SLIM','10PLUS'],
      '10years'=>['10YEARS','10SLIM','10PLUS'],
      '11years'=>['11YEARS','11SLIM','11PLUS'],
      '12years'=>['11YEARS','11SLIM','11PLUS'],
      '13years'=>['12YEARS','12SLIM','12PLUS'],
      '14years'=>['13YEARS','13SLIM','13PLUS'],
      '15years'=>['14YEARS','14SLIM','14PLUS'],
      '16years'=>['14YEARS','14SLIM','14PLUS']
  }

  def match_within_girls_top(value, item)
    GIRLS[value]
  end

  def match_within_girls_bottom(value, item)
    GIRLS[value]
  end
end