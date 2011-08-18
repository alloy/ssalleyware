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

    # It's important that we try to not add a certificate to the store that's
    # already in the store, because OpenSSL::X509::Store will raise an exception.
    def ssl_verify_peer(cert_string)
      cert = OpenSSL::X509::Certificate.new(cert_string)
      # Some servers send the same certificate multiple times. I'm not even joking... (gmail.com)
      return true if cert == @last_seen_cert
      @last_seen_cert = cert

      if ca_store.verify(@last_seen_cert)
        # A server may send the root certificate, which we already have and thus
        # should not be added to the store again.
        ca_store.add_cert(@last_seen_cert) unless @last_seen_cert.root?
        true
      else
        hostname = respond_to?(:hostname) ? self.hostname : nil
        fail OpenSSL::OpenSSLError.new("unable to verify the server certificate#{" of `#{hostname}'" if hostname}")
        false
      end
    end

    def ssl_handshake_completed
      if respond_to?(:hostname) && hostname = self.hostname
        unless OpenSSL::SSL.verify_certificate_identity(@last_seen_cert, hostname)
          fail OpenSSL::OpenSSLError.new("the hostname `#{hostname}' does not match the server certificate")
          false
        else
          true
        end
      else
        warn "Skipping hostname verification because `#{self.class.name}#hostname' is not available."
        false
      end
    end
  end
end

module OpenSSL
  module X509
    class Certificate
      def ==(other)
        other.respond_to?(:to_pem) && to_pem == other.to_pem
      end

      # A serial *must* be unique for each certificate. Self-signed certificates,
      # and thus root CA certificates, have the same `issuer' as `subject'.
      def top_level?
        serial == serial && issuer.to_s == subject.to_s
      end
      alias_method :root?, :top_level?
      alias_method :self_signed?, :top_level?
    end
  end
end
