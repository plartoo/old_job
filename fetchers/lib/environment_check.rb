# checks that the machines gem and xml libraries are operating correctly for fetchers to work correctly

class EnvironmentCheck

  TEST_HTML =<<-EOF
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="en-US">
<script type="text/javascript">
<!--
var product = getProduct('9A2933F2-4044-11E0-B655-BA209EED7540');

product.setAttributeData(
  {
     att1: 'Muslin',
     att2: '10',
     att3: '',
     att4: ''
  },
  {
     atrsku: '842539033919',
     atrcost: '119.40',
     atrmsrp: '445.00',
     atrsell: '445.00',
	 atrwas: '',
	 atrdssku: 'ad90fc713',
     atretady: '01',
     atretayr: '0001',
     atrreleasedy: '',
     atrreleasemn: '',
     atrreleaseyr: '',
     atrdssku: 'ad90fc713',
     atrsuplsku: '',
     atronhand: '2'
  }
);
// -->
</script>
</body>
</html>
  EOF

  ERROR =<<-EOF
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  XML environment is not sane
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  nokogiri must be compiled against libxml2 version 2.7.7

  wget ftp://xmlsoft.org/libxml2/libxml2-2.7.7.tar.gz
  tar xvzf libxml2-2.7.7.tar.gz
  cd libxml2-2.7.7 && ./configure --prefix=/usr && make && sudo make install
  sudo gem uninstall nokogiri --version=1.4.1
  sudo gem install nokogiri --version=1.4.1 -- --with-xml2-include=/usr/local/include/libxml2 --with-xml2-lib=/usr/local/lib
  ldconfig # ensure library cache refreshed

  EOF
  
  def check_xml_behavior
    x = Nokogiri::HTML(TEST_HTML)
    x.text.match(/product\.setAttributeData/)
  end

  def check_environment
    check_xml_behavior
  end
  
end

# returns a zero exit code on success, non-zero exit code on failure
if $0 == __FILE__
  require 'rubygems'
  gem 'nokogiri', "=1.4.1"
  require 'nokogiri'
  
  check = EnvironmentCheck.new

  exit(0) if check.check_xml_behavior
  abort(EnvironmentCheck::ERROR)
end
