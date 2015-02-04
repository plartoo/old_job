module UkTopToUsTop # :nodoc:
  def match_within_womens_top(value, item)
    {
      '4'=>'0',
      '6'=>'2',
      '8'=>'4',
      '10'=>'6',
      '12'=>'8',
      '14'=>'10',
      '16'=>'12',
      '18'=>'14',
      '20'=>'16',
      '22'=>'18',

      'P4'=>'P0',
      'P6'=>'P2',
      'P8'=>'P4',
      'P10'=>'P6',
      'P12'=>'P8',
      'P14'=>'P10',
      'P16'=>'P12',
      'P18'=>'P14',
      'P20'=>'P16',
      'P22'=>'P18',

      'MAT4'=>'MAT0',
      'MAT6'=>'MAT2',
      'MAT8'=>'MAT4',
      'MAT10'=>'MAT6',
      'MAT12'=>'MAT8',
      'MAT14'=>'MAT10',
      'MAT16'=>'MAT12',
      'MAT18'=>'MAT14',
      'MAT20'=>'MAT16'
    }[value]
  end

  BOYS_GIRLS = {
    '2YEARS'=>'2T',
    '3YEARS'=>'3T',

    '4YEARS'=>'4',
    '5YEARS'=>'5',
    '6YEARS'=>'6',
    '7YEARS'=>'7',
    '9YEARS'=>'8',
    '10YEARS'=>['9','10'],
    '11YEARS'=>'12',
    '12YEARS'=>'13',
    '13YEARS'=>'14',
    '14YEARS'=>['15','16'],
    '15YEARS'=>['17','18'],
    '16YEARS'=>['19','20'],

    '4SLIM'=>'4SLIM',
    '5SLIM'=>'5SLIM',
    '6SLIM'=>'6SLIM',
    '7SLIM'=>'7SLIM',
    '9SLIM'=>'8SLIM',
    '10SLIM'=>['9SLIM','10SLIM'],
    '11SLIM'=>'12SLIM',
    '12SLIM'=>'13SLIM',
    '13SLIM'=>'14SLIM',
    '14SLIM'=>['15SLIM','16SLIM'],
    '15SLIM'=>['17SLIM','18SLIM'],
    '16SLIM'=>['19SLIM','20SLIM'],

    '4HUSKY'=>'4HUSKY',
    '5HUSKY'=>'5HUSKY',
    '6HUSKY'=>'6HUSKY',
    '7HUSKY'=>'7HUSKY',
    '9HUSKY'=>'8HUSKY',
    '10HUSKY'=>['9HUSKY','10HUSKY'],
    '11HUSKY'=>'12HUSKY',
    '12HUSKY'=>'13HUSKY',
    '13HUSKY'=>'14HUSKY',
    '14HUSKY'=>['15HUSKY','16HUSKY'],
    '15HUSKY'=>['17HUSKY','18HUSKY'],
    '16HUSKY'=>['19HUSKY','20HUSKY']
  }

  def match_within_girls_top(value, item)
    BOYS_GIRLS[value]
  end

  def match_within_boys_top(value, item)
    BOYS_GIRLS[value]
  end

end
