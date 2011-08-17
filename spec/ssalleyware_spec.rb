require 'rubygems'
require 'bacon'
require 'mocha'
require 'mocha-on-bacon'

Bacon.summary_at_exit

$:.unshift File.expand_path("../../lib", __FILE__)
require "ssalleyware"

describe "SSAlleyWare, concerning the root CA certificates file" do
  it "returns the Debian/Ubuntu/Arch Linux one" do
    SSAlleyWare.ca_cert_file.should == "/etc/ssl/certs/ca-certificates.crt"
  end

  it "returns the Fedora/RHEL one" do
    SSAlleyWare.ca_cert_file.should == "/etc/pki/tls/certs/ca-bundle.crt"
  end

  it "returns the Debian/Ubuntu/Arch Linux one" do
    SSAlleyWare.ca_cert_file.should == "/etc/ssl/ca-bundle.pem"
  end

  it "returns the one bundled with the gem if none of the system versions is found" do
    SSAlleyWare.ca_cert_file.should == File.expand_path("../../lib/cacert-20110817.pem", __FILE__)
  end

  it "returns the one bundled with the gem if none of the system versions is readable" do
    SSAlleyWare.ca_cert_file.should == File.expand_path("../../lib/cacert-20110817.pem", __FILE__)
  end

  it "always returns the one that was specified by the user" do
    SSAlleyWare.ca_cert_file = '/path/to/cacert.pem'
    SSAlleyWare.ca_cert_file.should == '/path/to/cacert.pem'
  end
end
