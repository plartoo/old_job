module AcneUsSize # :nodoc:
  GIRLS = {
      'Newborn' => '0-3MONTHS',
      '0-3 months' => '0-3MONTHS',
      '3-6 months' => '3-6MONTHS',
      '6-9 months' => '6-12MONTHS',
      '6-12 months' => '6-12MONTHS',
      '9-12 months' => '6-12MONTHS',
      '12-18 months' => '12-18MONTHS',
      '18-24 months' => '18-24MONTHS',
      '3 M' => ['0-3MONTHS','3-6MONTHS'],
      '6 M' => ['3-6MONTHS','6-12MONTHS'],
      '9 M' => '6-12MONTHS',
      '12 M' => ['6-12MONTHS','12-18MONTHS'],
      '18 M'=>['12-18MONTHS','18-24MONTHS'],
      '24 M'=>['18-24MONTHS','2YEARS'],

      '3 months'=>['0-3MONTHS','3-6MONTHS'],
      '6 months'=>['3-6MONTHS','6-12MONTHS'],
      '9 months'=>'6-12MONTHS',
      '12 months'=>['6-12MONTHS','12-18MONTHS'],
      '18 months'=>['12-18MONTHS','18-24MONTHS'],
      '24 months'=>'18-24MONTHS',

      '2 YRS'=>'18-24MONTHS',
      '3 YRS'=>'3',
      '4 YRS'=>['4','4SLIM','4PLUS'],
      '5 YRS'=>['5','5SLIM','5PLUS'],
      '6 YRS'=>['6','6SLIM','6PLUS'],
      '7 YRS'=>['7','7SLIM','7PLUS'],
      '8 YRS'=>['8','8SLIM','8PLUS'],
      '9 YRS'=>['9','9SLIM','9PLUS'],
      '10 YRS'=>['10','10SLIM','10PLUS'],
      '11 YRS'=>['11','11SLIM','11PLUS'],
      '12 YRS'=>['12','12SLIM','12PLUS'],
      '13 YRS'=>['13','13SLIM','13PLUS'],
      '14 YRS'=>['14','14SLIM','14PLUS'],
      '15 YRS'=>['15','15SLIM','15PLUS'],
      '16 YRS'=>['16','16SLIM','16PLUS'],

      'ONE SIZE' => 'ALL_SIZES'
  }

  def match_within_girls_bottom(value, item)
    GIRLS[value]
  end

  def match_within_girls_top(value, item)
    GIRLS[value]
  end

  def match_within_girls_accessories(value, item)
    GIRLS[value]
  end

  BOYS = {
      'Newborn' => '0-3MONTHS',
      '0-3 months' => '0-3MONTHS',
      '3-6 months' => '3-6MONTHS',
      '6-9 months' => '6-12MONTHS',
      '6-12 months' => '6-12MONTHS',
      '9-12 months' => '6-12MONTHS',
      '12-18 months' => '12-18MONTHS',
      '18-24 months' => '18-24MONTHS',
      '3 M' => ['0-3MONTHS','3-6MONTHS'],
      '6 M' => ['3-6MONTHS','6-12MONTHS'],
      '9 M' => '6-12MONTHS',
      '12 M' => ['6-12MONTHS','12-18MONTHS'],
      '18 M'=>['12-18MONTHS','18-24MONTHS'],
      '24 M'=>['18-24MONTHS','2YEARS'],

      '3 months'=>['0-3MONTHS','3-6MONTHS'],
      '6 months'=>['3-6MONTHS','6-12MONTHS'],
      '9 months'=>'6-12MONTHS',
      '12 months'=>['6-12MONTHS','12-18MONTHS'],
      '18 months'=>['12-18MONTHS','18-24MONTHS'],
      '24 months'=>'18-24MONTHS',

      '2 YRS'=>'18-24MONTHS',
      '3 YRS'=>'3',
      '4 YRS'=>['4','4SLIM','4HUSKY'],
      '5 YRS'=>['5','5SLIM','5HUSKY'],
      '6 YRS'=>['6','6SLIM','6HUSKY'],
      '7 YRS'=>['7','7SLIM','7HUSKY'],
      '8 YRS'=>['8','8SLIM','8HUSKY'],
      '9 YRS'=>['9','9SLIM','9HUSKY'],
      '10 YRS'=>['10','10SLIM','10HUSKY'],
      '11 YRS'=>['11','11SLIM','11HUSKY'],
      '12 YRS'=>['12','12SLIM','12HUSKY'],
      '13 YRS'=>['13','13SLIM','13HUSKY'],
      '14 YRS'=>['14','14SLIM','14HUSKY'],
      '15 YRS'=>['15','15SLIM','15HUSKY'],
      '16 YRS'=>['16','16SLIM','16HUSKY'],

      'ONE SIZE' => 'ALL_SIZES'
  }

  def match_within_boys_bottom(value, item)
    BOYS[value]
  end

  def match_within_boys_top(value, item)
    BOYS[value]
  end

  def match_within_boys_accessories(value, item)
    BOYS[value]
  end

  def match_within_womens_top(value, item)
    {
      # ref. <http://www.acnestudios.com//category/shopping-help/?pageId=1648&parentCategory=21>
      # SWE to US
      '34' => ['4','XS'],
      '36' => ['6','S'],
      '38' => ['8','M'],
      '40' => ['10','L'],
      '42' => ['12','XL']
    }[value]
  end

  def match_within_womens_bottom(value, item)
    if value.match(%r#\d+/\d+#)
      waist = value.match(%r#(\d+)/\d+#)[1]
      inseam = value.match(%r#\d+/(\d+)#)[1]
      if inseam.to_i == 32
        waist + 'R'
      elsif inseam.to_i > 32
        waist + 'L'
      else
        waist + 'S'
      end
    else
      {
        '70 cm' => 'XS',
        '80 cm' => 'M',
        '85 cm' => 'M',
        '90 cm' => 'L',
        '95 cm' => 'L',
        '105 cm' => 'XL',
        # ref. <http://www.acnestudios.com//category/shopping-help/?pageId=1648&parentCategory=21>
        # SWE to US
        '34' => ['4','XS'],
        '36' => ['6','S'],
        '38' => ['8','M'],
        '40' => ['10','L'],
        '42' => ['12','XL']
      }[value]
    end
end

  def match_within_womens_accessories(value, item)
    {
      'One Size' => 'ALL_SIZES'
    }[value]
  end

  def match_within_womens_intimate(value, item)
    {
      'One Size' => ['XS','S','M','L','XL','XXL']
    }[value]
  end

  def match_within_mens_top(value, item)
    {
      # ref. <http://www.acnestudios.com//category/shopping-help/?pageId=1648&parentCategory=21>
      # SWE to US
      '46' => ['36','XS'],
      '48' => ['38','S'],
      '50' => ['40','M'],
      '52' => ['41','L'],
      '54' => ['44','XL']
    }[value]
  end

  def match_within_mens_bottom(value, item)
    if value.match(%r#\d+/\d+#) # like '31/34'
      value.gsub(%r#/#,'X')
    else
      {
        '70 cm' => 'XS',
        '80 cm' => 'M',
        '85 cm' => 'M',
        '90 cm' => 'L',
        '95 cm' => 'L',
        '105 cm' => 'XL',
        # ref. <http://www.acnestudios.com//category/shopping-help/?pageId=1648&parentCategory=21>
        # SWE to US
        '46' => ['36','XS'],
        '48' => ['38','S'],
        '50' => ['40','M'],
        '52' => ['41','L'],
        '54' => ['44','XL']
      }[value]
    end
  end

end
