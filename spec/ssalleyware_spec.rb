require 'rubygems'
require 'bacon'
require 'mocha'
require 'mocha-on-bacon'

Bacon.summary_at_exit

$:.unshift File.expand_path("../../lib", __FILE__)
require "ssalleyware"

describe "SSAlleyWare, concerning the root CA certificates file" do
  before do
    SSAlleyWare.ca_cert_file = nil
    File.stubs(:readable?).returns(true)
  end

  def stub(stub_path)
    SSAlleyWare::SYSTEM_CA_CERT_FILES.each do |path|
      File.stubs(:exist?).with(path).returns(path == stub_path)
    end
  end

  it "returns the Debian/Ubuntu/Arch Linux one" do
    stub(SSAlleyWare::DEBIAN_UBUNTU_ARCH_LINUX)
    SSAlleyWare.ca_cert_file.should == SSAlleyWare::DEBIAN_UBUNTU_ARCH_LINUX
  end

  it "returns the Fedora/RHEL one" do
    stub(SSAlleyWare::FEDORA_RHEL)
    SSAlleyWare.ca_cert_file.should == SSAlleyWare::FEDORA_RHEL
  end

  it "returns the openSUSE/SLE" do
    stub(SSAlleyWare::OPENSUSE_SLE)
    SSAlleyWare.ca_cert_file.should == SSAlleyWare::OPENSUSE_SLE
  end

  it "returns the one bundled with the gem if none of the system versions is found" do
    File.stubs(:exist?).returns(false)
    SSAlleyWare.ca_cert_file.should == SSAlleyWare::BUNDLED_CA_CERT_FILE
  end

  it "returns the one bundled with the gem if none of the system versions is readable" do
    File.stubs(:exist?).returns(true)
    File.stubs(:readable?).returns(false)
    SSAlleyWare.ca_cert_file.should == SSAlleyWare::BUNDLED_CA_CERT_FILE
  end

  it "always returns the one that was specified by the user" do
    File.stubs(:exist?).returns(true)
    SSAlleyWare.ca_cert_file = '/path/to/cacert.pem'
    SSAlleyWare.ca_cert_file.should == '/path/to/cacert.pem'
  end

  it "always uses the one bundled with the gem" do
    File.stubs(:exist?).returns(true)
    SSAlleyWare.use_bundled_ca_cert_file!
    SSAlleyWare.ca_cert_file.should == SSAlleyWare::BUNDLED_CA_CERT_FILE
  end
end

class Verifyer
  include SSAlleyWare::CertificateVerification
  attr_accessor :hostname
end

describe "SSAlleyWare::CertificateVerification" do
  def fixture_cert(name)
    File.expand_path("../fixtures/certificates/#{name}", __FILE__)
  end

  def fixture_cert_read(name)
    File.read(fixture_cert(name))
  end

  before do
    @verifyer                   = Verifyer.new
    SSAlleyWare.ca_cert_file    = fixture_cert('root_ca.pem')
    @root_ca_cert               = fixture_cert_read('root_ca.pem')
    @intermediate_ca_cert       = fixture_cert_read('intermediate_ca.pem')
    @server_cert                = fixture_cert_read('server.pem')
    @other_intermediate_ca_cert = fixture_cert_read('other_intermediate_ca.pem')
  end

  it "returns true for each successive certificate if signed by the ancestors in the chain" do
    @verifyer.ssl_verify_peer(@intermediate_ca_cert).should == true
    @verifyer.ssl_verify_peer(@server_cert).should == true
  end

  it "returns false if a certificate is not signed by the ancestor chain" do
    @verifyer.ssl_verify_peer(@other_intermediate_ca_cert).should == true
    @verifyer.expects(:fail).with { |error| error.class == OpenSSL::OpenSSLError }
    @verifyer.ssl_verify_peer(@server_cert).should == false
  end

  it "returns false if a certificate data is not a valid certificate" do
    @verifyer.ssl_verify_peer("BAD").should == false
  end

  it "does not fail if a root CA certificate is given, which the server *may* do" do
    @verifyer.ssl_verify_peer(@root_ca_cert).should == true
    @verifyer.ssl_verify_peer(@intermediate_ca_cert).should == true
    @verifyer.ssl_verify_peer(@server_cert).should == true
  end

  it "does not fail if any other certificate is send multiple times, which some servers do (imap.gmail.com)" do
    @verifyer.ssl_verify_peer(@intermediate_ca_cert).should == true
    @verifyer.ssl_verify_peer(@intermediate_ca_cert).should == true
    @verifyer.ssl_verify_peer(@intermediate_ca_cert).should == true
    @verifyer.ssl_verify_peer(@server_cert).should == true
  end

  it "verifies the hostname of the last certificate" do
    @verifyer.ssl_verify_peer(@intermediate_ca_cert)
    @verifyer.ssl_verify_peer(@server_cert)
    @verifyer.hostname = 'server.ssalleyware.local'
    @verifyer.ssl_handshake_completed.should == true
  end

  it "fails hostname verification if the hostname does not match the certificate" do
    @verifyer.ssl_verify_peer(@intermediate_ca_cert)
    @verifyer.ssl_verify_peer(@server_cert)
    @verifyer.hostname = 'server.somewhere-else.local'
    @verifyer.expects(:fail).with { |error| error.class == OpenSSL::OpenSSLError }
    @verifyer.ssl_handshake_completed.should == false
  end
end
