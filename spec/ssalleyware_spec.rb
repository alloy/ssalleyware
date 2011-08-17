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
    SSAlleyWare::SYSTEM_CA_CERT_PATHS.each do |path|
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
    SSAlleyWare.ca_cert_file.should == File.expand_path("../../lib/cacert.pem", __FILE__)
  end

  it "returns the one bundled with the gem if none of the system versions is readable" do
    File.stubs(:exist?).returns(true)
    File.stubs(:readable?).returns(false)
    SSAlleyWare.ca_cert_file.should == File.expand_path("../../lib/cacert.pem", __FILE__)
  end

  it "always returns the one that was specified by the user" do
    File.stubs(:exist?).returns(true)
    SSAlleyWare.ca_cert_file = '/path/to/cacert.pem'
    SSAlleyWare.ca_cert_file.should == '/path/to/cacert.pem'
  end
end
