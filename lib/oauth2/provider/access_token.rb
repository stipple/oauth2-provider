module OAuth2
  class Provider
    
    class AccessToken
      attr_reader :authorization
      
      def initialize(resource_owner = nil, scopes = [], access_token = nil, error = nil)
        @resource_owner = resource_owner
        @scopes         = scopes
        @access_token   = access_token
        @error          = error && INVALID_REQUEST
        
        authorize!(access_token, error)
        validate!
      end
      
      def client
        valid? ? @authorization.client : nil
      end
      
      def owner
        valid? ? @authorization.owner : nil
      end
      
      def response_headers
        return {} if valid?
        {'WWW-Authenticate' => "OAuth2 error='#{ @error }'"}
      end
      
      def response_status
        case @error
          when INVALID_REQUEST, INVALID_TOKEN then 401
          when INSUFFICIENT_SCOPE                            then 403
                                                             else 200
        end
      end
      
      def valid?
        @error.nil?
      end
      
    private
      
      def authorize!(access_token, error)
        return unless @authorization = Model.find_access_token(access_token)
        @authorization.update_attribute(:access_token, nil) if error
      end
      
      def validate!
        return @error = INVALID_REQUEST    unless @access_token
        return @error = INVALID_TOKEN      unless @authorization and not @authorization.expired?
        return @error = INSUFFICIENT_SCOPE unless @authorization.in_scope?(@scopes)
        
        if @resource_owner and @authorization.owner != @resource_owner
          @error = INSUFFICIENT_SCOPE
        end
      end
    end
    
  end
end

