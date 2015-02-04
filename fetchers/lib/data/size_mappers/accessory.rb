module Accessory # :nodoc:
  ACCESSORY_SIZES = {
                      'one size' => 'ALL_SIZES',
                      'One Size' => 'ALL_SIZES',
                      'OneSize' => 'ALL_SIZES',
                      'One Sz' => 'ALL_SIZES',
                      'ONE SZ' => 'ALL_SIZES',
                      'ONESIZE' => 'ALL_SIZES',
                      'Unsized' => 'ALL_SIZES'
                    }
  def match_within_womens_accessories(value, item)
    ACCESSORY_SIZES[value]
  end

  def match_within_mens_accessories(value, item)
    ACCESSORY_SIZES[value]
  end
end