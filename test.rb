# encoding: utf-8

ENV['RACK_ENV'] = 'test'

require 'simplecov'
SimpleCov.start

require 'minitest/autorun'
require 'rack/test'
require_relative 'server'

class GmailSenderTest < Minitest::Test
    def setup
        @initialize_params = {
            from: 'from@email.com',
            client_id: 'ID012345',
            client_secret: 'SECRET012345',
            refresh_token: 'REFRESH012345'
        }
    end

    def test_refresh
        sender = GmailSender.new(**@initialize_params)
        response = MiniTest::Mock.new
        response.expect(:body, {access_token: 'ACCESS012345'}.to_json, [])
        response.expect(:call, response, [
            URI.parse('https://accounts.google.com/o/oauth2/token'),
            {
                client_id: 'ID012345',
                client_secret: 'SECRET012345',
                refresh_token: 'REFRESH012345',
                grant_type: 'refresh_token'
            }
        ])
        Net::HTTP.stub(:post_form, response) do
            sender.refresh!
            assert_equal 'ACCESS012345', sender.access_token
        end
        response.verify
    end

    def test_send
        send_params = {
            to: 'to@email.com',
            subject: 'subject',
            body: 'body'
        }

        sender = GmailSender.new(**@initialize_params)
        assert_raises(GmailSender::NoAccessTokenError) do
            sender.send(**send_params)
        end

        sender.instance_variable_set(:@access_token, 'ACCESS012345')
        gmail = MiniTest::Mock.new
        gmail.expect(:call, nil, [:xoauth, 'from@email.com', {token: 'ACCESS012345'}])
        gmail.expect(:deliver, nil, [
            Mail.new(to: 'to@email.com', subject: 'subject', body: 'body')
        ])
        Gmail.stub(:connect!, gmail, gmail) do
            sender.send(**send_params)
        end
        gmail.verify
    end
end

class ServerTest < Minitest::Test
    include Rack::Test::Methods

    def app
        Sinatra::Application
    end

    def test_returns_400_if_missing_data
        post '/'
        assert_equal 400, last_response.status

        post '/', subject: 'Subject'
        assert_equal 400, last_response.status

        post '/', body: 'Body'
        assert_equal 400, last_response.status
    end

    def test_emails_and_returns_200
        read_response = lambda { |filename|
            if File.basename(filename) == 'config.json'
                return {
                    from: 'from@email.com',
                    to: 'to@email.com',
                    refresh_token: 'REFRESH012345'
                }.to_json
            elsif File.basename(filename) == 'oauth.json'
                return {
                    installed: {
                        client_id: 'ID012345',
                        client_secret: 'SECRET012345'
                    }
                }.to_json
            else
                raise StandardError
            end
        }
        File.stub(:read, read_response) do
            sender = MiniTest::Mock.new
            sender.expect(:call, sender, [{
                from: 'from@email.com',
                client_id: 'ID012345',
                client_secret: 'SECRET012345',
                refresh_token: 'REFRESH012345'
            }])
            sender.expect(:refresh!, nil, [])
            sender.expect(:send, nil, [{to: 'to@email.com', subject: 'subject', body: 'body'}])
            GmailSender.stub(:new, sender) do
                post '/', subject: 'subject', body: 'body'
                assert_equal 200, last_response.status
            end
            sender.verify
        end
    end
end
