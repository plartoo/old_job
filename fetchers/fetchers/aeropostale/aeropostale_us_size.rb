module AeropostaleUsSize # :nodoc:
  def match_within_womens_top(value, item)
    return value if value.is_a?(Array)
    {
      'ONESZ'=>['XS','S','M','L','XL','XXL','PLUS']
    }[value] || value
  end

  def match_within_womens_bottom(value, item)
    return value if value.is_a?(Array)
    {
      '00 R' => '00',

      '0 S' => '0S',
      '0 R' => '0',
      '0 L' => '0L',

      '1/2 S' => ['1S','2S'],
      '1/2' => ['1','2'],
      '1/2 R' => ['1','2'],
      '1/2 L' => ['1L','2L'],

      '3/4 S' => ['3S','4S'],
      '3/4' => ['3','4'],
      '3/4 R' => ['3','4'],
      '3/4 L' => ['3L','4L'],

      '5/6 S' => ['5S','6S'],
      '5/6' => ['5','6'],
      '5/6 R' => ['5','6'],
      '5/6 L' => ['5L','6L'],

      '7/8 S' => ['7S','8S'],
      '7/8' => ['7','8'],
      '7/8 R' => ['7','8'],
      '7/8 L' => ['7L','8L'],

      '9/10 S' => ['9S','10S'],
      '9/10' => ['9','10'],
      '9/10 R' => ['9','10'],
      '9/10 L' => ['9L','10L'],

      '11/12 S' => ['11S','12S'],
      '11/12' => ['11','12'],
      '11/12 R' => ['11','12'],
      '11/12 L' => ['11L','12L'],

      '13/14 S' => ['13S','14S'],
      '13/14' => ['13','14'],
      '13/14 R' => ['13','14'],
      '13/14 L' => ['13L','14L'],

      '15/16 S' => ['15S','16S'],
      '15/16' => ['15','16'],
      '15/16 R' => ['15','16'],
      '15/16 L' => ['15L','16L'],

      '17/18 S' => ['17S','18S'],
      '17/18' => ['17','18'],
      '17/18 R' => ['17','18'],
      '17/18 L' => ['17L','18L'],

      'ONESZ'=>['XS','S','M','L','XL','XXL','PLUS']

    }[value] || value
  end

  def match_within_womens_accessories(value, item)
    return value if value.is_a?(Array)
    {
      'ONESZ' => 'ALL_SIZES'
    }[value] || value
  end


  def match_within_mens_top(value, item)
    return value if value.is_a?(Array)
    {
      # the following are for shorts, which are SWIMWEAR and are mysteriously classified as 'top' in clothing_type_group
      # <http://www.aeropostale.com/info/index.jsp?categoryId=3707085&backTo=3789169&savePath=&mainTitle=Guys^+Shorts%2FSwim+Sizing>
      '27' => 'XXS',
      '28' => 'XXS',
      '29' => 'XS',
      '30' => 'XS',
      '31' => 'XS',
      '32' => 'S',
      '33' => 'S',
      '34' => ['S','M'],
      '35' => 'M',
      '36' => 'M',
      '37' => 'L',
      '38' => 'L',
      '39' => 'L',
      '40' => 'XL',
      '41' => 'XL',
      '42' => 'XL',
      '43' => 'XXL',
      '44' => 'XXL',
      '45' => 'XXL',
      'ONESZ'=>['XS','S','M','L','XL','XXL','PLUS']
    }[value]
  end

  def match_within_mens_bottom(value, item)
    return value if value.is_a?(Array)
    {
      # <http://www.aeropostale.com/info/index.jsp?categoryId=3707085&backTo=3789169&savePath=&mainTitle=Guys^+Shorts%2FSwim+Sizing>
      '27' => 'XXS',
      '28' => 'XXS',
      '29' => 'XS',
      '30' => 'XS',
      '31' => 'XS',
      '32' => 'S',
      '33' => 'S',
      '34' => ['S','M'],
      '35' => 'M',
      '36' => 'M',
      '37' => 'L',
      '38' => 'L',
      '39' => 'L',
      '40' => 'XL',
      '41' => 'XL',
      '42' => 'XL',
      '43' => 'XXL',
      '44' => 'XXL',
      '45' => 'XXL',
      'ONESZ'=>['XS','S','M','L','XL','XXL','PLUS']
    }[value] || value
  end

  def match_within_mens_accessories(value, item)
    return value if value.is_a?(Array)
    {
      'ONESZ' => 'ALL_SIZES'
    }[value] || value
  end

end
