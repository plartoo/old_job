require File.dirname(__FILE__) + '/test_helper'

class ClothingTypeMatcherTest < Test::Unit::TestCase

  def setup
    @fetcher_class = Victoriassecret
    ClothingTypeMatcher.i18n_version = 'us'
    ClothingTypeMatcher.fetcher_class = nil
  end

  Assertion_Pairs = [
                     ["Yanuk 6-pocket classic jean in the Recycled wash. 7.5\" rise, 33\" inseam. 99% Cotton/1% Elastic.", :JEANS],
                     ["This hand-crafted tee is adorned with Swarovski crystals. 100% Cotton.",
                      :TSHIRT],
                     ["Alice & Olivia tank with gold & bronze sequin detail. 95% Modal/5% Spandex",
                      :CASUAL_SHIRT],
                     ["Ana Nonza cami with rolled edges in Wine. 100% Cotton.",
                      :CASUAL_SHIRT],
                     ["Ana Capri stretch tube top in Blue/Mint stripes. 47% Poly/46% Rayon/7% Spandex",
                      :CASUAL_SHIRT],
                     ["Camp Beverly Hills short-sleeve pique polo in Banana. 100% Cotton.",
                      :CASUAL_SHIRT],
                     ["Polo jeans", :JEANS],
                     ["Catherine Malandrino long-sleeve v-neck knit sweater in White. 100% Pima Cotton.", :SWEATER],
                     ["Catherine Malandrino butterfly blouse in Sorbet/Coral. 78% Silk/22% Wool.",
                      :CASUAL_SHIRT],
                     ["Beau & Eros french terry culottes in Honeydew. 7\" rise, 23\" inseam. 46% Rayon/46% Poly/8% Spandex.", :CASUAL_PANTS],
                     ["Catherine Malandrino snap front silk trench coat in Sorbet. Shell: 70% Silk/30% Cotton Satin. Lining: 100% Acetate.", :OUTERWEAR],
                     ["575 denim knee length denim skirt with extended waist tab in the Light wash. Approximately 20\" in length. 97% Cotton/3% Lycra.", :SKIRT],
                     ["Alice & Olivia wide waistband trouser in pink/white stripes. 7.5\" rise, 33.5\" inseam. 100% Cotton.",
                      :CASUAL_PANTS],
                     ["frankie b maui trench, white/green/pink (final sale)",
                      :OUTERWEAR],
                     ["Generra wrinkled leather blazer in Bisque. 100% Leather. Lining: 100% Cotton.",
                      :SPORTCOAT],
                     ["Gentle Fawn zip windbreaker in White. 95% Cotton/5% Spandex.",
                      :OUTERWEAR],
                     ["Iisli fur shawl in White with sequin trim. 100% Rabbit fur. Lining: 100% Acetate.",
                      :CASUAL_SHIRT],
                     ["J.P. & Mattie empire camisole with bow detail on front. 97% Cotton/3% Spandex.",
                      :CASUAL_SHIRT],
                     ["Three filigree charm necklace is handmade in delicate 14k gold and is knotted on a leather cord with gold clasp.",
                      :JEWELRY],
                     ["Handmade filigree silver charms dangle on two delicate silver chains for an easy layered look. One spring ring clasp. 16\" long",
                      :JEWELRY],
                     ["Beau & The mixed moon chain is comprised of 3 brushed sterling silver moons interspersed on a chain. The middle moon measures 1 inch across and the tow side moons each measure .75 inches. The necklace measures 17 inches with an additional 2 inches of adjustable chain.",
                      :JEWELRY],
                     ["Lavit brazilian cut panty in a basic tulle. 88% Polyamide/12% Spandex.",
                      :INTIMATES],
                     ["Lavit underwire demi bra in a basic tulle. 88% Polyamide/12% Spandex.",
                      :INTIMATES],

                     ["Lavit underwire lingerie in a basic tulle. 88% Polyamide/12% Spandex.",
                      :INTIMATES],

                     ["Washed Corduroy Five Pocket.", :CASUAL_PANTS],
                     ["v-neck sweater.", :SWEATER],
                     ["Colorblock v-neck", :CASUAL_SHIRT],
                     ["Printed Scoop Neck", :CASUAL_SHIRT],

                     ["Arles Python Slingback", :SHOES],
                     ["Logo Tunic", :CASUAL_SHIRT],
                     ["Lurex Hooded Capelet", :OUTERWEAR]]

  def test_clothing_type_matching
    item = Item.new
    Assertion_Pairs.each do |text, type_sym|
      item.description = text
      item.dept = :womens
      assert_equal(ClothingType[type_sym, :womens], ClothingTypeMatcher.determine_clothing_type(ClothingTypeMatcher.fetcher_class,item), text)
    end
  end

  def test_nil_type
    item = Item.new
    item.description = "none"
    item.dept = :womens
    ClothingTypeMatcher.fetcher_class = @fetcher_class
    assert_equal(nil, ClothingTypeMatcher.determine_clothing_type(ClothingTypeMatcher.fetcher_class,item))
  end

  def test_load_patterns_calls_load_fetcher_specific_clothing_type_patterns_if_fetcher_class_variable_is_set
    ClothingTypeMatcher.fetcher_class = @fetcher_class
    ClothingTypeMatcher.expects(:load_fetcher_specific_clothing_type_patterns)
    ClothingTypeMatcher.load_patterns
  end

  def test_load_patterns_must_not_call_load_fetcher_specific_clothing_type_patterns_if_fetcher_class_variable_is_not_set
    ClothingTypeMatcher.fetcher_class = nil
    ClothingTypeMatcher.expects(:load_fetcher_specific_clothing_type_patterns).never
    ClothingTypeMatcher.load_patterns
  end

  def test_load_patterns_concatenates_common_patterns_to_retailer_specific_ones
    ClothingTypeMatcher.fetcher_class = @fetcher_class
    return_this = {"girls" => [[/test/, :TEST]]}
    ClothingTypeMatcher.expects(:load_fetcher_specific_clothing_type_patterns).returns(return_this)
    patterns = ClothingTypeMatcher.load_patterns
    assert_equal patterns["girls"].first, return_this["girls"].first
  end
end
