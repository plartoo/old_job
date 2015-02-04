module UsTopToUkTop # :nodoc:
  def match_within_womens_top(value, item)
    {
      'PLUS1X'=>'22',
      '0'=>'4',
      '2'=>'6',
      '4'=>'8',
      '6'=>'10',
      '8'=>'12',
      '10'=>'14',
      '12'=>'16',
      '14'=>'18',
      '16'=>'20',
      '18'=>'22',

      'P0'=>'P4',
      'P2'=>'P6',
      'P4'=>'P8',
      'P6'=>'P10',
      'P8'=>'P12',
      'P10'=>'P14',
      'P12'=>'P16',
      'P14'=>'P18',
      'P16'=>'P20',
      'P18'=>'P22',

      'MAT0'=>'MAT4',
      'MAT2'=>'MAT6',
      'MAT4'=>'MAT8',
      'MAT6'=>'MAT10',
      'MAT8'=>'MAT12',
      'MAT10'=>'MAT14',
      'MAT12'=>'MAT16',
      'MAT14'=>'MAT18',
      'MAT16'=>'MAT20',
    }[value]
  end

  BOYS_GIRLS = {
    '2T'=>'2YEARS',
    '3T'=>'3YEARS',
    '4T'=>['4YEARS', '4HUSKY', '4SLIM'],
    '5T'=>['5YEARS', '5HUSKY', '5SLIM'],

    '4'=>'4YEARS',
    '5'=>'5YEARS',
    '6'=>'6YEARS',
    '7'=>'7YEARS',
    '8'=>'9YEARS',
    '9'=>'10YEARS',
    '10'=>'10YEARS',
    '12'=>'11YEARS',
    '13'=>'12YEARS',
    '14'=>'13YEARS',
    '15'=>'14YEARS',
    '16'=>'14YEARS',
    '17'=>'15YEARS',
    '18'=>'15YEARS',
    '19'=>'16YEARS',
    '20'=>'16YEARS',

    '4SLIM'=>'4SLIM',
    '5SLIM'=>'5SLIM',
    '6SLIM'=>'6SLIM',
    '7SLIM'=>'7SLIM',
    '8SLIM'=>'9SLIM',
    '9SLIM'=>'10SLIM',
    '10SLIM'=>'10SLIM',
    '12SLIM'=>'11SLIM',
    '13SLIM'=>'12SLIM',
    '14SLIM'=>'13SLIM',
    '15SLIM'=>'14SLIM',
    '16SLIM'=>'14SLIM',
    '17SLIM'=>'15SLIM',
    '18SLIM'=>'15SLIM',
    '19SLIM'=>'16SLIM',
    '20SLIM'=>'16SLIM',

    '4HUSKY'=>'4HUSKY',
    '5HUSKY'=>'5HUSKY',
    '6HUSKY'=>'6HUSKY',
    '7HUSKY'=>'7HUSKY',
    '8HUSKY'=>'9HUSKY',
    '9HUSKY'=>'10HUSKY',
    '10HUSKY'=>'10HUSKY',
    '12HUSKY'=>'11HUSKY',
    '13HUSKY'=>'12HUSKY',
    '14HUSKY'=>'13HUSKY',
    '15HUSKY'=>'14HUSKY',
    '16HUSKY'=>'14HUSKY',
    '17HUSKY'=>'15HUSKY',
    '18HUSKY'=>'15HUSKY',
    '19HUSKY'=>'16HUSKY',
    '20HUSKY'=>'16HUSKY',

    'XS'=>['4YEARS', '4HUSKY', '4SLIM'],
    'S'=>['6YEARS', '6HUSKY', '6SLIM'],
    'M'=>['8YEARS', '8HUSKY', '8SLIM'],
    'L'=>['11YEARS', '11HUSKY', '11SLIM'],
    'XL'=>['13YEARS', '13HUSKY', '13SLIM'],
    'XXL'=>['15YEARS', '15HUSKY', '15SLIM']
  }

  def match_within_girls_top(value, item)
    BOYS_GIRLS[value]
  end

  def match_within_boys_top(value, item)
    BOYS_GIRLS[value]
  end

end
