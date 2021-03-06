module EuroShoeToUsShoe # :nodoc:
  # ref. <http://www.zappos.com/measure.zhtml?gclid=CI3MnubUu6ECFRkcawodnR-LAQ>
  def match_within_womens_shoe(value, item)
    {
      '34.5' => '3.5',
      '35' => ['4','4.5','5'],
      '35.5' => '5.5',
      '36' => ['5','5.5','6'],
      '36.5' => '6.5',
      '37' => ['6','6.5','7'],
      '37.5' => '7.5',
      '38' => ['7','7.5','8'],
      '38.5' => '8.5',
      '39' => ['8','8.5','9'],
      '39.5' => '9.5',
      '40' => ['9','9.5','10'],
      '40.5' => '10.5',
      '41' => ['10','10.5','11'],
      '41.5' => '11.5',
      '42' => ['11','11.5','12'],
      '42.5' => '12.5',
      '43' => ['12','12.5','13'],
      '43.5' => '13.5',
      '44' => ['13','13.5','14']
    }[value]
  end

  def match_within_mens_shoe(value, item)
    {
      '39' => ['6','6.5'],
      '39.5' => '7',
      '40' => ['7','7.5'],
      '40.5' => '7.5',
      '41' => ['7.5','8','8.5'],
      '41.5' => '8.5',
      '42' => ['8.5','9','9.5'],
      '42.5' => '9.5',
      '43' => ['9.5','10','10.5'],
      '43.5' => '10.5',
      '44' => ['10.5','11','11.5'],
      '44.5' => '11.5',
      '45' => ['11.5','12'],
      '45.5' => '12.5',
      '46' => '13',
      '46.5' => '13.5',
      '47' => '14',
      '47.5' => '14.5',
      '48' => '15',
      '48.5' => '15.5',
      '49' => '16'
    }[value]
  end
end