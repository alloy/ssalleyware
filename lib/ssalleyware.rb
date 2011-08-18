module SSAlleyWare
  DEBIAN_UBUNTU_ARCH_LINUX = "/etc/ssl/certs/ca-certificates.crt"
  FEDORA_RHEL              = "/etc/pki/tls/certs/ca-bundle.crt"
  OPENSUSE_SLE             = "/etc/ssl/ca-bundle.pem"
  SYSTEM_CA_CERT_FILES     = [DEBIAN_UBUNTU_ARCH_LINUX, FEDORA_RHEL, OPENSUSE_SLE]
  BUNDLED_CA_CERT_FILE     = File.expand_path('../cacert.pem', __FILE__)

  def self.ca_cert_file=(path)
    @ca_cert_file = path
  end

  def self.ca_cert_file
    @ca_cert_file ||= system_ca_cert_file || bundled_ca_cert_file
  end

  def self.system_ca_cert_file
    SYSTEM_CA_CERT_FILES.find do |path|
      File.exist?(path) && File.readable?(path)
    end
  end

  def self.bundled_ca_cert_file
    BUNDLED_CA_CERT_FILE
  end

  def self.use_bundled_ca_cert_file!
    self.ca_cert_file = bundled_ca_cert_file
  end

  module CertificateVerification
    def self.included(_)
      require 'openssl'
      super
    end

    def self.extended(_)
      require 'openssl'
      super
    end

    def ca_store
      unless @ca_store
        if file = SSAlleyWare.ca_cert_file
          @ca_store = OpenSSL::X509::Store.new
          @ca_store.add_file(file)
        else
          fail "you must specify a file with root CA certificates through `SSAlleyWare.ca_cert_file='"
        end
      end
      @ca_store
    end

    def ssl_verify_peer(cert_string)
      @last_seen_cert = OpenSSL::X509::Certificate.new(cert_string)
      if ca_store.verify(@last_seen_cert)
        begin
          ca_store.add_cert(@last_seen_cert)
        rescue OpenSSL::X509::StoreError => e
          # This is so lame, but there appears to be no way to check this in a simple way.
          #
          # TODO It _might_ be possible to do this with the C api.
          raise e unless e.message == 'cert already in hash table'
        end
        true
      else
        fail OpenSSL::OpenSSLError.new("unable to verify the server certificate of `#{@hostname}'")
        false
      end
    end
  end
end
