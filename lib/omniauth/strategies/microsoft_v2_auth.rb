require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies
    class MicrosoftV2Auth < OmniAuth::Strategies::OAuth2
      option :name, :microsoft_v2_auth

      DEFAULT_SCOPE = "openid email profile https://graph.microsoft.com/User.Read"

      option :client_options, {
        site:          'https://login.microsoftonline.com',
        authorize_url: '/common/oauth2/v2.0/authorize',
        token_url:     '/common/oauth2/v2.0/token'
      }

      option :authorize_options, [:scope]

      uid { raw_info["id"] }

      extra do
        {
          'raw_info' => raw_info,
          'params'   => access_token.params
        }
      end

      info do
        {
          email:      raw_info["mail"] || raw_info["userPrincipalName"],
          first_name: raw_info["givenName"],
          last_name:  raw_info["surname"],
          name:       full_name,
          nickname:   raw_info["userPrincipalName"],
        }
      end

      def raw_info
        @raw_info ||= access_token.get('https://graph.microsoft.com/v1.0/me').parsed
      end

      def authorize_params
        super.tap do |params|
          %w[display score auth_type].each do |v|
            if request.params[v]
              params[v.to_sym] = request.params[v]
            end
          end

          params[:scope] ||= DEFAULT_SCOPE
        end
      end

      def callback_url
        options[:redirect_uri] || (full_host + script_name + callback_path)
      end

      def full_name
        raw_info.values_at("givenName", "surname").compact.join(' ')
      end
    end
  end
end
