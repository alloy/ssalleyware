module SSAlleyWare
  DEBIAN_UBUNTU_ARCH_LINUX = "/etc/ssl/certs/ca-certificates.crt"
  FEDORA_RHEL              = "/etc/pki/tls/certs/ca-bundle.crt"
  OPENSUSE_SLE             = "/etc/ssl/ca-bundle.pem"
  SYSTEM_CA_CERT_PATHS     = [DEBIAN_UBUNTU_ARCH_LINUX, FEDORA_RHEL, OPENSUSE_SLE]

  def self.ca_cert_file=(path)
    @ca_cert_file = path
  end

  def self.ca_cert_file
    @ca_cert_file ||= system_ca_cert_file || bundled_ca_cert_file
  end

  def self.system_ca_cert_file
    SYSTEM_CA_CERT_PATHS.find do |path|
      File.exist?(path) && File.readable?(path)
    end
  end

  def self.bundled_ca_cert_file
    File.expand_path('../cacert.pem', __FILE__)
  end
end
