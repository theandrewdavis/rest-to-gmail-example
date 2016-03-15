# encoding: utf-8

require 'gmail'
require 'json'
require 'net/http'
require 'sinatra'
require 'uri'

class GmailSender
    class NoAccessTokenError < StandardError
    end

    attr_reader :from, :client_id, :client_secret, :refresh_token, :access_token

    def initialize(from:, client_id:, client_secret:, refresh_token:)
        @from = from
        @client_id = client_id
        @client_secret = client_secret
        @refresh_token = refresh_token
        @access_token = nil
    end

    def refresh!
        uri = URI.parse('https://accounts.google.com/o/oauth2/token')
        response = Net::HTTP.post_form(uri, {
            client_id:  @client_id,
            client_secret:  @client_secret,
            refresh_token:  @refresh_token,
            grant_type: 'refresh_token',
        })
        @access_token = JSON.parse(response.body)['access_token']
    end

    def send(to:, subject:, body:)
        raise NoAccessTokenError if not @access_token
        Gmail.connect!(:xoauth, @from, token: @access_token) do |gmail|
            mail = Mail.new(to: to, subject: subject, body: body)
            gmail.deliver(mail)
        end
    end
end

post '/' do
    return status 400 if not params.key?('subject') or not params.key?('body')

    config_filepath = File.join(File.dirname(__FILE__), 'secret', 'config.json')
    oauth_filepath = File.join(File.dirname(__FILE__), 'secret', 'client_id.json')
    config = JSON.parse(File.read(config_filepath))
    oauth = JSON.parse(File.read(oauth_filepath))

    sender = GmailSender.new(**{
        from: config['from'],
        client_id: oauth['installed']['client_id'],
        client_secret: oauth['installed']['client_secret'],
        refresh_token: config['refresh_token']
    })
    sender.refresh!
    sender.send(to: config['to'], subject: params[:subject], body: params[:body])
    status 200
end
