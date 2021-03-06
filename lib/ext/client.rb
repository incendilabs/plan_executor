module FHIR

  class Client

    attr_accessor :requests

    def record_requests(reply)
      @requests ||= []
      @requests << reply
    end

    def use_fhir_version(fhir_version)
      self.use_r4
      self.use_stu3 if fhir_version == :stu3
      self.use_dstu2 if fhir_version == :dstu2
    end

    def monitor_requests
      return if @decorated
      @decorated = true
      [:get, :put, :post, :delete, :head, :patch].each do |method|
        class_eval %Q{
          alias #{method}_original #{method}
          def #{method}(*args, &block)
            reply = #{method}_original(*args, &block)
            record_requests(reply)
            return reply
          end
        }
      end
    end

    def setup_security
      # TODO: implement oauth security?
      # options = self.get_oauth2_metadata_from_conformance
      # set_client_secrets(options) unless options.empty?
    end

    def set_client_secrets(options)
      puts "Using OAuth2 Options: #{options}"
      print 'Enter client id: '
      client_id = STDIN.gets.chomp
      print 'Enter client secret: '
      client_secret = STDIN.gets.chomp
      if client_id != "" && client_secret != ""
        options[:client_id] = client_id
        options[:client_secret] = client_secret
        # set_oauth2_auth(client,secret,authorizePath,tokenPath)
        self.set_oauth2_auth(options[:client_id], options[:client_secret], options[:authorize_url], options[:token_url])
      else
        puts "Ignoring OAuth2 credentials: empty id or secret. Using unsecured client..."
      end
    end

    def capability_statement_new(format = @default_format)
      if !@cached_capability_statement.nil? && format == @default_format
        return @cached_capability_statement
      end

      formats = [FHIR::Formats::ResourceFormat::RESOURCE_XML,
                 FHIR::Formats::ResourceFormat::RESOURCE_JSON,
                 FHIR::Formats::ResourceFormat::RESOURCE_XML_DSTU2,
                 FHIR::Formats::ResourceFormat::RESOURCE_JSON_DSTU2,
                 'application/xml',
                 'application/json']
      formats.insert(0, format)

      @cached_capability_statement = nil

      formats.each do |frmt|
        reply = get 'metadata', fhir_headers({ accept: "#{frmt}" })
        next unless reply.code == 200
        begin
          @cached_capability_statement = parse_reply(FHIR::DSTU2::Conformance, frmt, reply) if @fhir_version == :dstu2
          @cached_capability_statement = parse_reply(FHIR::STU3::CapabilityStatement, frmt, reply) if @fhir_version == :stu3
          @cached_capability_statement = parse_reply(FHIR::CapabilityStatement, frmt, reply) if @fhir_version != :dstu2 && @fhir_version != :stu3
        rescue
          @cached_capability_statement = nil
        end
        if @cached_capability_statement
          @default_format = frmt
          break
        end
      end
      @default_format = format if @default_format.nil?
      @cached_capability_statement
    end

    def fhir_patch(klass, id, patchset, options = {}, format = nil, additional_header = {})
      format ||= @default_format
      options = { resource: klass, id: id, format: format }.merge options
      headers = {}
      headers[:content_type] = "#{format}"
      headers[:prefer] = @return_preference if @use_return_preference
      headers.merge!(additional_header)
      if format == FHIR::Formats::ResourceFormat::RESOURCE_XML
        patchset = patchset.to_xml
      elsif format == FHIR::Formats::ResourceFormat::RESOURCE_JSON
        patchset = patchset.to_json
      end
      reply = patch resource_url(options), patchset, fhir_headers(headers)
      reply.resource = parse_reply(klass, format, reply)
      reply.resource_class = klass
      reply
    end

  end
end
